# -*- perl -*-

use Test::More tests => 4;

BEGIN { use_ok( 'Storable::CouchDB' ); }

my $s=My::Storable::CouchDB->new;
isa_ok($s, 'Storable::CouchDB');
is($s->db, "what-i-want", "db");
is($s->uri, "http://where.i.want:5984/", "uri");

package #on two lines so CPAN will not index
  My::Storable::CouchDB;
use base qw{Storable::CouchDB};
sub db {"what-i-want"};
sub uri {"http://where.i.want:5984/"};
1;
