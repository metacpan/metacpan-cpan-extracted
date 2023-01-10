package System::Info;

use strict;
use warnings;

our $VERSION = "0.063";

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

=head1 SEE ALSO

There are more modules that provide system and/or architectural information.

Where System::Info aims at returning the information that is useful for
bug reports, some other modules focus on a single aspect (possibly with
way more variables and methods than System::Info does supports), or are
limited to use on a specific architecture, like Windows or Linux.

Here are some of the alternatives and how to replace that code with what
System::Info offers. Not all returned values will be exactly the same.

=head2 Sys::Hostname

 use Sys::Hostname;
 say "Hostname: ", hostname;

 ->

 use System::Info;
 my $si = System::Info->new;
 say "Hostname: ", $si->host;

Sys::Hostname is a CORE module, and will always be available.

=head2 Unix::Processors

 use Unix::Processors;
 my $up = Unix::Processors->new;
 say "CPU type : ", $up->processors->[0]->type; # Intel(R) Core(TM) i7-6820HQ CPU @ 2.70GHz
 say "CPU count: ", $up->max_physical;          # 4
 say "CPU cores: ", $up->max_online;            # 8
 say "CPU speed: ", $up->max_clock;             # 2700

 ->

 use System::Info;
 my $si = System::Info->new;
 say "CPU type : ", $si->cpu;
 say "CPU count: ", $si->ncpu;
 say "CPU cores: ", $si->ncore;
 say "CPU speed: ", $si->cpu =~ s{^.*\b([0-9.]+)\s*[A-Z]Hz.*}{$1}r;

The number reported by max_physical is inaccurate for modern CPU's

=head2 Sys::Info

Sys::Info has a somewhat rigid configuration, which causes it to fail
installation on e.g. (modern versions of) CentOS and openSUSE Tumbleweed.

It aims at returning a complete set of information, but as I cannot
install it on openSUSE Tumbleweed, I cannot test it and show the analogies.

=head2 Sys::CPU

 use Sys::CPU;
 say "CPU type : ", Sys::CPU::cpu_type;  # Intel(R) Core(TM) i7-6820HQ CPU @ 2.70GHz
 say "CPU count: ", Sys::CPU::cpu_count; # 8
 say "CPU speed: ", Sys::CPU::cpu_clock; # 2700

 ->

 use System::Info;
 my $si = System::Info->new;
 say "CPU type : ", $si->get_cpu;         # or ->cpu
 say "CPU count: ", $si->get_core_count;  # or ->ncore
 say "CPU speed: ", $si->get_cpu =~ s{^.*\b([0-9.]+)\s*[A-Z]Hz.*}{$1}r;

The speed reported by Sys::CPU is the I<current> speed, and it will change
from call to call. YMMV.

Sys::CPU is not available on CPAN anymore, but you can still get is from
BackPAN.

=head2 Devel::Platform::Info

L<Devel::Platform::Info> derives information from the files C</etc/issue>,
C</etc/.issue> and the output of the commands C<uname -a> (and C<-m>, C<-o>,
C<-r>, and C<-s>) and C<lsb_release -a>. It returns no information on CPU
type, CPU speed, or Memory.

 use Devel::Platform::Info;
 my $info = Devel::Platform::Info->new->get_info ();
 # { archname => 'x86_64',
 #   codename => 'n/a',
 #   is32bit  => 0,
 #   is64bit  => 1,
 #   kernel   => 'linux-5.17.4-1-default',
 #   kname    => 'Linux',
 #   kvers    => '5.17.4-1-default',
 #   osflag   => 'linux',
 #   oslabel  => 'openSUSE',
 #   osname   => 'GNU/Linux',
 #   osvers   => '20220426',
 #   }

 ->

 use System::Info;
 my $si = System::Info->new;
 my $info = {
    archname => $si->cpu_type,       # x86_64
    codename => undef,
    is32bit  => undef,
    is64bit  => undef,
    kernel   => "$^O-".$si->_osvers, # linux-5.17.4-1-default
    kname    => $si->_osname,        # Linux
    kvers    => $si->_osvers,        # 5.17.4-1-default
    osflag   => $^O,                 # linux
    oslabel  => $si->distro,         # openSUSE Tumbleweed 20220426
    osname   => undef,
    osvers   => $si->distro,         # openSUSE Tumbleweed 20220426
    };

=head2 Devel::CheckOS

This one does not return the OS information as such, but features an
alternative to C<$^O>.

=head2 Sys::OsRelease

Interface to FreeDesktop.Org's os-release standard.

 use Sys::OsRealease;
 Sys::OsRelease->init;
 my $i = Sys::OsRelease->instance;
 say $i->ansi_color;                 # 0;32
 say $i->bug_report_url;             # https://bugs.opensuse.org
 say $i->cpe_name;                   # cpe:/o:opensuse:tumbleweed:20220426
 say $i->documentation_url;          # https://en.opensuse.org/Portal:Tumbleweed
 say $i->home_url;                   # https://www.opensuse.org/
 say $i->id;                         # opensuse-tumbleweed
 say $i->id_like;                    # opensuse suse
 say $i->logo;                       # distributor-logo-Tumbleweed
 say $i->name;                       # openSUSE Tumbleweed
 say $i->pretty_name;                # openSUSE Tumbleweed
 say $i->version_id;                 # 20220426

=head1 COPYRIGHT AND LICENSE

(c) 2016-2023, Abe Timmerman & H.Merijn Brand, All rights reserved.

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
