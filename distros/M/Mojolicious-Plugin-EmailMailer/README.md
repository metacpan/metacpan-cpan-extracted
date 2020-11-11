# NAME

Mojolicious::Plugin::EmailMailer - Mojolicious Plugin to send mail through Email::Mailer.

# SYNOPSIS

    # Mojolicious
    $self->plugin('EmailMailer');

    # Mojolicious with config
    $self->plugin('EmailMailer' => {
      from => 'example@example.org',
      how  => 'smtp',
      howargs => {
          hosts => [ 'smtp.example.org' ],
          ssl   => 1, # can be 'starttls'
          sasl_username => 'user_login',
          sasl_password => 's3cr3t'
      }
    });

    # Mojolicious::Lite
    plugin 'EmailMailer';

    # Mojolicious::Lite with config
    plugin 'EmailMailer' => {
      from => 'example@example.org',
      how  => 'smtp',
      howargs => {
          hosts => [ 'smtp.example.org' ],
          ssl   => 1, # can be 'starttls'
          sasl_username => 'user_login',
          sasl_password => 's3cr3t'
      }
    }

# DESCRIPTION

[Mojolicious::Plugin::EmailMailer](https://metacpan.org/pod/Mojolicious::Plugin::EmailMailer) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin to send mail through Email::Mailer.

Inspired by [Mojolicious::Plugin::Mail](https://metacpan.org/pod/Mojolicious::Plugin::Mail), I needed to be able to send mail through a server which uses `starttls`.

# CONFIGURATION

All parameters are optional.

Except for `how` and `howargs`, the configuration parameters are parameters for [Email::Mailer](https://metacpan.org/pod/Email::Mailer)’s `new` method.
See [https://metacpan.org/pod/Email::Mailer#PARAMETERS](https://metacpan.org/pod/Email::Mailer#PARAMETERS) for available parameters. Those parameters will be the default
ones and can be overwritten when using `send_mail` and `send_multiple_mail` helpers (see below).

As for `how` and `howargs` parameters, they are used to choose the transport for the mails (`sendmail`, a SMTP server…).
The `how` parameter can be:

- DevNull          - happily throw away your mail
- Failable         - a wrapper to makes things fail predictably
- Maildir          - deliver mail to a maildir on disk
- Mbox             - deliver mail to an mbox on disk
- Print            - print email to a filehandle (like stdout)
- SMTP             - send email over SMTP
- SMTP::Persistent - an SMTP client that stays online
- Sendmail         - send mail via sendmail(1)
- Test             - deliver mail in memory for testing
- Wrapper          - a mailer to wrap a mailer for mailing mail

Note that the `how` parameter is case-insensitive.

When giving a `how` parameter, the transport will be an instance of `Email::Sender::Transport::$how`, constructed with
`howargs` as parameters.

See [https://metacpan.org/release/Email-Sender](https://metacpan.org/release/Email-Sender) to find the available parameters for the transport you want to use.

# HELPERS

[Mojolicious::Plugin::EmailMailer](https://metacpan.org/pod/Mojolicious::Plugin::EmailMailer) contains three helpers: `send_mail`, `send_multiple_mail` and `render_mail`.

## send\_mail

Straightly send a mail, according to the given arguments and plugin configuration.

    $self->send_mail(
        to         => 'test@example.org',
        from       => 'test@example.org',
        'reply-to' => 'reply_to+test@example.org',
        cc         => '..',
        bcc        => '..',
        subject    => 'Test',
        text       => 'use Perl or die;',
        html       => '</p>use Perl or die;</p>',
    );

See [https://metacpan.org/pod/Email::Mailer#PARAMETERS](https://metacpan.org/pod/Email::Mailer#PARAMETERS) for available parameters.

If `send_mail()` succeeds, it'll return an instantiated [Email::Mailer](https://metacpan.org/pod/Email::Mailer) object based on the combined parameters.
If it fails, it will return 0 and create a log error message;

All parameters, will be used as mail headers, except the following ones:

- html
- text
- embed
- attachments
- process
- data
- transport
- width

Note that the `Subject`, `to` and `From` headers will be automatically UTF-8 encoded by the plugin, then encoded as mimewords
by [Email::Mailer](https://metacpan.org/pod/Email::Mailer#AUTOMATIC-HEADER-IFICATION).

When sending a text-only mail (with or without attachments), the default values of `Content-Transfer-Encoding` and `Content-Type`
headers are respectively `quoted-printable` and `text/plain; charset=utf8` and the text is encoded according to the charset
specified in the `Content-Type` header;

## send\_multiple\_mail

[Email::Mailer](https://metacpan.org/pod/Email::Mailer) allows to prepare a mail and send it more than one time, with different overriden parameters:

    Email::Mailer->new(
        from    => $from,
        subject => $subject,
        html    => $html
    )->send(
        { to => 'person_0@example.com' },
        { to => 'person_1@example.com' },
        {
            to      => 'person_2@example.com',
            subject => 'Override $subject with this',
        }
    );

You can do the same with `send_multiple_mail`:

    $self->send_multiple_mail(
        mail => {
            from    => $from,
            subject => $subject,
            html    => $html
        },
        send => [
            { to => 'person_0@example.com' },
            { to => 'person_1@example.com' },
            {
                to      => 'person_2@example.com',
                subject => 'Override $subject with this',
            }
        ]
    );

`mail`, a hashref, obviously contains the `Email::Mailer-`new()> arguments and `send`, an arrayref,
contains the `Email::Mailer-`send()> arguments.

If `send_multiple_mail()` succeeds, it'll return an array or arrayref (based on context) of the [Email::Mailer](https://metacpan.org/pod/Email::Mailer)
objects ultimately created.
If it fails, it will return 0 and create a log error message;

Note that the subject will be UTF-8 encoded, then encoded as mimeword, like this:

    use MIME::Words qw(encode_mimeword);
    $subject = encode_mimeword(encode('UTF-8', $subject), 'q', 'UTF-8');

When sending a text-only mail (with or without attachments), the default values of `Content-Transfer-Encoding` and `Content-Type`
headers are respectively `quoted-printable` and `text/plain; charset=utf8` and the text is encoded according to the charset
specified in the `Content-Type` header;

### render\_mail

    my $data = $self->render_mail('user/signup');

    # or use stash params
    my $data = $self->render_mail(template => 'user/signup', user => $user);

Render mail template and return data, mail template format is _mail_, i.e. _user/signup.mail.ep_.

# EXAMPLES

    my ($to, $from, $subject, $text, $html);

    # send a simple text email
    $self->send_mail(
        to      => $to,
        from    => $from,
        subject => $subject,
        text    => $text
    );

    # send multi-part HTML/text email with the text auto-generated from the HTML
    # and images and other resources embedded in the email
    $self->send_mail(
        to      => $to,
        from    => $from,
        subject => $subject,
        html    => $html
    );

    # send multi-part HTML/text email with the text auto-generated from the HTML
    # but skip embedding images and other resources
    $self->send_mail(
        to      => $to,
        from    => $from,
        subject => $subject,
        html    => $html,
        embed   => 0
    );

    # send multi-part HTML/text email but supply the text explicitly
    $self->send_mail(
        to      => $to,
        from    => $from,
        subject => $subject,
        html    => $html,
        text    => $text
    );

    # send multi-part HTML/text email with a couple of attached files
    use IO::All 'io';
    $self->send_mail(
        to          => $to,
        from        => $from,
        subject     => $subject,
        html        => $html,
        text        => $text,
        attachments => [
            {
                ctype  => 'application/pdf',
                source => 'file.pdf',
            },
            {
                ctype    => 'application/pdf',
                content  => io('file.pdf')->binary->all,
                encoding => 'base64',
                name     => 'file.pdf',
            },
        ],
    );

    # build an email and iterate over a data set for sending
    $self->send_multiple_mail(
        mail => {
            from    => $from,
            subject => $subject,
            html    => $html
        },
        send => [
            { to => 'person_0@example.com' },
            { to => 'person_1@example.com' },
            {
                to      => 'person_2@example.com',
                subject => 'Override $subject with this',
            }
        ]
    );

    # setup a second mail object based on the first but changing the "from"
    my $mail_0 = $self->send_mail(
        from    => $from,
        subject => $subject,
        html    => $html
    );
    if ($mail_0) {
        my $mail_1 = $mail_0->new(from => 'different_address@example.com');
        $mail_1->send;
    }

# METHODS

[Mojolicious::Plugin::EmailMailer](https://metacpan.org/pod/Mojolicious::Plugin::EmailMailer) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# BUGS and SUPPORT

The latest source code can be browsed and fetched at:

    https://framagit.org/fiat-tux/mojolicious/mojolicious-plugin-emailmailer
    git clone https://framagit.org/fiat-tux/mojolicious/mojolicious-plugin-emailmailer.git

Bugs and feature requests will be tracked at:

    https://framagit.org/fiat-tux/mojolicious/mojolicious-plugin-emailmailer/issues

# AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

# COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [Email::Mailer](https://metacpan.org/pod/Email::Mailer), [Email::Sender](https://metacpan.org/pod/Email::Sender), [https://mojolicious.org](https://mojolicious.org).
