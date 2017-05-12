package Mojolicious::Command::nopaste::Service::shadowcat;
use Mojo::Base 'Mojolicious::Command::nopaste::Service';

has description => "Post to paste.scsys.co.uk\n";

has irc_handled => 1;

sub paste {
  my $self = shift;
  my $ua = $self->ua;
  $ua->max_redirects(0);

  my $tx = $ua->post( 'http://paste.scsys.co.uk/paste' => form => {
    channel => $self->channel || '',
    nick    => $self->name || '',
    paste   => $self->text,
    summary => $self->desc || '',
  });

  unless ($tx->res->is_success) {
    say $tx->res->message;
    say $tx->res->body;
    exit 1;
  }

  # <meta http-equiv="refresh" content="5;url=http://paste.scsys.co.uk/290870">

  my $redir = $tx->res->dom->at('meta[http-equiv="refresh"]')->{content};
  my $url   = $1 if $redir =~ /url=(.*)/;

  die "Could not find redirect url\n" unless $url;

  require Mojo::URL;
  $url = Mojo::URL->new($url);

  $url->query( hl => 'on' ) if $self->language eq 'perl';
  
  return $url;
}

1;

