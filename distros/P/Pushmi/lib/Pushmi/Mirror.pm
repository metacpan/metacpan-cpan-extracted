package Pushmi::Mirror;
use strict;
use SVN::Core;
use SVN::Repos;
use SVN::Fs;

use SVK::Util qw(abs_path can_run);

sub install_hook {
    shift;
    my $repospath = shift;
    my $repos = SVN::Repos::open($repospath) or die; # XXX proper error

    $repos->fs->change_rev_prop(0, 'svk:notify-commit', '*');

    my $perl = join(' ', $^X, map { "'-I$_'" } @INC);
    my $pushmi = can_run('pushmi') or die "can't find pushmi";

    no warnings 'uninitialized';

    _install_hook($repospath, 'pre-commit', << "END");
#!/bin/sh
export SVKNOSVNCONFIG=1
export PUSHMI_CONFIG=$ENV{PUSHMI_CONFIG}
$perl $pushmi runhook \$1 --txnname \$2

END

    _install_hook($repospath, 'post-commit', << "END");
#!/bin/sh
export SVKNOSVNCONFIG=1
export PUSHMI_CONFIG=$ENV{PUSHMI_CONFIG}
$perl $pushmi unlock \$1 --revision \$2
$perl $pushmi verify \$1 --revision \$2 &

END

}

sub _install_hook {
    my ($repospath, $hook, $content) = @_;

    my $hpath = "$repospath/hooks/$hook";
    open my $fh, '>', $hpath or die $!;

    print $fh $content;

    close $fh;
    chmod 0755, $hpath;
    unless (-x $hpath) {
	# log info
	return 0;
    }
    return 1;
}

1;
