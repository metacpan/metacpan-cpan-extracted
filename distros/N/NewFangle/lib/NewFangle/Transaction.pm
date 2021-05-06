package NewFangle::Transaction 0.06 {

  use strict;
  use warnings;
  use 5.014;
  use NewFangle::FFI;
  use NewFangle::Segment;
  use FFI::Platypus::Memory ();
  use Ref::Util qw( is_blessed_ref );
  use JSON::MaybeXS ();
  use Carp ();

# ABSTRACT: NewRelic application class


  sub _segment
  {
    my $xsub = shift;
    my $txn = shift;
    my $seg = $xsub->($txn, @_);
    $seg->{txn} = $txn;
    $seg;
  }

  $ffi->attach( start_segment           => ['newrelic_txn_t','string','string'] => 'newrelic_segment_t' => \&_segment );
  $ffi->attach( start_datastore_segment => ['newrelic_txn_t','string[7]']       => 'newrelic_segment_t' => \&_segment );
  $ffi->attach( start_external_segment  => ['newrelic_txn_t','string[3]']       => 'newrelic_segment_t' => \&_segment );


  $ffi->attach( "add_attribute_$_" => ['newrelic_txn_t','string',$_] => 'bool' )
    for qw( int long double string );


  $ffi->attach( notice_error => [ 'newrelic_txn_t', 'int', 'string', 'string' ] );


  if($ffi->find_symbol('notice_error_with_stacktrace'))
  {
    $ffi->attach( notice_error_with_stacktrace => [ 'newrelic_txn_t', 'int', 'string', 'string', 'string' ] => sub {
      my($xsub, $self, $priority, $errmsg, $errorclass, $errstacktrace) = @_;
      $errstacktrace = [split /\n/, $errstacktrace] unless ref $errstacktrace eq 'ARRAY';
      $errstacktrace = JSON::MaybeXS::encode_json($errstacktrace);
      $xsub->($self, $priority, $errmsg, $errorclass, $errstacktrace);
    });
  }
  else
  {
    *notice_error_with_stacktrace = \&notice_error;
  }


  $ffi->attach( [ 'ignore_transaction' => 'ignore' ] => ['newrelic_txn_t'] => 'bool' );


  $ffi->attach( [ end_transaction => 'end' ] => ['opaque*'] => 'bool' );


 $ffi->attach( record_custom_event => [ 'newrelic_txn_t', 'opaque*' ] => sub {
   my($xsub, $self, $event) = @_;
   Carp::croak("event must be a NewFangle::CustomEvent")
     unless ref $event eq 'NewFangle::CustomEvent';
   $xsub->($self, $event);
   1;
 });


  $ffi->attach( record_custom_metric => [ 'newrelic_txn_t', 'string', 'double' ] => 'bool' );


  $ffi->attach( [ set_transaction_name => 'set_name' ] => [ 'newrelic_txn_t', 'string' ] => 'bool' );


  $ffi->attach_cast(_ptr_to_string => 'opaque', 'string');
  sub _create_dt_payload {
    my($xsub, $self, $seg) = @_;
    my $seg_ptr;
    if(defined $seg)
    {
      if(is_blessed_ref($seg) && $seg->isa('NewFangle::Segment'))
      {
        $seg_ptr = $seg->{ptr};
      }
      else
      {
        Carp::croak("$seg is not a NewFangle::Segment");
      }
    }
    my $str_ptr = $xsub->($self, $seg_ptr);
    defined $str_ptr
      ? do {
        my $str = _ptr_to_string($str_ptr);
        FFI::Platypus::Memory::free($str_ptr);
        $str;
      } : ();
  }

  $ffi->attach( create_distributed_trace_payload          => [ 'newrelic_txn_t', 'opaque' ] => 'opaque' => \&_create_dt_payload);
  $ffi->attach( create_distributed_trace_payload_httpsafe => [ 'newrelic_txn_t', 'opaque' ] => 'opaque' => \&_create_dt_payload);


  $ffi->attach( accept_distributed_trace_payload          => [ 'newrelic_txn_t', 'string', 'string' ] => 'bool' );
  $ffi->attach( accept_distributed_trace_payload_httpsafe => [ 'newrelic_txn_t', 'string', 'string' ] => 'bool' );

  sub DESTROY
  {
    my($self) = @_;
    $self->end if defined $$self;
  }

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::Transaction - NewRelic application class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use NewFangle;
 my $app = NewFangle::App->new;
 $app->start_web_transaction("txn_name");

=head1 DESCRIPTION

NewRelic transaction class

=head1 METHODS

=head2 start_segment

 my $seg = $txn->start_segment($name, $category);

Start a new segment.  Returns L<NewFangle::Segment> instance.

(csdk: newrelic_start_segment)

=head2 start_datastore_segment

 my $seg = $txn->start_datastore_segment([$product, $collection, $operation, $host, $port_path_or_id, $database_name, $query]);

Start a new datastore segment.  Returns L<NewFangle::Segment> instance.

(csdk: newrelic_start_datastore_segment)

=head2 start_external_segment

 my $seg = $txn->start_external_segment([$uri,$method,$library]);

Start a new external segment.  Returns L<NewFangle::Segment> instance.

(csdk: newrelic_start_external_segment)

=head2 add_attribute_int

 my $bool = $txn->add_attribute_int($key, $value);

(csdk: newrelic_add_attribute_int)

=head2 add_attribute_long

 my $bool = $txn->add_attribute_long($key, $value);

(csdk: newrelic_add_attribute_long)

=head2 add_attribute_double

 my $bool = $txn->add_attribute_double($key, $value);

(csdk: newrelic_add_attribute_double)

=head2 add_attribute_string

 my $bool = $txn->add_attribute_string($key, $value);

(csdk: newrelic_add_attribute_string)

=head2 notice_error

 $txn->notice_error($priority, $errmsg, $errclass);

For Perl you probably want to use C<notice_error_with_stacktrace>, see below.

(csdk: newrelic_notice_error)

=head2 notice_error_with_stacktrace

 $txn->notice_error_with_stacktrace($priority, $errmsg, $errorclass, $errstacktrace);

This works like notice_error above, except it lets you specify the stack trace instead
of using the C stack trace, which is likely not helpful for a Perl application.

This method requires a patch that hasn't currently been applied to the official NewRelic
C-SDK.  L<Alien::libnewrelic> should apply this fro you, but if you are building the
C-SDK yourself and need this method then you will need to apply this patch.

(csdk: notice_error_with_stacktrace)

=head2 ignore

 my $bool = $txn->ignore;

(csdk: newrelic_ignore_transaction)

=head2 end

 my $bool = $txn->end;

Ends the transaction.

(csdk: newrelic_end_transaction)

=head2 record_custom_event

 $txn->record_custom_event($event);

C<$event> should be an instance of L<NewFangle::CustomEvent>.

(csdk: newrelic_record_custom_event)

=head2 record_custom_metric

 $txn->record_custom_metric($name, $milliseconds);

(csdk: newrelic_record_custom_metric)

=head2 set_name

 my $bool = $txn->set_name($name);

(csdk: newrelic_set_transaction_name)

=head2 newrelic_create_distributed_trace_payload

 my $payload = $txn->create_distributed_trace_payload;
 my $payload = $txn->create_distributed_trace_payload($seg);

Note that to use distributed tracing the L<NewFangle::App> instance must have it enabled in
the configuration.  You can do this like:

 my $app = NewFangle::App->new({ distributed_tracing => { enabled => 1 } });

(csdk: newrelic_create_distributed_trace_payload)

=head2 newrelic_create_distributed_trace_payload_httpsafe

 my $payload = $txn->create_distributed_trace_payload_httpsafe;
 my $payload = $txn->create_distributed_trace_payload_httpsafe($seg);

(csdk: newrelic_create_distributed_trace_payload_httpsafe)

=head2 accept_distributed_trace_payload

 my $bool = $txn->accept_distributed_trace_payload($payload, $transport_type);

C<$transport_type> the recommended values are:

=over 4

=item C<Unknown>

=item C<HTTP>

=item C<HTTPS>

=item C<Kafka>

=item C<JMS>

=item C<IronMQ>

=item C<AMQP>

=item C<Queue>

=item C<Other>

=back

C<undef> can also be used in place of C<Unknown>, but an info-level message will be logged.

(csdk: newrelic_accept_distributed_trace_payload)

=head2 accept_distributed_trace_payload_httpsafe

 my $bool = $txn->accept_distributed_trace_payload_httpsafe($payload, $transport_type);

Same as C<accept_distributed_trace_payload> above, but uses the payload
from C<create_distributed_trace_payload_httpsafe>.

(csdk: newrelic_accept_distributed_trace_payload_httpsafe)

=head1 SEE ALSO

=over 4

=item L<NewFangle>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
