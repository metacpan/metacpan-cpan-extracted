package Mojolicious::Plugin::SendEmail 0.02;
use v5.26;
use warnings;

# ABSTRACT: Easily send emails from Mojolicious applications

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::SendEmail - Easily send emails from Mojolicious applications

Inspired by both L<Mojolicious::Plugin::Mail> and L<Mojolicious::Plugin::EmailMailer>

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Mojolicious::Plugin::SendEmail is a convenient wrapper for L<Email::Stuffer> and
L<Email::Sender::Transport::SMTP> for sending email from Mojolicious commands
and controllers, etc.

The basic concept here is that it sets up the SMTP details at initial plugin load
and then every subsequent call to L</create_email> or L</send_email> uses those
values, so that subsequently you don't need to worry about them.

A little bit of "added value" functionality exists in this module as well:

=over

=item * Unlike L<Email::Stuffer> you I<usually> don't need to tell it whether 
your body is text or HTML. See L</html> below for details

=item * This module uses the concept of recipient resolution to support "faux
distribution lists". See L</recipient_resolver> below for details

=back

=cut

use Mojo::Base 'Mojolicious::Plugin';

use Email::Stuffer;
use Params::Util qw(_INSTANCEDOES);
use Email::Sender::Transport::SMTP;

use experimental qw(signatures);

=pod

=head1 METHODS

L<Mojolicious::Plugin::SendEmail> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones

=head2 register

Register plugin in L<Mojolicious> application. All parameters given are passed
on to L<Email::Sender::Transport::SMTP> except for:

=head4 from

Sets the default C<from> address for all emails. If not given, 
L<"from"|/from1> will be required in all calls to L</create_email> and L</send_email>

=head4 recipient_resolver

Sets the function that will be used for resolving recipient aliases

=cut

sub register($self, $app, $conf = {}) {
  my $from = delete($conf->{from});
  my $rr   = delete($conf->{recipient_resolver}) // sub($add) {$add};
  delete($conf->{sasl_username}) unless (defined($conf->{sasl_username}));
  delete($conf->{sasl_password}) unless (defined($conf->{sasl_password}));

  my $transport = Email::Sender::Transport::SMTP->new($conf);

=pod

=head2 send_email

Construct and send an email based on configuration and the following parameters:

=head4 from

Overrides configured from address (if present) for the specific email. If from
address was not configured at plugin registration time, this parameter is required.

=head4 subject

Email message subject. Defaults to empty string if not given.

=head4 to

=head4 cc

=head4 bcc

Recipient address parameters for `to`, `cc`, and `bcc`, respectively. 
C<Mojolicious::Plugin::SendEmail> resolves all such recipients through the 
L</recipient_resolver> function. Takes a single argument, which can be either
a string or an ArrayRef (which can contain other arrayrefs if the recipient
resolver function handles recursive resolution).

=head4 body

The content of the email body. Can be plain text or HTML (see L</html> for 
details) Ignored if L</template> is given.

=head4 template

The name of a Mojolicious template to use for the email message body. L</body> 
is ignored if C<template> is given. Template format is I<mail>, so, e.g., 
C<user/signup> would use the file C<$TEMPLATES_DIR/user/signup.mail.ep>. Parameters
for the template should be provided (if needed) via L</params>

=head4 params

A hashref of parameters to be used for template rendering. Optional. Ignored unless
L</template> is specified.

=head4 html

A boolean flag to manually set message body content type: 1 for HTML, 0 for 
plain text. If not given, content type will be inferred automatically based on
the absence or presence of the string "<HTML" in the message body.

=head4 attachments

An ArrayRef of email attachments whose data is stored in memory. Each item may
either be a string, or an ArrayRef of the form [$data, $attributes] where C<$data>
is the attachment contents and C<$attributes> is a HashRef of additonal headers

See L<Email::Stuffer/attach> for details.

=head4 files

An ArrayRef of email attachments whose data is stored on disk. Each item may
either be a filename, or an ArrayRef of the form [$filename, $attributes] where 
C<$filename> is the relative or absolute path of the file to be attached and 
C<$attributes> is a HashRef of additonal headers

See L<Email::Stuffer/attach_file> for details.

=cut

  $app->helper(
    create_email => sub ($c, %args) {
      my $mail_from = $args{from} // $from;
      die("Can't send email: no from address given") unless ($mail_from);
      die("Can't send email: no to address given")   unless ($args{to});
      my $mail = Email::Stuffer->new(
        {
          transport => $transport,              # from config
          from      => $mail_from,              # from config, overridable, required
          to        => $rr->($args{to}),        # required
          subject   => $args{subject} // '',    # optional, default empty string
        }
      );
      my $unarray = sub ($x) {ref($x) eq 'ARRAY' ? $x->@* : $x};
      $mail->cc($unarray->($rr->($args{cc})))   if ($args{cc});
      $mail->bcc($unarray->($rr->($args{bcc}))) if ($args{bcc});

      my $body = '';
      if ($args{template}) {
        my $bs = $c->render_to_string(
          format   => 'mail',
          template => $args{template},
          ($args{params} // {})->%*
        );
        $body = $bs->to_string if ($bs);
      } elsif ($args{body}) {
        $body = $args{body};
      }
      $args{html} = index($body, '<html') != -1 unless (defined($args{html}));
      if ($args{html}) {
        $mail->html_body($body);
      } else {
        $mail->text_body($body);
      }

      foreach my $header (($args{headers} // [])->@*) {
        $mail->header($header->%*);
      }

      foreach my $att (($args{attachments} // [])->@*) {
        if (ref($att) eq 'ARRAY') {
          $mail->attach($att->[0], ($att->[1] // {})->%*);
        } else {
          $mail->attach($att);
        }
      }

      foreach my $att (($args{files} // [])->@*) {
        if (ref($att) eq 'ARRAY') {
          $mail->attach_file($att->[0], ($att->[1] // {})->%*);
        } else {
          $mail->attach_file($att);
        }
      }
      return $mail;
    }
  );

=pod

=head2 create_email

Just like L</send_email> except that instead of sending the email and returning
the result, the unsent L<Email::Stuffer> instance is returned instead, facilitating
further customization, serialization, delayed sending, etc.

=cut

  $app->helper(
    send_email => sub($c, %args) {
      $c->create_email(%args)->send();
    }
  );

=head2 email_transport( [$transport] )

If C<$transport> is provided, sets the email transport used for all future mail
sending. Must be a L<Email::Sender::Transport>. Returns the transport object.

=cut

  $app->helper(
    email_transport => sub ($c, $t = undef) {
      if (defined($t)) {
        if (_INSTANCEDOES($t, 'Email::Sender::Transport')) {
          $transport = $t;
        } else {
          die("email_transport argument must be an Email::Sender::Transport instance");
        }
      }
      return $transport;
    }
  );

}

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

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

=cut

1;

__END__
