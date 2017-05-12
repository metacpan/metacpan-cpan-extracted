use strict;
use warnings;

sub libxml2_config {
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

    print "checking for libxml2... ";
    run(['xml2-config', '--version'], \undef, \(my $ver))   or die "xml2-config: $?";
    print $ver;

    print "checking for libxml2 CFLAGS... ";
    run(['xml2-config', '--cflags'], \undef, \(my $cflags)) or die "xml2-config: $?";
    print $cflags;

    print "checking for libxml2 LIBS... ";
    run(['xml2-config', '--libs'  ], \undef, \(my $libs  )) or die "xml2-config: $?";
    print $libs;

    return {
        CFLAGS => $cflags,
        LIBS   => $libs,
    };
}

1;
