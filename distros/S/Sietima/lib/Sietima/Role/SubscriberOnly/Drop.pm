package Sietima::Role::SubscriberOnly::Drop;
use Moo::Role;
use Sietima::Policy;
use namespace::clean;

our $VERSION = '1.1.1'; # VERSION
# ABSTRACT: drop messages from non-subscribers


with 'Sietima::Role::SubscriberOnly';


sub munge_mail_from_non_subscriber { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::SubscriberOnly::Drop - drop messages from non-subscribers

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('SubscribersOnly::Drop')->new({
    %args,
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will silently discard
every incoming email that does not come from one of the list's
subscribers.

This is a "sub-role" of L<<
C<SubscribersOnly>|Sietima::Role::SubscriberOnly >>.

=head1 METHODS

=head2 C<munge_mail_from_non_subscriber>

Does nothing, returns an empty list.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
