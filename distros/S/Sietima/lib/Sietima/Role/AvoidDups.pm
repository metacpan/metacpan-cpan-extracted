package Sietima::Role::AvoidDups;
use Moo::Role;
use Sietima::Policy;
use Email::Address;
use namespace::clean;

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: prevent people from receiving the same message multiple times


around subscribers_to_send_to => sub ($orig,$self,$mail) {
    my @already_receiving = map {
        Email::Address->parse($_)
      } $mail->header_str('to'),$mail->header_str('cc');

    my %already_receiving = map {
        $_->address => 1
    } @already_receiving;

    return [
        grep {
            not $already_receiving{$_->address}
        }
            $self->$orig($mail)->@*,
    ];
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::AvoidDups - prevent people from receiving the same message multiple times

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('AvoidDups')->new(\%args);

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will not send a
message to a subscriber, if that subscriber is already mentioned in
the C<To:> or C<Cc:> header fields, because they can be assumed to be
already receiving the message directly from the sender.

=head1 MODIFIED METHODS

=head2 C<subscribers_to_send_to>

Filters out subscribers that L<match|Sietima::Subscriber/match> the
addresses in the C<To:> or C<Cc:> headers of the incoming email.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
