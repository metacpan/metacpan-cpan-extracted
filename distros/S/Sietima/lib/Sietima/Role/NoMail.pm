package Sietima::Role::NoMail;
use Moo::Role;
use Sietima::Policy;
use namespace::clean;

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: don't send mail to those who don't want it


around subscribers_to_send_to => sub ($orig,$self,$mail) {
    return [
        grep { $_->prefs->{wants_mail} // 1 }
            $self->$orig($mail)->@*,
    ];
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::NoMail - don't send mail to those who don't want it

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('NoMail')->new({
   %args,
   subscribers => [
    { primary => 'write-only@example.com', prefs => { wants_mail => 0 } },
    @other_subscribers,
   ],
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will not send messages
to subscribers that have the C<wants_mail> preference set to a false
value.

=head1 MODIFIED METHODS

=head2 C<subscribers_to_send_to>

Filters out subscribers that have the C<wants_mail> preference set to
a false value.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
