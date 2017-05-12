use strict;
use warnings;

sub glib2_config {
    local $| = 1; # autoflush

    eval{
      local($SIG{__DIE__}) = 'DEFAULT';
      require IPC::Run;
      IPC::Run->import(qw(run));
    };
    if( $@ )
    {
      *run = sub{
        my $cmds    = shift;
        my $in_ref  = shift;
        my $out_ref = shift;

        my $cmd_str = join(' ', @$cmds);
        ${$out_ref} = `$cmd_str`;
	return 1;
      };
    }

    local $| = 1; # autoflush

    print "checking for glib2... ";
    run(['pkg-config', '--modversion', 'glib-2.0'], \undef, \(my $ver))   or die "pkg-config: $?";
    print $ver;

    print "checking for CFLAGS... ";
    run(['pkg-config', '--cflags', 'glib-2.0'], \undef, \(my $cflags)) or die "pkg-config: $?";
    print $cflags;

    print "checking for LIBS... ";
    run(['pkg-config', '--libs', 'glib-2.0'], \undef, \(my $libs  )) or die "pkg-config: $?";
    print $libs;

    return {
        CFLAGS => $cflags,
        LIBS   => $libs,
    };
}

1;
