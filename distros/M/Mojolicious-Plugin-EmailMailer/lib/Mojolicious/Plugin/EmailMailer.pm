package Mojolicious::Plugin::EmailMailer;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::Util qw(encode md5_sum);
use Carp;
use Email::Mailer;
use Email::Sender::Util;
use Hash::Merge qw(merge);
use MIME::Words qw(encode_mimeword);
use Try::Tiny;

our $VERSION = '0.03';

use constant TEST => $ENV{MOJO_MAIL_TEST} || 0;
use constant FROM => 'test-emailmailer-plugin@mojolicio.us';

my $plugin_conf = {};
sub register ($self, $app, $conf = {}) {
    $conf->{from}       //= FROM;
    $conf->{'X-Mailer'} //= join ' ', 'Mojolicious',  $Mojolicious::VERSION, __PACKAGE__, $VERSION, '(Perl)';

    if ($conf->{how}) {
        my $howargs        = delete($conf->{howargs}) // {};
        $conf->{transport} = Email::Sender::Util->easy_transport(
            $self->_normalize_transport_name(
                delete($conf->{how})
            ) => $howargs
        );
    }
    $conf->{transport} = Email::Sender::Util->easy_transport('Test' => {}) if TEST;

    $plugin_conf = $conf;

    $app->helper(send_mail          => \&_send_mail);
    $app->helper(send_multiple_mail => \&_send_multiple_mail);
    $app->helper(render_mail        => \&_render_mail);
}

sub _send_mail ($c, %args) {
    %args = %{_text_encoding(%args)} if (defined($args{text}) && !defined($args{html}));
    %args = %{_encode_subject(%args)};

    try {
        return Email::Mailer->send(%{merge(\%args, $plugin_conf)})->[0];
    }
    catch {
        $c->app->log->error("[Mojolicious::Plugin::EmailMailer] There was an error while sending an email through send_mail helper. $_");
        return 0;
    }
}

sub _send_multiple_mail ($c, %args) {
    return 0 unless (defined($args{mail}) && defined($args{send}));

    $args{mail} = _text_encoding(%{$args{mail}}) if (defined($args{mail}->{text}) && !defined($args{mail}->{html}));
    $args{mail} = _encode_subject(%{$args{mail}});

    for my $mail (@{$args{send}}) {
        $mail = _text_encoding(%{$mail}) if (defined($mail->{text}) && !defined($mail->{html}));
        $mail = _encode_subject(%{$mail});
    }

    try {
        return Email::Mailer->new(%{merge($args{mail}, $plugin_conf)})->send(@{$args{send}});
    }
    catch {
        $c->app->log->error("[Mojolicious::Plugin::EmailMailer] There was an error while sending an email with send_multiple_mail helper. $_");
        return 0;
    }
}

sub _render_mail ($c, @args) {
    my $bytestream = $c->render_to_string(@args, format => 'mail');
    return $bytestream->to_string if $bytestream;
    return undef;
}

sub _normalize_transport_name ($c, $class = '') {
    my $lower = lc($class);
    # Sorted that according to the probability of use
    return 'Sendmail'         if $lower eq 'sendmail';
    return 'SMTP'             if $lower eq 'smtp';
    return 'SMTP::Persistent' if $lower eq 'smtp::persistent';
    return 'Maildir'          if $lower eq 'maildir';
    return 'Mbox'             if $lower eq 'mbox';
    return 'Print'            if $lower eq 'print';
    return 'Wrapper'          if $lower eq 'wrapper';
    return 'Test'             if $lower eq 'test';
    return 'DevNull'          if $lower eq 'devnull';
    return 'Failable'         if $lower eq 'failable';
    return $class;
}

sub _text_encoding (%args) {
    my $ct  = _header_key('Content-Type', %args);
    my $cte = _header_key('Content-Transfer-Encoding', %args);
    $args{'Content-Type'}              = 'text/plain; charset=utf8' unless defined $ct;
    $args{'Content-Transfer-Encoding'} = 'quoted-printable'         unless defined $cte;

    $ct //= 'Content-Type';
    (my $encoding = $args{$ct}) =~ s/.*charset=([^;]+);?.*/$1/;
    $args{text} = encode($encoding, $args{text});

    return \%args;
}

sub _encode_subject (%args) {
    for my $header ('subject', 'to', 'from') {
        my $key     = _header_key($header, %args);
        $args{$key} = encode('UTF-8', $args{$key}) if $key;
    }

    return \%args;
}

sub _header_key ($search, %args) {
    $search = lc($search);
    my ($key) = grep { lc($_) eq $search } keys %args;
    return $key;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::EmailMailer - Mojolicious Plugin to send mail through Email::Mailer.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::EmailMailer> is a L<Mojolicious> plugin to send mail through Email::Mailer.

Inspired by L<Mojolicious::Plugin::Mail>, I needed to be able to send mail through a server which uses C<starttls>.

=head1 CONFIGURATION

All parameters are optional.

Except for C<how> and C<howargs>, the configuration parameters are parameters for L<Email::Mailer>’s C<new> method.
See L<https://metacpan.org/pod/Email::Mailer#PARAMETERS> for available parameters. Those parameters will be the default
ones and can be overwritten when using C<send_mail> and C<send_multiple_mail> helpers (see below).

As for C<how> and C<howargs> parameters, they are used to choose the transport for the mails (C<sendmail>, a SMTP server…).
The C<how> parameter can be:

=over 2

=item DevNull          - happily throw away your mail

=item Failable         - a wrapper to makes things fail predictably

=item Maildir          - deliver mail to a maildir on disk

=item Mbox             - deliver mail to an mbox on disk

=item Print            - print email to a filehandle (like stdout)

=item SMTP             - send email over SMTP

=item SMTP::Persistent - an SMTP client that stays online

=item Sendmail         - send mail via sendmail(1)

=item Test             - deliver mail in memory for testing

=item Wrapper          - a mailer to wrap a mailer for mailing mail

=back

Note that the C<how> parameter is case-insensitive.

When giving a C<how> parameter, the transport will be an instance of C<Email::Sender::Transport::$how>, constructed with
C<howargs> as parameters.

See L<https://metacpan.org/release/Email-Sender> to find the available parameters for the transport you want to use.

=head1 HELPERS

L<Mojolicious::Plugin::EmailMailer> contains three helpers: C<send_mail>, C<send_multiple_mail> and C<render_mail>.

=head2 send_mail

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

See L<https://metacpan.org/pod/Email::Mailer#PARAMETERS> for available parameters.

If C<send_mail()> succeeds, it'll return an instantiated L<Email::Mailer> object based on the combined parameters.
If it fails, it will return 0 and create a log error message;

All parameters, will be used as mail headers, except the following ones:

=over 2

=item html

=item text

=item embed

=item attachments

=item process

=item data

=item transport

=item width

=back

Note that the C<Subject>, C<to> and C<From> headers will be automatically UTF-8 encoded by the plugin, then encoded as mimewords
by L<Email::Mailer|Email::Mailer#AUTOMATIC-HEADER-IFICATION>.

When sending a text-only mail (with or without attachments), the default values of C<Content-Transfer-Encoding> and C<Content-Type>
headers are respectively C<quoted-printable> and C<text/plain; charset=utf8> and the text is encoded according to the charset
specified in the C<Content-Type> header;

=head2 send_multiple_mail

L<Email::Mailer> allows to prepare a mail and send it more than one time, with different overriden parameters:

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

You can do the same with C<send_multiple_mail>:

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

C<mail>, a hashref, obviously contains the C<Email::Mailer->new()> arguments and C<send>, an arrayref,
contains the C<Email::Mailer->send()> arguments.

If C<send_multiple_mail()> succeeds, it'll return an array or arrayref (based on context) of the L<Email::Mailer>
objects ultimately created.
If it fails, it will return 0 and create a log error message;

Note that the subject will be UTF-8 encoded, then encoded as mimeword, like this:

  use MIME::Words qw(encode_mimeword);
  $subject = encode_mimeword(encode('UTF-8', $subject), 'q', 'UTF-8');

When sending a text-only mail (with or without attachments), the default values of C<Content-Transfer-Encoding> and C<Content-Type>
headers are respectively C<quoted-printable> and C<text/plain; charset=utf8> and the text is encoded according to the charset
specified in the C<Content-Type> header;

=head3 render_mail

  my $data = $self->render_mail('user/signup');

  # or use stash params
  my $data = $self->render_mail(template => 'user/signup', user => $user);

Render mail template and return data, mail template format is I<mail>, i.e. I<user/signup.mail.ep>.

=head1 EXAMPLES

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

=head1 METHODS

L<Mojolicious::Plugin::EmailMailer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 BUGS and SUPPORT

The latest source code can be browsed and fetched at:

  https://framagit.org/fiat-tux/mojolicious/mojolicious-plugin-emailmailer
  git clone https://framagit.org/fiat-tux/mojolicious/mojolicious-plugin-emailmailer.git

Bugs and feature requests will be tracked at:

  https://framagit.org/fiat-tux/mojolicious/mojolicious-plugin-emailmailer/issues

=head1 AUTHOR

  Luc DIDRY
  CPAN ID: LDIDRY
  ldidry@cpan.org
  https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<Email::Mailer>, L<Email::Sender>, L<https://mojolicious.org>.

=cut
