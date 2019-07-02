package NewRelic::Agent::FFI::Procedural;

use strict;
use warnings;
use 5.010;
use FFI::Platypus 0.56;
use FFI::Platypus::Memory qw( strdup free );
use FFI::Platypus::DL qw( dlopen dlerror RTLD_NOW RTLD_GLOBAL );
use FFI::CheckLib 0.25 qw( find_lib_or_die );
use base qw( Exporter );
use constant NEWRELIC_RETURN_CODE_OK                      => 0;
use constant NEWRELIC_RETURN_CODE_OTHER                   => -0x10001;
use constant NEWRELIC_RETURN_CODE_DISABLED                => -0x20001;
use constant NEWRELIC_RETURN_CODE_INVALID_PARAM           => -0x30001;
use constant NEWRELIC_RETURN_CODE_INVALID_ID              => -0x30002;
use constant NEWRELIC_RETURN_CODE_TRANSACTION_NOT_STARTED => -0x40001;
use constant NEWRELIC_RETURN_CODE_TRANSACTION_IN_PROGRESS => -0x40002;
use constant NEWRELIC_RETURN_CODE_TRANSACTION_NOT_NAMED   => -0x40003;
use constant NEWRELIC_ROOT_SEGMENT => 0;
use constant NEWRELIC_AUTOSCOPE    => 1;
use constant NEWRELIC_STATUS_CODE_SHUTDOWN => 0;
use constant NEWRELIC_STATUS_CODE_STARTING => 1;
use constant NEWRELIC_STATUS_CODE_STOPPING => 2;
use constant NEWRELIC_STATUS_CODE_STARTED  => 3;

# ABSTRACT: Procedural interface for NewRelic APM
our $VERSION = '0.09'; # VERSION


my $ffi;
our @lib;

BEGIN {
  $ffi = FFI::Platypus->new;
  $ffi->lib(@lib = do {
    my @find_lib_args = (
      lib => [ qw(newrelic-collector-client newrelic-common newrelic-transaction) ],
      alien => ['Alien::nragent'],
    );
    push @find_lib_args, libpath => ['/opt/newrelic/lib/'] if -d '/opt/newrelic/lib/';
    find_lib_or_die(@find_lib_args);
  });
}


$ffi->attach( newrelic_init => [ 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int' => sub {
  my($xsub, $license_key, $app_name, $app_language, $app_language_version) = @_;

  $license_key          ||= $ENV{NEWRELIC_LICENSE_KEY}          || '';
  $app_name             ||= $ENV{NEWRELIC_APP_NAME}             || 'AppName';
  $app_language         ||= $ENV{NEWRELIC_APP_LANGUAGE}         || 'perl';
  $app_language_version ||= $ENV{NEWRELIC_APP_LANGUAGE_VERSION} || $];

  my @new = (strdup($license_key), strdup($app_name), strdup($app_language), strdup($app_language_version));

  my $ret = $xsub->(@new);

  # cannot find documentation to confirm, but NR doesn't appear to copy these strings,
  # so we copy them.  But we want to free the old strings if we re-init.
  # NB. it's not even clear to me from the NR doco that you should be calling _init more than
  # once, but we've been doing it in production via NewRelic::Agent so...
  state $olds = [];
  foreach my $old (@$olds)
  {
    free($old);
  }
  $olds = \@new;
  
  $ret;
});


$ffi->attach( newrelic_transaction_begin                  => []                                                 => 'long' );
$ffi->attach( newrelic_transaction_set_name               => [ 'long', 'string' ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_request_url        => [ 'long', 'string' ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_max_trace_segments => [ 'long', 'int'    ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_category           => [ 'long', 'string' ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_type_web           => [ 'long' ]                                         => 'int'  );
$ffi->attach( newrelic_transaction_set_type_other         => [ 'long' ]                                         => 'int'  );
$ffi->attach( newrelic_transaction_add_attribute          => [ 'long', 'string', 'string' ]                     => 'int'  );
$ffi->attach( newrelic_transaction_notice_error           => [ 'long', 'string', 'string', 'string', 'string' ] => 'int'  );
$ffi->attach( newrelic_transaction_end                    => [ 'long' ]                                         => 'int'  );
$ffi->attach( newrelic_record_metric                      => [ 'string', 'double']                              => 'int'  );
$ffi->attach( newrelic_record_cpu_usage                   => [ 'double', 'double' ]                             => 'int'  );
$ffi->attach( newrelic_record_memory_usage                => [ 'double' ]                                       => 'int'  );
$ffi->attach( newrelic_segment_generic_begin              => [ 'long', 'long', 'string' ]                       => 'long' );


# the OO version explicitly passes in newrelic_basic_literal_replacement_obfuscator, but this doesn't seem to
# do much, as that appears to be the default.  For the Procedural version we pass in NULL by default, but you
# can override with another symbol if you want.  Needs to be a C symbol though, not a Perl code ref.
$ffi->attach( newrelic_segment_datastore_begin => [ 'long', 'long', 'string', 'string', 'string', 'string', 'opaque' ] => 'long' );


$ffi->attach( newrelic_segment_external_begin => [ 'long', 'long', 'string', 'string' ] => 'long' );
$ffi->attach( newrelic_segment_end            => [ 'long', 'long' ] => 'int' );


$ffi->attach( newrelic_register_message_handler => ['opaque'] => 'void' );
use constant newrelic_message_handler => $ffi->find_symbol('newrelic_message_handler');


use constant newrelic_basic_literal_replacement_obfuscator => $ffi->find_symbol('newrelic_basic_literal_replacement_obfuscator');


$ffi->attach( newrelic_request_shutdown => ['string'] => 'int' );


$ffi->attach( newrelic_enable_instrumentation => ['int'] => 'void' );

## TODO: make this work
#=head2 newrelic_register_status_callback
#
# newrelic_register_status_callback $callback;
#
#Register a function to be called whenever the status of the Collector Client
#changes.
#
#=cut
#
#$ffi->type('(int)->void' => 'status_callback_t');
#$ffi->attach( newrelic_register_status_callback => ['opaque'] => 'void' => sub {
#  my($xsub, $cb) = @_;
#
#  state $cb_code;
#  state $cb_closure;
#  state $cb_ptr;
#  
#  if(ref $cb eq 'CODE')
#  {
#    $cb_code = $cb;
#    $cb_closure = $ffi->closure($cb);
#    $cb_ptr     = $ffi->cast(status_callback_t => 'opaque', $cb_closure);
#    $xsub->($cb_ptr);
#  }
#  else
#  {
#    undef $cb_code;
#    undef $cb_closure;
#    undef $cb_ptr;
#    $xsub->($cb);
#  }
#});

our @EXPORT = sort grep /^newrelic_/i, keys %NewRelic::Agent::FFI::Procedural::;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewRelic::Agent::FFI::Procedural - Procedural interface for NewRelic APM

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use NewRelic::Agent::FFI::Procedural;
 
 # enable embedded mode:
 newrelic_register_message_handler newrelic_message_handler;
 
 # initialize:
 newrelic_init
   'abc123'     # license key
   'REST API'   # app name
 ;
 
 # use it:
 my $tx = newrelic_transaction_begin;
 ...
 my $rc = newrelic_transaction_end $tx;

=head1 DESCRIPTION

This module provides bindings for the L<NewRelic|https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk> Agent SDK.

Unlike L<NewRelic::Agent::FFI>, this is NOT a drop in replacement for L<NewRelic::Agent>.  The author believes this interface is better.
In addition to the reasons the author believes L<NewRelic::Agent::FFI> to be better than L<NewRelic::Agent> (listed in the former's documentation),
the author believes this module to be better than L<NewRelic::Agent::FFI> because:

=over 4

=item Object oriented interface does represent or add anything

The L<NewRelic::Agent> instance that you create doesn't represent anything in the NewRelic Agent SDK.  In fact if you don't understand
how things work under the hood, you might be confused into believing that you can initialize multiple agent instances in the same process.

=item Object oriented interface is slower

Because the unused C<$agent> instance needs to be shifted off the stack before calling the underlying C code there is a lot more overhead in the
object oriented interface.

=item Functions aren't renamed

The object oriented version renames a number of its methods, so translating C/C++ example code is nearly impossible.
The procedural version uses the same function name and constants, so translating example code from other languages
is easy.

=item API is complete

This interface is more complete than the object oriented version.

=back

=head1 FUNCTIONS

All functions are exported by default.  You can explicitly specify just the functions that you want in the
usual L<Exporter> way if you prefer.

Functions that return a C<$rc> will return one of these codes (NEWRELIC_RETURN_CODE_OK is 0, the others
are negative values):

=over 4

=item NEWRELIC_RETURN_CODE_OK

=item NEWRELIC_RETURN_CODE_OTHER

=item NEWRELIC_RETURN_CODE_DISABLED

=item NEWRELIC_RETURN_CODE_INVALID_PARAM

=item NEWRELIC_RETURN_CODE_INVALID_ID

=item NEWRELIC_RETURN_CODE_TRANSACTION_NOT_STARTED

=item NEWRELIC_RETURN_CODE_TRANSACTION_IN_PROGRESS

=item NEWRELIC_RETURN_CODE_TRANSACTION_NOT_NAMED

=back

Functions that return a C<$tx> will return a transaction id on success, and a (negative) C<$rc> code on failure.

Functions that return a C<$seg> will return a segment id on success, and a (negative) C<$rc> code on failure.

Functions that return a C<$address> are the address to a C function that can be passed to other C<newrelic_> functions as appropriate.

For functions that take a C<$parent_seg> argument, you can pass in NEWRELIC_AUTOSCOPE or NEWRELIC_ROOT_SEGMENT instead of
a literal segment id.

For functions that take a C<$tx> argument, you can pass in NEWRELIC_AUTOSCOPE instead of a literal transaction id.

=head2 newrelic_init

 my $rc = newrelic_init $license_key, $app_name, $app_language, $app_language_version;

Initialize the connection to NewRelic.

=over 4

=item C<$license_key>

A valid NewRelic license key for your account.

This value is also automatically sourced from the C<NEWRELIC_LICENSE_KEY> environment variable.

=item C<$app_name>

The name of your application.

This value is also automatically sourced from the C<NEWRELIC_APP_NAME> environment variable.

=item C<$app_language>

The language that your application is written in.

This value defaults to C<perl>, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE> environment variable.

=item C<$app_language_version>

The version of the language that your application is written in.

This value defaults to your perl version, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE_VERSION> environment variable.

=back

=head2 newrelic_transaction_begin

 my $tx = newrelic_transaction_begin;

Identifies the beginning of a transaction, which is a timed operation consisting of multiple segments. By default, transaction type is set to C<WebTransaction> and transaction category is set to C<Uri>.

Returns the transaction's ID on success, else negative warning code or error code.

=head2 newrelic_transaction_set_name

 my $rc = newrelic_transaction_set_name $tx, $name;

Sets the transaction name.

=head2 newrelic_transaction_set_request_url

 my $rc = newrelic_transaction_set_request_url $tx, $url;

Sets the transaction URL.

=head2 newrelic_transaction_set_max_trace_segments

 my $rc = newrelic_transaction_set_max_trace_segments $tx, $max;

Sets the maximum trace section for the transaction.

=head2 newrelic_transaction_set_category

 my $rc = newrelic_transaction_set_category $tx, $category;

Sets the transaction category.

=head2 newrelic_transaction_set_type_web

 my $rc = newrelic_transaction_set_type_web $tx;

Sets the transaction type to 'web'

=head2 newrelic_transaction_set_type_other

 my $rc = newrelic_transaction_set_type_other $tx;

Sets the transaction type to 'other'

=head2 newrelic_transaction_add_attribute

 my $rc = newrelic_transaction_add_attribute $tx, $key => $value;

Adds the given attribute (key/value pair) for the transaction.

=head2 newrelic_transaction_notice_error

 my $rc = newrelic_transaction_notice_error $tx, $exception_type, $error_message, $stack_trace, $stack_frame_delimiter;

Identify an error that occurred during the transaction. The first identified
error is sent with each transaction.

=head2 newrelic_transaction_end

 my $rc = newrelic_transaction_end $tx;

=head2 newrelic_record_metric

 my $rc = newrelic_record_metric $key => $value;

Records the given metric (key/value pair).  The C<$value> should be a floating point.

=head2 newrelic_record_cpu_usage

 my $rc = newrelic_record_cpu_usage $cpu_user_time_seconds, $cpu_usage_percent;

Records the CPU usage. C<$cpu_user_time_seconds> and C<$cpu_usage_percent> are floating point values.

=head2 newrelic_record_memory_usage

 my $rc = newrelic_record_memory_usage $memory_megabytes;

Records the memory usage. C<$memory_megabytes> is a floating point value.

=head2 newrelic_segment_generic_begin

 my $seg = newrelic_segment_generic_begin $tx, $parent_seg, $name;

Begins a new generic segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).  C<$name> is a string.

=head2 newrelic_segment_datastore_begin

 my $seg = newrelic_segment_datastore_begin $tx, $parent_seg, $table, $operation, $sql, $sql_trace_rollup_name;
 my $seg = newrelic_segment_datastore_begin $tx, $parent_seg, $table, $operation, $sql, $sql_trace_rollup_name, $sql_obfuscator;

Begins a new datastore segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).  C<$operation> should be
one of C<select>, C<insert>, C<update> or C<delete>.

If you want to provide your own obfuscator, you need to pass in the address of a C function.  To do that from Perl you can
create a closure with L<FFI::Platypus>, like so:

 use 5.010;
 use FFI::Platypus;
 use FFI::Platypus::Memory qw( strdup free );
 
 sub myobfuscator
 {
   # input SQL
   my($sql) = @_;
   
   # make some kind of transformation
   $sql =~ tr/a-z/z-a/;
   
   # because C has a different ownership model than Perl for functions
   # that return a string, you need to create a C pointer to a copy of
   # the return value.  On the next call we will free the previous copy.
   state $ptr = 0;
   free($ptr) if $ptr;
   return $ptr = strdup($sql);
 }
 
 $ffi->type('(string)->opaque' => 'obfuscator_t');
 my $myobfuscator_closure = $ffi->closure(\&myobfuscator);
 my $myobfuscator_ptr     = $ffi->cast('obfuscator_t' => 'opaque', $myobfuscator_closure);
 
 newrelic_segment_datastore_begin $tx, $seg, $table, $sql, $rollup, $myobfuscator_ptr;
 ...

=head2 newrelic_segment_external_begin

 my $seg = newrelic_segment_external_begin $tx, $parent_seg, $host, $name;

Begins a new external segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).

=head2 newrelic_segment_end

 my $rc = newrelic_segment_end $tx, $seg;

End the given segment.

=head2 newrelic_register_message_handler

 newrelic_register_message_handler $handler;

Register the message handler used to send messages to NewRelic.  The only useful way at the moment to use
this function is by giving it C<newrelic_message_handler>, which sends messages directly to NewRelic,
rather than through a separate daemon process:

 newrelic_register_message_handler newrelic_message_handler;

This needs to be called BEFORE you call C<newrelic_init>.

=head2 newrelic_message_handler

 my $address = newrelic_message_handler;

Returns the address of the C function that handles sending messages directly to NewRelic.  This cannot
be called directly from Perl, but can be passed to C<newrelic_register_message_handler> like so:

 newrelic_register_message_handler newrelic_message_handler;

This needs to be called BEFORE you call C<newrelic_init>.

=head2 newrelic_basic_literal_replacement_obfuscator

 my $address = newrelic_basic_literal_replacement_obfuscator;

Returns the address of the C function that does the basic/default obfuscator contained within the
NewRelic agent library.  Normally you wouldn't call this from Perl, so it is the address of the
function, not the function itself.  You can, however, call it via L<FFI::Platypus>:

 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new;
 $new->attach( newrelic_basic_literal_replacement_obfuscator, ['string'] => 'string');
 my $save = newrelic_basic_literal_replacement_obfuscator("SELECT * FROM user WHERE password = 'secret'");

=head2 newrelic_request_shutdown

 my $rc = newrelic_request_shutdown $reason;

Tell the Collector Client to shutdown and stop reporting application performance data to New Relic.

=head2 newrelic_enable_instrumentation

 newrelic_enable_instrumentation $set_enabled;

Disable/enable instrumentation. By default, instrumentation is enabled.

C<$set_enabled>  0 to disable, 1 to enable

=head1 CAVEATS

=head2 Platform Limitations

The SDK binaries provided by New Relic only work on Linux x86_64.  The binaries are labeled
as a "beta" and were released in July 2016.  It doesn't seem likely that New Relic will be
releasing new versions of the SDK.  The author of this module has had good success getting
this module to work on Ubuntu Precise and Xenial, and heard from user feedback that it works
with Bionic.  I have heard that it does NOT work with CentOS 7.  Your mileage may vary.

=head2 Not Fork Safe!

Bad things will happen if you call newrelic_init before forking.  So don't do that.

=head1 SEE ALSO

=over 4

=item L<NewRelic::Agent::FFI>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ville Skyttä (SCOP)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
