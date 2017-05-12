######################################################################
# Test suite for Pod::Licensizer
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use Pod::Licensizer;

plan tests => 8;

my $l = Pod::Licensizer->new();
$l->load_file( "t/eg/no-authors.pod" );

my $desc_rx    = qr/=head1 DESCRIPTION\n\nBlah is superb in every aspect.\n\n/;
my $license_rx = qr/=head1 LICENSE\n\nBlah Blah Blah\n\n/;
my $author_rx  = qr/=head1 AUTHORS?\n\nHoly Moly\n\n/;

$l->author_patch( "Holy Moly" );
like $l->as_string(), qr/$author_rx/, "no-authors i author";

$l->license_patch( "Blah Blah Blah" );
like $l->as_string(), qr/$desc_rx$license_rx$author_rx/, "no-authors i license";

$l->load_file( "t/eg/no-license.pod" );
$l->author_patch( "Holy Moly" );
like $l->as_string(), qr/$author_rx/, "no-license p author";
$l->license_patch( "Blah Blah Blah" );
like $l->as_string(), qr/$desc_rx$author_rx$license_rx/, "no-authors i license";

$l->load_file( "t/eg/no-nothing.pod" );
$l->author_patch( "Holy Moly" );
like $l->as_string(), qr/$author_rx/, "no-nothing i author";
$l->license_patch( "Blah Blah Blah" );
like $l->as_string(), qr/$desc_rx$author_rx$license_rx/, "no-nothing i license";

$l->load_file( "t/eg/sample.pod" );
$l->author_patch( "Holy Moly" );
like $l->as_string(), qr/$author_rx/, "sample p author";
$l->license_patch( "Blah Blah Blah" );
like $l->as_string(), qr/$desc_rx$author_rx$license_rx/, "sample p license";
