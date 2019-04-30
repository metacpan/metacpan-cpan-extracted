package Sietima::Role::ManualSubscription;
use Moo::Role;
use Sietima::Policy;
use Sietima::HeaderURI;
use namespace::clean;

our $VERSION = '1.0.5'; # VERSION
# ABSTRACT: adds standard list-related headers to messages

with 'Sietima::Role::WithOwner';


around list_addresses => sub($orig,$self) {
    my $list_name = $self->name // 'the list';

    return +{
        $self->$orig->%*,
        subscribe => Sietima::HeaderURI->new_from_address(
            $self->owner,
            { subject => "Please add me to $list_name" },
        ),
        unsubscribe => Sietima::HeaderURI->new_from_address(
            $self->owner,
            { subject => "Please remove me from $list_name" },
        ),
    };
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::ManualSubscription - adds standard list-related headers to messages

=head1 VERSION

version 1.0.5

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits(
    'Headers',
    'ManualSubscription',
  )->new({
    %args,
    owner => 'listmaster@example.com',
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role (and L<<
C<Headers>|Sietima::Role::Headers >>) applied will add, to each
outgoing message, headers specifying that to subscribe and
unsubscribe, people sould email the list owner.

=head1 MODIFIED METHODS

=head2 C<list_addresses>

This method declares two "addresses", C<subscribe> and
C<unsubscribe>. Both are C<mailto:> URLs for the list
L<owner|Sietima::Role::WithOwner/owner>, with different subjects.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
