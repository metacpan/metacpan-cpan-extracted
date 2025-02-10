package Sietima::Role::SubscriberOnly::Moderate;
use Moo::Role;
use Sietima::Policy;
use Email::Stuffer;
use namespace::clean;

our $VERSION = '1.1.4'; # VERSION
# ABSTRACT: moderate messages from non-subscribers


with 'Sietima::Role::SubscriberOnly',
    'Sietima::Role::WithMailStore',
    'Sietima::Role::WithOwner';


sub munge_mail_from_non_subscriber ($self,$mail) {
    my $id = $self->mail_store->store($mail,'moderation');
    my $notice = Email::Stuffer
        ->from($self->return_path->address)
        ->to($self->owner->address)
        ->subject("Message held for moderation - ".$mail->header_str('subject'))
        ->text_body("Use id $id to refer to it")
        ->attach(
            $mail->as_string,
            content_type => 'message/rfc822',
            # some clients, most notably Claws-Mail, seem to have
            # problems with encodings other than this
            encoding => '7bit',
        );

    return Sietima::Message->new({
        mail => $notice->email,
        from => $self->return_path,
        to => [ $self->owner ],
    });
}


sub resume ($self,$mail_id) {
    my $mail = $self->mail_store->retrieve_by_id($mail_id);
    $self->ignoring_subscriberonly(
        sub($s) { $s->handle_mail($mail) },
    );
    $self->mail_store->remove($mail_id);
}


sub drop ($self,$mail_id) {
    $self->mail_store->remove($mail_id);
}


sub list_mails_in_moderation_queue ($self,$runner,@) {
    my $mails = $self->mail_store->retrieve_by_tags('moderation');
    $runner->out(sprintf 'There are %d messages held for moderation:',scalar($mails->@*));
    for my $mail ($mails->@*) {
        $runner->out(sprintf '* %s %s "%s" (%s)',
                     $mail->{id},
                     $mail->{mail}->header_str('From')//'<no from>',
                     $mail->{mail}->header_str('Subject')//'<no subject>',
                     $mail->{mail}->header_str('Date')//'<no date>',
                     );
    }
}


sub show_mail_from_moderation_queue ($self,$runner,@) {
    my $id = $runner->parameters->{'mail-id'};
    my $mail = $self->mail_store->retrieve_by_id($id);
    $runner->out("Message $id:");
    $runner->out($mail->as_string =~ s{\r\n}{\n}gr);
}


sub resume_mail_from_moderation_queue ($self,$runner,@) {
    $self->resume($runner->parameters->{'mail-id'});
}


sub drop_mail_from_moderation_queue ($self,$runner,@) {
    $self->drop($runner->parameters->{'mail-id'});
}


around command_line_spec => sub ($orig,$self) {
    my $spec = $self->$orig();

    # this allows us to tab-complete identifiers from the shell!
    my $list_mail_ids = sub ($self,$runner,$args) {
        $self->mail_store->retrieve_ids_by_tags('moderation');
    };
    # a little factoring: $etc->($command_name) generates the spec for
    # sub-commands that require a mail id
    my $etc = sub($cmd) {
        return (
            summary => "$cmd the given mail, currently held for moderation",
            parameters => [
                {
                    name => 'mail-id',
                    required => 1,
                    summary => "id of the mail to $cmd",
                    completion => { op => $list_mail_ids },
                },
            ],
        );
    };

    $spec->{subcommands}{'list-held'} = {
        op => 'list_mails_in_moderation_queue',
        summary => 'list all mails currently held for moderation',
    };
    $spec->{subcommands}{'show-held'} = {
        op => 'show_mail_from_moderation_queue',
        $etc->('show'),
    };
    $spec->{subcommands}{'resume-held'} = {
        op => 'resume_mail_from_moderation_queue',
        $etc->('resume'),
    };
    $spec->{subcommands}{'drop-held'} = {
        op => 'drop_mail_from_moderation_queue',
        $etc->('drop'),
    };

    return $spec;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::SubscriberOnly::Moderate - moderate messages from non-subscribers

=head1 VERSION

version 1.1.4

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('SubscribersOnly::Moderate')->new({
    %args,
    owner => 'listmaster@example.com',
    mail_store => {
      class => 'Sietima::MailStore::FS',
      root => '/tmp',
    },
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will accept incoming
emails coming from non-subscribers, and store it for moderation. Each
such email will be forwarded (as an attachment) to the list's owner.

The owner will the be able to delete the message, or allow it.

This is a "sub-role" of L<<
C<SubscribersOnly>|Sietima::Role::SubscriberOnly >>, L<<
C<WithMailStore>|Sietima::Role::WithMailStore >>, and L<<
C<WithOwner>|Sietima::Role::WithOwner >>.

=head1 METHODS

=head2 C<munge_mail_from_non_subscriber>

L<Stores|Sietima::MailStore/store> the email with the C<moderation>
tag, and forwards it to the L<list
owner|Sietima::Role::WithOwner/owner>.

=head2 C<resume>

  $sietima->resume($mail_id);

Given the identifier returned when
L<storing|Sietima::MailStore/store>-ing an email, this method
retrieves the email and re-processes it via L<<
C<ignoring_subscriberonly>|Sietima::Role::SubscriberOnly/ignoring_subscriberonly
>>. This will make sure that the email is not caught again by the
subscriber-only filter.

=head2 C<drop>

  $sietima->drop($mail_id);

Given the identifier returned when
L<storing|Sietima::MailStore/store>-ing an email, this method deletes
the email from the store.

=head2 C<list_mails_in_moderation_queue>

  $sietima->list_mails_in_moderation_queue($sietima_runner);

This method L<retrieves all the
identifiers|Sietima::MailStore/retrieve_by_tags> of messages tagged
C<moderation>, and L<prints them out|App::Spec::Runner/out> via the
L<< C<Sietima::Runner> >> object.

This method is usually invoked from the command line, see L<<
/C<command_line_spec> >>.

=head2 C<show_mail_from_moderation_queue>

  $sietima->show_mail_from_moderation_queue($sietima_runner);

This method L<retrieves the email|Sietima::MailStore/retrieve_by_id>
of the message requested from the command line, and L<prints it
out|App::Spec::Runner/out> via the L<< C<Sietima::Runner> >> object.

This method is usually invoked from the command line, see L<<
/C<command_line_spec> >>.

=head2 C<resume_mail_from_moderation_queue>

  $sietima->resume_mail_from_moderation_queue($sietima_runner);

This method L<retrieves the email|Sietima::MailStore/retrieve_by_id>
of the message requested from the command line, and L<resumes|/resume>
it.

This method is usually invoked from the command line, see L<<
/C<command_line_spec> >>.

=head2 C<drop_mail_from_moderation_queue>

  $sietima->drop_mail_from_moderation_queue($sietima_runner);

This method L<retrieves the email|Sietima::MailStore/retrieve_by_id>
of the message requested from the command line, and L<drops|/drop> it.

This method is usually invoked from the command line, see L<<
/C<command_line_spec> >>.

=head1 MODIFIED METHODS

=head2 C<command_line_spec>

This method adds the following sub-commands for the command line:

=over

=item C<list-held>

  $ sietima list-held

Invokes the L<< /C<list_mails_in_moderation_queue> >> method, printing
the identifiers of all messages held for moderation.

=item C<show-held>

  $ sietima show-held 32946p6eu7867

Invokes the L<< /C<show_mail_from_moderation_queue> >> method,
printing one message held for moderation; the identifier is expected
as a positional parameter.

=item C<resume-held>

  $ sietima resume-held 32946p6eu7867

Invokes the L<< /C<resume> >> method, causing the held message to be
processed normally; the identifier is expected as a positional
parameter.

=item C<drop-held>

  $ sietima drop-held 32946p6eu7867

Invokes the L<< /C<drop> >> method, removing the held message; the
identifier is expected as a positional parameter.

=back

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
