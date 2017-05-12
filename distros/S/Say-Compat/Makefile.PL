#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %Prereqs;
$Prereqs{"Perl6::Say"} = 0.06 if $] < 5.010 or $ENV{PERL_RELEASING};

WriteMakefile(
    NAME            => "Say::Compat",

    VERSION_FROM    => "lib/Say/Compat.pm",
    ABSTRACT_FROM   => "lib/Say/Compat.pm",
    AUTHOR          => 'Michael G Schwern <schwern@pobox.com>',

    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    PREREQ_PM       => {
        %Prereqs
    },

    ($mm_ver < 6.46 ? () : (META_MERGE => {
        dynamic_config => 1,
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'http://github.com/schwern/say-compat/',
            bugtracker  =>      'http://github.com/schwern/say-compat/issues/',
            repository  =>      'http://github.com/schwern/say-compat/',
        },
    }))
);
