use strict;
use warnings;
use Test::More;
use File::Glob;
use File::Spec;

use Pod::POM;
use Pod::POM::View::Confluence;

my $has_test_longstring
    = eval { require Test::LongString; import Test::LongString; 1; };

my $parser = Pod::POM->new();
my $view   = 'Pod::POM::View::Confluence';

# get the list of sources
my @files = glob File::Spec->catfile(qw( t data *.pod ));
@files = grep {/$ARGV[0]/} @files if @ARGV;

plan tests => scalar @files;

for my $file (@files) {

    # get the confluence output
    my $pom = $parser->parse_file($file);
    my $got = $pom->present($view);

    # get the expected result
    ( my $expected = $file ) =~ s/\.pod$/.wiki/;
    $expected = slurp($expected);

    # compare
    if ( $file =~ /TODO/ ) {
    TODO: {
            local $TODO = 'not fully implemented yet';
            is_same_string( $got, $expected, "Confluence output of $file" );
        }
    }
    else {
        is_same_string( $got, $expected, "Confluence output of $file" );
    }
}

# helper routine
sub slurp {
    my ($file) = @_;
    local $/;
    open my $handle, '<', $file or do {
        diag "Can't open $file: $!";
        return;
    };
    return readline $handle;
}

# our own string comparison test function
sub is_same_string {
    my ( $got, $expected, $name ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if ($has_test_longstring) {
        is_string( $got, $expected, $name );
    }
    else {
        is( $got, $expected, $name );
    }
}

