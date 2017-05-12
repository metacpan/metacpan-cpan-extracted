package Tatsumaki::Service::XMPP;
use 5.008_001;
our $VERSION = "0.02";

use Any::Moose;
extends 'Tatsumaki::Service';

use constant DEBUG => $ENV{TATSUMAKI_XMPP_DEBUG};

use AnyEvent::XMPP::Client;
use Carp ();
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use namespace::clean -except => 'meta';

has jid      => (is => 'rw', isa => 'Str');
has password => (is => 'rw', isa => 'Str');
has xmpp     => (is => 'rw', isa => 'AnyEvent::XMPP::Client', lazy_build => 1);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if (@_ == 2) {
        $class->$orig(jid => $_[0], password => $_[1]);
    } else {
        $class->$orig(@_);
    }
};

sub _build_xmpp {
    my $self = shift;
    my $xmpp = AnyEvent::XMPP::Client->new(debug => DEBUG);
    $xmpp->add_account($self->jid, $self->password);
    $xmpp->reg_cb(
        error => sub { Carp::croak @_ },
        message => sub {
            my($client, $acct, $msg) = @_;

            return unless $msg->any_body;

            # TODO refactor this
            my $req = POST "/_services/xmpp/chat", [ from => $msg->from, to => $acct->jid, body => $msg->body ];
            my $env = $req->to_psgi;
            $env->{'tatsumaki.xmpp'} = {
                client  => $client,
                account => $acct,
                message => $msg,
            };
            $env->{'psgi.streaming'} = 1;

            my $res = $self->application->($env);
            $res->(sub { my $res = shift }) if ref $res eq 'CODE';
        },
        contact_request_subscribe => sub {
            my($client, $acct, $roster, $contact) = @_;
            $contact->send_subscribed;

            my $req = POST "/_services/xmpp/subscribe", [ from => $contact->jid, to => $acct->jid ];
            my $env = $req->to_psgi;
            $env->{'tatsumaki.xmpp'} = {
                client  => $client,
                account => $acct,
                contact => $contact,
            };
            $env->{'psgi.streaming'} = 1;

            my $res = $self->application->($env);
            $res->(sub { my $res = shift }) if ref $res eq 'CODE';
        },
    );
    $xmpp;
}

sub start {
    my($self, $application) = @_;
    $self->xmpp->start;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Tatsumaki::Service::XMPP - XMPP inbound service for Tatsumaki

=head1 SYNOPSIS

  use Tatsumaki::Application;

  package XMPPHandler;
  use base qw(Tatsumaki::Handler::XMPP);

  sub hello_command {
      my($self, $message) = @_;
      $message->reply("Hello!");
  }

  package main;
  use Tatsumaki::Service::XMPP;

  my $svc = Tatsumaki::Service::XMPP->new($jid, $password);
  my $app = Tatsumaki::Application->new([
      '/_services/xmpp/chat' => 'XMPPHandler',
  ]);
  $app->add_service($svc);
  $app;

=head1 DESCRIPTION

Tatsumaki::Service::XMPP is an inbound XMPP service for Tatsumaki,
which allows you to write an XMPP bot as a standard Tatsumaki web
application handler. Heavily inspired by Google AppEngine XMPP support.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Tatsumaki> L<AnyEvent::XMPP> L<http://code.google.com/appengine/articles/using_xmpp.html>

=cut
