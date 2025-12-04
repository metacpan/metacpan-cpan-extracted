Automating workflows, like SnakeMake and NextFlow, but with better debugging and portability.

Only 1 subroutine is exported: `task`
---------
Synopsis
---------
This is similar to snakeMake or NextFlow, but running in Perl.
The simplest use case is

    my $t = task({
        cmd => 'which ls'
    });

All tasks return a hash, showing at a minimum 1) exit code, 2) the directory that the job was done in, 3) stderr, and 4) stdout.

the only required key/argument is `cmd`, but other arguments are possible:

    die			  # die if not successful; 0 or 1
    input.files  # check for input files before running; SCALAR or ARRAY
    log.fh       # print to filehandle
    overwrite    # overwrite previously existing files: "true" or "false"
    output.files # product files that need to be checked; SCALAR or ARRAY

You may wish to output results to a logfile using a previously opened filehandle thus:

    my ($fh, $fname) = tempfile( UNLINK => 0, DIR => '/tmp');
    my $t = task({
    	cmd            => 'which ln',
    	'log.fh'       => $fh,
    	'output.files' => $fname,
    	overwrite      => 1
    });
    close $fh;
