Automating workflows, like SnakeMake and NextFlow, but with better debugging and portability.

Only 1 subroutine is exported: `task`
---------
Synopsis
---------
This is similar to snakeMake or NextFlow, but running in Perl.
The simplest use case is

    my $t = task({
        cmd            => 'which ls'
        'output.files' => '/tmp/AFK3mnEK8L.log'
    });

the output is a hash reference:

    {
        cmd            "which ls",
        die            1,
        dir            "/home/con/Scripts/SimpleFlow",
        done           "now",
        dry.run        0,
        duration       0.00191903114318848,
        exit           0,
        note           "",
        output.files   [
            [0] "/tmp/AFK3mnEK8L.log"
        ],
        overwrite      1,
        source.file    "t/01.t",
        source.line    29,
        stderr         "",
        stdout         "/usr/bin/ls",
        will.do        "done"
    }

All tasks return a hash, showing at a minimum 1) exit code, 2) the directory that the job was done in, 3) stderr, and 4) stdout.

the only required key/argument is `cmd`, but other arguments are possible:

	'die',			# die if not successful; 0 or 1
	'dry.run',      # dry run or not
	'input.files',  # check for input files; SCALAR or ARRAY
	'log.fh',
	'note',         # a note for the log
	'overwrite',    # 0 or 1
	'output.files'	# product files that need to be checked; can be scalar or array;

`input.files` are checked before execution, if any of those files are missing, the program will die.
`output.files` are checked after execution, if any of those files are missing, the program will die.

You may wish to output results to a logfile using a previously opened filehandle thus:

    open my $fh, '>', 'logfile.txt';
    my $t = task({
    	cmd            => 'which ln',
    	'log.fh'       => $fh,
    	'output.files' => ['cpx.gro', 'cpx.top'],
    	overwrite      => 1
    });
    close $fh;

sometimes a dry run may be desirable:

    my $t = task({
       cmd       => 'a long-running/time-consuming command',
       'dry.run' => 1,
       'log.fh'  => $fh
    });

which will print the command as it is to the log
