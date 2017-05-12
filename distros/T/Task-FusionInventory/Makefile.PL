use strict;
use warnings;

use ExtUtils::MakeMaker;
use English qw(-no_match_vars);

my %args = (
    NAME          => 'Task-FusionInventory',
    ABSTRACT_FROM => 'lib/Task/FusionInventory.pm',
    VERSION_FROM  => 'lib/Task/FusionInventory.pm',
    LICENSE       => 'GPL_2',
    AUTHOR        => 'Guillaume Rousse <guillomovitch@gmail.com>',
    PREREQ_PM     => {
        'Module::Install'                 => 0,
        # core
        'Compress::Zlib'                  => 0,
        'File::Which'                     => 0,
        'HTTP::Daemon'                    => 0,
        'IO::Socket::SSL'                 => 0,
        'LWP'                             => '5.8',
        'LWP::Protocol::https'            => 0,
        'Net::IP'                         => 0,
        'Socket::GetAddrInfo'             => 0,
        'Text::Template'                  => 0,
        'UNIVERSAL::require'              => 0,
        'XML::TreePP'                     => '0.26',
        # inventory
        'Parse::EDID'                     => 0,
        # deploy
        'Archive::Extract'                => 0,
        'Digest::SHA'                     => 0,
        'File::Copy::Recursive'           => 0,
        'JSON'                            => 0,
        'POE::Component::Client::Ping'    => 0,
        'URI::Escape'                     => 0,
        # network discovery and inventory
        'Crypt::DES'                      => 0,
        'Digest::MD5'                     => 0,
        'Net::SNMP'                       => 0,
        'Net::NBName'                     => 0,
        # wake-on-LAN
        'Net::Write::Layer2'              => 0,
    },
    TEST_REQUIRES => {
        'HTTP::Proxy'                  => 0,
        'HTTP::Server::Simple'         => 0,
        'HTTP::Server::Simple::Authen' => 0,
        'IO::Capture::Stderr'          => 0,
        'IPC::Run'                     => 0,
        'Test::Compile'                => 0,
        'Test::Deep'                   => 0,
        'Test::Exception'              => 0,
        'Test::MockModule'             => 0,
        'Test::More'                   => '0.93',
        'Test::NoWarnings'             => 0,
        'Test::MockObject'             => 0,
        'Test::HTTP::Server::Simple'   => 0,
    }
);

if ($OSNAME eq 'MSWin32') {
    $args{PREREQ_PM}->{'Win32::OLE'}         = 0;
    $args{PREREQ_PM}->{'Win32::TieRegistry'} = 0;
    $args{PREREQ_PM}->{'Win32::Job'}         = 0;
    $args{PREREQ_PM}->{'Win32::Daemon'}      = 0;
} else {
    $args{PREREQ_PM}->{'Proc::Daemon'}    = 0;
    $args{PREREQ_PM}->{'Proc::PID::File'} = 0;
    $args{PREREQ_PM}->{'Net::CUPS'}       = 0;
}

WriteMakefile(%args);
