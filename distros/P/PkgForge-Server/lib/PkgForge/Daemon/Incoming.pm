package PkgForge::Daemon::Incoming; # -*-perl-*-
use strict;
use warnings;

# $Id: Incoming.pm.in 14914 2010-12-01 09:41:14Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 14914 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Daemon/Incoming.pm.in $
# $Date: 2010-12-01 09:41:14 +0000 (Wed, 01 Dec 2010) $

our $VERSION = '1.1.10';

my $PLEASE_STOP = 0;

use Moose;
use MooseX::Types::Moose qw(Int);

extends 'PkgForge::Daemon', 'PkgForge::Handler::Incoming';

has 'poll' => (
    is       => 'ro',
    isa      => Int,
    default  => 60,
    required => 1,
    documentation => 'Interval (in seconds) to wait between queue runs',
);

override 'shutdown' => sub {
    my ($self) = @_;

    $self->logger->notice('Handling shutdown request');

    $PLEASE_STOP = 1;

    return;
};

after 'start' => sub {
    my ($self) = @_;

    $self->logger->notice('Starting incoming queue processing daemon');

    $self->preflight();

    while ( !$PLEASE_STOP ) {
        $self->logger->notice('Processing queue');
        $self->execute();
        $self->logger->notice('Finished processing queue');

        if ( !$PLEASE_STOP ) {
            sleep $self->poll;
        }
    }

    $self->logger->notice('Stopping incoming queue processing daemon');

    exit 0;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
