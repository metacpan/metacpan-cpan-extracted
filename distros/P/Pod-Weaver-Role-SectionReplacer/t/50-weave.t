#!perl -T

use strict;
use warnings;

use lib 't/inc';

use Test::More;
use Test::Differences;
use Moose::Autobox 0.10;

use PPI;

use Pod::Elemental;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

use Pod::Weaver;

my @tests = (
    [ pod_with_test_section           => 'with test section',           ],
    [ pod_with_multiple_test_section  => 'with multiple test section',  ],
    [ pod_with_test_section_alias     => 'with test section alias',     ],
    [ pod_with_test_section_and_alias => 'with test section and alias', ],
    [ pod_without_test_section        => 'without test section',        ],
    );

my $tests_per_test = 2;

plan tests => (  scalar( @tests ) * $tests_per_test );

my $perl_document = <<'END_OF_PERL';
package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';
END_OF_PERL

my ( $sequence ) = Pod::Weaver::Config::Finder->new->read_config(
    't/test_files/50-weave'
    );
my $weaver = Pod::Weaver->new_from_config_sequence( $sequence, {} );

foreach my $test ( @tests )
{
    my $in_file   = 't/test_files/' . $test->[ 0 ] . '.in.pod';
    my $out_file  = 't/test_files/' . $test->[ 0 ] . '.out.pod';
    my $test_name = $test->[ 1 ];

    my $in_pod       = do { local $/; open my $fh, '<', $in_file;  <$fh> };
    my $expected_pod = do { local $/; open my $fh, '<', $out_file; <$fh> };

    my $pod_document = Pod::Elemental->read_string( $in_pod );
    my $ppi_document = PPI::Document->new( \$perl_document );

    my $woven_pod_document = $weaver->weave_document( {
        pod_document => $pod_document,
        ppi_document => $ppi_document,
        } );

    my $expected_pod_document = Pod::Elemental->read_string( $expected_pod );
    #  Clean it up before we compare.
    Pod::Elemental::Transformer::Pod5->new->transform_node(
        $expected_pod_document
        );
    my $nester = Pod::Elemental::Transformer::Nester->new( {
        top_selector => s_command( [ qw(head1) ] ),
        content_selectors => [
            s_flat,
            s_command( [ qw(head2 head3 head4 over item back) ]),
            ],
        } );
    $nester->transform_node( $expected_pod_document );


    #
    #  1:  Test the Pod::Elemental structure for the Pod.
    eq_or_diff(
        $woven_pod_document,
        $expected_pod_document,
        "$test_name pod structure correct",
        );

    #
    #  2:  Test the Pod as a string is the expected.
    #  This is more sensitive to upstream changes in Pod::Elemental
    #  (for example white-space in the output), and provides little
    #  benefit in terms of increased testing, however it _does_ produce
    #  output that's considerably more human-readable in the case of
    #  test 1 failing.
    eq_or_diff(
        $woven_pod_document->as_pod_string,
        $expected_pod,
        "$test_name pod string correct",
        );
}

