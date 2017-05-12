#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::MythWeb',
    VERSION_FROM => 'lib/Net/MythWeb.pm',
    ABSTRACT     => 'Interface to MythWeb',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'DateTime'                   => '0',
        'DateTime::Format::Strptime' => '0',
        'HTML::TreeBuilder::XPath'   => '0',
        'Moose'                      => '0',
        'MooseX::StrictConstructor'  => '0',
        'URI'                        => '0',
        'WWW::Mechanize'             => '0',
    }
);

