package JIRA::API::NotificationSchemeEventTypeId 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::NotificationSchemeEventTypeId -

=head1 SYNOPSIS

  my $obj = JIRA::API::NotificationSchemeEventTypeId->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< id >>

The ID of the notification scheme event.

=cut

has 'id' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


1;
