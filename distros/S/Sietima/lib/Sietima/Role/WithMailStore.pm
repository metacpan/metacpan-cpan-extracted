package Sietima::Role::WithMailStore;
use Moo::Role;
use Sietima::Policy;
use Sietima::Types qw(MailStore MailStoreFromHashRef);
use namespace::clean;

our $VERSION = '1.0.5'; # VERSION
# ABSTRACT: role for lists with a store for messages


has mail_store => (
    is => 'ro',
    isa => MailStore,
    required => 1,
    coerce => MailStoreFromHashRef,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::WithMailStore - role for lists with a store for messages

=head1 VERSION

version 1.0.5

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('WithMailStore')->new({
    %args,
    mail_store => {
      class => 'Sietima::MailStore::FS',
      root => '/tmp',
    },
  });

=head1 DESCRIPTION

This role adds a L<< /C<mail_store> >> attribute.

On its own, this role is not very useful, but other roles (like L<<
C<SubscriberOnly::Moderate>|Sietima::Role::SubscriberOnly::Moderate
>>) can have uses for an object that can persistently store messages.

=head1 ATTRIBUTES

=head2 C<mail_store>

Required instance of an object that consumes the L<<
C<Sietima::MailStore> >> role. Instead of passing an instance, you can
pass a hashref (like in the L</synopsis>): the C<class> key provides
the class name, and the rest of the hash will be passed to its
constructor.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
