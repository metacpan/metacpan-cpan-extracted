package JIRA::API::SanitizedJqlQueries 0.01;
# DO NOT EDIT! This is an autogenerated file.
use 5.020;
use Moo 2;
use experimental 'signatures';
use Types::Standard qw(Str Bool Num Int Object ArrayRef);
use MooX::TypeTiny;

=head1 NAME

JIRA::API::SanitizedJqlQueries -

=head1 SYNOPSIS

  my $obj = JIRA::API::SanitizedJqlQueries->new();
  ...

=cut

sub as_hash( $self ) {
    return { $self->%* }
}

=head1 PROPERTIES

=head2 C<< queries >>

The list of sanitized JQL queries.

=cut

has 'queries' => (
    is       => 'ro',
    isa      => ArrayRef[Object],
);


1;
