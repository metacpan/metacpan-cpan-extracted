use inc::Module::Install;
name 'Net-Redmine';
all_from 'lib/Net/Redmine.pm';

requires
    "Any::Moose"                    => "0.07",
    "DateTime::Format::DateParse"   => "0.04",
    "DateTimeX::Easy"               => "0.086",
    "Encode"                        => "2.31",
    "HTML::WikiConverter"           => "0.68",
    "HTML::WikiConverter::Markdown" => "0.05",
    "IO::All"                       => "0.39",
    "IO::String"                    => "1.08",
    "Params::Validate"              => "0.91",
    "Text::CSV::Slurp"              => "0.5",
    "URI"                           => "1.38",
    "URI::Escape"                   => "3.29",
    "WWW::Mechanize"                => "1.52",
    "Regexp::Common"                 => "2.122",
    "Regexp::Common::Email::Address" => "1.01",
    "pQuery"                        => "0.07";

build_requires
    "Test::Cukes"             => "0.06",
    "Test::Memory::Cycle"     => "1.04",
    "Text::Greeking"          => "0.11",
    "Quantum::Superpositions" => "1.03",
    "Test::More"              => "0.86";

repository 'http://github.com/gugod/net-redmine';

tests 't/*.t';
author_tests 'xt';

auto_include;
# auto_license;
WriteAll;
