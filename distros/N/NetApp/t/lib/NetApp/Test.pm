#
# $Id: $
#

package NetApp::Test;

use strict;
use warnings;
use English;

select(STDERR); $| = 1;
select(STDOUT); $| = 1;

# The author has to set these ssh options to workaround the lack of a
# centrally managed known_hosts file:
#
# export NETAPP_SSH_COMMAND = \
#	ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR
#
# If your ssh environment required additional default options, specify
# them here.  Do NOT specify the identify file in these arguments.
my $ssh_command = [ split( /\s+/, $ENV{NETAPP_SSH_COMMAND} || 'ssh' ) ];

# This variable specifies the default ssh identify file to use
my $ssh_identity = $ENV{NETAPP_SSH_IDENTITY};

our @filer_args	= ();

# Specify a list of NAS filers to use for the test suite. This
# variable should a whitespace-separated list of colon-separated
# entries.  Each entry should be of the form:
#
#	$hostname:$protocol:$extra
#
# where $hostname is the hostname of the filer, $protocol is either
# 'ssh' or 'telnet', and $extra is either the ssh identity file
# (optional) or the telnet password.  If the ssh_identity file is NOT
# specified in these entries, then a default must have been specified
# above.  If the protocol is not given, then it defaults to 'ssh'.

if ( $ENV{NETAPP_TEST_FILERS} ) {

    foreach my $entry ( split /\s+/, $ENV{NETAPP_TEST_FILERS} ) {

        my ($hostname,$protocol,$extra) = split /:/, $entry, 3;

        $protocol		||= 'ssh';

        my $filer_arg	= {
            hostname	=> $hostname,
            protocol	=> $protocol,
        };

        if ( $protocol eq 'ssh' ) {
            $filer_arg->{ssh_command} = $ssh_command;
            $filer_arg->{ssh_identity} = $extra || $ssh_identity;
        } elsif ( $extra ) {
            $filer_arg->{telnet_password} = $extra;
        }

        push @filer_args, $filer_arg;

    }

}

1;
