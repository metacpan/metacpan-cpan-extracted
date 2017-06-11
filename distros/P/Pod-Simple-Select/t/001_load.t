# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 5;
#use lib "../lib";
BEGIN { use_ok( 'Pod::Simple::Select' ); }

my $p = Pod::Simple::Select->new ();
isa_ok ($p, 'Pod::Simple::Select');

$p->select(["head1", ["NAME", "VERSION"]]);
$p->output_hash();
my $path = $INC{'Pod/Simple/Select.pm'};
my %h = $p->parse_file($path);
ok( exists $h{NAME});
ok ( exists $h{VERSION});
like ($h{NAME}, qr/^=head1 NAME.*Pod::Simple::Select.*Select/s, "Name content ok");

