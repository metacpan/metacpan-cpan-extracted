package Net::Hacky::Detect::IP;

# Base modules
use 5.006;
use strict;
use warnings;

use File::Temp qw( tempfile );
use IO::Socket::IP;
use Try::Tiny;
use Capture::Tiny ':all';

=head1 NAME

Net::Hacky::Detect::IP - Hackily try different methods of attaining local system IPs

=head1 VERSION

Version 0.023

=cut

our $VERSION = '0.023';

my $tools = {
    unix => {
        tools => [[qw(netstat -an4)],[qw(netstat -an6)],[qw(ip addr show)],[qw(ifconfig)],[qw(sockstat -4)],[qw(sockstat -6)]],
        paths => [qw(/bin/ /sbin/ /usr/sbin/ /usr/bin/)]
    },
    windows => {
        tools => [[qw(netstat -an)],[qw(ipconfig)],[qw(cscript)]],
        paths => [""]
    }
};

my $cscript = <<'EOF';

On Error Resume Next
strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration")

For Each objItem In colItems
    For Each objValue In objItem.IPAddress
        If objValue <> "" Then
        WScript.Echo objValue
        End If
    Next
Next

EOF

=head1 SYNOPSIS

    use Net::Hacky::Detect::IP;
    my $ip = Net::Hacky::Detect::IP->new();

    my @ips = @{ $ip->scan() };

    foreach my $host (@ips) {
        print "Detected ip: $host\n";
        if ($ip->checkIP($host)) {
            print "IP is deffinetly usable! (Was tested twice as scan() auto checks)\n";
        }
    }

=head1 DESCRIPTION 

Hackily concatenate output from multiple system commands then attempt to find valid ips from it, once found they are 
tested for connectability then returned. This is not pretty nor very clever but extracting system ips is a nightmare
however you go about it and this method appears to be the more reliable.

=head1 METHODS

=head2 new

Create a new object for interacting with Net-Hacky-Detect-IP

=cut 

sub new {
    my ($class) = @_;

    # Some private stuff for ourself
    my $self = {
    };

    # Go with god my son
    bless $self, $class;
    return $self;
}


=head2 scan

Attempt to find local system ips, 1 optional argument, of '4' or '6' designating wether
to look for ipv4 or ipv6 addresses, if left blank search for both.

Returns a list of local ips for the system, will return a blank [] list if nothing found.

=cut

sub scan {
    my $self = shift;
    my $type = shift;
    
    if (!$type || $type !~ m#^4|6$#) {
        $type = 0;
    }

    my $return = [];
    my $os = 'unix';
    
    if ($^O =~ m#win#i) { $os = 'windows' } 

    # Some short cuts and initial scalars for storing things in
    my $dumps = "";
    my $short = $tools->{$os};

    # Go searching for something we can use
    foreach my $tool ( @{ $short->{tools} } ) {
        my ($cmd,@args) = @{$tool};
        foreach my $path ( @{ $short->{paths} } ) {
            # Full path to the binary
            my $fullpath = "$path$cmd";
            
            # If the arguments have 4 or 6 in them, there ipv4 or ipv6, we may not need one of them..
            if ($args[0] && $type != 0) {
                my ($flags) = $args[0] =~ m#(4|6)#;
                if ($flags && $type !~ m#\Q$flags#) { 
                    next;
                }
            }

            # Storage space for the execution returns
            my ($merged, @result);

            # If this is a call for cscript, we need to act differently..
            if ($cmd eq 'cscript') {
                # Generate a path to a writable space
                my $winScript = File::Temp::tempdir() . '\\' . 'findip.vbs';
                
                # Write our vbs to that location
                open(my $fh,'>',$winScript);
                print $fh $cscript;
                close($fh);

                # Push the filepath into the arguments
                push @args,$winScript;
            }
            
            # If we are on unix we do not need to execute everything we can check the path exists.
            next if ( $os eq 'unix' && !-e $fullpath );
            
            # Execute and collect;
            try {
                ($merged, @result) = capture_merged{ system($fullpath,@args) };
            };

            # Execute and store output within the script
            $dumps .= $merged ;
        }
    }

    # Check we found anything at all
    if (length($dumps) < 10) { return [] }
    
    # Ok we did find something ...first extract remove all \n
    ($dumps) =~ s#\n# #g;
    
    # Then convert into an array split into words
    my @possibleIP = split(/\s+/,$dumps);
    
    # Make sure we only look at unique ips
    my $unique;
    
    # Validate all the ips, for speed we will do a silly check first
    foreach my $testIP (@possibleIP) {
        if ( ($type == 4 || $type == 0) && $testIP =~ m#(\d+\.\d+\.\d+\.\d+)#) {
            # Copy $1 to $IP because it looks prettier
            my $IP = $1;
            
            # Check we have not already dealt with this ip and its valid
            next if ($unique->{$IP});
            $unique->{$IP} = 1;
            if (!$self->_checkIP4($IP)) { next }

            # Push the valid ip into the return space
            push @$return,$IP;
        }
        elsif ( ($type == 6 || $type == 0) && $testIP =~ m#:# && $testIP =~ m#[0-9]# && $testIP =~ m#^([a-f0-9:]+)$#) {
            # Copy $1 to $IP because it looks prettier
            my $IP = $1;

            # Check we have not already dealt with this ip and its valid
            next if ($unique->{$IP});
            $unique->{$IP} = 1;
            if (!$self->_checkIP6($IP)) { next }

            # Push the valid ip into the return space
            push @$return,$IP;
        }
    }
    return $return;
}

=head2 checkIP 

Check an IP is valid and usable, takes 1 mandatory argument;

Argument 1 Should be an ip address (not hostname)

Returns 1 on success 'valid' and 0 on failure 'invalid'

=cut

sub checkIP {
    my ($self,$host) = @_;

    if ($host =~ m#\.#) { 
        return $self->_checkIP4($host);
    } 
    elsif ($host =~ m#:#) {
        return $self->_checkIP6($host);
    }
    else { 
        warn "$host does not look like an IPv6 nor IPv4, ignored.";
    }
}

sub _checkIP4 {
    my ($self,$host) = @_;
    
    # A few safety checks
    if (!$host) {
        warn "Incorrect number of arguments, returning fail";
        return 0;
    }

    # By default fail the bind
    my $bindsuccess = 0;
    
    # Split the ip into relevent blocks
    my @ip = split(/\./,$host);

    # Do a more precise check (This should rule out all netmasks and broadcasts)
    return 0 if ($ip[0] <= 0 || $ip[0] >= 255);
    return 0 if ($ip[1] < 0 || $ip[1] > 255);
    return 0 if ($ip[2] < 0 || $ip[2] > 255);
    return 0 if ($ip[3] <= 0 || $ip[3] >= 255);
    
    # Bind port 0 'Select the first one availible'
    my $port = 0;
    my $sock = IO::Socket::IP->new(
        Domain      =>  PF_INET,
        LocalAddr   =>  $host,
        LocalPort   =>  $port,
        Proto       =>  'tcp',
        ReuseAddr   =>  1
    );
    if ($sock) {
        $bindsuccess=1;
    }

    return $bindsuccess;
}

sub _checkIP6 {
    my ($self,$host) = @_;
    
    # A few safety checks
    if (!$host) {
        warn "Incorrect number of arguments, returning fail";
        return 0;
    }
    
    # By default fail the bind
    my $bindsuccess = 0;

   # Bind port 0 'Select the first one availible'
    my $port = 0;
    my $sock = IO::Socket::IP->new(
        Domain      =>  PF_INET6,
        LocalAddr   =>  $host,
        LocalPort   =>  $port,
        Proto       =>  'tcp',
        ReuseAddr   =>  1
    );
    if ($sock) {
        $bindsuccess=1;
    }

    return $bindsuccess;
}


=head1 AUTHOR

Paul G Webster, C<< <daemon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the authors code repository at C<https://gitlab.com/paul-g-webster/PL-Net-Hacky-Detect-IP>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Hacky::Detect::IP


You can also look for information at:

=over 4

=item * GitLab: The authors gitlab page for this project

L<https://gitlab.com/paul-g-webster/PL-Net-Hacky-Detect-IP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Hacky-Detect-IP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Hacky-Detect-IP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Hacky-Detect-IP/>

=back


=head1 ACKNOWLEDGEMENTS

Thank you for all the continued help from irc.freenode.net #perl and irc.perl.org #perl

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Paul G Webster.

This program is distributed under the (Simplified) BSD License:
L<http://www.opensource.org/licenses/BSD-2-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::Hacky::Detect::IP
