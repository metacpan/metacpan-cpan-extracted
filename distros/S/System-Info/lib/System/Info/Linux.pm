package System::Info::Linux;

use strict;
use warnings;

use base "System::Info::Base";

our $VERSION = "0.052";

=head1 NAME

System::Info::Linux - Object for specific Linux info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo;
    $self->prepare_os;
    $self->prepare_proc_cpuinfo or return;

    for ($self->get_cpu_type) {
	m/arm/     and do { $self->linux_arm;   last };
	m/aarch64/ and do { $self->linux_arm;   last };
	m/ppc/     and do { $self->linux_ppc;   last };
	m/sparc/   and do { $self->linux_sparc; last };
	m/s390x/   and do { $self->linux_s390x; last };
	# default
	$self->linux_generic;
	}
    return $self;
    } # prepare_sysinfo

=head2 $si->prepare_os

Use os-specific tools to find out more about the operating system.

=cut

sub _file_info {
    my ($file, $os) = @_;
    open my $fh, "<", $file or return;
    while (<$fh>) {
	m/^\s*[;#]/ and next;
	chomp;
	m/\S/ or next;
	s/^\s+//;
	s/\s+$//;
	if (my ($k, $v) = (m/^(.*\S)\s*=\s*(\S.*)$/)) {
	    # Having a value prevails over being defined
	    defined $os->{$k} and next;
	    $v =~ s/^"\s*(.*?)\s*"$/$1/;
	    $v =~ m{^["(]?undef(?:ined)?[")]$}i and $v = "undefined";
	    $os->{$k} = $v;
	    next;
	    }
	m/^[12][0-9]{3}(?:,\s*[12][0-9]{3})*$/ and next; # Copyright years
	exists $os->{$_} or $os->{$_} = undef;
	}
    close $fh;
    } # _file_info

sub _lsb_release {
    my $os = shift;

    $ENV{SMOKE_USE_ETC} and return;

    $os->{DISTRIB_ID} || $os->{DISTRIB_RELEASE} || $os->{DISTRIB_CODENAME}
	or return;

    #use DP;die DDumper $os;
    open my $ch, "lsb_release -a 2>&1 |" or return;
    my %map = (
	"LSB Version"		=> "don't care",
	"Distributor ID"	=> "DISTRIB_ID",
	"Description"		=> "DISTRIB_DESCRIPTION",
	"Release"		=> "DISTRIB_RELEASE",
	"Code"			=> "DISTRIB_CODENAME",
	);
    while (<$ch>) {
	chomp;
	m/^\s*(\S.*?)\s*:\s*(.*?)\s*$/ or next;
	$os->{$map{$1} || $1} ||= $2 unless $2 eq "n/a";
	}
    } # _lsb_release

sub prepare_os {
    my $self = shift;

    my $etc = $ENV{SMOKE_USE_ETC} || "/etc";
    my @dist_file = grep { -f $_ && -s _ } map {
	-d $_ ? glob ("$_/*") : ($_)
	} glob ("$etc/*[-_][rRvV][eE][lLrR]*"), "$etc/issue",
		"$etc.defaults/VERSION", "$etc/VERSION", "$etc/release";

    my $os = $self->_os;
    my %os;
    my $distro;
    foreach my $df (@dist_file) {
	# use "debian" out of /etc/debian-release
	unless (defined $distro or $df =~ m/\blsb-/) {
	    ($distro = $df) =~ s{^$etc(?:\.defaults)?/}{}i;
	    $distro =~ s{[-_]?(?:release|version)\b}{}i;
	    }
	_file_info ($df, \%os);
	}
    _lsb_release (\%os);

    keys %os or return;

    foreach my $key (keys %os) {
	my $KEY = uc $key;
	defined $os{$key} or next;
	exists $os{$KEY} or $os{$KEY} = $os{$key};
	}

    if ($os{DISTRIB_DESCRIPTION}) {
	$distro = $os{DISTRIB_DESCRIPTION};
	$os{DISTRIB_CODENAME} && $distro !~ m{\b$os{DISTRIB_CODENAME}\b}i and
	    $distro .= " ($os{DISTRIB_CODENAME})";
	if ($os{VERSION_ID} && $distro !~ m{\b$os{VERSION_ID}\b}i) {
	    $distro .= " $os{VERSION_ID}";
	    }
	elsif ($os{DISTRIB_RELEASE} && $distro !~ m{\b$os{DISTRIB_RELEASE}\b}i) {
	    $distro .= " $os{DISTRIB_RELEASE}";
	    }
	}
    elsif ($os{PRETTY_NAME}) {
	$distro = $os{PRETTY_NAME};          # "openSUSE 12.1 (Asparagus) (x86_64)"
	if (my $vid = $os{VERSION_ID}) {     # wheezy 7 => 7.2
	    my @rv;
	    if (@rv = grep m{^$vid\.} => sort keys %os) {
		# from /etc/debian_version
		$rv[0] =~ m/^[0-9]+\.\w+$/ and
		    $distro =~ s/\b$vid\b/$rv[0]/;
		}
	    if (!@rv && defined $os{NAME} and # CentOS Linux 7 = CentOS Linux 7.1.1503
		 @rv = grep m{^$os{NAME} (?:(?:release|version)\s+)?$vid\.} => sort keys %os) {
		if ($rv[0] =~ m/\s($vid\.[-.\w]+)/) {
		    my $vr = $1;
		    $distro =~ s/\s$vid\b/ $vr/;
		    }
		}
	    }
	$distro =~ s{\s*[-:/,]\s*Version\s*:?\s*}{ };
	$distro =~ s/\)\s+\(\w+\)\s*$/)/;    # remove architectural part
	$distro =~ s/\s+\(?(?:i\d86|x86_64)\)?\s*$//; # i386 i486 i586 x86_64
	}
    elsif ($os{VERSION} && $os{NAME}) {
	$distro = qq{$os{NAME} $os{VERSION}};
	}
    elsif ($os{VERSION} && $os{CODENAME}) {
	if (my @welcome = grep s{^\s*Welcome\s+to\s+(\S*$distro\S*)\b.*}{$1}i => keys %os) {
	    $distro = $welcome[0];
	    }
	$distro .= qq{ $os{VERSION}};
	$distro =~ m/\b$os{CODENAME}\b/ or
	    $distro .= qq{ ($os{CODENAME})};
	}
    elsif ($os{MAJORVERSION} && defined $os{MINORVERSION}) {
	-d "/usr/syno" || "@dist_file" =~ m{^\S*/VERSION$} and $distro .= "DSM";
	$distro .= qq{ $os{MAJORVERSION}.$os{MINORVERSION}};
	$os{BUILDNUMBER}    and $distro .= qq{-$os{BUILDNUMBER}};
	$os{SMALLFIXNUMBER} and $distro .= qq{-$os{SMALLFIXNUMBER}};
	}
    elsif ($os{DISTRIBVER} && exists $os{NETBSDSRCDIR}) {
	(my $dv = $os{DISTRIBVER}) =~ tr{ ''"";}{}d;
	$distro .= qq{ NetBSD $dv};
	}
    else {
	# /etc/issue:
	#  Welcome to SUSE LINUX 10.0 (i586) - Kernel \r (\l).
	#  Welcome to openSUSE 10.2 (i586) - Kernel \r (\l).
	#  Welcome to openSUSE 10.2 (X86-64) - Kernel \r (\l).
	#  Welcome to openSUSE 10.3 (i586) - Kernel \r (\l).
	#  Welcome to openSUSE 10.3 (X86-64) - Kernel \r (\l).
	#  Welcome to openSUSE 11.1 - Kernel \r (\l).
	#  Welcome to openSUSE 11.2 "Emerald" - Kernel \r (\l).
	#  Welcome to openSUSE 11.3 "Teal" - Kernel \r (\l).
	#  Welcome to openSUSE 11.4 "Celadon" - Kernel \r (\l).
	#  Welcome to openSUSE 12.1 "Asparagus" - Kernel \r (\l).
	#  Welcome to openSUSE 12.2 "Mantis" - Kernel \r (\l).
	#  Welcome to openSUSE 12.3 "Dartmouth" - Kernel \r (\l).
	#  Welcome to openSUSE 13.1 "Bottle" - Kernel \r (\l).
	#  Welcome to openSUSE 13.2 "Harlequin" - Kernel \r (\l).
	#  Welcome to openSUSE Leap 42.1 - Kernel \r (\l).
	#  Welcome to openSUSE 20151218 "Tumbleweed" - Kernel \r (\l).
	#  Welcome to SUSE Linux Enterprise Server 11 SP1 for VMware  (x86_64) - Kernel \r (\l).
	#  Ubuntu 10.04.4 LTS \n \l
	#  Debian GNU/Linux wheezy/sid \n \l
	#  Debian GNU/Linux 6.0 \n \l
	#  CentOS release 6.4 (Final)
	# /etc/redhat-release:
	#  CentOS release 5.7 (Final)
	#  CentOS release 6.4 (Final)
	#  Red Hat Enterprise Linux ES release 4 (Nahant Update 2)
	# /etc/debian_version:
	#  6.0.4
	#  wheezy/sid
	#  squeeze/sid

	my @key = sort keys %os;
	s/\s*\\[rln].*// for @key;

	my @vsn = grep m/^[0-9.]+$/ => @key;
	#$self->{__X__} = { os => \%os, key => \@key, vsn => \@vsn };

	if (my @welcome = grep s{^\s*Welcome\s+to\s+}{}i => @key) {
	    ($distro = $welcome[0]) =~ s/"([^"]+)"/($1)/;
	    }
	elsif (my @rel  = grep m{\brelease\b}i => @key) {
	    @rel > 1 && $rel[0] =~ m/^Enterprise Linux Enterprise/
		     && $rel[1] =~ m/^Oracle Linux/ and shift @rel;
	    $distro = $rel[0];
	    $distro =~ s/ *release//;
	    $distro =~ s/Red Hat Enterprise Linux/RHEL/; # Too long for subject
	    # RHEL ES 4 (Nahant Update 2) => RHEL Server 4.2 (Nahant)
	    $distro =~ s/^RHEL ES (\d+)\s+(.*)\s+Update\s+(\d+)/RHEL Server $1.$3 $2/;
	    }
	elsif ( my @lnx  = grep m{\bLinux\b}i => @key ) {
	    $distro = $lnx[0];
	    }
	elsif ( $distro && @vsn ) {
	    $distro .= "-$vsn[0]";
	    }
	else {
	    $distro = $key[0];
	    }
	$distro =~ s/\s+-\s+Kernel.*//i;
	}
    if ($distro =~ s/^\s*(.*\S)\s*$/$1/) {
	$self->{__distro} = $distro;
	$os .= " [$distro]";
	}
    $self->{__os} = $os;
    } # prepare_os

=head2 $si->linux_generic

Check C</proc/cpuinfo> for these keys:

=over

=item "processor"  (count occurrence for __cpu_count)

=item "model name" (part of __cpu)

=item "vendor_id"  (part of __cpu)

=item "cpu mhz"    (part of __cpu)

=item "cpu cores"  (add values to add to __cpu_count)

=back

=cut

sub linux_generic {
    my $self = shift;

    my $n_phys_id   = $self->count_unique_in_cpuinfo (qr/^physical id\s+:/) || 0;
    my $n_core_id   = $self->count_unique_in_cpuinfo (qr/^core id\s+:/)     || 0;
    my $n_processor = $self->count_unique_in_cpuinfo (qr/^processor\s+:/)   || 0;
    my $n_cpu       = $n_phys_id || $n_core_id || $n_processor;

    # ::diag"Np: $n_phys_id, NC: $n_core_id, NP: $n_processor, NC: $n_cpu";
    $self->{__cpu_count} = $n_cpu;

    my @parts = ("model name", "vendor_id", "cpu mhz");
    my %info = map { ($_ => $self->from_cpuinfo ($_)) } @parts;
    $self->{__cpu} = sprintf "%s (%s %.0fMHz)", map { $info{$_} } @parts;

    if ($n_phys_id) {
	$n_processor > $n_phys_id and
	    $self->{__cpu_count} .= " [$n_processor cores]";
	return;
	}
    if ($n_core_id) {
	$n_processor > $n_core_id and
	    $self->{__cpu_count} .= " [$n_processor cores]";
	return;
	}

    my $n_cores = 0;
    my $core_id = 0;
    my %cores;
    for my $cores (grep m/(cpu cores|core id)\s*:\s*\d+/ => $self->_proc_cpuinfo) {
	my ($tag, $count) = $cores =~ m/^(.*\S)\s*:\s*(\d+)/ or next;
	if ($tag eq "core id") {
	    $core_id = $count;
	    }
	else {
	    $cores{$core_id} = $count;
	    }
	}
    $n_cores += $cores{$_} for keys %cores;

    $n_cores > $n_cpu and $self->{__cpu_count} .= " [$n_cores cores]";
    } # _linux_generic

=head2 $si->linux_arm

Check C</proc/cpuinfo> for these keys:

=over

=item "processor"  (count occurrence for __cpu_count)

=item "Processor" (part of __cpu)

=item "BogoMIPS"  (part of __cpu)

=back

=cut

sub linux_arm {
    my $self = shift;

    $self->{__cpu_count} = $self->count_in_cpuinfo (qr/^processor\s+:\s+/i);

    my $cpu  = $self->from_cpuinfo ("Processor") ||
	       $self->from_cpuinfo ("Model[_ ]name");
    my $bogo = $self->from_cpuinfo ("BogoMIPS");
    my $mhz  = 100 * int (($bogo + 50) / 100);
    $cpu =~ s/\s+/ /g;
    $mhz and $cpu .= " ($mhz MHz)";
    $self->{__cpu} = $cpu;
    } # _linux_arm

=head2 $si->linux_ppc

Check C</proc/cpuinfo> for these keys:

=over

=item "processor"  (count occurrence for __cpu_count)

=item "cpu"     (part of __cpu)

=item "machine" (part of __cpu)

=item "clock"   (part of __cpu)

=item "detected" (alters machine if present)

=back

=cut

sub linux_ppc {
    my $self = shift;

    $self->{__cpu_count} = $self->count_in_cpuinfo (qr/^processor\s+:\s+/);

    my @parts = qw( cpu machine clock );
    my %info = map { ($_ => $self->from_cpuinfo ($_)) } @parts;
    if ($info{detected} = $self->from_cpuinfo ("detected as")){
	$info{detected} =~ s/.*(\b.+Mac G\d).*/$1/;
	$info{machine} = $info{detected};
	}

    $self->{__cpu} = sprintf "%s %s (%s)", map { $info{$_} } @parts;
    } # linux_ppc

=head2 $si->linux_sparc

Check C</proc/cpuinfo> for these keys:

=over

=item "processor"  (count occurrence for __cpu_count)

=item "cpu"        (part of __cpu)

=item "Cpu0ClkTck" (part of __cpu)

=back

=cut

sub linux_sparc {
    my $self = shift;

    $self->{__cpu_count} = $self->from_cpuinfo ("ncpus active");

    my @parts = qw( cpu Cpu0ClkTck );
    my %info  = map { ($_ => $self->from_cpuinfo ($_)) } @parts;
    my $cpu   = $info{cpu};
    $info{Cpu0ClkTck} and
	$cpu .=  sprintf " (%.0fMHz)", hex ($info{Cpu0ClkTck}) / 1_000_000;
    $self->{__cpu} = $cpu;
    } # linux_sparc

=head2 $si->linux_s390x

Check C</proc/cpuinfo> for these keys:

=over

=item "processor"  (count occurrence for __cpu_count)

=item "Processor" (part of __cpu)

=item "BogoMIPS"  (part of __cpu)

=back

=cut

sub linux_s390x {
    my $self = shift;

    $self->{__cpu_count} = $self->count_in_cpuinfo (qr/^processor\s+\d+:\s+/i);

    my $cpu  = $self->from_cpuinfo ("vendor_id") ||
	       $self->from_cpuinfo ("Processor") ||
	       $self->from_cpuinfo ("Model[_ ]name");
    my $bogo = $self->from_cpuinfo (qr{BogoMIPS(?:\s*per[ _]CPU)?}i);
    my $mhz  = 100 * int (($bogo + 50) / 100);
    $cpu =~ s/\s+/ /g;
    $mhz and $cpu .= " ($mhz MHz)";
    $self->{__cpu} = $cpu;
    } # _linux_s390x

=head2 $si->prepare_proc_cpuinfo

Read the complete C<< /proc/cpuinfo >>.

=cut

sub prepare_proc_cpuinfo {
    my $self = shift;

    if (open my $pci, "<", "/proc/cpuinfo") {
	chomp (my @pci = <$pci>);
	s/[\s\xa0]+/ /g for @pci;
	s/ $//          for @pci;
	$self->{__proc_cpuinfo} = \@pci;
	close $pci;
	return 1;
	}
    } # prepare_proc_cpuinfo

=head2 $si->count_in_cpuinfo ($regex)

Returns the number of lines $regex matches for.

=cut

sub count_in_cpuinfo {
    my ($self, $regex) = @_;

    return scalar grep /$regex/, $self->_proc_cpuinfo;
    } # count_in_cpuinfo

=head2 $si->count_unique_in_cpuinfo ($regex)

Returns the number of lines $regex matches for.

=cut

sub count_unique_in_cpuinfo {
    my ($self, $regex) = @_;

    my %match = map { $_ => 1 } grep /$regex/ => $self->_proc_cpuinfo;
    return scalar keys %match;
    } # count_unique_in_cpuinfo

=head2 $si->from_cpuinfo ($key)

Returns the first value of that key in C<< /proc/cpuinfo >>.

=cut

sub from_cpuinfo {
    my ($self, $key) = @_;

    my ($first) = grep m/^\s*$key\s*[:=]\s*/i => $self->_proc_cpuinfo;
    defined $first or $first = "";
    $first =~ s/^\s*$key\s*[:=]\s*//i;
    return $first;
    } # from_cpuinfo

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
