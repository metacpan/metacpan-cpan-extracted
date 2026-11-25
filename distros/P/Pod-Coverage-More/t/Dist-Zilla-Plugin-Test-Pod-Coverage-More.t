#!perl

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use Capture::Tiny qw{capture};
use Cwd           qw{abs_path};
use File::pushd   qw{pushd};
use FindBin;
use Test::DZil qw{Builder simple_ini};

my $LIB = abs_path("$FindBin::Bin/../lib");

# The module of a distribution that documents its one sub, or documents it with an argument that it does not take.
my %MODULE = (
    documented => "package Corpus;\nuse strict;\nuse warnings;\n\n=head1 FUNCTIONS\n\n=head2 double(count)\n\n=over 4\n\n=item count - Num - what to double\n\n=back\n\nReturns Num.\n\n    my \$four = Corpus::double(2);\n\n=cut\n\nsub double {\n    my (\$count) = \@_;\n    return \$count * 2;\n}\n\n1;\n",
    misnamed   => "package Corpus;\nuse strict;\nuse warnings;\n\n=head1 FUNCTIONS\n\n=head2 double(amount)\n\n=over 4\n\n=item amount - Num - what to double\n\n=back\n\nReturns Num.\n\n    my \$four = Corpus::double(2);\n\n=cut\n\nsub double {\n    my (\$count) = \@_;\n    return \$count * 2;\n}\n\n1;\n",
);

# The distribution built with the plugin from the module MODULE, and what the test it adds says when it runs over the build.
sub build_and_test {
    my ($module) = @_;
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/bogus' },
        {
            add_files => {
                'source/dist.ini'      => simple_ini( 'GatherDir', 'Test::Pod::Coverage::More' ),
                'source/lib/Corpus.pm' => $MODULE{$module},
            },
        },
    );
    $tzil->build;
    my $dir = pushd( $tzil->tempdir->child('build') );
    my ( $out, $err, $status ) = capture { system( $^X, "-I$LIB", '-Ilib', 'xt/author/pod-coverage-more.t' ) };    ## no critic (logicLAB::ProhibitShellDispatch) the test that the build adds is what is under test
    return ( $tzil, $status, "$out$err" );
}

subtest added_test => sub {
    my ( undef, $status, $said ) = build_and_test('documented');
    is( $status, 0, "the test that the plugin adds passes over a module whose POD documents its sub" ) or diag($said);
    like( $said, qr/^ok[ ]1[ ]-[ ]POD[ ]coverage[ ]of[ ]Corpus$/m, "with one test for the module" );

    ( undef, $status, $said ) = build_and_test(q{misnamed});
    isnt( $status, 0, "and fails over one whose POD names an argument that the sub does not take" );
    like( $said, qr/amount/, "naming it" ) or diag($said);
};

subtest register_prereqs => sub {
    my ($tzil) = build_and_test('documented');
    my $develop = $tzil->prereqs->as_string_hash->{develop}{requires};
    ok( exists $develop->{'Test::Pod::Coverage::More'}, "the distribution requires Test::Pod::Coverage::More for development" ) or diag( join q{ }, sort keys %$develop );
};

done_testing;
