use strict;
require 5.010;
use feature 'say';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 0};
use Devel::Confess 'color';
use Cwd 'getcwd';
use warnings FATAL => 'all';
package SimpleFlow;
our $VERSION = 0.08;
use Time::HiRes;
use Term::ANSIColor;
use Scalar::Util 'openhandle';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 0};
use Devel::Confess 'color';
use Cwd 'getcwd';
use warnings FATAL => 'all';
use Capture::Tiny 'capture';
use Exporter 'import';
our @EXPORT = qw(say2 task);
our @EXPORT_OK = @EXPORT;

sub say2 { # say to both command line and log file
	my ($msg, $fh) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	my @c = caller;
	if (not openhandle($fh)) {
		die "the filehandle given to $current_sub with \"$msg\" from $c[1] line $c[2] isn't actually a filehandle";
	}
	$msg = "\@ $c[1] line $c[2] $msg";
	say $msg;
	say $fh $msg;
}

sub task {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @c = caller;
	my @reqd_args = (
		'cmd', # the shell command
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'die',			  # die if not successful; 0 or 1
		'dry.run',       # dry run or not
		'input.files',   # check for input files; SCALAR or ARRAY
		'log.fh',
		'note',          # a note for the log
		'overwrite',     # 
		'output.files'	  # product files that need to be checked; can be scalar or array
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say "the above arguments are not recognized by $current_sub";
		p @defined_args, array_max => scalar @defined_args;
		die "The above args are accepted by $current_sub";
	}
	if (
			(defined $args->{'log.fh'}) &&
			(not openhandle($args->{'log.fh'}))
		) {
		p $args;
		die "the filehandle given to $current_sub isn't actually a filehandle";
	}
	my (%input_file_size, @existing_files, @output_files);
	if (defined $args->{'input.files'}) {
		my $ref = ref $args->{'input.files'};
		my @missing_files;
		if ($ref eq 'ARRAY') {
			@missing_files = grep {not -f -r $_ } @{ $args->{'input.files'} };
			%input_file_size = map { $_ => -s $_ } @{ $args->{'input.files'} };
		} elsif ($ref eq '') { # scalar
			@missing_files = grep {not -f -r $_ } ($args->{'input.files'});
			%input_file_size = map { $_ => -s $_ } ($args->{'input.files'} );
		} else {
			p $args;
			die 'ref type "' . $ref . '" is not allowed for "input.files"';
		}
		if (scalar @missing_files > 0) {
			say STDERR 'this list of arguments:';
			p $args;
			my $dir = getcwd();
			say STDERR 'Cannot run because these files are either missing or unreadable in: ' . getcwd();
			p @missing_files;
			die 'the above files are missing or are not readable';
		}
	}
	my $msg = "\@ $c[1] line $c[2] The command is:\n" . colored(['blue on_bright_red'], $args->{cmd});
	say $msg;
	say {$args->{'log.fh'}} "\@ $c[1] line $c[2] The command is:\n $args->{cmd})" if defined $args->{'log.fh'};
	if (defined $args->{'output.files'}) { # avoid "uninitialized value" warning
		my $ref = ref $args->{'output.files'};
		if ($ref eq 'ARRAY') {
			@output_files = @{ $args->{'output.files'} };
		} elsif ($ref eq '') { # a scalar
			@output_files = $args->{'output.files'};
		} else {
			p $args;
			die "$ref isn't allowed for \"output.files\"";
		}
	}
	if (scalar @output_files > 0) {
		@existing_files = grep {-f $_} @output_files;
	}
	my %r = (
		cmd            => $args->{cmd},
		dir				=> getcwd(),
		'source.file'  => $c[1],
		'source.line'  => $c[2],
		'output.files' => [@output_files],
	);
	$r{'die'}     = $args->{'die'}     // 1; # by default, true
	$r{'dry.run'} = $args->{'dry.run'} // 0; # by default, false
	$r{note}      = $args->{note}      // '';# by default, false
	$r{overwrite} = $args->{overwrite} // 0; # by default, false
	$r{'will.do'} = 'yes';
	$r{'will.do'} = 'no'  if $args->{'dry.run'};
	if (defined $args->{'input.files'}) {
		$r{'input.files'} = $args->{'input.files'};
		$r{'input.file.size'} = \%input_file_size;
	}
	my %output_file_size = map {$_ => -s $_} @output_files;
	if ((!$args->{overwrite}) && (scalar @output_files > 0) && (scalar @existing_files == scalar @output_files)) { # this has been done before
		$r{done} = 'before';
		$r{'will.do'} = 'no';
		say colored(['black on_green'], "\"$args->{cmd}\"\n") . ' has been done before';
		$r{done} = 'before';
		$r{'output.file.size'} = \%output_file_size;
		p(%r, output => $args->{'log.fh'}) if defined $args->{'log.fh'};
		$r{duration} = 0;
		p %r;
		return \%r;
	} else {
		$r{done} = 'not yet';
	}
	if ($r{'dry.run'}) {
		say "\@ $c[1] line $c[2] the command was going to be:";
		say colored(['red on_black'], "\"$args->{cmd}\"");
		say 'But this is a dry run';
		say '-------------';
		$r{duration} = 0;
		return \%r;
	}
	my $t0 = Time::HiRes::time();
	($r{stdout}, $r{stderr}, $r{'exit'}) = capture {
		system( $args->{cmd} );
	};
	my $t1 = Time::HiRes::time();
	$r{duration} = $t1-$t0;
	foreach my $std ('stderr', 'stdout') {
		$r{$std} =~ s/\s+$//; # remove trailing whitespace/newline
	}
	$r{done} = 'now';
	$r{'will.do'} = 'done';
	my @missing_output_files = grep {not -f -r $_} @output_files;
	if (scalar @missing_output_files > 0) {
		say STDERR "this input to $current_sub:";
		p $args;
		say {$args->{'log.fh'}} "this input to $current_sub:" if defined $args->{'log.fh'};
		p($args, output => $args->{'log.fh'}) if defined $args->{'log.fh'};
		say STDERR 'has these output files missing:';
		say {$args->{'log.fh'}} 'has these output files missing:' if defined $args->{'log.fh'};
		p @missing_output_files;
		p(@missing_output_files, output => $args->{'log.fh'}) if defined $args->{'log.fh'};
		die 'those above files should have been made but are missing';
	}
	%output_file_size = map {$_ => -s $_} @output_files;
#	p %output_file_size;
	my @files_with_zero_size = grep { $output_file_size{$_} == 0} @output_files;
	if (scalar @files_with_zero_size > 0) {
		p @files_with_zero_size;
		warn 'the above output files have 0 size.';
	}
	p(%r, output => $args->{'log.fh'}) if defined $args->{'log.fh'};
	if (($r{'die'}) && ($r{'exit'} != 0)) {
		p %r;
		die "\"$args->{cmd}\" failed from $c[1] line $c[2]"
	}
	p %r;
	return \%r;
}
1;
__END__

=encoding utf8

=head1 NAME

SimpleFlow - easy, simple workflow manager (and logger); for keeping track of and debugging large and complex shell command workflows

=head1 SYNOPSIS

This is similar to snakeMake or NextFlow, but running in Perl.
The simplest use case is

    my $t = task({
        cmd => 'which ls'
    });

All tasks return a hash, showing at a minimum 1) exit code, 2) the directory that the job was done in, 3) stderr, and 4) stdout.

the only required key/argument is `cmd`, but other arguments are possible:

    die          # die if not successful; 'true' or 'false'
    input.files  # check for input files before running; SCALAR or ARRAY
    log.fh       # print to filehandle
    note         # a note for the log
    overwrite    # overwrite previously existing files: "true" or "false"
    output.files # product files that need to be checked; SCALAR or ARRAY

You may wish to output results to a logfile using a previously opened filehandle thus:

    my ($fh, $fname) = tempfile( UNLINK => 0, DIR => '/tmp');
    my $t = task({
        cmd            => 'which ln',
        'log.fh'       => $fh,
        'note'         => 'testing where ln comes from',
        'output.files' => $fname,
        overwrite      => 1
    });
    close $fh;

=head1 Examples

Consider a very complex pipeline in which mistakes are *very* easily made, and there are numerous files to keep track of.  SimpleFlow is designed to simplify these steps with a script, with automated checks at every step, in a very intuitive way:

    my $g_tpr = "3md.$group.tpr";
    task({
    	cmd           => "echo $val | gmx convert-tpr -s 3md.tpr -o $g_tpr -n cpx.ndx",
    	'input.files' => ['3md.tpr', 'cpx.ndx'],
    	'log.fh'      => $log,
    	'output.files'=> $g_tpr, # only do this once
    	overwrite     => 'true'
    });
    my $subset_xtc = "3md.$group.$n.xtc";
    task({
    	cmd            => "echo $val | gmx trjconv -s $g_tpr -f 3md_out$n.xtc -o $subset_xtc -n cpx.ndx",
    	'input.files'  => ["3md_out$n.xtc", $g_tpr],
    	'log.fh'       => $log,
    	'output.files' => $subset_xtc,
    	overwrite      => 'true'
    });
    my $gro = "3md.$group.$n.gro";
    task({
    	'input.files'  => [$g_tpr, $subset_xtc],
    	'log.fh'       => $log,
    	cmd            => "echo $val | gmx trjconv -s $g_tpr -f $subset_xtc -o $gro",
    	'output.files' => $gro,
    	overwrite      => 'true'
    });
    mkdir "xvg/$group" unless -d "xvg/$group";
    my $dir = "xvg/$group/" . sprintf '%u', $n;
    mkdir $dir unless -d $dir;
    task({
    	cmd            => "gmx chi -s $g_tpr -f $subset_xtc -phi -psi -all",
    	'log.fh'       => $log,
    	'input.files'  => [$gro, $subset_xtc],
    	overwrite      => 'true'
    });
    foreach my $f (list_regex_files('\.xvg$')) {
    	rename $f, "$dir/$f";
    	say2("Moved $f to $dir/$f", $log);
    }

Every `task` returns a hash, which is printed to a log if specified:

    {
    cmd               "gmx chi -s 3md.Receptor.tpr -f 3md.Receptor.09.xtc -phi -psi -all",
    die               1,
    dir               "/home/con/ui/pipelinePepPriML/default/2puy",
    done              "now",
    dry.run           0,
    duration          0.0776150226593018,
    exit              0,
    input.file.size   {
        3md.Receptor.09.gro   12874711,
        3md.Receptor.09.xtc   2208928
    },
    input.files       [
        [0] "3md.Receptor.09.gro" (dualvar: 3),
        [1] "3md.Receptor.09.xtc" (dualvar: 3)
    ],
    note              "",
    output.files      [],
    overwrite         "true",
    source.file       "0.sanity.check.pl",
    source.line       73,
    stderr            "                       :-) GROMACS - gmx chi, 2025.3 (-:

    Executable:   /home/con/prog/gromacs-2025.3/build/bin/gmx
    Data prefix:  /home/con/prog/gromacs-2025.3 (source tree)
    Working dir:  /home/con/ui/pipelinePepPriML/default/2puy
    Command line:
      gmx chi -s 3md.Receptor.tpr -f 3md.Receptor.09.xtc -phi -psi -all

    Reading file 3md.Receptor.tpr, VERSION 2025.3 (single precision)
    Reading file 3md.Receptor.tpr, VERSION 2025.3 (single precision)
    Analyzing from residue 1 to residue 61
    60 residues with dihedrals found
    305 dihedrals found
    Reading frame     500 time  500.000   
    j after resetting (nr. active dihedrals) = 179
    Printing psiMET19.x(...skipping 1338 chars...)",
        stdout            "",
        will.do           "done"
    }

