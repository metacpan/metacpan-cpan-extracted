package Pushmi::Command::Unlock;
use base 'Pushmi::Command::Mirror';
use strict;
use warnings;

use SVK::I18N;

my $logger = Pushmi::Config->logger('pushmi.unlock');

sub options {
    ( 'revision=i' => 'revision' )
}

sub run {
    my ($self, $repospath) = @_;
    $self->canonpath($repospath);
    my $repos = SVN::Repos::open($repospath) or die "Can't open repository: $@";

    my $t = $self->root_svkpath($repos);

    $self->setup_auth;
    my ($mirror) = $t->is_mirrored;

    my $token   = join(':', $mirror->repos->path, $mirror->_lock_token);
    if ($self->{revision}) {
        # non-runhook commits (like sync), nothing to unlock for.
        my $expected = $t->repos->fs->revision_prop($self->{revision}, 'svk:committed-by') or return;
        if ($expected ne $token) {
            $logger->logdie("[$repospath] revision $self->{revision} does not own lock $expected, expecting $token");
        }
    }
    my $memd = Pushmi::Config->memcached;
    if (my $content = $memd->get( $token ) ) {
        $logger->info("[$repospath] lock $token ($content) removed");
        print loc("Removing lock %1 on %2.\n", $content, $repospath);
        $mirror->unlock('force');
    }
    else {
        $logger->info("[$repospath] lock $token not found");
    }

    return;
}

1;
