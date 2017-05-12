#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Command;

#  Benchmarks take about a minute to run all 100+, this lets people
#  skip them.  If they don't have Test::Slow installed, then we assume
#  they don't care that the tests might be slow.
eval "use Test::Slow;";

use Template::Benchmark;

use File::Spec;
use FindBin;
use Config;
use Cwd ();

my $num_features   = scalar( Template::Benchmark->valid_features() );
my $num_types      = scalar( Template::Benchmark->valid_cache_types() );
my $num_benchmarks = $num_features * $num_types * 2;

plan tests => $num_benchmarks;

my ( $script_dir, $perl, $script, $script_options, $cmd, $tc );

{
    my ( @candidate_dirs );

    foreach my $startdir ( Cwd::cwd(), $FindBin::Bin )
    {
        push @candidate_dirs,
            File::Spec->catdir( $startdir, '..', 'script' ),
            File::Spec->catdir( $startdir, 'script' );
    }

    @candidate_dirs = grep { -d $_ } @candidate_dirs;

    plan skip_all => ( 'unable to find script dir relative to bin: ' .
        $FindBin::Bin . ' or cwd: ' . Cwd::cwd() )
        unless @candidate_dirs;

    $script_dir = $candidate_dirs[ 0 ];
}

$script = File::Spec->catfile( $script_dir, 'benchmark_template_engines' );

#  Untaint stuff so -T doesn't complain.
delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};   # Make %ENV safer

#  We trust their Cwd info and so forth, so blindly untaint this.
( $script ) = $script =~ /^(.*)$/;

#  Ditto their perl location.
#  We run the script via the currently invoked perl, because the
#  shebang perl at the top of the script is probably the wrong version
#  under a smoke tester.
( $perl ) = $^X =~ /^(.*)$/;

#  Some smoke-test setups seem to set @INC so subcommands can't see
#  where they've installed the required modules.
local $ENV{ PERL5LIB } = join( $Config{ path_sep } || ':', @INC );
#diag( "Settinng PERL5LIB: $ENV{PERL5LIB}" );


SKIP: {
    eval "use Template::Benchmark::Engines::TemplateSandbox";
    skip 'Template::Benchmark::Engines::TemplateSandbox required to load ' .
        "to test benchmarks: $@", $num_benchmarks
        if $@;

    foreach my $cache_type ( Template::Benchmark->valid_cache_types() )
    {
        foreach my $template_feature ( Template::Benchmark->valid_features() )
        {
            my ( $base_cmd );

            $base_cmd = "$perl $script -d '-1' -r 1 --nofeatures --notypes " .
                "--onlyplugin TemplateSandbox " .
                "--$cache_type --$template_feature";

            #
            #  n1:  Does these options work?
            $cmd = $base_cmd;
#            diag( "Testing script output with command: $cmd" );
            $tc = Test::Command->new( cmd => $cmd );
            $tc->stdout_like(
                qr/(:?^---\ Engine\ errors .*)?
                   (:?^---\ Starting\ Benchmarks .*)
                   (:?^---\ Template\ Benchmark .*)
                   (:?^TS .*)
                   (:?^---\ \Q$cache_type\E .*)
                   (:?^TS .*)
                  /xms, "--$template_feature --$cache_type runs ok" );
            $tc->stderr_is_eq( '',
                "--$template_feature --$cache_type produces no warnings" );
        }
    }
}
