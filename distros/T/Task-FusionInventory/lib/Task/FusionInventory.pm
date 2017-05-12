package Task::FusionInventory;

use strict;
use warnings;

our $VERSION = '1.00';

1;

__END__

=pod

=head1 NAME

Task::FusionInventory - FusionInventory Agent development dependencies

=head1 VERSION

version 1.00

=head1 SYNOPSIS

This is just a Task module to install dependencies. There's no code to use
or run.

=head1 DESCRIPTION

Installing this module will install all the modules needed for FusionInventory
Agent development.

The following modules are installed everyhwere:

=over

=item * Archive::Extract

=item * Compress::Zlib

=item * Crypt::DES

=item * Digest::MD5

=item * Digest::SHA

=item * File::Copy::Recursive

=item * File::Which

=item * HTTP::Daemon

=item * HTTP::Proxy

=item * HTTP::Server::Simple

=item * HTTP::Server::Simple::Authen

=item * IO::Capture::Stderr

=item * IO::Socket::SSL

=item * IPC::Run

=item * JSON

=item * LWP

=item * LWP::Protocol::https

=item * Module::Install

=item * Net::IP

=item * Net::NBName

=item * Net::SNMP

=item * Net::Write::Layer2

=item * Parse::EDID

=item * POE::Component::Client::Ping

=item * Socket::GetAddrInfo

=item * Test::Compile

=item * Test::Deep

=item * Test::Exception

=item * Test::HTTP::Server::Simple

=item * Test::MockModule

=item * Test::MockObject

=item * Test::More

=item * Test::NoWarnings

=item * Text::Template

=item * UNIVERSAL::require

=item * URI::Escape

=item * XML::TreePP

=back

The following modules are installed on Win32 systems only:

=over

=item * Win32::Daemon

=item * Win32::Job

=item * Win32::OLE

=item * Win32::TieRegistry

=back

The following modules are installed on non-Win32 systems only:

=over

=item * Net::CUPS

=item * Proc::Daemon

=item * Proc::PID::File

=back

=head1 AUTHOR

Guillaume Rousse <guillomovitch@gmail.com>

=head1 LICENSE

This software is licensed under the terms of GPLv2+.

=cut
