#!perl
use 5.024;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

local $| = 1;

my %optional = (
    'Mojo::IOLoop::Thread' => {
        version => '0.10',
        skip    => $^O ne 'MSWin32',
        msg     => 'You will need the optional module Mojo::IOLoop::Thread (>= 0.10) to use parallel job processing.'
    },
    'Text::CSV_XS' => {
        version => '1.36',
        msg     => 'Please consider installing Text::CSV_XS for much faster CSV handling',
    },
    'DBI' => {
        version => '1.636',
        msg     => 'For reading data from Databases, you will need DBI (>= 1.636)',
    },
    'Spreadsheet::Read' => {
        version => '0.83',
        msg     => 'For reading data from Spreadsheets, you will need Spreadsheet::Read (>= 0.83)',
    },
    'Spreadsheet::ParseODS' => {
        version => '0.26',
        msg     => 'For reading data from ODS/SXC Spreadsheets, you will need Spreadsheet::ParseODS (>= 0.26)',
    },
    'Spreadsheet::ParseXLSX' => {
        version => '0.24',
        msg     => 'For reading data from XLSX Spreadsheets, you will need Spreadsheet::ParseXLSX (>= 0.24)',
    },
);


for my $mod ( keys %optional ) {
    my $om = $optional{$mod};
    next if $om->{skip};

    print "Checking optional module $mod $om->{version}: ";
    my $ok = eval "require $mod; $mod->VERSION >= $om->{version};";    ## no critic (ProhibitStringyEval)
    if ( $@ || !$ok ) {
        sleep 1;
        print "NOT FOUND!\n";
        print "*** ", $om->{msg}, "\n";
        sleep 2;
    }
    else {
        print "FOUND!\n";
    }
}


WriteMakefile(
    NAME         => 'Spreadsheet::Compare',
    VERSION_FROM => 'lib/Spreadsheet/Compare.pm',
    ABSTRACT     => 'Module for comparing spreadsheet-like datasets',
    AUTHOR       => 'Thomas Kratz <tomk@cpan.org>',
    LICENSE      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => { version => 2 },
        no_index       => { directory => ['t'] },
        prereqs        => { runtime => { requires => { perl => '5.024' } } },
        resources      => {
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
            bugtracker => {
                web => 'https://github.com/tomk3003/spreadsheet-compare/issues'
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/tomk3003/spreadsheet-compare.git',
                web  => 'https://github.com/tomk3003/spreadsheet-compare',
            },
        },
    },
    PREREQ_PM => { qw(
        Mojolicious                8.43
        Path::Tiny                 0.100
        YAML::Any                  0
        Log::Log4perl              0
        Try::Tiny                  0
        Class::Method::Modifiers   0
        Text::CSV                  1.96
        Excel::Writer::XLSX        1.00
        Pod::Find                  0
        Pod::Usage                 0
        Capture::Tiny              0
    ) },
    TEST_REQUIRES => {
        'Test::Exception' => 0.43,
        $ENV{SPREADSHEET_COMPARE_TEST_ALL}
        ? qw(
            DBD::SQLite                1.52
            Spreadsheet::Read          0.83
            Spreadsheet::ParseXLSX     0.24
            Spreadsheet::ParseODS      0.26
            )
        : (),
    },
    EXE_FILES => ['script/spreadcomp'],
    test      => { TESTS => 't/*.t' }
);
