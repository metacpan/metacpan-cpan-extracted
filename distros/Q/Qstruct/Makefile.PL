use strict;

use ExtUtils::MakeMaker;
use Config;


my ($LIBS) = map { /^LIBS=(.*)$/ && $1 || () } @ARGV;
my ($INC) = map { /^INC=(.*)/ && $1 || () } @ARGV;
my $myextlib = '';
{
    $LIBS ||= '';
    my @libdata = ExtUtils::Liblist->ext($LIBS || '-lqstruct', 0, 'parse_qstructs');
    my @stdinc = qw(/usr/include /usr/local/include);
    push @stdinc, $libdata[3] if $libdata[3];
    my($Head) = grep -f "$_/qstruct/compiler.h", @stdinc;
    if(($INC || $Head) && $libdata[0]) {
        $INC ||= "-I$Head" if -f "$libdata[3]/qstruct/compiler.h";
        warn "Will use SYSTEM qstruct in $libdata[3]\n";
        $LIBS ||= '-lqstruct';
        warn "If that path isn't a standard one, you may need to set LD_LIBRARY_PATH!\n"
            if($libdata[4][0] =~ /.so/);
    } else {
        warn "Will use my own copy of libqstruct.\n";
        $myextlib = 'libqstruct/libqstruct$(LIB_EXT)';
    }
}

$LIBS = "$LIBS $ENV{XLDLIBS}" if $ENV{XLDLIBS};

my %args = (
    NAME => 'Qstruct',
    VERSION_FROM => 'lib/Qstruct.pm',
    PREREQ_PM => {
      'Math::Int64' => '0.27_04',
    },
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text lib/Qstruct.pm > $(DISTVNAME)/README',
    },
    OBJECT                => '$(O_FILES)', # link all the C files too
    LIBS                => $LIBS,
    CCFLAGS => $ENV{XCFLAGS} || '',
    ($myextlib ? (
        MYEXTLIB        => $myextlib,
        INC                => '-I./libqstruct',
        ) : (
        INC                => $INC
        )
    ),
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Qstruct.git',
            bugtracker => 'https://github.com/hoytech/Qstruct/issues',
        },
    };
}

WriteMakefile(%args);




sub MY::postamble {
  return <<'EOT';
$(MYEXTLIB): libqstruct/Makefile libqstruct/qstruct/*.h libqstruct/*.rl libqstruct/*.c
	cd libqstruct && $(MAKE) libqstruct$(LIB_EXT)
EOT
}

sub MY::realclean {
  return <<'EOT';
realclean: clean
	cd libqstruct && $(MAKE) clean
EOT
}
