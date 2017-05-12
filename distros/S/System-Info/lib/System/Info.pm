package System::Info;

use strict;
use warnings;

our $VERSION = "0.054";

use base "Exporter";
our @EXPORT_OK = qw( &sysinfo &si_uname );

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

Sometimes one wants a more elaborate description of the system one is
working on.

=head1 METHODS

=head2 System::Info->new

Factory method, with fallback to the information in C<< POSIX::uname () >>.

=cut

sub new {
    my $factory = shift;

    $^O =~ m/aix/i               and return System::Info::AIX->new;
    $^O =~ m/bsd/i               and return System::Info::BSD->new;
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

(c) 2016-2017, Abe Timmerman & H.Merijn Brand All rights reserved.

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
