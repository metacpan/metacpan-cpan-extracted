package Neo4p::Connect;
use base Exporter;
use REST::Neo4p;
use strict;
use warnings;

our @EXPORT=qw/connect/;

sub connect {
  my ($TEST_SERVER,$user,$pass) = @_;
  eval {
    REST::Neo4p->connect($TEST_SERVER,$user,$pass);
  };
  if ( my $e = REST::Neo4p::CommException->caught() ) {
    if ($e->message =~ /certificate verify failed/i) {
      REST::Neo4p->agent->ssl_opts(verify_hostname => 0); # testing only!
      REST::Neo4p->connect($TEST_SERVER,$user,$pass);
      return;
    }
    else {
      return $e;
    }
  }
  elsif ( $e = Exception::Class->caught()) {
    return $e;
  }
}
