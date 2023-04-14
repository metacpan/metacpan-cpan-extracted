package Sietima::Role::ReplyTo;
use Moo::Role;
use Sietima::Policy;
use Types::Standard qw(Bool);
use List::AllUtils qw(part);
use namespace::clean;

our $VERSION = '1.1.2'; # VERSION
# ABSTRACT: munge the C<Reply-To> header


with 'Sietima::Role::WithPostAddress';


has munge_reply_to => (
    is => 'ro',
    isa => Bool,
    default => 0,
);


around munge_mail => sub ($orig,$self,$mail) {
    my @messages = $self->$orig($mail);
    my @ret;
    for my $m (@messages) {
        my ($leave,$munge) = part {
            my $m = $_->prefs->{munge_reply_to};
            defined $m ? (
                $m ? 1 : 0
            ) : ( $self->munge_reply_to ? 1 : 0 )
        } $m->to->@*;

        if (not ($munge and $munge->@*)) {
            # nothing to do
            push @ret,$m;
        }
        elsif (not ($leave and $leave->@*)) {
            # all these recipients want munging
            $m->mail->header_str_set('Reply-To',$self->post_address->address);
            push @ret,$m;
        }
        else {
            # some want it, some don't: create two different messages
            my $leave_message = Sietima::Message->new({
                mail => $m->mail,
                from => $m->from,
                to => $leave,
            });

            my $munged_mail = Email::MIME->new($m->mail->as_string);
            $munged_mail->header_str_set('Reply-To',$self->post_address->address);

            my $munged_message = Sietima::Message->new({
                mail => $munged_mail,
                from => $m->from,
                to => $munge,
            });

            push @ret,$leave_message,$munged_message;
        }
    }
    return @ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::ReplyTo - munge the C<Reply-To> header

=head1 VERSION

version 1.1.2

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('ReplyTo')->new({
    %args,
    return_path => 'list-bounce@example.com',
    munge_reply_to => 1,
    post_address => 'list@example.com',
    subscribers => [
      { primary => 'special@example.com', prefs => { munge_reply_to => 0 } },
      @other_subscribers,
    ],
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will, on request, set
the C<Reply-To:> header to the value of the L<<
C<post_address>|Sietima::Role::WithPostAddress >> attribute.

This behaviour can be selected both at the list level (with the L<<
/C<munge_reply_to> >> attribute) and at the subscriber level (with the
C<munge_reply_to> preference). By default, the C<Reply-To:> header is
not touched.

This is a "sub-role" of L<<
C<WithPostAddress>|Sietima::Role::WithPostAddress >>.

=head1 ATTRIBUTES

=head2 C<munge_reply_to>

Optional boolean, defaults to false. If set to a true value, all
messages will have their C<Reply-To:> header set to the value of the
L<< /C<post_address> >> attribute. This setting can be overridden by
individual subscribers with the C<munge_reply_to> preference.

=head1 MODIFIED METHODS

=head2 C<munge_mail>

For each message returned by the original method, this method
partitions the subscribers, who are recipients of the message,
according to their C<munge_reply_to> preference (or the L<<
/C<munge_reply_to> >> attribute, if a subscriber does not have the
preference set).

If no recipients want the C<Reply-To:> header modified, this method
will just pass the message through.

If all recipients want the C<Reply-To:> header modified, this method
will set the header, and pass the modified message.

If some recipients want the C<Reply-To:> header modified, and some
don't, this method will clone the message, modify the header in one
copy, set the appropriate part of the recipients to each copy, and
pass both through.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
