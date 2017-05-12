use inc::Module::Install;

name     'Task-Padre-Plugin-Deps';
all_from 'lib/Task/Padre/Plugin/Deps.pm';
author   'Gabor Szabo';
license  'perl';

requires 'Padre'                   => '0.21';

# Padre::Plugin::AcmePlayCode   0.02,
requires 'Acme::PlayCode';

# Padre::Plugin::Alarm
requires 'Audio::Beep';

# Padre::Plugin::Autoformat
requires 'Text::Autoformat';

# Padre::Plugin::CSS 0.02
requires 'WebService::Validator::CSS::W3C';
requires 'CSS::Minifier::XS';

# Padre::Plugin::DataWalker
requires  'Wx::Perl::DataWalker' => '0.02';
requires  'YAML::XS'             => '0';

# Padre::Plugin::Encrypt  0.01
requires 'Crypt::CBC';
requires 'Crypt::Blowfish';

# Padre::Plugin::HTML 0.03
requires 'XML::XPath' => 0;
requires 'WebService::Validator::HTML::W3C' => 0;
requires 'HTML::Tidy' => 0;
requires 'HTML::Lint' => 0;

# Padre::Plugin::HTMLExport
requires 'Syntax::Highlight::Engine::Kate' => 0;

# Padre::Plugin::InstallPARDist',
requires 'ExtUtils::InferConfig'   => '0.02';
requires 'ExtUtils::InstallPAR'    => '0.01';
requires 'LWP::Simple';
        
# Padre::Plugin::JavaScript 0.22
requires 'JavaScript::Beautifier'   => '0.03';
requires 'JavaScript::Minifier::XS';

# Padre::Plugin::Nopaste
requires 'App::Nopaste';

# Padre::Plugin::PAR',
requires 'PAR::Packer';

# Padre::Plugin::PerlCritic 0.03
requires 'Perl::Critic';

# Padre::Plugin::PerlTidy 0.01
requires 'Perl::Tidy';

# Padre::Plugin::XML
requires 'XML::Tidy';

# SVN, Git
requires 'Capture::Tiny' => '0.03';

feature 'Install experimental Padre plugin that runs on Parrot?',
    -default        => 0,
    'Parrot::Embed' => 0;

feature 'Install Padre plugin for Perl6?',
    -default                   => 0,
    'Syntax::Highlight::Perl6' => '0.038',
    'URI'                      => '1.37',
    'Readonly'                 => '1.03',
    'IPC::Run3'                => '0.042';

# Padre::Plugin::PSI
feature 'Install Experimental Padre plugin written in Perl 6?',
    -default         => 0,
    'Inline::Rakudo' => '0.02';

# Padre::Plugin::SVK
feature 'Install Simple SVK interface for Padre?',
    -default        => 0,
    'SVK'           => '2.0.2';

# Padre::Plugin::Catalyst
feature 'Install Simple Catalyst helper interface for Padre?',
    -default                    => 0,
    'Module::Pluggable::Object' => 3.9,
    'Catalyst::Devel'           => '2.0.2';

build_requires 'Test::More';
build_requires 'Test::NeedsDisplay' => '1.05';

auto_install;

WriteAll;
