use Test::More;
use strict;
use warnings;

use File::Spec::Functions;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

eval { require Test::LongString; import Test::LongString; };
my $has_test_longstring = $@ eq '';

# our own string comparison test function
sub is_same_string {
    my ($got, $expected, $name) = @_;
    if ($has_test_longstring) {
        is_string( $got, $expected, $name);
    }
    else {
        is( $got, $expected, $name);
    }
}

my %avail = map { $_ => 1 }
    grep { $_ ne 'default' } Pod::POM::View::HTML::Filter->filters();

# all available files
my $re = @ARGV ? qr/@{[shift]}/ : qr//;
my @pods = grep { /$re/ } glob( catfile( 't', 'pod', '*.src' ) );

# compute the test data
my %result;
my %pod;
for my $file (@pods) {

    # read the file
    my $content;
    {
        local $/;
        open my $fh, $file or diag "Can't open $file: $!";
        $content = <$fh>;
        close $fh;
    }

    # process the file content
    my ( $pod, @results ) = split /__RESULT__\n/, $content;
    for my $result (@results) {
        my ( $filters, $output ) = split /\n/, $result, 2;
        $result{$file}{$filters} = $output;
    }

    # create the pod
    $pod{$file} = $pod;
}

# compute the total number of tests
my $tests;
$tests += $_ for map { /\+/ ? 2 : 1 } map { keys %$_ } values %result;
plan tests => $tests;

# run the tests for all files
for my $file ( sort keys %result ) {

    for my $format ( sort keys %{ $result{$file} } ) {

    SKIP: {
            my $skip = $format =~ /\+/ ? 2 : 1;

            # create the view
            my $view = Pod::POM::View::HTML::Filter->new();

            # format is for example: +html-perl
            while ( $format =~ /([+-])(\w+)/g ) {

                # skip if required filter not here
                skip "$file <$format> [$2 not available]", $skip
                    if $1 eq '+' && !$avail{$2};

                # remove unwanted filter
                $view->delete($2) if $1 eq '-';
            }

            # create the POM
            my $pom = Pod::POM->new()->parse_text( $pod{$file} );

            # compare the results
            is_same_string( $view->print($pom),
                $result{$file}{$format},
                "$file <$format>"
            );

            # test a duplicate run on the same $pom/$view pair
            if ( $format =~ /\+/ ) {
                is_same_string( $view->print($pom),
                    $result{$file}{$format},
                    "$file <$format> (2nd run)"
                );
            }
        }
    }
}

