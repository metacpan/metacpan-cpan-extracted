use strict;
use warnings;
use Protocol::UWSGI qw(:all);
# Encode...
my $req = build_request(
  uri    => 'http://localhost',
  method => 'GET',
  remote => '1.2.3.4:1234',
);
# ... and decode again
warn "URI was " . uri_from_env(
  extract_frame(\$req)
);

