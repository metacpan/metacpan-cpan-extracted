package Monitoring::Spooler::Cmd::Command::flush;
$Monitoring::Spooler::Cmd::Command::flush::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::flush::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: remove all pending notifications

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'Monitoring::Spooler::Cmd::Command';
# has ...
has 'all' => (
    'is'    => 'ro',
    'isa'   => 'Bool',
    'default' => 0,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'a',
    'documentation' => 'When set also clears all pause flags',
);

has 'type' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 't',
    'documentation' => 'When set only messages of this type (text or phone) are removed',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;
    # flush the whole queue
    my $sql = 'DELETE FROM msg_queue';
    my @args = ();
    if($self->type()) {
        $sql .= ' WHERE type = ?';
        push(@args, $self->type());
    }
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log(message => 'Failed to prepare statemnt ('.$sql.'): '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if($sth->execute(@args)) {
        $self->logger()->log( message => 'Flushed message queue', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
    }
    $sth->finish();

    if($self->all()) {
        my $sql = 'DELETE FROM paused_groups';
        my $sth = $self->dbh()->prepare($sql);
        if($sth) {
            if($sth->execute()) {
                $self->logger()->log( message => 'Deleted all group pause flags', level => 'debug', );
            } else {
                $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
            }
            $sth->finish();
        } else {
            $self->logger()->log( message => 'Failed to prepare statement ('.$sql.'): '.$self->dbh()->errstr, level => 'warning', );
        }
        $sql = 'DELETE FROM paused_users';
        $sth = $self->dbh()->prepare($sql);
        if($sth) {
            if($sth->execute()) {
                $self->logger()->log( message => 'Deleted all user pause flags', level => 'debug', );
            } else {
                $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
            }
            $sth->finish();
        } else {
            $self->logger()->log( message => 'Failed to prepare statement ('.$sql.'): '.$self->dbh()->errstr, level => 'warning', );
        }
    }

    return 1;
}

sub abstract {
    return "Flush (delete) the notification queue";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::flush - remove all pending notifications

=head1 DESCRIPTION

This class implements a command to delete all queued messages.

Given the --all option is will also delete all pause flags.

=head1 NAME

Monitoring::Spooler::Cmd::Command::Flush - Flush all queued messages

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
