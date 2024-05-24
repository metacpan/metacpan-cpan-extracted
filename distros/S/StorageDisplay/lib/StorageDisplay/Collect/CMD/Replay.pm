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

# in order to load the StorageDisplay::Collect::CMD module
use StorageDisplay::Collect;

package StorageDisplay::Collect::CMD::Replay;
# ABSTRACT: Use cached command output to collect data
our $VERSION = '2.06'; # VERSION


use parent -norequire => "StorageDisplay::Collect::CMD";
use Scalar::Util 'blessed';
use Data::Dumper;
use Data::Compare;

sub new {
    my $class = shift;
    my %args = ( @_ );
    if (not exists($args{'replay-data'})) {
        die 'replay-data argument required';
    }
    my $self = $class->SUPER::new(@_);
    $self->{'_attr_replay_data'} = $args{'replay-data'};
    $self->{'_attr_replay_data_nextid'}=0;
    return $self;
}

sub _replay {
    my $self = shift;
    my $args = shift;
    my $ignore_keys = shift;
    my $msgerr = shift;

    my $entry = $self->{'_attr_replay_data'}->[$self->{'_attr_replay_data_nextid'}++];
    if (not defined($entry)) {
        print STDERR "E: no record for $msgerr\n";
        die "No records anymore\n";
    }
    foreach my $k (keys %{$args}) {
        if (not exists($entry->{$k})) {
            print STDERR "E: no record for $msgerr\n";
            die "Missing '$k' in record:\n".Data::Dumper->Dump([$entry], ['record'])."\n";
        }
    }
    if (! Compare($entry, $args, { ignore_hash_keys => $ignore_keys })) {
        print STDERR "E: record for different arguments\n";
        foreach my $k (@{$ignore_keys}) {
            delete($entry->{$k});
        }
        die "Bad record:\n".
            Data::Dumper->Dump([$args, $entry], ['requested', 'recorded'])."\n";
    }
    return $entry;
}

sub _replay_cmd {
    my $self = shift;
    my $args = { @_ };
    my $cmd = $self->_replay(
        $args,
        ['stdout', 'root'],
        "command ".$self->cmd2str(@{$args->{'cmd'}}),
        );
    my $cmdrequested = $self->cmd2str(@{$args->{'cmd'}});
    if ($args->{'root'} != $cmd->{'root'}) {
        print STDERR "W: Root mode different for $cmdrequested\n";
    }
    print STDERR "Replaying".($cmd->{'root'}?' (as root)':'')
        .": ", $cmdrequested, "\n";
    my @infos = @{$cmd->{'stdout'}};
    my $infos = join("\n", @infos);
    if (scalar(@infos)) {
        # will add final endline
        $infos .= "\n";
    }
    open(my $fh, "<",  \$infos);
    return $fh;
}

sub open_cmd_pipe {
    my $self = shift;
    return $self->_replay_cmd(
        'root' => 0,
        'cmd' => [ @_ ],
        );
}

sub open_cmd_pipe_root {
    my $self = shift;
    return $self->_replay_cmd(
        'root' => 1,
        'cmd' => [ @_ ],
        );
}

sub has_file {
    my $self = shift;
    my $filename = shift;
    my $fileaccess = $self->_replay(
        {
            'filename' => $filename,
        },
        [ 'value' ],
        "file access check to '$filename'");
    return $fileaccess->{'value'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Collect::CMD::Replay - Use cached command output to collect data

=head1 VERSION

version 2.06

This module is mainly useful for debug or test only. It allows
one to replace real data collect on machine by the recorded
output of all commands.

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
