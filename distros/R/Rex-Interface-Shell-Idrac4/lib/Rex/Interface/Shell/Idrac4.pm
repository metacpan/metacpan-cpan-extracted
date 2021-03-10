#
# (c) adjust GmbH
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Interface::Shell::Idrac4;

# ABSTRACT: Rex module to support iDRAC 4.00.00.00

use strict;
use warnings;

our $VERSION = 'v0.1.0';

use Rex::Interface::Shell::Default;
use base qw(Rex::Interface::Shell::Default);

sub new {
    my $class = shift;
    my $proto = ref($class) || $class;
    my $self  = $proto->SUPER::new(@_);

    bless $self, $class;

    return $self;
}

sub detect {
    my ( $self, $con ) = @_;

    my ($output);
    eval {
        ($output) = $con->direct_exec('racadm getversion');
        1;
    } or do {
        return 0;
    };
    if ( $output && $output =~ m/iDRAC Version/ms ) {
        return 1;
    }

    return 0;
}

sub exec {
    my ( $self, $cmd, $option ) = @_;
    return $cmd;
}

1;

__END__

=pod

=head1 NAME

Rex::Interface::Shell::Idrac4 -- Rex module to support Idrac4

=head1 DESCRIPTION

Rex module to support Idrac4 shell.

=head1 LICENSE

This software is Copyright (c) 2021 by adjust GmbH.
This is free software, licensed under: The GNU Lesser General Public License, Version 3, June 2007

=head1 SUBROUTINES/METHODS

=over 4

=back

=cut

=head3 new

Initialize a Rex::Interface::Shell::Idrac4 object.

=cut

=head3 detect

Detect an Idrac4 shell.

=over 4

=back

=cut

=head3 exec

Execute a command with the Idrac4 shell.

=cut


