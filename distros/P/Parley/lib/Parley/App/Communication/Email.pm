package Parley::App::Communication::Email;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use Perl6::Export::Attrs;

use Parley::App::I18N qw( :locale );

sub queue_email :Export( :email ) {
    my ($c, $options) = @_;
    $c->log->info('queuing an email');
    eval {
        my $queued_mail = $c->model('ParleyDB')->resultset('EmailQueue')->create(
            {
                sender          => $options->{headers}{from}        || q{Missing From <chisel@somewhere.com>},

                recipient_id    => $options->{recipient}->id()      || 0,
                subject         => $options->{headers}{subject}     || q{Subject Line Missing},
                text_content    => $options->{text_content}         || q{Email Body Text Missing},
                html_content    => $options->{html_content}         || undef,
            }
        );
    };
    if ($@) {
        $c->log->error($@);
        return;
    }
    $c->log->info('email queued');
    return 1; # success
}

sub send_email :Export( :email ) {
    my ($c, $options) = @_;
    my ($text_content, $html_content, $email_status);

    my $locale = first_valid_locale($c, [qw/email_templates/]);
    $c->log->debug('first_valid_locale is: ' . $locale);

    # preparing for future expansion, where we intend to build multipart emails
    # and we'll be using ->{template}{text} and ->{template}{html}
    if (            exists $options->{template}
            and ref($options->{template}) ne 'HASH'
    ) {
        $c->log->warn(
              q{DEPRECATED use of ->{template} = 'file.eml'}
            . q{: plain-text template name should be stored in }
            . q{->{template}{text} instead of ->{template}}
        );

        # put the data in the right place
        my $tpl_name = $options->{template};
        $options->{template} = {};
        $options->{template}{text} = $tpl_name;
    }

    # we don't send anything immediately ... push it into the queue of outgoing
    # messages

    # prepare the text content portion of the message - we read this from a
    # [template] file which we render
    $c->log->info(
        $c->path_to(
            'root',
            'email_templates',
            $locale
        )
    );
    $text_content = $c->view('Plain')->render(
        $c,
        $options->{template}{text},
        {
            additional_template_paths => [
                $c->path_to(
                    'root',
                    'email_templates',
                    $locale
                )
            ],

            # automatically make the person data available
            person => $options->{person},

            # pass through extra TT data
            %{ $options->{template_data} || {} },
        }
    );

    # if we have html_content, prepare that for queueing
    if (defined $options->{template}{html}) {
        $html_content = $c->view('Plain')->render(
            $c,
            $options->{template}{html},
            {
                #additional_template_paths => [ $c->config->{root} . q{/email_templates}],
                additional_template_paths => [
                    $c->path_to(
                        'root',
                        'email_templates',
                        $locale
                    )
                ],

                # automatically make the person data available
                person => $options->{person},

                # pass through extra TT data
                %{ $options->{template_data} || {} },
            }
        );
    }

    # queue the message
    $email_status = $c->queue_email(
        {
            headers => {
                from        =>     $options->{headers}{from}
                                || q{Missing From <missing.from@localhost>},
                subject     =>     $options->{headers}{subject}
                                || q{Subject Line Missing},
            },

            recipient       => $options->{person},
            text_content    => $text_content,
            html_content    => $html_content,
        },
    );

    # did we queue the email OK?
    if ($email_status) {
        $c->log->info(
              q{send_email(}
            . $options->{person}->email()
            . q{): }
            . $email_status
        );

        return 1;
    }
    else {
        $c->log->error( $email_status );
        $c->stash->{error}{message} =
            $c->localize(q{EMAIL SEND PROBLEM});
        return 0;
    }
}

1;

__END__

=head1 NAME

Parley::App::Communication::Email - email helper functions

=head1 SYNOPSIS

  use Parley::App::Communication::Email;

  send_email($c, $options);

=head1 SEE ALSO

L<Parley::Controller::Root>, L<Catalyst::Plugin::Email>, L<Catalyst>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
