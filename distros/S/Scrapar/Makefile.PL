use lib 'lib';
use inc::Module::Install;

name 'Scrapar';
author 'Yung-chung Lin <henearkrxern@gmail.com>';
version '0.0.1';
license 'Perl';
requires 'Exporter::Lite'         => 0;
requires 'File::Find::Rule'       => 0;
requires 'Getopt::Std'            => 0;
requires 'HTML::Query'            => 0;
requires 'HTML::SimpleLinkExtor'  => 0;
requires 'HTML::TableExtract'     => 0;
requires 'List::MoreUtils'        => 0;
requires 'Text::Table'            => 0;
requires 'XML::RSS'               => 0;
requires 'XML::XPath'             => 0;
requires 'XML::XPath::XMLParser'  => 0;
requires 'HTML::TreeBuilder'      => 0;
requires 'List::Util::PP'         => '1.21';
requires 'Scalar::Util::PP'       => '1.21';
requires 'File::Find::Rule'       => '0.30';
requires 'UNIVERSAL::require'     => '0.13';
requires 'List::Util'             => '1.21';
requires 'Email::Find'            => 0;
requires 'URI::Escape'            => 0;
requires 'Regexp::Common'         => 0;
requires 'DBI'                    => 0;
requires 'Date::Format'           => 0;
requires 'Log::Handler'           => 0;
requires 'Sys::MemInfo'           => 0;
requires 'Locale::Country'        => 0;
requires 'WWW::Mechanize::Cached' => 0;

requires_external_bin 'python';

auto_install;
scripts('bin/*.pl');
WriteAll;
