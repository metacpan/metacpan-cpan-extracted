package System::Info;

use strict;
use warnings;

our $VERSION = "0.057";

use base "Exporter";
our @EXPORT_OK = qw( &sysinfo &sysinfo_hash &si_uname );

use System::Info::AIX;
use System::Info::BSD;
use System::Info::Cygwin;
use System::Info::Darwin;
use System::Info::Generic;
use System::Info::Haiku;
use System::Info::HPUX;
use System::Info::Irix;
use System::Info::Linux;
use System::Info::Solaris;
use System::Info::VMS;
use System::Info::Windows;

=head1 NAME

System::Info - Factory for system specific information objects

=head1 SYNOPSIS

    use System::Info;

    my $si = System::Info->new;

    printf "Hostname:              %s\n", $si->host;
    printf "Number of CPU's:       %s\n", $si->ncpu;
    printf "Processor type:        %s\n", $si->cpu_type; # short
    printf "Processor description: %s\n", $si->cpu;      # long
    printf "OS and version:        %s\n", $si->os;

or

    use System::Info qw( sysinfo );
    printf "[%s]\n", sysinfo ();

or

    $ perl -MSystem::Info=si_uname -le print+si_uname

=head1 DESCRIPTION

System::Info tries to present system-related information, like number of CPU's,
architecture, OS and release related information in a system-independent way.
This releases the user of this module of the need to know if the information
comes from Windows, Linux, HP-UX, AIX, Solaris, Irix, or VMS, and if the
architecture is i386, x64, pa-risc2, or arm.

=head1 METHODS

=head2 System::Info->new

Factory method, with fallback to the information in C<< POSIX::uname () >>.

=cut

sub new {
    my $factory = shift;

    $^O =~ m/aix/i               and return System::Info::AIX->new;
    $^O =~ m/bsd|dragonfly/i     and return System::Info::BSD->new;
    $^O =~ m/cygwin/i            and return System::Info::Cygwin->new;
    $^O =~ m/darwin/i            and return System::Info::Darwin->new;
    $^O =~ m/haiku/              and return System::Info::Haiku->new;
    $^O =~ m/hp-?ux/i            and return System::Info::HPUX->new;
    $^O =~ m/irix/i              and return System::Info::Irix->new;
    $^O =~ m/linux/i             and return System::Info::Linux->new;
    $^O =~ m/solaris|sunos|osf/i and return System::Info::Solaris->new;
    $^O =~ m/VMS/                and return System::Info::VMS->new;
    $^O =~ m/mswin32|windows/i   and return System::Info::Windows->new;

    return System::Info::Generic->new;
    }

=head2 sysinfo

C<sysinfo> returns a string with C<host>, C<os> and C<cpu_type>.

=cut

sub sysinfo {
    my $si = System::Info->new;
    my @fields = $_[0]
	? qw( host os cpu ncpu cpu_type )
	: qw( host os cpu_type );
    return join " ", @{ $si }{ map "_$_" => @fields };
    } # sysinfo

=head2 sysinfo_hash

C<sysinfo_hash> returns a hash reference with basic system information, like:

  { cpu       => 'Intel(R) Core(TM) i7-6820HQ CPU @ 2.70GHz (GenuineIntel 2700MHz)',
    cpu_count => '1 [8 cores]',
    cpu_cores => 8,
    cpu_type  => 'x86_64',
    distro    => 'openSUSE Tumbleweed 20171030',
    hostname  => 'foobar',
    os        => 'linux - 4.13.10-1-default [openSUSE Tumbleweed 20171030]',
    osname    => 'Linux',
    osvers    => '4.13.10-1-default'
    }

=cut

sub sysinfo_hash {
    my $si = System::Info->new;
    return {
	hostname  => $si->{_host},
	cpu       => $si->{_cpu},
	cpu_type  => $si->{_cpu_type},
	cpu_count => $si->{_ncpu},
	cpu_cores => $si->{_ncore},
	os        => $si->{_os},
	osname    => $si->{__osname},
	osvers    => $si->{__osvers},
	distro    => $si->{__distro}
		  || join " " => $si->{__osname}, $si->{__osvers},
	};
    } # sysinfo

=head2 si_uname (@args)

This class gathers most of the C<uname(1)> info, make a comparable
version. Takes almost the same arguments:

    a for all (can be omitted)
    n for nodename
    s for os name and version
    m for cpu name
    c for cpu count
    p for cpu_type

=cut

sub si_uname {
    my $si = System::Info->new;
    return $si->si_uname (@_);
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2018, Abe Timmerman & H.Merijn Brand All rights reserved.

With contributions from Jarkko Hietaniemi, Campo Weijerman, Alan Burlison,
Allen Smith, Alain Barbet, Dominic Dunlop, Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
