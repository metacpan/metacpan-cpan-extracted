package Mojo::Sendgrid::Mail;
use Mojo::Base -base;

use Mojo::UserAgent;

has 'sendgrid' => sub { die }; # Mojo::Sendgrid object
has 'ua' => sub { Mojo::UserAgent->new };

# Implement the defined parameters from Sendgrid Web API v2 mail endpoint
# Perld doesn't accept - so need to use _ and convert to - for the final req
my %parameters = (
  send => {
    required => [qw(to subject from)],
    require_one  => [qw(text html)],
    optional => [qw(toname cc ccname bcc bccname fromname replyto date files content headers x_smtpapi)],
  },
);

has [@{$parameters{send}{required}}] => sub { die "required attribute missing" };
has [@{$parameters{send}{require_one}}];
has [@{$parameters{send}{optional}}];

sub send {
  my $self = shift;

  $self->ua->post(
    $self->sendgrid->apiurl =>
    {Authorization => $self->_bearer} =>
    form => $self->_form =>
    # If there are any subscribers to the event issue the request non-blocking and emit event
    # Otherwise issue the request blocking
    $self->sendgrid->has_subscribers('mail_send') ? sub {$self->sendgrid->emit(mail_send => @_)} : ()
  );
}

# Create the hash to be supplied to the form option of Mojo::UserAgent
sub _form {
  my $self = shift->_require_one;
  return {map {($_=~s/_/-/r)=>$self->$_} grep {$self->$_} @{$parameters{send}{required}}, @{$parameters{send}{optional}}};
}

# I don't know how else to enforce requiring at least one attribute of a group
# of options
sub _require_one {
  my $self = shift;
  my $require_one = 0;
  push @{$parameters{send}{required}}, $_ and $require_one++ for grep {$self->$_} @{$parameters{send}{require_one}};
  die sprintf "one of %s attribute missing", join ',', @{$parameters{send}{require_one}} if @{$parameters{send}{require_one}} && !$require_one;
  $self;
}

sub _bearer { sprintf "Bearer %s", shift->sendgrid->apikey }

1;

=encoding utf8

=head1 NAME

Mojo::Sendgrid::Mail - Mail endpoint of the Sendgrid API implementation for
the Mojolicious framework

=head1 VERSION

0.01

=head1 SYNOPSIS

  See L<Mojo::Sendgrid>

=head1 DESCRIPTION

L<Mojo::Sendgrid::Mail> is the mail endpoint of the Sendgrid API and is non-
blocking thanks to L<Mojo::IOLoop> from the wonderful L<Mojolicious> framework.

This class inherits from L<Mojo::Base>.

=head1 EVENTS

=head2 mail_send

Emitted after a Sendgrid API response is received, if there are any subscribers.

=head1 ATTRIBUTES

=head2 to (required)

Email address of the recipients.

=head2 from (required)

Email address of the sender.

=head2 subject (required)

The subject of your email.

=head2 text (must include at least one of the text or html attributes)

The plain text content of your email message.

=head2 html (must include at least one of the text or html attributes)

The HTML content of your email message.

=head2 toname

Give a name to the recipient.

=head2 cc

Email address of the CC'd recipients.

=head2 ccname

This is the name appended to the cc field.

=head2 bcc

Email address of the BCC'd recipients.

=head2 bccname

This is the name appended to the bcc field.

=head2 fromname

This is the name appended to the from email field.

=head2 replyto

Append a reply-to field to your email message.

=head2 date

Specify the date header of your email.

=head2 files

Files to be attached.

=head2 content

Content IDs of the files to be used as inline images.

=head2 headers

A collection of key/value pairs in JSON format.

=head2 x_smtpapi

Please review the SMTP API to view documentation on what you can do with the
JSON headers.

=head1 METHODS

=head2 send

  $self = $self->send;

Build the Web request to send and deliver an email using Sendgrid.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Stefan Adams - C<sadams@cpan.org>

=cut
