package Sietima;
use Moo;
use Sietima::Policy;
use Types::Standard qw(ArrayRef Object FileHandle Maybe);
use Type::Params qw(compile);
use Sietima::Types qw(Address AddressFromStr
                      EmailMIME Message
                      Subscriber SubscriberFromAddress SubscriberFromStr SubscriberFromHashRef
                      Transport);
use Sietima::Message;
use Sietima::Subscriber;
use Email::Sender::Simple qw();
use Email::Sender;
use Email::Address;
use namespace::clean;

with 'MooX::Traits';
our $VERSION = '1.0.4'; # VERSION
# ABSTRACT: minimal mailing list manager


has return_path => (
    isa => Address,
    is => 'ro',
    required => 1,
    coerce => AddressFromStr,
);


my $subscribers_array = ArrayRef[
    Subscriber->plus_coercions(
        SubscriberFromAddress,
        SubscriberFromStr,
        SubscriberFromHashRef,
    )
];
has subscribers => (
    isa => $subscribers_array,
    is => 'lazy',
    coerce => $subscribers_array->coercion,
);
sub _build_subscribers { +[] }


has transport => (
    isa => Transport,
    is => 'lazy',
);
sub _build_transport { Email::Sender::Simple->default_transport }


sub handle_mail_from_stdin($self,@) {
    my $mail_text = do { local $/; <> };
    # we're hoping that, since we probably got called from an MTA/MDA,
    # STDIN contains a well-formed email message, addressed to us
    my $incoming_mail = Email::MIME->new(\$mail_text);
    return $self->handle_mail($incoming_mail);
}


sub handle_mail($self,$incoming_mail) {
    state $check = compile(Object,EmailMIME); $check->(@_);

    my (@outgoing_messages) = $self->munge_mail($incoming_mail);
    for my $outgoing_message (@outgoing_messages) {
        $self->send_message($outgoing_message);
    }
    return;
}


sub subscribers_to_send_to($self,$incoming_mail) {
    state $check = compile(Object,EmailMIME); $check->(@_);

    return $self->subscribers;
}


sub munge_mail($self,$incoming_mail) {
    state $check = compile(Object,EmailMIME); $check->(@_);

    return Sietima::Message->new({
        mail => $incoming_mail,
        from => $self->return_path,
        to => $self->subscribers_to_send_to($incoming_mail),
    });
}


sub send_message($self,$outgoing_message) {
    state $check = compile(Object,Message); $check->(@_);

    my $envelope = $outgoing_message->envelope;
    if ($envelope->{to} && $envelope->{to}->@*) {
        $self->transport->send(
            $outgoing_message->mail,
            $envelope,
        );
    }

    return;
}

sub _trait_namespace { 'Sietima::Role' } ## no critic(ProhibitUnusedPrivateSubroutines)


sub list_addresses($self) {
    return +{
        return_path => $self->return_path,
    };
}


sub command_line_spec($self) {
    return {
        name => 'sietima',
        title => 'a simple mailing list manager',
        subcommands => {
            send => {
                op => 'handle_mail_from_stdin',
                summary => 'send email from STDIN',
            },
        },
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima - minimal mailing list manager

=head1 VERSION

version 1.0.4

=head1 SYNOPSIS

  use Sietima;

  Sietima->new({
    return_path => 'the-list@the-domain.tld',
    subscribers => [ 'person@some.were', @etc ],
  })->handle_mail_from_stdin;

=head1 DESCRIPTION

Sietima is a minimal mailing list manager written in modern Perl. It
aims to be the spiritual successor of L<Siesta>.

The base C<Sietima> class does very little: it just puts the email
message from C<STDIN> into a new envelope using L<< /C<return_path> >>
as sender and all the L<< /C<subscribers> >> addresses as recipients,
and sends it.

Additional behaviour is provided via traits / roles. This class
consumes L<< C<MooX::Traits> >> to simplify composing roles:

  Sietima->with_traits(qw(AvoidDups NoMail))->new(\%args);

These are the traits provided with the default distribution:

=over 4

=item L<< C<AvoidDups>|Sietima::Role::AvoidDups >>

prevents the sender from receiving copies of their own messages

=item L<< C<Debounce>|Sietima::Role::Debounce >>

avoids mail-loops using a C<X-Been-There> header

=item L<< C<Headers>|Sietima::Role::Headers >>

adds C<List-*> headers to all outgoing messages

=item L<< C<ManualSubscription>|Sietima::Role::ManualSubscription >>

specifies that to (un)subscribe, people should write to the list owner

=item L<< C<NoMail>|Sietima::Role::NoMail >>

avoids sending messages to subscribers who don't want them

=item L<< C<ReplyTo>|Sietima::Role::ReplyTo >>

optionally sets the C<Reply-To> header to the mailing list address

=item L<< C<SubjectTag>|Sietima::Role::SubjectTag >>

prepends a C<[tag]> to the subject header of outgoing messages that
aren't already tagged

=item L<< C<SubscriberOnly::Drop>|Sietima::Role::SubscriberOnly::Drop >>

silently drops all messages coming from addresses not subscribed to
the list

=item L<< C<SubscriberOnly::Moderate>|Sietima::Role::SubscriberOnly::Moderate >>

holds messages coming from addresses not subscribed to the list for
moderation, and provides commands to manage the moderation queue

=back

The only "configuration mechanism" currently supported is to
initialise a C<Sietima> object in your driver script, passing all the
needed values to the constructor. L<< C<Sietima::CmdLine> >> is the
recommended way of doing that: it adds command-line parsing capability
to Sietima.

=head1 ATTRIBUTES

=head2 C<return_path>

A L<< C<Email::Address> >> instance, coerced from string if
necessary. This is the address that Sietima will send messages
I<from>.

=head2 C<subscribers>

An array-ref of L<< C<Sietima::Subscriber> >> objects, defaults to the
empty array.

Each item can be coerced from a string or a L<< C<Email::Address> >>
instance, or a hashref of the form

  { address => $string, %other_attributes }

The base Sietima class only uses the address of subscribers, but some
roles use the other attributes (L<< C<NoMail>|Sietima::Role::NoMail
>>, for example, uses the C<prefs> attribute, and L<<
C<SubscriberOnly> >> uses C<aliases> via L<<
C<match>|Sietima::Subscriber/match >>)

=head2 C<transport>

A L<< C<Email::Sender::Transport> >> instance, which will be used to
send messages. If not passed in, Sietima uses L<<
C<Email::Sender::Simple> >>'s L<<
C<default_transport>|Email::Sender::Simple/default_transport >>.

=head1 METHODS

=head2 C<handle_mail_from_stdin>

  $sietima->handle_mail_from_stdin();

This is the main entry-point when Sietima is invoked from a MTA. It
will parse a L<< C<Email::MIME> >> object out of the standard input,
then pass it to L<< /C<handle_mail> >> for processing.

=head2 C<handle_mail>

  $sietima->handle_mail($email_mime);

Main driver method: converts the given email message into a list of
L<< C<Sietima::Message> >> objects by calling L<< /C<munge_mail> >>,
then sends each of them by calling L<< /C<send_message> >>.

=head2 C<subscribers_to_send_to>

  my $subscribers_aref = $sietima->subscribers_to_send_to($email_mime);

Returns an array-ref of L<< C<Sietima::Subscriber> >> objects that
should receive copies of the given email message.

In this base class, it just returns the value of the L<<
/C<subscribers> >> attribute. Roles such as L<<
C<AvoidDups>|Sietima::Role::AvoidDups >> modify this method to exclude
some subscribers.

=head2 C<munge_mail>

  my @messages = $sietima->munge_mail($email_mime);

Returns a list of L<< C<Sietima::Message> >> objects representing the
messages to send to subscribers, based on the given email message.

In this base class, this method returns a single instance to send to
all L<< /C<subscribers_to_send_to> >>, containing exactly the given
email message.

Roles such as L<< C<SubjectTag>|Sietima::Role::SubjectTag >> modify
this method to alter the message.

=head2 C<send_message>

  $sietima->send_message($sietima_message);

Sends the given L<< C<Sietima::Message> >> object via the L<<
/C<transport> >>, but only if the message's
L<envelope|Sietima::Message/envelope> specifies some recipients.

=head2 C<list_addresses>

  my $addresses_href = $sietima->list_addresses;

Returns a hashref of L<< C<Sietima::HeaderURI> >> instances (or things
that can be passed to its constructor, like L<< C<Email::Address> >>,
L<< C<URI> >>, or strings), that declare various addresses related to
this list.

This base class declares only the L<< /C<return_path> >>, and does not
use this method at all.

The L<< C<Headers>|Sietima::Role::Headers >> role uses this to
populate the various C<List-*> headers.

=head2 C<command_line_spec>

  my $app_spec_data = $sietima->command_line_spec;

Returns a hashref describing the command line processing for L<<
C<App::Spec> >>. L<< C<Sietima::CmdLine> >> uses this to build the
command line parser.

This base class declares a single sub-command:

=over

=item C<send>

Invokes the L<< /C<handle_mail_from_stdin> >> method.

For example, in a C<.qmail> file:

  |/path/to/sietima send

=back

Roles can extend this to provide additional sub-commands and options.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
