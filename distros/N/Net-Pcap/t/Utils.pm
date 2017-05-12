use strict;
use Socket;

$ENV{'LANG'} = $ENV{'LANGUAGE'} = $ENV{'LC_MESSAGES'} = 'C';

=pod

=head1 NAME

Utils - Utility functions for testing C<Net::Pcap>

=head1 FUNCTIONS

=over 4

=item  B<is_available()>

Returns true if the given function name is available in the version of 
the pcap library the module is being built against. 

=cut

my %available_func = ();
FUNCS: {
    open(FUNCS, 'funcs.txt') or warn "can't read 'funcs.txt': $!\n" and next;
    while(my $line = <FUNCS>) { chomp $line; $available_func{$line} = 1; }
    close(FUNCS);
}

sub is_available {
    return $available_func{$_[0]}
}


=item B<is_allowed_to_use_pcap()>

Returns true if the user running the test is allowed to use the packet 
capture library. On Unix systems, this function tries to open a raw socket. 
On Win32 systems (ActivePerl, Cygwin), it just checks whether the user 
has administrative privileges. 

=cut

sub is_allowed_to_use_pcap {
    # Win32: ActivePerl, Cygwin
    if ($^O eq 'MSWin32' or $^O eq 'cygwin') {
        my $is_admin = 0;
        eval 'no warnings; use Win32; $is_admin = Win32::IsAdminUser()';
        $is_admin = 1 if $@; # Win32::IsAdminUser() not available
        return $is_admin
    }

    # Unix systems
    else {
        if(socket(S, PF_INET, SOCK_RAW, getprotobyname('icmp'))) {
            close(S);
            return 1
        }
        else {
            return 0
        }
    }
}

=item B<find_network_device()>

Returns the name of a device suitable for listening to network traffic.

=cut

my $err;
my %devs = ();
my @devs = Net::Pcap::findalldevs(\%devs, \$err);

# filter out unusable devices
@devs = grep { $_ ne "lo" and $_ ne "lo0" and $_ !~ /GenericDialupAdapter/ } @devs;

# check if the user has specified a prefered device to use for tests
if (open(PREF, "device.txt")) {
    my $dev = <PREF>;
    chomp $dev;
    unshift @devs, $dev;
}

sub find_network_device {
    return wantarray ? @devs : $devs[0]
}

=back

=cut

1
