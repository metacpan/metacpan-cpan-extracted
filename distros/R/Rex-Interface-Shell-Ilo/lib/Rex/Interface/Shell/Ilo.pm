#
# (c) adjust GmbH
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Interface::Shell::Ilo;

# ABSTRACT: Rex module to support iLO

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
        ($output) = $con->direct_exec('version');
        1;
    } or do {
        return 0;
    };
    if ( $output && $output =~ m/SM-CLP Version/msx ) {
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

Rex::Interface::Shell::Ilo -- Rex module to support iLO

=head1 DESCRIPTION

Rex module to support iLO via the SMASH CLP shell.

=head1 LICENSE

This software is Copyright (c) 2021 by adjust GmbH.
This is free software, licensed under: The GNU Lesser General Public License, Version 3, June 2007

=head1 SUBROUTINES/METHODS

=over 4

=back

=cut

=head3 new

Initialize a Rex::Interface::Shell::Ilo object.

=cut

=head3 detect

Detect a Ilo (SMASH CLP) shell

=over 4

=back

=cut

=head3 exec

Execute a command with the SMASH CLP shell.

=cut


