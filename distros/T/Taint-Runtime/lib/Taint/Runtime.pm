package Taint::Runtime;

=head1 NAME

Taint::Runtime - Runtime enable taint checking

=cut

use strict;
use Exporter;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION $TAINT);
use XSLoader;

@ISA = qw(Exporter);
%EXPORT_TAGS = (
                'all' => [qw(
                             taint_start
                             taint_stop
                             taint_enabled
                             tainted
                             is_tainted
                             taint
                             untaint
                             taint_env
                             taint_deeply
                             $TAINT
                             ) ],
                );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw(taint_start taint_stop);

$VERSION = '0.03';
XSLoader::load('Taint::Runtime', $VERSION);

###----------------------------------------------------------------###

tie $TAINT, __PACKAGE__;

sub TIESCALAR {
  return bless [], __PACKAGE__;
}

sub FETCH {
  _taint_enabled() ? 1 : 0;
}

sub STORE {
  my ($self, $val) = @_;
  $val = 0 if ! $val || $val eq 'disable';
  $val ? _taint_start() : _taint_stop();
}

###----------------------------------------------------------------###

### allow for special enable/disable keywords
sub import {
  my $change;
  for my $i (reverse 1 .. $#_) {
    next if $_[$i] !~ /^(dis|en)able$/;
    my $val = $1 eq 'dis' ? 0 : 1;
    splice @_, $i, 1, ();
    die 'Cannot both enable and disable $TAINT during import' if defined $change && $change != $val;
    $TAINT = $val;
  }
  __PACKAGE__->export_to_level(1, @_);
}

###----------------------------------------------------------------###

sub taint_start { _taint_start(); }

sub taint_stop  { _taint_stop() }

sub taint_enabled { _taint_enabled() }

sub tainted { _tainted() }

sub is_tainted { return if ! defined $_[0]; ! eval { eval '#'.substr($_[0], 0, 0); 1 } }

# slower on tainted and undef
# modified version from standard lib/perl/5.8.5/tainted.pl
sub is_tainted2 { local $^W = 0; local $@; eval { kill 0 * $_[0] }; $@ =~ /^Insecure/ }

sub taint {
  my $str = shift;
  my $ref = ref($str) ? $str : \$str;
  $$ref = '' if ! defined $$ref;
  $$ref .= tainted();
  return ref($str) ? 1 : $str;
}

sub untaint {
  my $str = shift;
  my $ref = ref($str) ? $str : \$str;
  if (! defined $$ref) {
    $$ref = undef;
  } else {
    $$ref = ($$ref =~ /(.*)/s) ? $1 : do { require Carp; Carp::confess("Couldn't find data to untaint") };
  }
  return ref($str) ? 1 : $str;
}

###----------------------------------------------------------------###

sub taint_env {
  taint_deeply(\%ENV);
}

sub taint_deeply {
  my ($ref, $seen) = @_;

  return if ! defined $ref; # can undefined be tainted ?

  if (! ref $ref) {
    taint \$_[0]; # better be modifyable
    return;

  } elsif (UNIVERSAL::isa($ref, 'SCALAR')) {
    taint $ref;
    return;
  }

  ### avoid circular descent
  $seen ||= {};
  return if $seen->{$ref};
  $seen->{$ref} = 1;

  if (UNIVERSAL::isa($ref, 'ARRAY')) {
    taint_deeply($_, $seen) foreach @$ref;

  } elsif (UNIVERSAL::isa($ref, 'HASH')) {
    while (my ($key, $val) = each %$ref) {
      taint_deeply($key);
      taint_deeply($val, $seen);
      $ref->{$key} = $val;
    }
  } else {
    # not really sure if or what to do for GLOBS or CODE refs
  }
}

###----------------------------------------------------------------###

1;

__END__

=head1 SYNOPSIS

  ### sample "enable" usage

  #!/usr/bin/perl -w
  use Taint::Runtime qw(enable taint_env);
  taint_env();
  # having the keyword enable in the import list starts taint


  ### sample $TAINT usage

  #!/usr/bin/perl -w
  use Taint::Runtime qw($TAINT taint_env);
  $TAINT = 1;
  taint_env();

  # taint is now enabled

  if (1) {
    local $TAINT = 0;

    # do something we trust
  }

  # back to an untrustwory area



  ### sample functional usage

  #!/usr/bin/perl -w
  use strict;
  use Taint::Runtime qw(taint_start is_tainted taint_env
                        taint untaint
                        taint_enabled);

  ### other operations here

  taint_start(); # taint should become active
  taint_env(); # %ENV was previously untainted

  print taint_enabled() ? "enabled\n" : "not enabled\n";

  my $var = taint("some string");

  print is_tainted($var) ? "tainted\n" : "not tainted\n";

  $var = untaint($var);
  # OR
  untaint \$var;

  print is_tainted($var) ? "tainted\n" : "not tainted\n";



=head1 DESCRIPTION

First - you probably shouldn't use this module to control taint.
You should probably use the -T switch on the commandline instead.
There are a somewhat limited number of legitimate use cases where
you should use this module instead of the -T switch.  Unless you
have a specific and good reason for not using the -T option, you
should use the -T option.

Taint is a good thing.  However, few people (that I work with or talk
to or discuss items with) use taint even though they should.  The goal of
this module isn't to use taint less, but to actually encourage its use
more.  This module aims to make using taint as painless as possible (This
can be an argument against it - often implementation of security implies
pain - so taking away pain might lessen security - sort of).

In general - the more secure your script needs to be - the earlier
on in your program that tainting should be enabled.  For most setuid scripts,
you should enable taint by using the -T switch.  Without doing so you allow
for a non-root user to override @INC which allows for them to put their
own module in the place of trusted modules.  This is bad.  This is very bad.
Use the -T switch.

There are some common places where this module may be useful, and where
most people don't use it.  One such place is in a web server.  The -T switch
removes PERL5LIB and PERLLIB and '.' from @INC (or remove them before
they can be added).  This makes sense under setuid.  The use of the -T switch
in a CGI environment may cause a bit of a headache.  For new development,
CGI scripts it may be possible to use the -T switch and for mod_perl environments
there is the PerlTaint variable.  Both of these methods will enable taint
and from that point on development should be done with taint.

However, many (possibly most) perl web server implentations add their
own paths to the PERL5LIB.  All CGI's and mod_perl scripts can then have access.
Using the -T switch throws a wrench into the works as suddenly PERL5LIB
disappears (mod_perl can easily have the extra directories added again
using <perl>push @INC, '/our/lib/dir';</perl>).  The company I work for
has 200 plus user visible scripts mixed with some mod_perl.  Currently
none of the scripts use taint.  We would like for them all to, but it
is not feasible to make the change all at once.  Taint::Runtime allows for moving legacy
scripts over one at a time.

Again, if you are using setuid - don't use this script.

If you are not using setuid and have reasons not to use the -T and are
using this module, make sure that taint is enabled before processing
any user data.  Also remember that BECAUSE THE -T SWITCH WAS NOT USED
%ENV IS INITIALLY NOT MARKED AS TAINTED.  Call taint_env() to mark
it as tainted (especially important in CGI scripts which all read from
$ENV{'QUERY_STRING'}).

If you are not using the -T switch, you most likely should use the
following at the very top of your script:

  #!/usr/bin/perl -w

  use strict;
  use Taint::Runtime qw(enable taint_env);
  taint_env();

Though this module allows for you to turn taint off - you probably shouldn't.
This module is more for you to turn taint on - and once it is on it probably
ought to stay on.

=head1 NON-EXPORTABLE XS FUNCTIONS

The following very basic functions provide the base functionality.

=over 4

=item _taint_start()

Sets PL_tainting

=item _taint_stop()

Sets PL_tainting

=item _taint_enabled()

View of PL_tainting

=item _tainted()

Returns a zero length tainted string.

=back

=head1 $TAINT VARIABLE

The variable $TAINT is tied to the current state of taint.
If $TAINT is set to 0 taint mode is off.  When it is set to
1 taint mode is enabled.

  if (1) {
    local $TAINT = 1;

    # taint is enabled
  }

=head1 EXPORT FUNCTIONS

=over 4

=item enable/disable

Not really functions.  If these keywords are in
the import list, taint will be either enabled
or disabled.

=item taint_start

Start taint mode.  $TAINT will equal 1.

=item taint_stop

Stop taint mode.  $TAINT will equal 0.

=item taint_env

Convenience function that taints the keys and values of %ENV.  If
the -T switch was not used - you most likely should call
this as soon as taint mode is enabled.

=item taint

Taints the passed in variable.  Only works on writeable scalar values.
If a scalar ref is passed in - it is modified.  If a scalar is passed in
(non ref) it is copied, modified and returned.  If a value was undefined,
it becomes a zero length defined and tainted string.

  taint(\$var_to_be_tainted);

  my $tainted_copy = taint($some_var);

For a stronger taint, see the Taint module by Dan Sulgalski which is
capable of tainting most types of data.

=item untaint

Untaints the passed in variable.  Only works on writeable scalar values.
If a scalar ref is passed in - it is modified.  If a scalar is passed in
(non ref) it is copied, modified and returned.  If a value was undefined
it becomes an untainted undefined value.

Note:  Just because the variable is untainted, doesn't mean that it
is safe.  You really should use CGI::Ex::Validate, or Data::FormValidator
or any of the Untaint:: modules.  If you are doing your own validation, and
once you have put the user data through very strict checks, then you
can use untaint.

  if ($var_to_be_untainted =~ /^[\w\.\-]{0,100}$/) {
    untaint(\$var_to_be_untainted);
  }

  my $untainted_copy = untaint($some_var);

=item taint_enabled

Boolean - Is taint on.

=item tainted

Returns a zero length tainted string.

=item is_tainted

Boolean - True if the passed value is tainted.

=item taint_deeply

Convenience function that attempts to deply recurse a
structure and mark it as tainted.  Takes a hashref, arrayref,
scalar ref, or scalar and recursively untaints the structure.

For a stronger taint, see the Taint module by Dan Sulgalski which is
capable of tainting most types of data.

=back

=head1 TURNING TAINT ON

(Be sure to call taint_env() after turning taint on the first time)

  #!/usr/bin/perl -T


  use Taint::Runtime qw(enable);
  # this does not create a function called enable - just starts taint

  use Taint::Runtime qw($TAINT);
  $TAINT = 1;


  use Taint::Runtime qw(taint_start);
  taint_start;


=head1 TURNING TAINT OFF

  use Taint::Runtime qw(disable);
  # this does not create a function called disable - just stops taint


  use Taint::Runtime qw($TAINT);
  $TAINT = 0;


  use Taint::Runtime qw(taint_stop);
  taint_stop;


=head1 CREDITS

C code was provided by "hv" on perlmonks.  This module wouldn't
really be possible without insight into the internals that "hv"
provided.  His post with the code was shown in this node on
perlmonks:

  http://perlmonks.org/?node_id=434086

The basic premise in that node was the following code:

  use Inline C => 'void _start_taint() { PL_tainting = 1; }';
  use Inline C => 'SV* _tainted() { PL_tainted = 1; return newSVpvn("", 0); }';

In this module, these two lines have instead been turned into
XS for runtime speed (and so you won't need Inline and Parse::RecDescent).

Note: even though "hv" provided the base code example, that doesn't mean that he
necessarily endorses the idea.  If there are disagreements, quirks, annoyances
or any other negative side effects with this module - blame me - not "hv."

=head1 THANKS

Thanks to Alexey A. Kiritchun for pointing out untaint failure on multiline strings.

=head1 AUTHOR

Paul Seamons (2005)

C stub functions by "hv" on perlmonks.org

=head1 LICENSE

This module may be used and distributed under the same
terms as Perl itself.

=cut
