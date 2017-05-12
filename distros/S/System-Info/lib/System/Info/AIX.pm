package System::Info::AIX;

use strict;
use warnings;

use base "System::Info::Base";

our $VERSION = "0.050";

=head1 NAME

System::Info::AIX - Object for specific AIX info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo;

    local $ENV{PATH} = "$ENV{PATH}:/usr/sbin";
    $self->prepare_os;

    my @lsdev = grep m/Available/ => `lsdev -C -c processor -S Available`;
    $self->{__cpu_count} = scalar @lsdev;

    my ($info) = grep m/^\S+/ => @lsdev;
    ($info) = $info =~ m/^(\S+)/;
    $info .= " -a 'state type'";

    my ($cpu) = grep m/\benable:[^:\s]+/ => `lsattr -E -O -l $info`;
    ($cpu) = $cpu =~ m/\benable:([^:\s]+)/;
    $cpu =~ s/\bPowerPC(?=\b|_)/PPC/i;

    (my $cpu_type = $cpu) =~ s/_.*//;
    $self->{__cpu}      = $cpu;
    $self->{__cpu_type} = $cpu_type;

    my $os = $self->_os;
    if ( $> == 0 ) {
	chomp (my $k64 = `bootinfo -K 2>/dev/null`);
	$k64 and $os       .= "/$k64";
	chomp (my $a64 = `bootinfo -y 2>/dev/null`);
	$a64 and $cpu_type .= "/$a64";
	}
    $self->{__os} = $os;
    } # prepare_sysinfo

=head2 $si->prepare_os

Use os-specific tools to find out more about the operating system.

Abbreviations used in AIX OS version include

 ML   Maintenance Level
 TL   Technology Level
 SP   Service Pack
 CSP  Conclusive/Last SP
 RD   Release Date (YYWW)

When the OS version reports as C<AIX 5.3.0.0/TL12-05>, the C<05> is
the C<SP> number. Newer versions of AIX report using C<TL>, where older
AIX releases report using C<ML>. See C<oslevel -?>.

=cut

sub prepare_os {
    my $self = shift;

    my $os = $self->_os;
    # First try the format used since 5.3ML05
    chomp ($os = `oslevel -s`);
    if ($os =~ m/^(\d+)-(\d+)-(\d+)-(\d+)$/ && $1 >= 5300) {
	# 6100-09-03-1415 = AIX 6.1.0.0 TL09 SP03 (release 2014, week 15)
	# Which will show as AIX 6.1.0.0/TL09-03
	$os = join (".", split m// => $1) . "/TL$2-$3";
	}
    else {
	chomp ($os = `oslevel -r`);
	# 5300-12 = AIX 5.3.0.0/ML12
	if ($os =~ m/^(\d+)-(\d+)$/) {
	    $os = join (".", split // => $1) . "/ML$2";
	    }
	else {
	    chomp ($os = `oslevel`);
	    # 5.3.0.0 = AIX 5.3.0.0

	    # And try figuring out at what maintainance level we are
	    my $ml = "00";
	    for (grep m/ML\b/ => `instfix -i`) {
		if (m/All filesets for (\S+) were found/) {
		    $ml = $1;
		    $ml =~ m/^\d+-(\d+)_AIX_ML/ and $ml = "ML$1";
		    next;
		    }
		$ml =~ s/\+*$/+/;
		}
	    $os .= "/$ml";
	    }
	}
    $os =~ s/^/AIX - /;
    $self->{__os} = $os;
    } # prepare_os

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2017, Abe Timmerman & H.Merijn Brand, All rights reserved.

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
