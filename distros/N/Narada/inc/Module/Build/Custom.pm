package Module::Build::Custom;
use strict;
use warnings;
use parent 'Module::Build';

my $TAR = (grep {-x "$_/gtar"} split /:/, $ENV{PATH}) ? 'gtar' : 'tar';
for my $cmd (qw( bash find chmod ), $TAR) {
    if (!grep {-x "$_/$cmd"} split /:/, $ENV{PATH}) {
        die "Command not found: $cmd\n"
    }
}
die "GNU tar required\n" if `$TAR --version` !~ /GNU/ms;

# WARNING:  Empty directories in skel/ MUST contain .keep file to force
#           inclusion of these directories in MANIFEST and module distribution.
#           These files will not be installed by `narada-new-1`.

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;
    print "Forcing skel/var/patch/ChangeLog to be symlink ...\n";
    unlink 'skel/var/patch/ChangeLog';
    symlink '../../doc/ChangeLog', 'skel/var/patch/ChangeLog' or die "symlink: $!";
    $self->_inject_skel('blib/script/narada-new-1');
}

sub _inject_skel {
    my ($self, $script) = @_;
    print "Injecting skel/ into $script ...\n";
    use File::Temp qw( mktemp );
    my $new = `cat \Q$script\E`;
    $new =~ s/\s*(^__DATA__\n.*)?\z/\n\n__DATA__\n/ms;
    my $filename = mktemp("$script.XXXXXXXX");
    open my $f, '>', $filename or die "open: $!";
    print {$f} $new;
    system("find skel/ -type f -exec chmod u+w {} +")
        == 0 or die "system: $?\n";
    my $TAR = (grep {-x "$_/gtar"} split /:/, $ENV{PATH}) ? 'gtar' : 'tar';
    open my $tar, '-|', $TAR.' cf - -C skel --exclude .keep ./' or die "open: $!";
    use MIME::Base64;
    local $/;
    print {$f} encode_base64(<$tar>);
    close $f or die "close: $!";
    my ($atime, $mtime) = (stat($script))[8,9];
    utime $atime, $mtime, $filename or die "utime: $!";
    rename $filename, $script or die "rename: $!";
    chmod 0755, $script or die "chmod: $!";
    return;
}


1;
