# NAME

Pcore::SMTP - non-blocking SMTP protocol implementation

# SYNOPSIS

    my $smtp = Pcore::SMTP->new( {
        host     => 'smtp.gmail.com',
        port     => 465,
        username => 'username@gmail.com',
        password => 'password',
        tls      => 1,
    } );

    $smtp->sendmail(
        from     => 'from@host',
        reply_to => 'from@host',
        to       => 'to@host',
        cc       => 'cc@host',
        bcc      => 'bcc@host',
        subject  => 'email subject',
        body     => $message_body,
        sub ($res) {
            say $res;

            $cb->();

            return;
        }
    );

# DESCRIPTION

AnyEvent based SMTP protocol implementation.

# ATTRIBUTES

# METHODS

# NOTES

If you are using gmail and get error 534 "Please log in via your web browser", go to [https://myaccount.google.com/lesssecureapps](https://myaccount.google.com/lesssecureapps) and allow less secure apps.

# SEE ALSO

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.
