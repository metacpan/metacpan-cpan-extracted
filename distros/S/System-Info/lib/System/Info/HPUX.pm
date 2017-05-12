package System::Info::HPUX;

use strict;
use warnings;

use base "System::Info::Base";

our $VERSION = "0.050";

=head1 NAME

System::Info::HPUX - Object for specific HP-UX info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo;

    $self->{__os} =~ s/hp-ux/HP-UX/;
    chomp (my $k64 = `/usr/bin/getconf KERNEL_BITS 2>/dev/null`);
    length $k64 and $self->{__os} .= "/$k64";

    # ioscan is always available
    $self->{__cpu_count} = grep m/^processor/ => `/usr/sbin/ioscan -knfCprocessor`;

    $self->_prepare_cpu_type;
    return $self;
    } # prepare_sysinfo

sub _prepare_cpu_type {
    my $self = shift;

    my $parisc = 0;
    # For now, unknown cpu_types are set as the Generic
    chomp (my $cv = `/usr/bin/getconf CPU_VERSION 2>/dev/null`);

    # see /usr/include/sys/unistd.h for hex values
    if ($cv < 0x20B) {
	# $self->{__cpu_type} = sprintf("Unknown CPU_VERSION 0x%x", $cv);
	}
    elsif ($cv >= 0x20C && $cv <= 0x20E) {
	$self->{__cpu_type} = "Motorola"; # You have an antique
	}
    elsif ($cv <= 0x2FF) {
	$self->{__cpu_type} = "PA-RISC";
	$self->{__cpu_type} = "PA-RISC1.0" if $cv == 0x20B;
	$self->{__cpu_type} = "PA-RISC1.1" if $cv == 0x210;
	$self->{__cpu_type} = "PA-RISC1.2" if $cv == 0x211;
	$self->{__cpu_type} = "PA-RISC2.0" if $cv == 0x214;
	$parisc++;
	}
    elsif ($cv == 0x300) {
	$self->{__cpu_type} = "ia64";
	}
    else {
	# $self->{__cpu_type} = sprintf("Unknown CPU_VERSION 0x%x", $cv);
	}
    if ($parisc) {
	my (@cpu, $lst);
	chomp (my $model = `model`);
	(my $m = $model) =~ s{.*/}{};
	foreach my $f (qw( /usr/sam/lib/mo/sched.models
			   /opt/langtools/lib/sched.models )) {
	    if (open my $fh, "<", $f) {
		@cpu = grep m/$m/i => <$fh>;
		close $fh;
		@cpu and last;
		}
	    }
	if (@cpu == 0 && open my $lst,
			      "echo 'sc product cpu;il' | /usr/sbin/cstm |") {
	    while (<$lst>) {
		s/^\s*(PA)\s*(\d+)\s+CPU Module.*/$m 1.1 $1$2/ or next;
		$2 =~ m/^8/ and s/ 1.1 / 2.0 /;
		push @cpu, $_;
		}
	    }
	if (@cpu and $cpu[0] =~ m/^\S+\s+(\d+\.\d+[a-z]?)\s+(\S+)/) {
	     my ($arch, $cpu) = ("PA-RISC$1", $2);
	     $self->{__cpu} = $cpu;
	     chomp (my $hw3264 =
		    `/usr/bin/getconf HW_32_64_CAPABLE 2>/dev/null`);
	    (my $osvers = $self->{__os}) =~ s/.*[AB]\.//;
	    $osvers =~ s{/.*}{};
	    $osvers <= 10.20 and $hw3264 = 0;
	    if ($hw3264 == 1) {
		$self->{__cpu_type} = $arch . "/64";
		}
	    elsif ($hw3264 == 0) {
		$self->{__cpu_type} = $arch . "/32";
		}
	    }
	}
    else {
	my $machinfo = `/usr/contrib/bin/machinfo`;
	if ($machinfo =~ m/processor model:\s+(\d+)\s+(.*)/) {
	    $self->{__cpu} = $2;
	    }
	elsif ($machinfo =~ m{\s*[0-9]+\s+(intel.r.*processor)\s*\(([0-9.]+)\s*([GM])Hz.*}mi) {
	    my ($m, $s, $h) = ($1, $2, $3);
	    $m =~ s{ series processor}{};
	    $h eq "G" and $s = int ($s * 1024);
	    $self->{__cpu} = "$m/$s";
	    }
	$machinfo =~ m/Clock\s+speed\s+=\s+(.*)/ and
	    $self->{__cpu} .= "/$1";
	}
    } # _prepare_cpu_type

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2017, Abe Timmerman & H.Merijn Brand, All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

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
