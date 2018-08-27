use Test::More tests => 2;
use strict;
use warnings;
use Pod::Github;
use Path::Tiny;
use FindBin qw($Bin);

my %default_args = (
    'syntax-highlight' => 1,
    'title-case' => 1,
    'shift-headings' => 1,
);

test( 'basic.in', {}, 'basic.out' );
test( 'basic.in', { inline => ['NAME', 'FUNCTIONS'], exclude => ['SYNOPSIS']},
    'sections.out' );

sub test {
    my ($infile, $args, $outfile, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    open my $infh, '<', "$Bin/../t/fixtures/$infile" or die "in: $!";

    $args = { %default_args,  %$args };

    my $expected = path("$Bin/../t/fixtures/$outfile")->slurp_utf8;

    my $obj = Pod::Github->new(%$args);
    $obj->output_string(\my $actual);
    $obj->parse_file($infh);

    is( $actual, $expected, $name );
}
