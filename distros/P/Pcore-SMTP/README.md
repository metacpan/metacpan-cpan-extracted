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

    # send email with two attachments
    $message_body = [ [ 'filename1.ext', \$content1 ], [ 'filename2.ext', \$content2 ] ];

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

## new(\\%args)

Please, see ["SYNOPSIS"](#SYNOPSIS)

## sendmail(%args)

Where %args are:

- from

    from email address.

- reply\_to

    reply to email address.

- to

    This argument can be either Scalar or ArrayRef\[Scalar\].

- cc

    This argument can be either Scalar or ArrayRef\[Scalar\].

- bcc

    This argument can be either Scalar or ArrayRef\[Scalar\].

- subject

    Email subject.

- body

    Email body. Can be Scalar|ScalarRef|ArrayRef\[Scalar|ScalarRef|ArrayRef\].

    If body is ArrayRef - email will be composed as multipart/mixed. Each part can be a `$body` or `\$body` or a `[$headers, $body]`. If `$headers` ia plain scalar - this will be a filename, and headers array will be generated. Or you can specify all required headers manually in ArrayRef.

    Examples:

        $body = 'message body';

        $body = \'message body';

        $body = [ 'body1', \$body2, [ \@headers, $content ] ];

        # send email with two file attachmants
        $body = [ 'message body', [ 'filename1.txt', \$content1 ], [ 'filename2.txt', \$content2 ] ];

        # manually specify headers
        # send HTML email with 1 attachment
        $body = [ [ ['Content-Type: text/html'], \$body ], [ 'filename1.txt', \$attachment ] ];

# NOTES

If you are using gmail and get error 534 "Please log in via your web browser", go to [https://myaccount.google.com/lesssecureapps](https://myaccount.google.com/lesssecureapps) and allow less secure apps.

# SEE ALSO

[http://foundation.zurb.com/emails.html](http://foundation.zurb.com/emails.html)

[https://habrahabr.ru/post/317810/](https://habrahabr.ru/post/317810/)

# AUTHOR

zdm <zdm@softvisio.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.
