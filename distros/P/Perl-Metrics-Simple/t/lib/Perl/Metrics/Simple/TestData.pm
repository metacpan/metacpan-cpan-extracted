package Perl::Metrics::Simple::TestData;
use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars);
use Readonly;

our $VERSION = '0.01';

# Bad hack. Do this in the data instead!
our @ORDER_OF_FILES = qw(
  Module.pm
  Moose.pm
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
        $main_stats->{mccabe_complexity} +=
          $hash->{main_stats}->{mccabe_complexity};
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
                mccabe_complexity => 1,
                name              => '{code not in named subroutines}',
                path              => "$test_directory/no_packages_nor_subs",
            },
            subs     => [],
            packages => [],
        },
        'empty_file.pl' => {
            path       => "$test_directory/empty_file.pl",
            lines      => 0,
            main_stats => {
                lines             => 0,
                mccabe_complexity => 0,
                name              => '{code not in named subroutines}',
                path              => "$test_directory/empty_file.pl",
            },
            subs     => [],
            packages => [],
        },
        'package_no_subs.pl' => {
            path       => "$test_directory/package_no_subs.pl",
            lines      => 12,
            main_stats => {
                lines             => 12,
                mccabe_complexity => 3,
                name              => '{code not in named subroutines}',
                path              => "$test_directory/package_no_subs.pl",
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
                mccabe_complexity => 2,
                name              => '{code not in named subroutines}',
                path              => "$test_directory/subs_no_package.pl",
            },
            subs => [
                {
                    name              => 'foo',
                    lines             => 1,
                    mccabe_complexity => 1,
                    path              => "$test_directory/subs_no_package.pl",
                },
                {
                    name              => 'bar',
                    lines             => 2,
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
                mccabe_complexity => 1,
                name              => '{code not in named subroutines}',
                path => "$test_directory/Perl/Code/Analyze/Test/Module.pm",
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
                'Perl::Metrics::Simple::Test::Module',
                'Perl::Metrics::Simple::Test::Module::InnerClass'
            ],
        },
        'Moose.pm' => {
            path       => "$test_directory/Perl/Code/Analyze/Test/Moose.pm",
            lines      => 9,
            main_stats => {
                lines             => 3,
                mccabe_complexity => 1,
                name              => '{code not in named subroutines}',
                path => "$test_directory/Perl/Code/Analyze/Test/Moose.pm",
            },
            subs => [
                {
                    name              => 'foo',
                    lines             => 3,
                    mccabe_complexity => 1,
                    path => "$test_directory/Perl/Code/Analyze/Test/Moose.pm",
                },
                {
                    name              => '_after_bar',
                    lines             => 3,
                    mccabe_complexity => 1,
                    path => "$test_directory/Perl/Code/Analyze/Test/Moose.pm",
                },
            ],
            packages => [
                'Perl::Metrics::Simple::Test::Moose',
            ],
        },
      },
      'Perl::Metrics::Simple::Analysis';
    return $test_data;
}
1;
__END__



