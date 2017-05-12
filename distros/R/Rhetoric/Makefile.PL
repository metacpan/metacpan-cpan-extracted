use inc::Module::Install;

name 'Rhetoric';
all_from 'lib/Rhetoric.pm';

requires 'aliased'                    => 0;
requires 'common::sense'              => 0;
requires 'Squatting'                  => '0.81';
requires 'File::Find::Rule'           => 0;
requires 'File::Path::Tiny'           => 0;
requires 'File::Which'                => 0;
requires 'IO::All'                    => 0;
requires 'Memoize'                    => 0;
requires 'Method::Signatures::Simple' => 0;
requires 'CGI'                        => '1.30';
requires 'Data::Page'                 => 0;
requires 'Ouch'                       => '0.03';
requires 'Try::Tiny'                  => 0;
requires 'XML::Atom'                  => 0;
requires 'Module::Find'               => 0;
requires 'Squatting::On::PSGI'        => '0.05';
requires 'Template'                   => 0;
requires 'Pod::Simple'                => 0;
requires 'Text::Textile'              => 0;
requires 'Text::Markdown'             => 0;

install_script 'bin/rh';
install_script 'bin/rh-init';
install_script 'bin/rh-export';
install_script 'bin/rh-import-themes';
install_script 'bin/rh-psgi';

install_share 'share';

WriteAll;
