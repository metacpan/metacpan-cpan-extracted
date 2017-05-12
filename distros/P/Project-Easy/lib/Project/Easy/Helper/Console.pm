package Project::Easy::Helper;

use Class::Easy;

sub console {

	my @params = @ARGV;
	@params = @_
		if scalar @_;
	
	my ($package, $libs) = &_script_wrapper(); # Project name and "libs" path

	unless (try_to_use ('Devel::REPL')) {
		die "Devel::REPL required for interactive console";
	}
	
	my $repl = Devel::REPL->new;
	$repl->load_plugin('LexEnv');
	$repl->load_plugin('History');
	# $repl->load_plugin('MultiLine::PPI');
	
	$repl->lexical_environment->do(<<'CODEZ');
use Class::Easy;
use IO::Easy;
CODEZ
	
	$repl->run;

}

1;