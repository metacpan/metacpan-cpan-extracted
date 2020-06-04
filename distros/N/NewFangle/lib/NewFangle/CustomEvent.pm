package NewFangle::CustomEvent 0.03 {

  use strict;
  use warnings;
  use 5.020;
  use NewFangle::FFI;
  use Carp ();

# ABSTRACT: NewRelic custom event class


  $ffi->attach( [ create_custom_event => 'new' ] => ['string'] => 'newrelic_custom_event_t' => sub {
    my($xsub, undef, $event_type) = @_;
    my $self = $xsub->($event_type);
    Carp::croak("unable to create NewFangle::CustomEvent instance, see log for details") unless defined $self;
    $self;
  });


  $ffi->attach( [ "custom_event_add_attribute_$_" => "add_attribute_$_" ] => [ 'newrelic_custom_event_t', 'string', $_ ] => 'bool' )
    for qw( int long double string );

  $ffi->attach( [ discard_custom_event => 'DESTROY' ] => ['opaque*'] => 'bool' => sub {
    my($xsub, $self) = @_;
    my $ptr = $$self;
    $xsub->(\$ptr) if $ptr;
  });

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::CustomEvent - NewRelic custom event class

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use NewFangle;
 my $app   = NewFangle::App->new;
 my $txn   = $app->start_web_transaction("my-txn");
 my $event = NewFangle::CustomEvent->new("my event");
 $txn->record_custom_event($event);

=head1 DESCRIPTION

NewRelic custom event class.

=head1 CONSTRUCTOR

=head2 new

 my $event = NewFangle::CustomEvent->new($event_type);

Creates a NewRelic application custom event.

(csdk: newrelic_create_custom_event)

=head2 add_attribute_int

 $event->add_attribute_int($key, $value);

(csdk: newrelic_custom_event_add_attribute_int)

=head2 add_attribute_long

 $event->add_attribute_long($key, $value);

(csdk: newrelic_custom_event_add_attribute_long)

=head2 add_attribute_double

 $event->add_attribute_double($key, $value);

(csdk: newrelic_custom_event_add_attribute_double)

=head2 add_attribute_string

 $event->add_attribute_string($key, $value);

(csdk: newrelic_custom_event_add_attribute_string)

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
