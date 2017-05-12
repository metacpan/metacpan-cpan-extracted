package Pushmi::Command::Verify;
use base 'Pushmi::Command::Mirror';
use strict;
use warnings;
use constant subcommands => qw(enable correct);

use IPC::Run3 'run3';

use SVK::I18N;

my $logger = Pushmi::Config->logger('pushmi.verify');

sub options {
    ( 'revision=i' => 'revision',
      'enable'     => 'enable',
      'correct'    => 'correct',
    )
}

sub get_path {
    my ($self, $repospath) = @_;
    $self->canonpath($repospath);
    my $repos = SVN::Repos::open($repospath) or die "Can't open repository: $@";
    return $self->root_svkpath($repos);
}

sub run {
    my ($self, $repospath) = @_;
    my $t = $self->get_path($repospath);

    $t->repos->fs->revision_prop(0, 'pushmi:auto-verify')
	or return;

    die "Revision required.\n" unless $self->{revision};

    my $verify_mirror = Pushmi::Config->config->{verify_mirror} || 'verify-mirror';
    my $path = $t->path;
    my $output;

    eval {
        run3 [(grep length, split / |'(.*?)'/, $verify_mirror),
              $repospath, $path, $self->{revision}],
             \undef, \$output, \$output
        };

    unless ($?) {
	$logger->debug("[$repospath] revision $self->{revision} verified");
	return;
    }

    $logger->logdie("[$repospath] can't run verify: $!") if $? == -1;

    $t->repos->fs->change_rev_prop(0, 'pushmi:inconsistent', $self->{revision});

    $logger->logdie("[$repospath] can't verify: $output");
}

package Pushmi::Command::Verify::enable;
use base 'Pushmi::Command::Verify';

sub run {
    my ($self, $repospath) = @_;
    my $t = $self->get_path($repospath);

    $t->repos->fs->change_rev_prop(0, 'pushmi:auto-verify', '*');

    print "Auto-verify enabled for $repospath.\n";
}

package Pushmi::Command::Verify::correct;
use base 'Pushmi::Command::Verify';

sub run {
    my ($self, $repospath) = @_;
    my $t = $self->get_path($repospath);

    my $rev = $t->repos->fs->revision_prop(0, 'pushmi:inconsistent')
	or return;

    $t->repos->fs->change_rev_prop(0, 'pushmi:inconsistent', undef);

    print "Inconsistency on revision $rev on $repospath cleared.\n";
}


=head1 NAME

Pushmi::Command::Verify - revision verification

=head1 SYNOPSIS

 verify --revision N REPOSPATH
 verify --enable REPOSPATH
 verify --correct REPOSPATH

=head1 OPTIONS

 --revision               : The revision to verify
 --enable                 : Turn on auto-verify
 --correct                : Clear the inconsistency flag

=head1 DESCRIPTION

See README.

=cut

1;
