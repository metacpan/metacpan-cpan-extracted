use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile
    ( NAME                => 'Sympatic'
    , AUTHOR              => q{YOUR NAME <youremail@example.com>}
    , VERSION_FROM        => 'lib/Sympatic.pm'
    , ABSTRACT            => 'A boilerplate to enforce the coding style of Sympa mailing list manager'
    , PL_FILES            => {}
    , clean               => { FILES => 'Petition-*' }
    , PREREQ_PM =>
        { 'Function::Parameters' => '2.001003'
        , 'Types::Standard'      => '1.002001'
        , 'autodie'              => '2.29'
        , 'utf8::all'            => '0.024'
        , 'Moo'                  => '2.002005' }
    , TEST_REQUIRES =>
        { 'Test::Simple'   => '1.302120'
        , 'Test::Kwalitee' => '1.27' }
    , dist  =>
        { COMPRESS => 'gzip -9f'
        , SUFFIX => 'gz' }
    , ($eumm_version >= 6.3001 ? ('LICENSE'=> 'perl') : ()));
