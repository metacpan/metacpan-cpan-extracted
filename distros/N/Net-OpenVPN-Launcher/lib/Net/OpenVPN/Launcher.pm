package Net::OpenVPN::Launcher;
use strict;
use warnings;
use Moo;
use Method::Signatures;
use IPC::Cmd qw(can_run);
use Carp qw/croak/;
use sigtrap qw(die normal-signals);

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 NAME

Net::OpenVPN::Launcher - start, stop and restart OpenVPN as a sub-process.

=head1 SYNOPSIS

    use Net::OpenVPN::Launcher;

    my $pm = Net::OpenVPN::Launcher->new;

    $pm->start($filepath_to_config_file);

    # do some stuff

    # now stop the first instance of OpenVPN and start another
    $pm->start($filepath_to_alt_config_file);

    # do some stuff

    $pm->stop;

=head1 DESCRIPTION

L<Net::OpenVPN::Launcher> is an object oriented module that provides methods to start, stop and restart OpenVPN. It's useful because it runs OpenVPN processes as a non-blocking sub-process. This allows you to start and stop several OpenVPN processes within the same Perl program. 


=head1 SYSTEM REQUIREMENTS

=over

=item *

OpenVPN needs to be installed and in $PATH (or in bin, in $PATH). 

=item *

This module has been tested on OpenVPN version 2.2.1 - it should work with most versions of OpenVPN.

=item *

Currently only works with Linux-like operating systems.

=item *

By default OpenVPN needs to be run with root privileges, hence any Perl program using this module will need to be run as root unless OpenVPN has been configured to run under user privileges.

=back

=head1 METHODS

=head2 start

Initialises OpenVPN with a config file. Requires a filepath to an OpenVPN config file. See the OpenVPN L<documentation|http://openvpn.net/index.php/open-source/documentation/manuals/427-openvpn-22.html> for example config files and options.

    $pm->start('openvpn.conf');

=cut

method start ($config_filepath) {
    # check that config filepath exists
    open( my $config, '<', $config_filepath );
    croak "config filepath $config_filepath not readable"
      unless -e $config_filepath;

    $self->config($config_filepath);

    # check openvpn is installed
    my $openvpn_path = can_run('openvpn');
    croak "openvpn binary not found" unless $openvpn_path; 

    # stop existing process
    $self->stop if $self->openvpn_pid;

    # run openvpn in child process
    my $pid = fork(); 
    unless ($pid) {    
        exec "$openvpn_path $config_filepath";
    }
    $self->openvpn_pid($pid);
    return 1;
}

=head2 restart

Restarts the existing OpenVPN process with the same configuration file as before.

    $pm->restart;

=cut

method restart {
    unless ($self->config && $self->openvpn_pid) {
        croak "Error: no running OpenVPN process found";
    }
    $self->start($self->config);
    return 1;
}

=head2 stop

Kills the OpenVPN process.

    $pm->stop;

=cut

method stop {
    if ( $self->openvpn_pid ) {
        # check if UID has permission to kill the openvpn process
        kill 0, $self->openvpn_pid
          ? kill 9, $self->openvpn_pid
          : croak 'Error: unable to kill the openvpn PID: '
          . $self->openvpn_pid;
    }
    else {
        croak 'Error: no PID found for openvpn process';
    }
    sleep(1);
    return 1;
}

=head1 INTERNAL METHODS

=head2 DEMOLISH

This method is called on object destruction and it will call the stop method if any active openvpn processes are found. This means it is not necessary to call the stop method when exiting the program.

=cut

sub DEMOLISH {
    my $self = shift;
    $self->stop if $self->openvpn_pid;
}

=head2 config

This is a getter/setter method for the filepath to the OpenVPN configuration file.

=cut

has config => ( is  => 'rw' );

=head2 openvpn_pid

This is a getter/setter method for the PID of the openvpn process.

=cut

has openvpn_pid => (
    is  => 'rw',
    isa => sub {
        die "$_[0] is not a number" unless $_[0] =~ /[0-9]+/;
    },
);

1;

=head1 AUTHOR

David Farrell, C<< <davidnmfarrell at gmail.com> >>, L<perltricks.com|http://perltricks.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-openvpn-proxymanager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OpenVPN-Launcher>.  I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OpenVPN::Launcher


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OpenVPN-Launcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OpenVPN-Launcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OpenVPN-Launcher>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OpenVPN-Launcher/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

