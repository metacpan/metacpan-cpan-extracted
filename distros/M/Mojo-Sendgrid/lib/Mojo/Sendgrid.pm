package Mojo::Sendgrid;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::Sendgrid::Mail;

our $VERSION = '0.05';

has apikey => sub { $ENV{SENDGRID_APIKEY} or die "config apikey missing" };
has apiurl => sub { $ENV{SENDGRID_APIURL} || 'https://api.sendgrid.com/api/mail.send.json' };

sub mail { Mojo::Sendgrid::Mail->new(sendgrid => shift, @_) }

1;

=encoding utf8

=head1 NAME

Mojo::Sendgrid - Sendgrid API implementation for the Mojolicious framework

=head1 VERSION

0.05

=head1 SYNOPSIS

  use Mojo::Sendgrid;

  my $sendgrid = Mojo::Sendgrid->new(
                   config => {
                     apikey => 'get your key from api.sendgrid.com',
                     #apiurl => 'you do not need to set this',
                   },
                 );

  $sendgrid->on(mail_send => sub {
    my ($sendgrid, $ua, $tx) = @_;
    say $tx->res->body;
  });

  say $sendgrid->mail(
    to      => q(a@b.com),
    from    => q(x@y.com),
    subject => time,
    text    => time
  )->send;

  Mojo::IOLoop->start;

=head1 DESCRIPTION

L<Mojo::Sendgrid> is an implementation of the Sendgrid API and is non-blocking
thanks to L<Mojo::IOLoop> from the wonderful L<Mojolicious> framework.

It currently implements the mail endpoint of the Web API v2.

This class inherits from L<Mojo::EventEmitter>.

=head1 EVENTS

Mojo::Sendgrid inherits all events from Mojo::EventEmitter and can emit the following new ones.

=head2 mail_*

See <Mojo::Sendgrid::Mail> for full list

=head1 ATTRIBUTES

=head2 config

Holds the configuration hash.

=head2 apikey

Accesses the apikey element of L</config>.
Can be overridden by the environment variable SENDGRID_APIKEY.
This attribute is required to have a value.

=head2 apiurl

Accesses the apiurl element of L</config>.
Can be overridden by the environment variable SENDGRID_APIURL.
This attribute by default uses the Web API v2 URL documented by Sendgrid.

=head1 METHODS

=head2 mail

  $self = $self->mail(%args);

The mail endpoint of the Sendgrid Web API v2.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Stefan Adams - C<sadams@cpan.org>

=cut