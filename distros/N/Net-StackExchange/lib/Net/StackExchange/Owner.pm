package Net::StackExchange::Owner;
BEGIN {
  $Net::StackExchange::Owner::VERSION = '0.102740';
}

# ABSTRACT: Attributes to represent a user

use Moose;
use Moose::Util::TypeConstraints;

has [
    qw{
        user_id
        reputation
      }
    ] => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has 'user_type' => (
    is       => 'rw',
    isa      => enum( [ qw{ anonymous unregistered registered moderator } ] ),
    required => 1,
);

has [
    qw{
        display_name
        email_hash
      }
    ] => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

no Moose;
no Moose::Util::TypeConstraints;

1;



=pod

=head1 NAME

Net::StackExchange::Owner - Attributes to represent a user

=head1 VERSION

version 0.102740

=head1 SYNOPSIS

=head1 ATTRIBUTES

=head2 C<user_id>

Returns id of the user.

=head2 C<user_type>

Returns type of the user.

=head2 C<display_name>

Returns displayable name of the user.

=head2 C<reputation>

Returns reputation of the user.

=head2 C<email_hash>

Returns email hash, suitable for fetching a gravatar.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

