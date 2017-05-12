package Monitoring::Spooler::Cmd::Command::rm;
$Monitoring::Spooler::Cmd::Command::rm::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::rm::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: remove a single message

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
has 'message_id' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'required' => 1,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'm',
    'documentation' => 'Remove the message identified by this ID',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    # remove a single message from the queue
    my $sql = 'DELETE FROM msg_queue WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Could not prepare statement: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if($sth->execute($self->message_id())) {
        $self->logger()->log( message => 'Deleted message #'.$self->message_id().' from queue.', level => 'debug', );
        $sth->finish();
        return 1;
    } else {
        $self->logger()->log( message => 'Could not execute statement: '.$sth->errstr, level => 'warning', );
        $sth->finish();
        return;
    }
}

sub abstract {
    return "Remove a single message from the notification queue.";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::rm - remove a single message

=head1 DESCRIPTION

This class implement a command that deletes a single message from the queue.

=head1 METHODS

=head2 execute

Remove the message #<message_id> from the queue.

=head1 NAME

Monitoring::Spooler::Cmd::Command::Rm - Remove messages from the queue

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
