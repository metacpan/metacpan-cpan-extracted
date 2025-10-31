Automating workflows, like SnakeMake and NextFlow, but with better debugging and portability.

Only 1 subroutine is exported: `task`
---------
Synopsis
---------
```
open my $log, '>', 'log.txt';
task({
	cmd		      => 'gmx_cvtool.sh -n -i cpx -g cpx.gro',
	'output.files' => 'cpx.dx',
	'log.fh'       => $log,
});
```
which outputs a log
