package common;
use warnings;
use strict;
use vars qw(@ISA);
@ISA = qw(Exporter);
use blib;
use Cwd qw( cwd );
use English qw( -no_match_vars );
use File::Copy::Recursive qw( dircopy );
use File::DirCompare;
use File::Path qw( mkpath rmtree );
use File::Spec;
# this has to go before Module::Starter to affect it
use Test::MockTime qw( set_fixed_time restore_time );
use Module::Starter qw(
    Module::Starter::Plugin::CGIApp
);
use Module::Starter::App;
use Test::More;
use Time::Piece;

=head1 NAME

common - common functions and variables for this modules tests

=head1 VERSION

Version 1.4

=cut

our $VERSION = '1.4';

our @EXPORT = qw/ run_tests /;

sub compare_trees {
    my ($old, $new, $different, $extra, $missing) = @_;

    File::DirCompare->compare($old, $new, sub {
            my ($expected, $got) = @_;

            if (!$expected) {
                push @{$extra}, $got;
            }
            elsif (!$got) {
                push @{$missing}, $expected;
            }
            else {
                push @{$different}, $got;
            }
        },
        {
            # ignore line endings in file comparisons.
            cmp => sub {
                my ($expected, $got) = @_;

                return File::Compare::compare($expected, $got, sub {
                    my ($line1, $line2) = @_;
                    chomp $line1;
                    chomp $line2;
                    return $line1 ne $line2;
                });
            },
        },
    );
}

sub run_tests {
    my ($type, $keep) = @_;

    my %builder = (
        mb   => 'Module::Build',
        mi   => 'Module::Install',
        eumm => 'ExtUtils::MakeMaker',
    );

    my $dir = File::Spec->catdir(cwd, 't');
    my $old = File::Spec->catdir($dir, 'temp');
    my $new = File::Spec->catdir($dir, 'Example-Dist');

    if ( -d $old ) {
        rmtree $old || die "$OS_ERROR\n";
    }
    if ( -d $new ) {
        rmtree $new || die "$OS_ERROR\n";
    }

    mkpath $old or die "$OS_ERROR\n";
    dircopy 't/expected', $old or die "$OS_ERROR\n";
    dircopy "t/$type", $old or die "$OS_ERROR\n";

    # Standardize the test environment so things like differing time zones and
    # line endings don't cause false test failures.
    $ENV{MODULE_STARTER_DIR} = $dir;
    $ENV{MODULE_TEMPLATE_DIR} = File::Spec->catdir(  'share', 'default' );
    $ENV{TZ} = 'UTC';
    Time::Piece::_tzset();  # workaround for lack of POSIX::tzset in strawberry
    set_fixed_time('2010-01-01T00:00:00Z');

    Module::Starter->create_distro(
        distro  => 'Example-Dist',
        modules => [ 'Foo::Bar', 'Foo::Baz' ], 
        dir     => $new,
        author  => 'Jaldhar H. Vyas', 
        email   => 'jaldhar@braincells.com',
        builder => $builder{$type},
    );
    restore_time();
    
    my (@different, @extra, @missing);

    plan tests => 3;
    compare_trees($old, $new, \@different, \@extra, \@missing);
    is(scalar @different, 0, 'different files') || diag join "\n", @different;
    is(scalar @extra, 0, 'extra files') || diag join "\n", @extra;
    is(scalar @missing, 0, 'missing files') || diag join "\n", @missing;

    if ( -d $old && !defined $keep) {
        rmtree $old || die "$OS_ERROR\n";
    }

    if ( -d $new && !defined $keep) {
        rmtree $new || die "$OS_ERROR\n";
    }

    return;
}

1;
