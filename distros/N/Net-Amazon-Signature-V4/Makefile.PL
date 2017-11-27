use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefile_args = (
    NAME                => 'Net::Amazon::Signature::V4',
    AUTHOR              => q{Tim Nordenfur <tim@gurka.se>},
    VERSION_FROM        => 'lib/Net/Amazon/Signature/V4.pm',
    ABSTRACT_FROM       => 'lib/Net/Amazon/Signature/V4.pm',
    MIN_PERL_VERSION    => '5.8.1',
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Digest::SHA' => 0,
        'Time::Piece' => '1.17',
        'URI::Escape' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'File::Slurper' => 0,
        'HTTP::Request' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        no_index => {
            directory => [ 'xt' ],
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Grinnz/Net-Amazon-Signature-V4.git',
                web  => 'https://github.com/Grinnz/Net-Amazon-Signature-V4',
            },
        },
        x_contributors => [
            'Arthur Axel fREW Schmidt <frioux@gmail.com>',
            'Dan Book <dbook@cpan.org>',
            'Karen Etheridge <ether@cpan.org>',
            'Steven Hartland <steven.hartland@multiplay.co.uk>',
        ],
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Amazon-Signature-V4-*' },
);

delete $WriteMakefile_args{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31') };
delete $WriteMakefile_args{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.46') };
delete $WriteMakefile_args{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48') };
unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
  my $test_requires = delete $WriteMakefile_args{TEST_REQUIRES};
  $WriteMakefile_args{PREREQ_PM}{$_} = $test_requires->{$_} for keys %$test_requires;
}

WriteMakefile(%WriteMakefile_args);
