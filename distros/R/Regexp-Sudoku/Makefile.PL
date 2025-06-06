#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my  $PACKAGE      =  'Regexp::Sudoku';

my  $LIB_FILE     =  "lib/$PACKAGE.pm";
    $LIB_FILE     =~  s!::!/!g;
my  $POD_FILE     =   $LIB_FILE;
    $POD_FILE     =~  s/\.pm$/.pod/;
my  $LOCAL_ADDR   =  'cpan';
my  $DOMAIN       =  'abigail.freedom.nl';
my  $REPO         =   $PACKAGE;
    $REPO         =~  s!::!-!g;
my  $REPO_HOST    =  'github.com';
my  $ME           =  'Abigail';
my  $REPOSITORY   =  "git://$REPO_HOST/$ME/$REPO.git";


my %args = (
    NAME                 =>  $PACKAGE,
    VERSION_FROM         =>  $LIB_FILE,
    ABSTRACT_FROM        =>  $POD_FILE,
    PREREQ_PM            => {
        'strict'                     =>  0,
        'warnings'                   =>  0,
        'experimental'               =>  0,
        'Exporter'                   =>  0,
        'Hash::Util::FieldHash'      =>  0,
        'List::Util'                 =>  0,
        'Math::Sequence::DeBruijn'   =>  0,
    },
    MIN_PERL_VERSION     =>   5.028,
    AUTHOR               =>  "$ME <$LOCAL_ADDR\@$DOMAIN>",
    LICENSE              =>  'mit',
    META_MERGE           => {
        test_requires    => {
            'strict'             => 0,
            'warnings'           => 0,
            'experimental'       => 0,
            'lib'                => 0,
            'List::Util'         => 0,
            'Exporter'           => 0,
            'Test::More'         => 0.88,
            'Test::Exception'    => 0,
        },
        resources        => {
            repository   => $REPOSITORY,
        },
        keywords         => [qw [ ]],
    },
);

$args {META_MERGE} {build_requires} ||= {
    'ExtUtils::MakeMaker' =>  0,
    %{$args {META_MERGE} {test_requires}}
};

$args {META_MERGE} {configure_requires} ||=
    $args {META_MERGE} {build_requires};

my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
