#!/usr/bin/perl

use ExtUtils::MakeMaker;

use 5.008;
use warnings;

WriteMakefile(
    NAME            => "Serengeti",
    ABSTRACT        => "",
    VERSION_FROM    => "lib/Serengeti.pm",
    PREREQ_PM       => {
        "accessors::ro"             => 0,
        "File::Basename"            => 0,
        "File::Path"                => 0,
        "File::Slurp"               => 0,
        "HTML::Selector::XPath"     => 0,
        "HTML::TreeBuilder::XPath"  => 0,
        "HTTP::Response"            => 0,
        "JavaScript"                => 1.16,
        "List::Util"                => 0,
        "Module::Load"              => 0,
        "Module::Pluggable"         => 0,
        "Regexp::Common"            => 0,
        "Scalar::Util"              => 0,
        "Test::Exception"           => 0,
        "URI"                       => 0,
        "URI::Escape"               => 0,
        "WWW::Curl"                 => 4.12,
    },
    AUTHOR        => 'Claes Jakobsson <claesjac@cpan.org>',
);
