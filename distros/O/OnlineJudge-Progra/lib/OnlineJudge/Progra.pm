#!/usr/bin/perl
package OnlineJudge::Progra;

use File::Spec::Functions qw(catfile catdir); 
use Time::HiRes qw(time);
use Proc::Killall;
use File::Copy;
use warnings;
use strict;

our $VERSION = '0.023';

$0 = 'progra';

# these words cannot be in user's source code
my @BADWORDS = ();

# output and error files (only if running in background mode)
my $output_file	= 'output.log';
my $error_file	= 'error.log';
my $log_file		= 'messages.log';

# defines how source codes must be compiled according to its language
my $COMPILERS = {
	'c'		=> '/usr/bin/gcc _SOURCECODE_ -o _BINARY_ > /dev/null 2>&1',
	'cpp'	=> '/usr/bin/g++ _SOURCECODE_ -o _BINARY_ > /dev/null 2>&1',
};

# defines how programs must be executed according to its language
my $EXEC = {
	'pl'  => '/usr/bin/perl _FILE_',
	'py'  => '/usr/bin/python _FILE_',
	'c'   => './_FILE_',
	'cpp' => './_FILE_',
};

sub new {
	my $class 	= shift;
	my $self 	= {};

	$self->{'background'}    	= 1;
	$self->{'log'}    			= 1;
	$self->{'verbose'}       	= undef;
	$self->{'pid_file'}      	= undef;
	$self->{'get_sub'}       	= undef;
	$self->{'update_sub'}    	= undef;
	$self->{'time_interval'} 	= 60; 		# in seconds
	$self->{'home'}          	= '/tmp';
	$self->{'diff_options'}  	= 'biw'; 

	bless $self, $class;

	return $self;
}

sub set_background {
	my $self 	= shift;
	my $value 	= shift or undef;

	if ( $value ) { $self->{'background'} = 1; }
}

# home directory is used for storing log and pid files.
sub set_home {
	my $self 	= shift;
	my $dir 	= shift or undef;

	if ( $dir ) {
		if ( !(-d $dir) ) { 
			$self->error("Error: $dir does not exist or is not a directory."); 
		}
		$self->{'home'} = $dir;
	}
}

# time interval must be in seconds
sub set_timeinterval {
	my $self 	= shift;
	my $value 	= shift or undef;

	if ( $value ) { $self->{'time_interval'} = $value; }
}

# set a new compiler or replace a previous one
sub set_compiler {
	my $self = shift;
	my $lang = shift;
	my $comp = shift;
	
	$COMPILERS->{ $lang } = $comp;
}

# set a new way of executing a program or replace a previous one
sub set_exec {
	my $self = shift;
	my $lang = shift;
	my $exec = shift;
	
	$EXEC->{ $lang } = $exec;
}

# set logging (true by default)
sub set_logging {
	my $self 	= shift;
	my $value 	= shift or undef;
	
	if ( defined($value) ) { $self->{'log'} = $value; }
}

# set diff options
sub diff_options {
	my $self 	= shift;
	my $options = shift;
	
	if ( $options ) { $self->{'diff_options'} = $options; }
}

sub verbose {
	my $self 	= shift;
	my $value 	= shift or undef;
	
	if ( $value ) { $self->{'verbose'} = 1; }
}

# e.g. system, exec, etc.
sub load_badwords {
	my $self = shift;
	my $file = shift;
	
	open my $F, '<', $file or $self->error("can't open badwords file: $file");
	local $/;
	my $content = <$F>;
	close $F;
	
	$content =~ s/\n//g;
	@BADWORDS = split(',', $content);
}

sub run {
	my $self	= shift;
	my %args	= @_;
	
	my $get_sub		= $args{'get_sub'};
	my $update_sub 	= $args{'update_sub'};

	if ( !(defined($get_sub)) or !(defined($update_sub)) ) {
		$self->error('missing get and/or update subroutines!');
	}
	
	$self->{'get_sub'}    = $get_sub;
	$self->{'update_sub'} = $update_sub;
	
	my $home       	= $self->{'home'};
	my $background	= $self->{'background'};
	
	my $output 	= catfile( $home, $output_file );
	my $errors 	= catfile( $home, $error_file );
	$log_file 		= catfile( $home, $log_file );
	my $pid_file;
	
	if ( !$background ) {
		$pid_file = catfile( $home, $$.'.pid' );
		
		open my $F, '>', $pid_file or $self->error('could not create PID file');
		print {$F} $$;
		close $F; 	

		# everything is OK
		print ":: progra running with pid $$\n";
		
		$self->{'pid_file'} = $pid_file;
		
		# start judging! 
		$self->judge();
	} 
	else {
		my $pid = fork();
		
		if ( $pid ) {
			# to stop pogra delete PID file
			$pid_file = catfile( $home, $pid.'.pid' );
	
			open my $F, '>', $pid_file or $self->error('could not create PID file');
			print {$F} $pid;
			close $F; 	

			# everything is OK
			print ":: progra running with pid $pid\n";
		} 
		elsif ( $pid == 0 ) {
			chdir $home;

			close STDIN;
			open STDOUT, '>>', $output;
			open STDERR, '>>', $errors;
			
			$| = 1;
	
			# let's just wait a sec
			sleep 1;
			$pid_file = catfile( $home, $$.'.pid' );
			$self->{'pid_file'} = $pid_file;
			
			# start judging!
			$self->judge();
		}
	} 
}

sub judge {
	my $self = shift;
	
	my $get_sub 		= $self->{'get_sub'};
	my $update_sub 	= $self->{'update_sub'};
	my $time_interval = $self->{'time_interval'};
	my $pid_file 		= $self->{'pid_file'};
	
	my $date = $self->get_date();
	print ":: progra started - $date\n";
	
	# main loop
	while (1) {
		if ( !(-e $pid_file) ) {
			$date = $self->get_date();
			print ":: progra terminated - $date\n\n";
			last;
		}
		
		my @requests = $get_sub->();
		
		if (@requests) {
			foreach my $request ( @requests ) {
				# process each request individually
				my $processed = $self->process_request( $request );
				# and update request information
				$update_sub->( $processed );
			}
		}
		
		# do not stress
		sleep $time_interval;
		undef @requests;
	}
}

sub process_request {
	my $self 	= shift;
	my $r 		= shift;

	# update comment before processing
	$r->{'comment'} 		= 'PC';
	$r->{'grade'} 			= 0;
	$r->{'timemarked'} 		= time();
	# in case source code fails before being tested
	$r->{'executiontime'}	= 0;

	# processing a request is divided in three/four steps:
	#  - check for badwords in source code.
	#  - compile source code (if needed)
	#  - test user's program.
	#  - delete created files.
	$self->check($r);
	if ( $r->{'compile'} ) { $self->compile($r); }
	$self->test($r);
	$self->clean($r);
	
	# build the processed request (original request may have some garbage)
	my $processed = {};
	$processed->{'rid'}           = $r->{'rid'};
	$processed->{'grade'}         = $r->{'grade'};
	$processed->{'executiontime'} = $r->{'executiontime'};
	$processed->{'timemarked'}    = $r->{'timemarked'};
	$processed->{'comment'}       = $r->{'comment'};

	if ( $self->{'verbose'} ) {
		print "\nrequest: $processed->{'rid'}\ngrade: $processed->{'grade'}\n";
		print "execution time: $processed->{'executiontime'}\ntime marked: ";
		print "$processed->{'timemarked'}\ncomment: $processed->{'comment'}\n";
	}
	
	return $processed;
}

# this should be complemented with stronger security policies
# see TODO in the POD for mode detail
sub check {
	my $self 	= shift;
	my $r 		= shift;
	
	$r->{'executiontime'} 	= 0;
		
	if ( (open my $F, '<', $r->{'sourcecode'}) ) {
		my @content = <$F>;
		close $F;

		foreach my $bw ( @BADWORDS ) {
			my $has_badword = grep( /$bw/, @content );
			if ( $has_badword ) {
				# request comment is updated
				$r->{'comment'} = "BW: $bw";
				if( $self->{'log'} != 0 ) {
					$self->log($r);
				}
				return;
			}
		}
	} else {
		$self->warn($r->{'rid'}." - error while reading $r->{'sourcecode'}");
		$r->{'comment'} = 'IE ('.$r->{'rid'}.')';
	}
}

# get the compile string associated with a given language
sub get_compile_string {
	my $self			= shift;
	my $sourcecode	= shift;
	my $binary			= shift;
	my $lang			= shift;
		
	my $compile_string	= $COMPILERS->{ $lang };
	$compile_string		=~ s/_SOURCECODE_/$sourcecode/;
	$compile_string		=~ s/_BINARY_/$binary/;
	
	return $compile_string;
}

sub compile {
	my $self 	= shift;
	my $r		= shift;
	
	# if a previous step failed, it does not continue
	if ( $r->{'comment'} ne 'PC' ) {
		return;
	}
	
	my $binary;
	# all source codes have extension, right?
	if ( $r->{'sourcecode'} =~ /.*\/(.+)\.\w+/ ){ $binary = $1; }
	
	my $compile_string = $self->get_compile_string( $r->{'sourcecode'}, $binary, $r->{'lang'} );
	
	chdir $r->{'userpath'};
	system( $compile_string );
	
	if ( !(-e $binary) ) { $r->{'comment'} = 'CE'; }
	
	$r->{'binary'} = $binary;
}

# get the execution string associated with a given language
sub get_exec_string {
	my $self			= shift;
	my $sourcecode	= shift;
	my $lang			= shift;
	
	my $exec_string	= $EXEC->{ $lang };
	$exec_string		=~ s/_FILE_/$sourcecode/;
	
	return $exec_string;
}

sub test {
	my $self 	= shift;
	my $r 		= shift;
	
	# if a previous step failed, it does not continue
	if ( $r->{'comment'} ne 'PC' ) {
		return;
	}
	
	my ($inittime, $finaltime, $totaltime) = (0, 0, 0);
	my $averagetime;
	
	my $systeminput  	= $r->{'taskpath'}.'input.';
	my $systemoutput 	= $r->{'taskpath'}.'output.';
	my $useroutput   	= $r->{'userpath'}.'output';
	
	my $score = 0;
	
	for ( my $i = 0; $i < $r->{'testcases'}; $i++ ) {
				
		if ( !(-e $systeminput.$i) ) {
			$self->warn($r->{'rid'}." - error: system input file does not exist: $systeminput$i");
			$r->{'comment'} = 'IE ('.$r->{'rid'}.')';
			return;
		}		
		
		if ( !(-e $systemoutput.$i) ) {
			$self->warn($r->{'rid'}." - error: system output file does not exist: $systemoutput$i");
			$r->{'comment'} = 'IE ('.$r->{'rid'}.')';
			return;
		}
		
		my $exec_string;
		if( $r->{'compile'} ) {
			$exec_string = $self->get_exec_string($r->{'binary'}, $r->{'lang'});
		} else {
			$exec_string = $self->get_exec_string($r->{'sourcecode'}, $r->{'lang'});
		}
		
		# child processes are ignored in order to avoid "zombies"
		$SIG{'CHLD'} = 'IGNORE';

		eval {
			$SIG{'ALRM'} = sub { die 'time limit exceeded' };
			
			alarm $r->{'timelimit'};
			$inittime = time();

			chdir $r->{'userpath'};
			
			# execute redirecting input and output
			system($exec_string.' < '.$systeminput.$i.' > '.$useroutput);

			$finaltime = time();
			alarm 0;
		};
		
		killall('KILL', $r->{'sourcecode'});
		
		$totaltime = $finaltime - $inittime;
		$totaltime = substr($totaltime, 0, 6);
		# sometimes time is negative....don't know why
		$totaltime = 0 if ( $totaltime < 0 );
				
		$averagetime += $totaltime;
				
		if ( $@ =~ /time limit exceeded/ ) {
			$r->{'comment'} = 'TL';
			if( $self->{'log'} != 0 ) {
				$self->log($r);
			}	
			return;
		}

		if ( $self->compare( $systemoutput.$i, $useroutput ) ) {
			# test case passed :-)
			$score += $r->{'maxscore'}/$r->{'testcases'};	
		}
	}
	
	# approved!
	if ( $score == $r->{'maxscore'} ) {
		$r->{'comment'} = 'AC';
	} 
	# keep trying..
	else {
		$r->{'comment'} = 'WA';
	}
	
	$r->{'executiontime'} = $averagetime/$r->{'testcases'};
	$r->{'grade'}         = $score;
}

# returns true if files are equal
sub compare {
	my $self			= shift;
	my $systemoutput	= shift;
	my $useroutput	= shift;
	my $options		= $self->{'diff_options'};

	# diff command will return a true value if there are any 
	# differences between the files.  The -b argument ignores 
	# extra white spaces, the -w ignores all white spaces,
	# the -i ignore case differences
	my $diff = `diff -$options $systemoutput $useroutput`;
	
	(!$diff) ? return 1 : return 0;
}

sub clean {
	my $self 	= shift;
	my $r 		= shift;	
	
	# remove output file created by user's program
	unlink $r->{'userpath'}.'output';
	if( $r->{'compile'} and (-e $r->{'binary'}) ) { unlink $r->{'binary'}; }	 
}

sub warn {
        my $self 	= shift;
        my $error 	= shift;
        my ( $package, $filename, $line, $sub, $dayname );

        my $date		= $self->get_date();
        my $errstr		= ":: [$date] > ";
        $errstr		.= "\"$error\"\n";

        # we want to know where the error came from
        $filename	= ( caller(1) )[1];
        $line		= ( caller(1) )[2];
        $sub		= ( caller(1) )[3];

        $errstr .= " - called by $sub() in $filename line $line\n";
        $errstr .= "\n";
	
        warn $errstr;
}

sub error {
        my $self 	= shift;
        my $error 	= shift;
        my ( $package, $filename, $line, $sub );

        my $date		= $self->get_date();
        my $errstr		= ":: [$date] > ";
        $errstr		.= "\"$error\"\n";
    
        print ":: progra terminated - $date\n\n";

        # we want to know where the error came from
        $filename 	= ( caller(1) )[1];
        $line 		= ( caller(1) )[2];
        $sub 		= ( caller(1) )[3];

        $errstr .= " - called by $sub() in $filename line $line\n";
        $errstr .= "\n";

        die $errstr;
}

# it keeps the logs in home directory
sub log {
        my $self = shift;
        my $r    = shift;

        my ($hour, $min) = (0, 0);
        my $home = $self->{'home'};
        my $date = $self->get_date();
        my $msg  = ":: [$date] > ";
        $msg    .= $r->{'comment'}." on ".$r->{'rid'}."\n";
    
        print ":: logging - $date\n";
    
        open my $F, '>>', $log_file or error('cannot open messages.log file!');
        print {$F} $msg;
        close $F;
	
		# save the source code that caused logging
        if ( $date =~ /.*\s+(\d+):(\d+)/ ) { ($hour, $min) = ($1, $2); }
	
        if ( !(-d catdir($home, 'logged')) ) { 
			mkdir catdir($home, 'logged'); 
		} 
	
        my $filename = catfile( $home, catfile( 'logged', $r->{'rid'}.'_'.$hour.$min.'.'.$r->{'lang'} ) );
        copy( $r->{'sourcecode'}, $filename );
}

sub get_date {
        my $self = shift;
	
        my ($sec,$min,$hour,$mday,$mon,$year, $wday) = localtime(time);
        my $days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

        $year += 1900;
        $mon++;

        my $dayname = $days->[$wday];
        
        $hour		= '00' if ($hour == 0);
        $hour		= '0'.$hour if ($hour < 10);
        $min		= '00' if ($min == 0);
        $min		= '0'.$min if ($min < 10);
        $mon		= '0'.$mon if ($mon < 10);
        my $date 	= "$dayname $year/$mon/$mday $hour:$min";
    
        return $date;
}

1;

__END__

=head1 NAME

OnlineJudge::Progra - (Just Another) Programming Tasks Grading System
 
=head1 VERSION

Version 0.021

=head1 SYNOPSIS

 use OnlineJudge::Progra;
 
 # Create your soubroutine to obtain new requests to process.
 # Returns requests to be processed.
 sub get {
	 #...
	 return @requests;
 }

 # Create your subroutine to update requests wherever you store them.
 # Receives a processed request.
 sub update {
	 my $request = shift;
	 # ...
 }

 my $judge = OnlineJudge::Progra->new();
 
 $judge->set_home('/home/progra/'); # progra's home
 $judge->set_timeinterval(30);		# in seconds
 
 $judge->run(
	get_sub => sub { &get },
	update_sub => sub { &update }
 );	


=head1 DESCRIPTION

Progra is an online judge capable of compile and test programs
written to solve a programming task.
 
=head1 METHODS

=head2 set_home(/home/foo/bar)

Sets the home directory for progra files (logs, pid file, etc). If not specified,
is set to '/tmp'. Once progra starts, it creates a .pid file in its home directory. 
You should remove the .pid file created in this directory in order to stop progra.

=head2 set_timeinterval(n)

The time interval defines the amount of time (in seconds) progra waits to check 
again for new requests to process. Default to 60 seconds.

=head2 set_background(true/false)

Defines if progra runs on background or not. In case background is
set, the output and errors will be redirected to the output.log and error.log 
files found in progra's home directory. True by default.

=head2 set_logging(true/false)

Defines if progra log risky situations or not (badwords and time limits).  
Anything different than zero is considered true. True by default.

=head2 set_compiler('ext', '/path/to/compiler _SOURCECODE_ -options _BINARY_')

Defines how source codes of a given language must be compiled. The B<_SOURCECODE_>
and B<_BINARY_> strings must be present (yes, with both underscores) and they
will be internally replaced by the corresponding filenames. Example: 

 # how a .c file should be compiled
 $judge->set_compiler('c', '/usr/bin/gcc _SOURCECODE_ -o _BINARY_')
 
There are some compiler strings by default:

 c: /usr/bin/gcc _SOURCECODE_ -o _BINARY_
 cpp: /usr/bin/g++ _SOURCECODE_ -o _BINARY_
 
If you want to avoid the output generated by compilation errors, you should
add '> /dev/null 2>&1' at the end of the string, otherwise it would be redireced
to standard output.

=head2 set_exec('ext', 'string to execute _FILE_')

Defines how programs of a given language must be executed. The B<_FILE_> string
must be present and it would be internally replaced by the corresponding
filename. Example:

 # how a .pl file should be 'executed'
 $judge->set_exec('pl', '/usr/bin/perl _FILE_')
 
 # how a .c file should be executed
 $judge->set_exec('c', './_FILE_');

There are some execution strings by default:

 pl: /usr/bin/perl _FILE_
 c: ./_FILE_
 cpp: ./_FILE_
 py: /usr/bin/python _FILE_

=head2 diff_options(string)

Replace options for diff command. By default are: 'biw'.
The -b argument ignores extra white spaces, the -w ignores 
all white spaces, the -i ignores case differences.

=head2 load_badwords(/path/to/file.txt)

Open the specified file and load the badwords into memory. They must be
separated by commas. This is quite basic and should be enhanced with 
stronger security policies.

Example: system, exec, popen, etc. 

Be aware that system and system() are different words!

=head2 verbose(true/false)

Defines if Progra runs in verbose. If true, it prints out every
processed request to standard output. False by default.

=head2 run(get_sub => &get, update_sub => &update)

Runs the judge. It has two mandatory parameters, C<get_sub> and 
C<update_sub>. Both define the subroutines used to obtain new 
requests and to update processed requests.

Subroutines to obtain new requests must return an array
of hash references:

 (
	 {
		 'rid'	=> 1,
		 'sourcecode' => '/home/progra/users/1/task1.pl'
		 'lang' => 'pl',
		 'compile' => 0,
		 'userpath' => '/home/progra/users/1/',
		 'taskpath' => '/home/progra/tasks/1/',
		 'timelimit' => 1,
		 'testcases' => 10,
		 'maxscore'	=> 100,
	 },
	 {
		 'rid'	=> 2,
		 'sourcecode' => '/home/progra/users/2/task1.c',
		 'lang' => 'c',
		 'compile' => 1,
		 'userpath' => '/home/progra/users/2/'
		 'taskpath' => '/home/progra/tasks/1/',
		 'timelimit' => 1,
		 'testcases' => 20,
		 'maxscore' => 100,
	 }
 )
  

You B<MUST> specify a I<rid>, it identifies the processed request uniquely.

You B<MUST> specify a I<language>. It cannot compile and/or execute a 
source code/program if it does not know its language. The format used is 
according to its source code extension: Perl => pl, C => c, C++ => cpp and
so on. The extension used must be consistent with the ones used in compile
and exec strings.

You B<MUST> specify a I<testcases> number. It has to be consistent with the
test cases you made. If you made ten test cases, they need to be 
named from 0 to 9 with I<input.> and I<output.> prefix, depending on if they 
are input or output files.

If you do not specify a I<maxscore>, it will be 100 by default. This way 
the score obtained for every test case passed will be 100 divided by the
number of test cases.

If you do not specify a I<timelimit>, it will be 1 second by default. 

The compile field specifies if the source code must be compiled or not. False 
if not specified.

You B<MUST> specify a I<sourcecode>, I<userpath> and I<taskpath>. 
Test cases files B<MUST> be inside I<taskpath>. Example:

 -- /home/progra/tasks/1/
 --------------- input.0
 --------------- output.0
 --------------- input.1
 --------------- output.1
 
This represents a directory with I<2> test cases.

Subroutines to update processed requests must receive a hash 
structure like this:

 {
	 'rid' => 1,
	 'grade' => 100,
	 'timemarked' => 1233455,
	 'executiontime' => 0.001,
	 'comment' => 'AC'
 }

The timemarked field is an Unix time stamp, it records the time when the
request was processed. The execution time field is the average execution
time of all test cases. The comment field is a string that represents the
state of the request. The possible values are:

 AC. Accepted, the program passed all test cases.
 WA. Wrong Answer, the program didn't pass all test cases.
 PC. Processing, the source code is in the queue waiting to be processed.
 TL. Time Limit Exceeded, the program ran out of time.
 CE. Compilation Error, there was an error while trying to compile the source code.
 BW: $word. The forbidden word $word was found in the source code.
 IE. Internal Error, something went wrong in progra, check the error.log file.

Note: when a bad/forbidden word is found in the source code or a time limit happens 
when executing it, a directory named "logged" will be created and the source code
that caused the security breach will be saved with the format "requestid_hourmin.ext"

Progra will return the result of a request inmediately after processing it, 
so the update subroutine must receive only one request at a time. Progra will call 
this subroutine for each request processed.


=head1 BUGS

No bugs found so far.

=head1 TODO

There are lots of things to do:

=over

=item Implement some kind of sandbox for safely test and compile.

=item Try with distributed processing.

=item Create working modules that use progra.

=back

=head1 AVAILABILITY

 The latest version of progra is available from CPAN:

 http://search.cpan.org/dist/OnlineJudge-Progra/

 You can also browse the git repository at:

 https://github.com/ileiva/onlinejudge-progra.git
       

=head1 AUTHOR

 israel leiva <ilv AT cpan DOT org>

=head1 COPYRIGHT

 Copyright (c) 2011-2014 israel leiva

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 http://www.gnu.org/licenses/

=cut
