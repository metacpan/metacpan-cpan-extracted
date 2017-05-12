# $Header$
# $Revision$
# $Author$
# $Source$
# $Date$
###############################################################################

package Perl::Metrics::Lite::TestData;
use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars);
use Readonly;

our $VERSION = '0.01';

# Bad hack. Do this in the data instead!
our @ORDER_OF_FILES = qw(
  Module.pm
  empty_file.pl
  no_packages_nor_subs
  package_no_subs.pl
  subs_no_package.pl
);

my %TestData = ();

sub new {
    my ( $class, %parameters ) = @_;
    my $self = {};
    bless $self, ref $class || $class;
    $TestData{$self} = $self->make_test_data( $parameters{test_directory} );
    return $self;
}

sub get_test_data {
    my $self = shift;
    return $TestData{$self};
}

sub get_main_stats {
    my $self       = shift;
    my $test_data  = $self->get_test_data;
    my $main_stats = {};

    foreach my $file_name (@ORDER_OF_FILES) {
        my $hash = $test_data->{$file_name};
        $main_stats->{lines}             += $hash->{main_stats}->{lines};
    }
    return $main_stats;
}

sub get_file_stats {
    my $self       = shift;
    my $test_data  = $self->get_test_data;
    my @file_stats = ();
    foreach my $file_name (@ORDER_OF_FILES) {
        my $hash                    = $test_data->{$file_name};
        my $stats_hash_for_one_file = {
            path       => $hash->{path},
            main_stats => $hash->{main_stats},
        };
        push @file_stats, $stats_hash_for_one_file;
    }
    return \@file_stats;
}

sub make_test_data {
    my $self           = shift;
    my $test_directory = shift;
    if ( !-d $test_directory ) {
        confess "test_directory '$test_directory' not found! ";
    }
    my $test_data = bless {
        'no_packages_nor_subs' => {
            path       => "$test_directory/no_packages_nor_subs",
            lines      => 4,
            main_stats => {
                lines             => 4,
                path              => "$test_directory/no_packages_nor_subs",
                packages          => 0,
            },
            subs     => [],
            packages => [],
        },
        'empty_file.pl' => {
            path       => "$test_directory/empty_file.pl",
            lines      => 0,
            main_stats => {
                lines             => 0,
                path              => "$test_directory/empty_file.pl",
                packages          => 0,
            },
            subs     => [],
            packages => [],
        },
        'package_no_subs.pl' => {
            path       => "$test_directory/package_no_subs.pl",
            lines      => 12,
            main_stats => {
                lines             => 12,
                path              => "$test_directory/package_no_subs.pl",
                packages          => 1,
            },
            subs => [

            ],
            packages => ['Hello::Dolly'],
        },
        'subs_no_package.pl' => {
            path       => "$test_directory/subs_no_package.pl",
            lines      => 8,
            main_stats => {
                lines             => 5,
                path              => "$test_directory/subs_no_package.pl",
                packages          => 0,
            },
            subs => [
                {
                    name              => 'foo',
                    lines             => 1,
                    line_number       => 10,
                    mccabe_complexity => 1,
                    path              => "$test_directory/subs_no_package.pl",
                },
                {
                    name              => 'bar',
                    lines             => 2,
                    line_number       => 11,
                    mccabe_complexity => 1,
                    path              => "$test_directory/subs_no_package.pl",
                }
            ],
            packages => [],
        },
        'Module.pm' => {
            path       => "$test_directory/Perl/Code/Analyze/Test/Module.pm",
            lines      => 29,
            main_stats => {
                lines             => 6,
                path => "$test_directory/Perl/Code/Analyze/Test/Module.pm",
                packages => 2,
            },
            subs => [
                {
                    name              => 'new',
                    lines             => 5,
                    mccabe_complexity => 1,
                    path => "$test_directory/Perl/Code/Analyze/Test/Module.pm",
                },
                {
                    name              => 'foo',
                    lines             => 9,
                    mccabe_complexity => 8,
                    path => "$test_directory/Perl/Code/Analyze/Test/Module.pm",
                },
                {
                    name              => 'say_hello',
                    lines             => 9,
                    mccabe_complexity => 5,
                    path => "$test_directory/Perl/Code/Analyze/Test/Module.pm",
                },
            ],
            packages => [
                'Perl::Metrics::Lite::Test::Module',
                'Perl::Metrics::Lite::Test::Module::InnerClass'
            ],
        },
      },
      'Perl::Metrics::Lite::Analysis';
    return $test_data;
}
1;
__END__



