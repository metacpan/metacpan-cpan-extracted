package JIRA::API::NotificationSchemeEvent 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::NotificationSchemeEvent -

=head1 SYNOPSIS

  my $obj = JIRA::API::NotificationSchemeEvent->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< event >>

Details about a notification event.

=cut

has 'event' => (
    is       => 'ro',
    isa      => Object,
);

=head2 C<< notifications >>

=cut

has 'notifications' => (
    is       => 'ro',
    isa      => ArrayRef[Object],
);


1;
