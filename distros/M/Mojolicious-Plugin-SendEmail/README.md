# NAME

Mojolicious::Plugin::SendEmail - Easily send emails from Mojolicious applications

Inspired by both [Mojolicious::Plugin::Mail](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AMail) and [Mojolicious::Plugin::EmailMailer](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AEmailMailer)

# SYNOPSIS

    # Register plugin
    $self->plugin('SendEmail' => {
      from => '"My Application" <myapp@tyrrminal.dev>',
      host => ...,
      port => ...,
      recipient_resolver => sub { ... },
      ...
    });

    ...

    # Send simple email
    $c->send_email(
      to      => 'mark@tyrrminal.dev',
      subject => "Alert: MyApp failure",
      body    => "An error occurred when processing nightly data"
    );

    ...

    # Send template-based email with attachments
    $c->send_email(
      to       => 'daily',
      subject  => 'Nightly Attendance Report',
      template => 'reports/nightly_attendance',
      params   => {
        data => $report_data
      },
      files => ['generated/Nightly_Attendance_Report.xlsx']
    );

# DESCRIPTION

Mojolicious::Plugin::SendEmail is a convenient wrapper for [Email::Stuffer](https://metacpan.org/pod/Email%3A%3AStuffer) and
[Email::Sender::Transport::SMTP](https://metacpan.org/pod/Email%3A%3ASender%3A%3ATransport%3A%3ASMTP) for sending email from Mojolicious commands
and controllers, etc.

The basic concept here is that it sets up the SMTP details at initial plugin load
and then every subsequent call to ["create\_email"](#create_email) or ["send\_email"](#send_email) uses those
values, so that subsequently you don't need to worry about them.

A little bit of "added value" functionality exists in this module as well:

- Unlike [Email::Stuffer](https://metacpan.org/pod/Email%3A%3AStuffer) you _usually_ don't need to tell it whether 
your body is text or HTML. See ["html"](#html) below for details
- This module uses the concept of recipient resolution to support "faux
distribution lists". See ["recipient\_resolver"](#recipient_resolver) below for details

# METHODS

[Mojolicious::Plugin::SendEmail](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASendEmail) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin)
and implements the following new ones

## register

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. All parameters given are passed
on to [Email::Sender::Transport::SMTP](https://metacpan.org/pod/Email%3A%3ASender%3A%3ATransport%3A%3ASMTP) except for:

#### from

Sets the default `from` address for all emails. If not given, 
["from"](#from1) will be required in all calls to ["create\_email"](#create_email) and ["send\_email"](#send_email)

#### recipient\_resolver

Sets the function that will be used for resolving recipient aliases

## send\_email

Construct and send an email based on configuration and the following parameters:

#### from

Overrides configured from address (if present) for the specific email. If from
address was not configured at plugin registration time, this parameter is required.

#### subject

Email message subject. Defaults to empty string if not given.

#### to

#### cc

#### bcc

Recipient address parameters for \`to\`, \`cc\`, and \`bcc\`, respectively. 
`Mojolicious::Plugin::SendEmail` resolves all such recipients through the 
["recipient\_resolver"](#recipient_resolver) function. Takes a single argument, which can be either
a string or an ArrayRef (which can contain other arrayrefs if the recipient
resolver function handles recursive resolution).

#### body

The content of the email body. Can be plain text or HTML (see ["html"](#html) for 
details) Ignored if ["template"](#template) is given.

#### template

The name of a Mojolicious template to use for the email message body. ["body"](#body) 
is ignored if `template` is given. Template format is _mail_, so, e.g., 
`user/signup` would use the file `$TEMPLATES_DIR/user/signup.mail.ep`. Parameters
for the template should be provided (if needed) via ["params"](#params)

#### params

A hashref of parameters to be used for template rendering. Optional. Ignored unless
["template"](#template) is specified.

#### html

A boolean flag to manually set message body content type: 1 for HTML, 0 for 
plain text. If not given, content type will be inferred automatically based on
the absence or presence of the string "<HTML" in the message body.

#### attachments

An ArrayRef of email attachments whose data is stored in memory. Each item may
either be a string, or an ArrayRef of the form \[$data, $attributes\] where `$data`
is the attachment contents and `$attributes` is a HashRef of additonal headers

See ["attach" in Email::Stuffer](https://metacpan.org/pod/Email%3A%3AStuffer#attach) for details.

#### files

An ArrayRef of email attachments whose data is stored on disk. Each item may
either be a filename, or an ArrayRef of the form \[$filename, $attributes\] where 
`$filename` is the relative or absolute path of the file to be attached and 
`$attributes` is a HashRef of additonal headers

See ["attach\_file" in Email::Stuffer](https://metacpan.org/pod/Email%3A%3AStuffer#attach_file) for details.

## create\_email

Just like ["send\_email"](#send_email) except that instead of sending the email and returning
the result, the unsent [Email::Stuffer](https://metacpan.org/pod/Email%3A%3AStuffer) instance is returned instead, facilitating
further customization, serialization, delayed sending, etc.

## email\_transport( \[$transport\] )

If `$transport` is provided, sets the email transport used for all future mail
sending. Must be a [Email::Sender::Transport](https://metacpan.org/pod/Email%3A%3ASender%3A%3ATransport). Returns the transport object.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
