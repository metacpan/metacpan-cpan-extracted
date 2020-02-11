use Test::Most 		0.25;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(dirname(dirname(abs_path($0)))), t => 'lib');
use SkipUnlessBash;
use TestUtilFuncs qw< bash_debug_is >;


# from https://github.com/barefootcoder/perlx-bash/issues/3
my $TEST_LMOD_OUTPUT = <<'END';
+ '[' -z '' ']'
+ case "$-" in
+ __lmod_vx=x
+ '[' -n x ']'
+ set +x
Shell debugging temporarily silenced: export LMOD_SH_DBG_ON=1 for this output (/usr/share/lmod/lmod/init/bash)
Shell debugging restarted
+ unset __lmod_vx
+ some debugging line
END

bash_debug_is { system( bash => -c => 'echo -n "$@" >&2', echo => $TEST_LMOD_OUTPUT ) } "+ some debugging line\n",
		 'bash_debug_is seems to work as expected';


done_testing;
