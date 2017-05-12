package Squatting::On::Mojo;
use strict;
use warnings;
use CGI::Cookie;

our $VERSION = '0.03';
our %p;

$p{e} = sub {
  my $tx  = shift;
  my $req = $tx->req;
  my $url = $req->url;
  my %env;
  $env{QUERY_STRING}   = $url->query || '';
  $env{REQUEST_PATH}   = $url->path->to_string;
  $env{REQUEST_URI}    = "$env{REQUEST_PATH}?$env{QUERY_STRING}";
  $env{REQUEST_METHOD} = $req->method;
  my $h = $req->headers->{_headers};
  for (keys %$h) {
    my $header = "HTTP_" . uc($_);
    $header =~ s/-/_/g;
    $env{$header} = $h->{$_}[0]; # FIXME: I need to handle multiple occurrences of a header.
  }
  \%env;
};

$p{c} = sub {
  my $tx = shift;
  my $c  = $tx->req->cookies;
  my %k;
  for (@$c) { $k{$_->name} = $_->value; }
  \%k;
};

$p{init_cc} = sub {
  my ($c, $tx) = @_;
  my $cc = $c->clone;
  $cc->env     = $p{e}->($tx);
  $cc->cookies = $p{c}->($tx);
  $cc->input   = $tx->req->params->to_hash;
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = {};
  # $cc->state = ?
  $cc->status = 200;
  $cc;
};

sub mojo {
  no strict 'refs';
  my ($app, $mojo, $tx) = @_;
  my ($c,   $p)  = &{ $app . "::D" }($tx->req->url->path);
  my $cc      = $p{init_cc}->($c, $tx);
  $cc->log    = $mojo->log;
  my $content = $app->service($cc, @$p);
  my $h       = $tx->res->headers;
  my $ch      = $cc->headers;
  for my $header (keys %$ch) {
    if (ref $ch->{$header} eq 'ARRAY') {
      for my $item (@{ $ch->{$header} }) {
        $h->add($header => $item);
      }
    } else {
      $h->add($header => $ch->{$header});
    }
  }
  $tx->res->code($cc->status);
  $tx->res->body($content);
  $tx;
}

1;

__END__

=head1 NAME

Squatting::On::Mojo - squat on top of Mojo

=head1 SYNOPSIS

First, Create a Mojo app:

  mojo generate app Foo

Then, Embed a Squatting app Into It:

  cd foo
  $EDITOR lib/Foo.pm

  use Pod::Server 'On::Mojo';
  Pod::Server->init;

  sub handler {
    my ($self, $tx) = @_;
    Pod::Server->mojo($self, $tx);
    $tx;
  }

=head1 DESCRIPTION

The purpose of this module is to allow Squatting apps to be embedded inside
Mojo apps. This is done by adding a C<mojo> method to the Squatting app that
knows how to translate between Mojo and Squatting. To use this module, pass
the string 'On::Mojo' to the use statement that loads your Squatting app.

=head1 API

=head2 Refinements based on lessons learned from Catalyst

=head3 App->mojo($mojo, $tx)

Calling the mojo method will let the Squatting app handle the request.  The
C<$tx> should have its L<Mojo::Message::Response> object populated by
L<Squatting>, and C<$tx> should be ready to return when finished.

=head1 SEE ALSO

L<Mojo>, L<Catalyst>, L<Squatting::On::Catalyst>, L<Pod::Server>

=head1 AUTHOR

John Beppu E<lt>beppu@cpan.orgE<gt>

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
