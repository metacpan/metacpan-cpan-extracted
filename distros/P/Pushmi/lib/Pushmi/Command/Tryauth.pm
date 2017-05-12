package Pushmi::Command::Tryauth;
use base 'Pushmi::Command::Mirror';

our ($USER, $PASS) = @_;

sub pushmi_auth {
    my ($cred, $realm, $default_username, $may_save, $pool) = @_;
    $cred->username($USER);
    $cred->password($PASS);
    $cred->may_save(0);
    return $SVN::_Core::SVN_NO_ERROR;
}

sub run {
    my ($self, $repospath, $user, $pass) = @_;
    ($USER, $PASS) = ($user, $pass);
    die "repospath required" unless $repospath;
    $self->canonpath($repospath);
    my $repos = SVN::Repos::open($repospath) or die "Can't open repository: $@";
    my $t = $self->root_svkpath($repos);
    my ($mirror) = $t->is_mirrored;
    $self->setup_auth;
    my $editor = eval { $mirror->get_commit_editor('', '*should not be committed*', sub {}) };
    if ($editor) {
	$editor->abort_edit;
	exit 0;
    }
    exit 1;
}

1;

