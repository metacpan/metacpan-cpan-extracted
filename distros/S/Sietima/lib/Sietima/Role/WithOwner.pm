package Sietima::Role::WithOwner;
use Moo::Role;
use Sietima::Policy;
use Sietima::Types qw(Address AddressFromStr);
use namespace::clean;

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: role for lists with an owner


has owner => (
    is => 'ro',
    isa => Address,
    required => 1,
    coerce => AddressFromStr,
);


around list_addresses => sub($orig,$self) {
    return +{
        $self->$orig->%*,
        owner => $self->owner,
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::WithOwner - role for lists with an owner

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('WithOwner')->new({
    %args,
    owner => 'listmaster@example.com',
  });

=head1 DESCRIPTION

This role adds an L<< /C<owner> >> attribute, and exposes it via the
L<< C<list_addresses>|Sietima/list_addresses >> method.

On its own, this role is not very useful, but other roles (like L<<
C<SubscriberOnly::Moderate>|Sietima::Role::SubscriberOnly::Moderate
>>) can have uses for an owner address.

=head1 ATTRIBUTES

=head2 C<owner>

Required instance of L<< C<Email::Address> >>, coercible from a
string. This is the address of the owner of the list.

=head1 MODIFIED METHODS

=head2 C<list_addresses>

This method declares the C<owner> address.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
