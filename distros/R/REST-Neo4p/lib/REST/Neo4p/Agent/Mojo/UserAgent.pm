use v5.10;
package REST::Neo4p::Agent::Mojo::UserAgent;
use base qw/Mojo::UserAgent REST::Neo4p::Agent/;
use REST::Neo4p::Exceptions;
use MIME::Base64;
use Carp qw/carp/;
use HTTP::Response;
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Agent::Mojo::UserAgent::VERSION = '0.4001';
}

our @default_headers;
our @protocols_allowed;

# LWP::UserAgent API

sub agent {
  my $self = shift;
  my ($name) = @_;
  $self->transactor->name($name) if defined $name;
  return $self->transactor->name;
}

sub credentials {
  my $self = shift;
  my ($srv, $realm, $user, $pwd) = @_;
  $self->{_user} = $user;
  $self->{_pwd} = $pwd;
  $self->{_userinfo} = "$user:$pwd";
  $self->{_realm} = $realm;
  $self->on(start => sub {
	      my ($ua,$tx) = @_;
	      $tx->req->url->userinfo($ua->{_userinfo})
		unless ($tx->req->url->userinfo)
	    });
  return;
}

sub default_header {
  my $self = shift;
  my ($hdr, $value) = @_;
  push @{$self->{_default_headers}}, $hdr, $value;
  return;
}

sub add_header { push @{$_[0]->{_default_headers}}, @_[1,2] }
sub remove_header { 
  my $a = $_[0]->{_default_headers};
  my $i;
  for (0..$#$a) { if ($$a[$_] eq $_[1]) { $i=$_; last; } }
  splice @$a,$i,2 if defined $i;
}
sub protocols_allowed {
  my $self = shift;
  my ($protocols) = @_;
  push @{$self->{_protocols_allowed}}, @$protocols;
  return;
}

sub http_response {
  my ($tx) = @_;
  # kludge : if 400 error, pull the tmp file content back into response
  # body 
  if (!defined $tx->res->code) {
      $tx->res->code(598) if $tx->res->error;
  }
  elsif (($tx->res->code =~ /^4[0-9][0-9]/) && $tx->res->content->asset->is_file ) {
    $tx->res->body($tx->res->content->asset->slurp);
  }
  my $resp = HTTP::Response->new(
    $tx->res->code,
    $tx->res->message // $tx->res->default_message // $tx->res->error,
    [%{$tx->res->headers->to_hash}],
    $tx->res->body
   );
  return $resp;
}

sub timeout { shift->connect_timeout(@_) }

sub get { shift->_do('GET',@_) }
sub delete { shift->_do('DELETE',@_) }
sub put { shift->_do('PUT',@_) }
sub post { shift->_do('POST',@_) }

sub _do {
  my $self = shift;
  my ($rq, $url, @args) = @_;
  use experimental qw/smartmatch/;
  my ($tx, $content, $content_file);
  # neo4j wants to redirect .../data to .../data/
  # and mojo doesn't want to redirect at all...
  $self->max_redirects || $self->max_redirects(2);
  given ($rq) {
    when (/get|delete/i) {
      $tx = $self->build_tx($rq => $url => { @{$self->{_default_headers}} });
    }
    when (/post|put/i) {
      my @rm;
      for my $i (0..$#args) {
	given ($args[$i]) {
	  when ('Content') {
	    $content = $args[$i+1];
	    push @rm, $i, $i+1;
	  }
	  when (':content_file') {
	    $content_file = $args[$i+1];
	    push @rm, $i, $i+1;
	  }
	  default {
	    1;
	  }
	}
      }
      delete @args[@rm];
      my @bricks = ($rq => $url => { @{$self->{_default_headers}}, @args});
      push @bricks, json => $content if defined $content;
      $tx = $self->build_tx(@bricks);
      if (defined $content_file) {
	open my $cfh, ">", $content_file;
	$tx->res->content->unsubscribe('read')->on(
	  read => sub { $cfh->syswrite($_[1]) }
	 );
      }
    }
    default {
      REST::Neo4p::NotImplException->throw("Method $rq not implemented in ".__PACKAGE__."\n");
    }
  }
  $tx = $self->start($tx);
  if ($content_file) {
    $tx->res->content->asset(Mojo::Asset::File->new);
    $tx->res->content->asset->path($content_file);
  }
  http_response($tx);
}

1;
