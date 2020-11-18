#$Id$
use v5.10;
package REST::Neo4p::Agent::HTTP::Thin;
use base qw/HTTP::Thin REST::Neo4p::Agent/;
use URI::Escape;
use MIME::Base64;
use REST::Neo4p::Exceptions;
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Agent::HTTP::Thin::VERSION = '0.4000';
}

my $unsafe = "^A-Za-z0-9\-\._~:+?%&=";
sub agent {
  my $self = shift;
  return $self->{agent} = $_[0] if @_;
  return $self->{agent};
}

sub credentials {
  my $self = shift;
  my ($srv,$realm,$user,$pwd) = @_;
  $self->{_user} = $user;
  $self->{_pwd} = $pwd;
  if ($user && $pwd) {
    $self->default_header(
      'Authorization' => "Basic " . encode_base64("$user:$pwd", '')
    );
  }
  1;
}

sub default_header {
  my $self = shift;
  my ($hdr,$value) = @_;
  $self->{default_headers}->{$hdr} = $value;
  return;
}

sub add_header { shift->{default_headers}->{$_[0]} = $_[1] }
sub remove_header { delete shift->{default_headers}->{$_[0]} }

sub protocols_allowed {
  1;
}

sub timeout { $_[0]->{timeout} = $_[1] }

sub get { shift->_do('GET',@_) }
sub delete { shift->_do('DELETE',@_) }
sub put { shift->_do('PUT',@_) }
sub post { shift->_do('POST',@_) }

sub _do {
  my $self = shift;
  my ($rq, $url, @args) = @_;
  use experimental qw/smartmatch/;
#  if (length($self->{_user}) && length($self->{_pwd})) {
#    $url =~ s|(https?://)|${1}$$self{_user}:$$self{_pwd}@|;
#  }
#  $DB::single = 1 if $url =~ /Roger/;
  $url =~ s{/([^/]+)}{'/'.uri_escape_utf8($1,$unsafe)}ge;
  my ($resp,$content,$content_file);
  given ($rq) {
    when (/get|delete/i) {
      $resp = $self->request(uc $rq, $url);
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
      my %options;
      if (@args) {
	my %args = @args;
	$options{headers} = \%args;
      }

      $options{content} = $content if $content;
      if (defined $content_file) {
	open my $cfh,">", $content_file or die "content file : $!";
	$options{data_callback} = sub { $cfh->write($_[0], length ($_[0])) };
      }
      $resp = $self->request(uc $rq, $url, \%options);
    }
    default {
      REST::Neo4p::NotImplException->throw("Method $rq not implemented in ".__PACKAGE__."\n");
    }
  }
  if ($resp->code == 599) {
    given( $resp->content ) {
      when (/timeout/) {
	$resp->code(500);
	$resp->message("Connection timeout");
      }
      default {
	1;
      }
    }
  }
  return $resp;
}

1;
