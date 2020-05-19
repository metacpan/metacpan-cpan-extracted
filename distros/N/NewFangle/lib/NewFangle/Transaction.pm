package NewFangle::Transaction 0.01 {

  use strict;
  use warnings;
  use 5.020;
  use NewFangle::FFI;
  use NewFangle::Segment;
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


  $ffi->attach( "notice_error" => [ 'newrelic_txn_t', 'int', 'string', 'string' ] );


  $ffi->attach( [ 'ignore_transaction' => 'ignore' ] => ['newrelic_txn_t'] => 'bool' );


  $ffi->attach( [ end_transaction => 'end' ] => ['opaque*'] => 'bool' );


 $ffi->attach( record_custom_event => [ 'newrelic_txn_t', 'opaque*' ] => sub {
   my($xsub, $self, $event) = @_;
   Carp::croak("event must be a NewFangle::CustomEvent")
     unless ref $event eq 'NewFangle::CustomEvent';
   $xsub->($self, $event);
 });


  $ffi->attach( record_custom_metric => [ 'newrelic_txn_t', 'string', 'double' ] => 'bool' );


  $ffi->attach( [ set_transaction_name => 'set_name' ] => [ 'newrelic_txn_t', 'string' ] => 'bool' );

# TODO: newrelic_create_distributed_trace_payload
# TODO: newrelic_accept_distributed_trace_payload
# TODO: newrelic_create_distributed_trace_payload_httpsafe
# TODO: newrelic_accept_distributed_trace_payload_httpsafe

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

version 0.01

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

(csdk: newrelic_notice_error)

=head2 ignore

 my $bool = $txn->ignore;

csdk: newrelic_ignore_transaction)

=head2 end

 my $bool = $txn->end;

Ends the transaction.

(csdk: newrelic_end_transaction)

=head2 record_custom_event

 $txn->record_custom_event;

(csdk: newrelic_record_custom_event)

=head2 record_custom_metric

 $txn->record_custom_metric($name, $milliseconds);

(csdk: newrelic_record_custom_metric)

=head2 set_name

 my $bool = $txn->set_name($name);

(csdk: newrelic_set_transaction_name)

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
