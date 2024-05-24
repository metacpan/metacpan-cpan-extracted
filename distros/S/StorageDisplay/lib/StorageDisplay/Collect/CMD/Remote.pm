#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use 5.14.0;

# Implementation note: unused module for now

package StorageDisplay::Collect::CMD::Remote;
# ABSTRACT: Collect data on remote machine with SSH
our $VERSION = '2.06'; # VERSION


use StorageDisplay::Collect;
use Net::OpenSSH;
use Term::ReadKey;
END {
    ReadMode('normal');
}
use Moose;
use MooseX::NonMoose;
extends 'StorageDisplay::Collect::CMD';

has 'ssh' => (
    is    => 'ro',
    isa   => 'Net::OpenSSH',
    required => 1,
    );


sub open_cmd_pipe {
    my $self = shift;
    my $ssh = $self->ssh;
    my @cmd = @_;
    print STDERR "[SSH]Running: ", join(' ', @cmd), "\n";
    my ($dh, $pid) = $ssh->pipe_out(@cmd) or
    die "pipe_out method failed: " . $ssh->error." for '".join("' '", @cmd)."'\n";
    return $dh;
}

sub open_cmd_pipe_root {
    my $self = shift;
    my @cmd = (qw(sudo -S -p), 'sudo password:'."\n", '--', @_);
    ReadMode('noecho');
    my $dh = $self->open_cmd_pipe(@cmd);
    my $c = ord($dh->getc);
    $dh->ungetc($c);
    ReadMode('normal');
    return $dh;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $remote = shift;

    my $ssh = Net::OpenSSH->new($remote);
    $ssh->error and
    die "Couldn't establish SSH connection: ". $ssh->error;

    return $class->$orig(
        'ssh' => $ssh,
        );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Collect::CMD::Remote - Collect data on remote machine with SSH

=head1 VERSION

version 2.06

Commands to collect data for StorageDisplay are run through SSH

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
