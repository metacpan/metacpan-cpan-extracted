use 5.008005;
use strict;
use inc::Module::Install 1.00;

# Workaround for the fact that Module::Install loads the modules
# into memory and when Test::NoWarnings is loaded it will hide
# the warnings generated from that point.
eval {
	require Test::NoWarnings;
	$SIG{__WARN__} = 'DEFAULT';
};

# Configure-time dependencies MUST be done first.
# This version ensures that we have a new MakeMaker that
# WON'T load modules to determine the version.
# This _SHOULD_ theoretically make the "require Test::NoWarnings".
# stuff above here no longer needed.
configure_requires 'ExtUtils::MakeMaker' => '6.98';


name 'Task-Test';
license 'perl';
author 'Gabor Szabo';
all_from 'lib/Task/Test.pm';
requires 'perl' => '5.008005';

requires 'Test::Exception'      => '0.32';
requires 'Test::More'           => '1.001003';
requires 'Test::Most'           => '0.33';
requires 'Test::MockObject'     => '1.20140408';
requires 'Test::NoWarnings'     => '1.04';
requires 'Test::Output'         => '1.03';
requires 'Test::Perl::Critic'   => '1.02';
requires 'Test::Pod'            => '1.48';
requires 'Test::Pod::Coverage'  => '1.10';
requires 'Test::Script'         => '1.07';
requires 'Test::WWW::Mechanize' => '1.44';
requires 'Test::Warn'           => '0.30';
requires 'Test::Strict'         => '0.23';
requires 'Test::Deep'           => '0.112';
requires 'Test::Distribution'   => '2.00';
requires 'Test::Inline'         => '2.213';
requires 'Test::Snapshots'      => '0.02';
requires 'Test::Kwalitee'       => '1.19';
requires 'Test::Spelling'       => '0.19';
requires 'Test::DatabaseRow'    => '2.04';
requires 'Test::Differences'    => '0.62';
requires 'Test::Memory::Cycle'  => '1.04';
requires 'Test::Taint'          => '1.06';
requires 'Test::Class'          => '0.46';
requires 'Test::Class::Moose'   => '0.54';
requires 'Test::FailWarnings'   => '0.008';
requires 'Test::Warnings'       => '0.016';
requires 'Test::Fatal'          => '0.013';
requires 'Test::File'           => '1.36';
requires 'Test::LongString'     => '0.15';
requires 'Test::XPath'          => '0.16';


requires 'Template'             => '2.25';      # helper for Devel::Cover
requires 'PPI::HTML'            => '1.08';       # helper for Devel::Cover
requires 'Perl::Tidy'           => '20140711';      # helper for Devel::Cover
requires 'Pod::Coverage'        => '0.23';
requires 'Pod::Coverage::CountParents' => '0';  # no version number in module.
requires 'Parallel::Iterator'   => '1.00';
requires 'JSON::XS'             => '3.01';
requires 'Browser::Open'        => '0.04';

requires 'Test::Compile'        => '1.2.0';



requires 'Test::HTML::Lint'     => '2.20';
requires 'HTML::Lint'           => '2.20';
#requires 'Test::WWW::Simple'    => '0.34';

requires 'Fennec'               => '2.017';
requires 'Fennec::Declare'      => '1.002';


requires 'Win32::GuiTest'       => '1.60' if win32;
requires 'Win32::GUIRobot'      => '0.05' if win32;

requires 'Pod::Spell'           => '1.15';
requires 'Devel::Cover'         => '1.15';
requires 'Devel::NYTProf'       => '5.06';

requires 'Net::Telnet'          => '3.04';
requires 'IO::Socket'           => '1.25';
requires 'Net::FTP'             => '1.27';
requires 'Net::SSH'             => '0.09';
requires 'Net::SSH::Perl'       => '1.37';
requires 'Plack'                => '1.0031';
requires 'Net::Server'          => '2.008';


requires 'LWP::UserAgent'       => '6.06';
requires 'LWP::Simple'          => '6.00';
requires 'LWP::Protocol::https' => '6.04';
requires 'HTTP::Proxy'          => '0.301';
#requires 'HTTP::Recorder'       => '0.07';
requires 'File::Compare'        => '0'; # core
requires 'Text::Diff'           => '1.41';
requires 'DBD::Mock'            => '1.45';
#requires 'Test::Unit'           => '0.25';
requires 'IPC::Run'             => '0.92';
requires 'IPC::Run3'            => '0.048';

requires 'Selenium::Remote::Driver' => '0.2102';
requires 'Test::Expect'             => '0.31';
requires 'Expect'                   => '1.21';
requires 'Expect::Simple'           => '0.04';
requires 'Test::Class'              => '0.46';
requires 'Test::Mock::Simple'       => '0.04';
requires 'Test::MockTime'           => '0.12';
requires 'Test::Class::Moose'       => '0.54';
requires 'X11::GUITest'             => '0.28' if $^O eq 'linux';
requires 'Capture::Tiny'            => '0.24';

requires 'List::MoreUtils'          => '0.33';
requires 'HTTP::Daemon'             => '6.01';
requires 'HTTP::Status'             => '6.03';
requires 'HTML::Tidy'               => '1.56';
requires 'Test::HTML::Tidy'         => '1.00';

requires 'TAP::Formatter::HTML'     => '0.11';
requires 'Smolder'                  => '1.51';
requires 'WWW::Mechanize::Firefox'  => '0.76';

requires 'Test::WWW::Mechanize::PSGI' => '0.35';
requires 'Data::Random'               => '0.11';
requires 'HTTP::CookieJar::LWP'       => '0.006';
requires 'WWW::Mechanize::PhantomJS'  => '0.06';

# color support for prove:
requires 'Term::ANSIColor'          => '4.03' if not win32;
requires 'Win32::Console'           => '0.10' if win32;


no_index 'directory' => qw{ t xt eg share inc privinc };
homepage 'https://github.com/szabgab/Task-Test';
bugtracker 'https://github.com/szabgab/Task-Test';
repository 'https://github.com/szabgab/Task-Test';

WriteAll;
