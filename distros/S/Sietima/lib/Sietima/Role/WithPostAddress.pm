package Sietima::Role::WithPostAddress;
use Moo::Role;
use Sietima::Policy;
use Sietima::Types qw(Address AddressFromStr);
use namespace::clean;

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: role for lists with a posting address


has post_address => (
    is => 'lazy',
    isa => Address,
    coerce => AddressFromStr,
);
sub _build_post_address($self) { $self->return_path }

around list_addresses => sub($orig,$self) {
    return +{
        $self->$orig->%*,
        post => $self->post_address,
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::WithPostAddress - role for lists with a posting address

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('WithPostAddress')->new({
    %args,
    return_path => 'list-bounce@example.com',
    post_address => 'list@example.com',
  });

=head1 DESCRIPTION

This role adds an L<< /C<post_address> >> attribute, and exposes it
via the L<< C<list_addresses>|Sietima/list_addresses >> method.

On its own, this role is not very useful, but other roles (like L<<
C<ReplyTo>|Sietima::Role::ReplyTo >>) can have uses for a post
address.

=head1 ATTRIBUTES

=head2 C<post_address>

An L<< C<Email::Address> >> object, defaults to the value of the L<<
C<return_path>|Sietima/return_path >> attribute. This is the address
that the mailing list receives messages at.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
