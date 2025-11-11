use strict;
require 5.010;
use feature 'say';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 0};
use Devel::Confess 'color';
use Cwd 'getcwd';
use warnings FATAL => 'all';
package SimpleFlow;
our $VERSION = 0.02;
use Term::ANSIColor;
use Scalar::Util 'openhandle';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 0};
use Devel::Confess 'color';
use Cwd 'getcwd';
use warnings FATAL => 'all';
use Capture::Tiny 'capture';
use Exporter 'import';
our @EXPORT = qw(task);

sub task {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
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
		'input.files',   # check for input files; SCALAR or ARRAY
		'log.fh',        # print to filehandle
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
			(defined $args->{'log.fh'})
			&&
			(not openhandle($args->{'log.fh'}))
		) {
		p $args;
		die "the filehandle given to $current_sub isn't actually a filehandle";
	}
	if (not defined $args->{'log.fh'}) {
		p $args;
		warn "$current_sub didn't receive a filehandle: no logging for the above task will be done.";
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
	say 'The command is ' . colored(['blue on_bright_red'], $args->{cmd});
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
	$args->{'die'}			= $args->{'die'}		// 'true';
	$args->{overwrite}	= $args->{overwrite} // 'false';
	my %r = (
		cmd             => $args->{cmd},
		'die'           => $args->{'die'},
		dir				 => getcwd(),
		overwrite       => $args->{overwrite},
		'output.files' => [@output_files],
	);
	if (defined $args->{'input.files'}) {
		$r{'input.files'} = $args->{'input.files'};
		$r{'input.file.size'} = \%input_file_size;
	}
	my %output_file_size = map {$_ => -s $_} @output_files;
	if (($args->{overwrite} eq 'false') && (scalar @existing_files > 0)) { # this has been done before
		say colored(['black on_green'], "\"$args->{cmd}\"\n") . ' has been done before';
		$r{done} = 'before';
		$r{'output.file.size'} = \%output_file_size;
		p(%r, output => $args->{'log.fh'}, show_memsize => 0) if defined $args->{'log.fh'};
		return \%r;
	}
	($r{stdout}, $r{stderr}, $r{'exit'}) = capture {
		system( $args->{cmd} );
	};
	foreach my $std ('stderr', 'stdout') {
		$r{$std} =~ s/\s+$//; # remove trailing whitespace/newline
	}
	$r{done} = 'now';
	my @missing_output_files = grep {not -f -r $_} @output_files;
	if (scalar @missing_output_files > 0) {
		say STDERR "this input to $current_sub:";
		p $args;
		say STDERR 'has these files missing:';
		p @missing_output_files;
		die 'those above files should be made but are missing';
	}
	%output_file_size = map {$_ => -s $_} @output_files;
#	p %output_file_size;
	my @files_with_zero_size = grep { $output_file_size{$_} == 0} @output_files;
	if (scalar @files_with_zero_size > 0) {
		p @files_with_zero_size;
		warn 'the above output files have 0 size.';
	}
	p(%r, output => $args->{'log.fh'}, show_memsize => 0) if defined $args->{'log.fh'};
	if (($args->{'die'} eq 'true') && ($r{'exit'} != 0)) {
		p %r;
		die "$args->{cmd} failed"
	}
	return \%r;
}
1;
__END__

=encoding utf8

=head1 NAME

SimpleFlow - easy, simple workflow manager (and logger)

=head1 SYNOPSIS

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
