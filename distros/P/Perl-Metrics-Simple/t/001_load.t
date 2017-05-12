# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Perl::Metrics::Simple' ); }

my $object = Perl::Metrics::Simple->new ();
isa_ok ($object, 'Perl::Metrics::Simple');


