#
# $Id: PP.pm,v 0.1.1.2 2001/12/01 14:03:47 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: PP.pm,v $
# Revision 0.1.1.2  2001/12/01 14:03:47  ram
# patch2: noted that this software is now unmaintained
#
# Revision 0.1.1.1  2001/04/25 12:18:11  ram
# patch1: forgot to expand copyright notice in files
# patch1: updated version number
#
# Revision 0.1  2001/04/25 10:41:48  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Pod::PP;

require Pod::Parser;
use vars qw(@ISA $VERSION);
@ISA = qw(Pod::Parser);

$VERSION = '0.102';

use Carp::Datum;
use Log::Agent;
use Getargs::Long;
use File::Basename;

require Pod::PP::Env;
require Pod::PP::State;

use Pod::PP::State::Info;

my $MAX_EXPANSION = 100;		# Maximum levels of recursive P<> expansion

#
# ->make
#
# Creation routine
#
sub make {
	DFEATURE my $f_;
	my $pkg = shift;
	my ($incpath, $symbols) = getargs(@_,
		qw(incpath=ARRAY symbols=HASH));

	my $self = bless Pod::Parser->new(), $pkg;
	$self->{file_env} = Pod::PP::Env->make($incpath, $symbols);

	$self->init_parser();

	#
	# Don't initialize env, it will be done in parse_from_*() routines.
	#

	return DVAL $self;
}

#
# Attribute access
#

sub env			{ $_[0]->{env} }
sub ifstate		{ $_[0]->{ifstate} }
sub file_env	{ $_[0]->{file_env} }
sub exp_level	{ $_[0]->{exp_level} }
sub exp_symbol	{ $_[0]->{exp_symbol} }
sub exp_podinfo	{ $_[0]->{exp_podinfo} }
sub begin_start	{ $_[0]->{begin_start} }
sub begin_data	{ $_[0]->{begin_data} }

###
### Pod::PP interface
###

#
# ->parse_from_filehandle		-- redefined
#
# Intitial pre-processing.
# Resets the environment at the start of a new file.
#
sub parse_from_filehandle {
	DFEATURE my $f_;
	my $self = shift;

	#
	# This feature may be called either directly, or via
	# SUPER::parse_from_file(), which call parse_from_filehandle()
	# on the opened file.
	#
	# Therefore, we must lazily initialize the environment, because
	# we could come from subparse_from_file(), where the environment is
	# already there.
	#

	$self->init_env() unless $self->env;
	$self->SUPER::parse_from_filehandle(@_);

	return DVOID;
}

#
# ->subparse_from_file
#
# This is used to pre-process another file using the same environment,
# so that any define/undef in there impacts us also.  Typically for
# "include" statements.
#
sub subparse_from_file {
	DFEATURE my $f_;
	my $self = shift;
	my ($file) = @_;

	my $clone = bless Pod::Parser->new(), ref $self;
	$clone->init_parser();
	$clone->{env} = $self->env;				# Share environment object
	$clone->SUPER::parse_from_file($file);	# Hence we don't want init_env()!

	return DVOID;
}

###
### Pod::Parser callbacks
###

#
# ->begin_input
#
# Pod::Parser callback at the beginning of each file.
#
sub begin_pod {
	DFEATURE my $f_;
	my $self = shift;

	#
	# We can't recurse via an "=for pp include" whilst we're in a begin.
	# Assert that.
	#

	DASSERT !$self->begin_start;
	DASSERT $self->begin_data eq '';

	return DVOID;
}

#
# ->end_input
#
# Pod::Parser callback at the end of each file.
#
sub end_input {
	DFEATURE my $f_;
	my $self = shift;

	#
	# Reset the if/elif/else/endif stack.  Will warn on pending "if".
	#

	$self->ifstate->reset();

	#
	# Make sure that we're not in the middle of an "=begin pp" directive...
	# If we are, warn them and discard collected data.
	#

	my $bstart = $self->begin_start;
	return DVOID unless $bstart;

	my ($which, $podinfo) = @{$bstart};
	my ($file, $line) = $podinfo->file_line();

	logwarn "no =end for \"=begin pp $which\" started at \"%s\", line %d",
		$file, $line;

	#
	# Discard, discard!
	#

	$self->{begin_start} = undef;	# Start of last =begin pp
	$self->{begin_data} = '';		# Stuff seen in begin block

	return DVOID;
}

#
# Flow control commands -- must always be interpreted, whatever the state
#
my %PP_flow = (
	'ifdef'		=>	'pp_ifdef',
	'ifndef'	=>	'pp_ifndef',
	'if'		=>	'pp_if',
	'elif'		=>	'pp_elif',
	'else'		=>	'pp_else',
	'endif'		=>	'pp_endif',
);

#
# Symbol manipulation commands -- don't go through interpolate()
#
my %PP_sym = (
	%PP_flow,
	'define'	=>	'pp_define',
	'undef'		=>	'pp_undef',
);

#
# Supported Pod::PP directives:
#
my %PP = (
	%PP_sym,
	'require'	=>	'pp_require',
	'include'	=>	'pp_include',
	'image'		=>	'pp_image',
	'comment'	=>	'pp_comment',
);

#
# ->command
#
# Pod::Parser callback on "=" or "==" commands.
#
# We're only interested in "for/begin/end pp" and "pp" commands, and leave
# the others intact.
#
sub command {
	DFEATURE my $f_;
	my $self = shift;
	my ($command, $paragraph, $line, $podinfo) = @_;

	my $ok = $self->ifstate->state == POD_PP_STATE_OK;

	#
	# Buffer input if we're within a begin
	#

	my $begin = $self->begin_start;
	if ($begin) {
		my $pp = '';
		$pp = $1 if $paragraph =~ s/^(pp\s+)//;
		(my $now = $paragraph) =~ s/(?:\r?\n)?\r?\n$//s;

		if ($command eq 'end' && length $pp) {

			#
			# Finishing already started command?
			#

			my ($which, $podinfo, $ppcmd, $options) = @$begin;

			if ($which eq $now) {		
				#
				# We found the end of your "=begin pp" command.
				#
				# Fine, but execute it only if we're in the OK state
				# or if it's a control flow command (if/else/endif).
				#

				$self->pp($ppcmd, $options, $self->begin_data, $podinfo)
					if $ok || exists $PP_flow{$ppcmd};

				$self->{begin_start} = undef;
				$self->{begin_data} = '';

				return DVOID;
			}

			# Fall through
		}

		#
		# Still within begin... buffer data.
		#

		$self->{begin_data} .= "=$command $pp$now\n\n";

		return DVOID;
	}

	if (
		 $command =~ /^pp$/ ||
		($command =~ /^(?:for|begin)$/ && $paragraph =~ s/^pp\s+//)
	) {

		#
		# A "=begin pp" is deferred up to the point where we reach the
		# matching =end.
		#

		if ($command eq 'begin') {
			DASSERT !$self->begin_start, "nested =begin are not processed";

			(my $now = $paragraph) =~ s/(?:\r?\n)?\r?\n$//s;
			$begin = $self->{begin_start} = [$now, $podinfo];
		}

		#
		# Proper format is "=for pp command" or "=pp command"
		#
		# An interpolation pass is done on the remaining of the line to
		# expand interior sequences, unless command is flagged for no
		# interpolation (symbol manipulation commands).
		#
		# Each command may be followed by options, held within <> and
		# immediately following the command name, as in:
		#
		#   =pp image <center> "file.png"
		#
		# The options are defined on a command basis.  Various options are
		# separated via spaces, just like within SGML tags.
		#

		if ($paragraph =~ s/^(\w+)\s*//) {
			my $ppcmd = $1;
			$paragraph = $self->interpolate($paragraph, $line)
				unless exists $PP_sym{$ppcmd};

			my $options = '';
			$options = $1 if $paragraph =~ s/^<(.*?)>\s*//;

			#
			# An =begin is not executed right now...
			# The command parameters will be what follows till the =end.
			#

			if ($begin) {
				my ($file, $line) = $podinfo->file_line;
				$paragraph =~ s/(?:\r?\n)+$//s;
				$self->{begin_data} = $paragraph . " ";
				push @$begin, ($ppcmd, $options);
				return DVOID;
			}

			#
			# Commands are only executed if we're in the OK state, or when
			# it's a control flow one (if/else/endif).
			#

			$self->pp($ppcmd, $options, $paragraph, $podinfo)
				if $ok || exists $PP_flow{$ppcmd};

			return DVOID;
		}

		my ($file, $line) = $podinfo->file_line;
		logwarn "ignoring badly formed Pod::PP directive at \"%s\", line %d",
			$file, $line;

		# Fall through...
	}

	return DVOID unless $ok;
	
	#
	# Since we pre-process, normalize output with a single "="
	# and add trailing "\n" if necessary (command started with "==")
	#

	my $out = $self->output_handle();
	print $out "=$command";
	print $out length $paragraph ?
		(" " . $self->interpolate($paragraph, $line)) : "\n";
	print $out "\n" unless $paragraph =~ /\r?\n\r?\n/s;

	return DVOID;
}

#
# ->interior_sequence
#
# Pod::Parser callback on [A-Z]<> commands
# We're only interested in processing P<> sequences and leave the others as-is.
#
sub interior_sequence {
	DFEATURE my $f_;
	my $self = shift;
	my ($seq_command, $seq_argument, $podinfo) = @_;

	return DVOID unless $self->ifstate->state == POD_PP_STATE_OK;

	return DVAL $podinfo->raw_text() unless $seq_command eq 'P';
	return DVAL $self->recursive_expansion($seq_argument, $podinfo);
}

#
# ->verbatim
#
# Pod::Parser callback on verbatim paragraph
# Stuff if in begin_data if we're within a begin.
#
sub verbatim {
	DFEATURE my $f_;
	my $self = shift;
	my ($paragraph, $line, $podinfo) = @_;

	return DVOID unless $self->ifstate->state == POD_PP_STATE_OK;

	if ($self->begin_start) {
		$self->{begin_data} .= $paragraph;
	} else {
		my $out = $self->output_handle();
		print $out $paragraph;
	}

	return DVOID;
}

#
# ->textblock
#
# Pod::Parser callback on text block
# Stuff if in begin_data if we're within a begin.
#
sub textblock {
	DFEATURE my $f_;
	my $self = shift;
	my ($paragraph, $line, $podinfo) = @_;

	return DVOID unless $self->ifstate->state == POD_PP_STATE_OK;

	if ($self->begin_start) {
		$self->{begin_data} .= $paragraph;
	} else {
		my $out = $self->output_handle();
		print $out $self->interpolate($paragraph, $line);
	}

	return DVOID;
}


###
### Pre-processing callbacks
###

#
# ->pp
#
# A Pod pre-processor command.
# Dispatch to relevant routine.
#
sub pp {
	DFEATURE my $f_;
	my $self = shift;
	my ($command, $options, $paragraph, $podinfo) = @_;

	DREQUIRE defined $self->{env},
		"has called preprocess_from_*() to start with on $self";

	my $routine = $PP{$command};
	my $what;
	my $error;
	chomp $paragraph;				# Strip trailing end-paragraph marker

	#
	# Each processing routine is given the following arguments:
	#
	#  $opts          a list ref, containing all the options
	#  $paragraph     the text containg the command arguments
	#  $podinfo       the Pod::Parser location object
	#
	# Routines are expected to return an empty string if OK, or an error
	# message if something goes wrong.
	#

	if (defined $routine) {
		my @opts = split(/\s+/, $options);
		$error = $self->$routine(\@opts, $paragraph, $podinfo);
		return DVOID unless $error;
		$what = "failed: $error";
	} else {
		$what = "ignored";
	}

	#
	# Flag unknown/failed command, and let it go through as-is.
	#

	my ($file, $line) = $podinfo->file_line;
	if (defined $error) {
		logerr "error in Pod::PP directive '%s' at \"%s\", line %d: %s",
			$command, $file, $line, $error;
	} else {
		logwarn "unknown Pod::PP directive '%s' at \"%s\", line %d",
			$command, $file, $line;
	}

	my $out = $self->output_handle();
	my $cmd = $podinfo->cmd_name();
	$paragraph =~ s/^/\t/gm;			# Indent whole paragrah
	$paragraph =~ s/^\t//s;				# But remove initial tab

	printf $out "=for pp comment (at \"%s\", line %d):\n", $file, $line;
	printf $out "\tFollowing \"=$cmd\" directive $what\n";
	printf $out "\t=%s $command", $cmd eq 'pp' ? $cmd : "$cmd pp";
	print $out " <$options>" if $options ne '';
	print $out length $paragraph ? " $paragraph" : "\n";
	print $out "\n" unless $paragraph =~ /\r?\n\r?\n$/s;

	return DVOID;
}

#
# ->pp_comment
#
# Process a "comment" directive.
#
sub pp_comment {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	return DVAL '';		# Comment ignored
}

#
# ->pp_include
#
# Process an "include" directive.
#
sub pp_include {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my ($file, $line) = $podinfo->file_line;
	return DVAL "no filename found" unless $paragraph =~ /^"(.*)"/;

	my $incfile = $self->env->lookup_file($file, $1);
	return DVAL "cannot find \"$1\"" unless $incfile;

	$self->subparse_from_file($incfile);

	return DVAL '';					# OK
}

#
# ->pp_require
#
# Process a "require" directive.
# Like "include", but done once per file.
#
sub pp_require {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my ($file, $line) = $podinfo->file_line;
	return DVAL "no filename found" unless $paragraph =~ /^"(.*)"/;

	my $env = $self->env;
	my $incfile = $env->lookup_file($file, $1);
	return DVAL "cannot find \"$1\"" unless $incfile;

	return DVAL '' if $env->is_parsed($incfile);
	$env->set_is_parsed($incfile);

	$self->subparse_from_file($incfile);

	return DVAL '';					# OK
}

#
# ->pp_define
#
# Process a "define" directive.
#
sub pp_define {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	return DVAL "no symbol found" unless $paragraph =~ s/^(\w+)\s*//;

	my $symbol = $1;
	my $env = $self->env;

	if ($env->is_defined($symbol)) {
		my ($file, $line) = $podinfo->file_line;
		logwarn "redefining Pod::PP symbol '%s' at \"%s\", line %d",
			$symbol, $file, $line;
	}

	chomp $paragraph;
	$env->define($symbol, $paragraph);

	return DVAL '';					# OK
}

#
# ->pp_undef
#
# Process an "undef" directive.
#
sub pp_undef {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	return DVAL "no symbol found" unless $paragraph =~ /^(\w+)\s*/;

	$self->env->undefine($1);
	return DVAL '';					# OK
}

#
# ->pp_image
#
# Process an "image" directive.
#
sub pp_image {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my ($file, $line) = $podinfo->file_line;
	return DVAL "no filename found" unless $paragraph =~ /^"(.*)"/;

	my $src = $1;
	my $alt = basename $src;
	$alt =~ s/\.\w+$//;

	my $align = "";
	$align = ' ALIGN="right"' if grep($_ eq "right", @$opts);	# XXX use hash
	$align = ' ALIGN="center"' if grep($_ eq "center", @$opts);	# XXX use hash

	my $out = $self->output_handle();
	my $str = <<EOS;
:=for html <P$align><IMG SRC="$src" ALT="$alt"></P>

:=begin text

 [image "$src" not rendered]

:=end text

EOS
	$str =~ s/^://gm;		# POD directives protected for trivial parsers
	print $out $str;

	return DVAL '';
}

###
### State machine for if/elif/else/endif
###

#
# _pp_test_symbol
#
# Handle "if(n)def SYMBOL" condition.
#
sub _pp_test_symbol {
	DFEATURE my $f_;
	my $self = shift;
	my ($def, $paragraph, $podinfo) = @_;

	my $ifstate = $self->ifstate;
	my $cmd = $def ? "ifdef" : "ifndef";

	if ($ifstate->state != POD_PP_STATE_OK) {
		# Skip till matching "endif"
		$ifstate->push($cmd, POD_PP_STATE_ENDIF, $podinfo);
		return DVOID;
	}

	unless ($paragraph =~ s/^(\w+)\s*//) {
		my ($file, $line) = $podinfo->file_line();
		logwarn "no Pod::PP symbol found for 'if%sdef' at \"%s\", line %d",
			$def ? "" : "n", $file, $line;
		# Skip till matching "else"/"endif"
		$ifstate->push($cmd, POD_PP_STATE_ALT, $podinfo);
		return DVOID;
	}

	my $symbol = $1;
	my $test = $self->env->is_defined($symbol);
	$test = !$test unless $def;
	$ifstate->push($cmd, $test ? POD_PP_STATE_OK : POD_PP_STATE_ALT, $podinfo);

	return DVOID;
}

#
# pp_ifdef
#
# Handle "ifdef SYMBOL" condition.
#
sub pp_ifdef {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	return DVAL $self->_pp_test_symbol(1, $paragraph, $podinfo);
}

#
# pp_ifndef
#
# Handle "ifndef SYMBOL" condition.
#
sub pp_ifndef {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	return DVAL $self->_pp_test_symbol(0, $paragraph, $podinfo);
}

#
# pp_if
#
# Handle "if expr" condition
#
sub pp_if {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my $ifstate = $self->ifstate;
	if ($ifstate->state != POD_PP_STATE_OK) {
		# Skip till matching "endif"
		$ifstate->push(POD_PP_STATE_ENDIF, $podinfo);
		return DVOID;
	}

	my $test = $self->env->evaluate($paragraph, $podinfo);
	$ifstate->push("if",
		$test ? POD_PP_STATE_OK : POD_PP_STATE_ALT, $podinfo);

	return DVOID;
}

#
# pp_elif
#
# Handle "elif expr" condition
#
sub pp_elif {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my $ifstate = $self->ifstate;
	my $state = $ifstate->state;

	if (
		$state == POD_PP_STATE_OK ||		# We kept last "if"/"elif"
		$state == POD_PP_STATE_ENDIF		# Skip anyway
	) {
		$ifstate->replace(POD_PP_STATE_ENDIF, $podinfo);
		return DVOID;
	}
	my $test = $self->env->evaluate($paragraph, $podinfo);
	$ifstate->replace("elif",
		$test ? POD_PP_STATE_OK : POD_PP_STATE_ALT, $podinfo);

	return DVOID;
}

#
# pp_else
#
# Handle "else" instruction
#
sub pp_else {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my $ifstate = $self->ifstate;
	my $test = $ifstate->state == POD_PP_STATE_ALT;
	$ifstate->replace("else",
		$test ? POD_PP_STATE_OK : POD_PP_STATE_ENDIF, $podinfo);
}

#
# pp_endif
#
# Handle "endif" instruction
#
sub pp_endif {
	DFEATURE my $f_;
	my $self = shift;
	my ($opts, $paragraph, $podinfo) = @_;

	my $ifstate = $self->ifstate;
	$ifstate->pop($podinfo);
}

###
### Internal calls
###

#
# init_parser
#
# Initialize per-parser data.
#
sub init_parser {
	DFEATURE my $f_;
	my $self = shift;

	$self->{begin_start} = undef;	# Start of last =begin pp
	$self->{begin_data} = '';		# Stuff seen in begin block

	$self->{ifstate} = Pod::PP::State->make();

	return DVOID;
}

#
# ->init_env
#
# Initialize pre-processing environment.
#
sub init_env {
	DFEATURE my $f_;
	my $self = shift;

	$self->{env} = $self->file_env->clone();
	$self->{exp_level} = 0;

	return DVOID;
}

#
# ->recursive_expansion
#
# Expand `sym' as a symbol then call interpolate on the result.
# We limit the maximum recursion to $MAX_EXPANSION to be able to flag loops.
#
sub recursive_expansion {
	DFEATURE my $f_;
	my $self = shift;
	my ($sym, $podinfo) = @_;

	my $env = $self->env;
	my $level = $self->{exp_level};
	unless ($level) {
		$self->{exp_symbol} = $sym;
		$self->{exp_podinfo} = $podinfo;
	}
	my ($file, $line) = $self->exp_podinfo->file_line();

	unless ($env->is_defined($sym)) {
		logwarn "using undefined Pod::PP symbol '%s' at \"%s\", line %d",
			$sym, $file, $line;
		return DVAL '';
	}

	my $text = $env->symbol_value($sym);

	if ($level > $MAX_EXPANSION) {
		logwarn "endless expansion for Pod::PP symbol '%s' at \"%s\", line %d",
			$self->exp_symbol, $file, $line;
		return DVAL $text;
	}

	$self->{exp_level}++;
	$text = $self->interpolate($text, $line);
	$self->{exp_level}--;

	return DVAL $text;
}

1;

=head1 NAME

Pod::PP - POD pre-processor

=head1 SYNOPSIS

 # normally used via the podpp script

 require Pod::PP;

 my $pp = Pod::PP->make(
     -incpath   => ['h', 'h/sys'],
     -symbols   => { DIR => "/var/www", TMPDIR => "/var/tmp" },
 );

 $pp->parse_from_filehandle(\*STDIN);
 $pp->parse_from_file("file.pp");

=head1 DESCRIPTION

The C<Pod::PP> module is a POD pre-processor  built on top of C<Pod::Parser>.
The helper script B<podpp> provides a pre-processor command for POD, 
whose interface is very much like B<cpp>, the C pre-processor.
However, unlike C, the C<Pod::PP> processing is not normally invoked when
parsing POD.

If you wish to automate the pre-processing for every POD file, you need to
write C<.pp> files (say) instead of C<.pod> files, and add the following
B<make> rules to your C<Makefile>:

    PODPP = podpp
    PP_FLAGS =

    .SUFFIXES: .pp .pod

    .pp.pod:
        $(PODPP) $(PP_FLAGS) $< >$*.pod

Those teach B<make> how to derive a C<.pod> from a C<.pp> file using
the B<podpp> pre-processor.

C<Pod::PP> uses the C<PE<lt>E<gt>> notation to request symbol expansion.
Since it processes text, you need to tag the symbols to be expanded
explicitely.  Expansion is done recursively, until there is no more
expansion possible.

If you are familiar with B<cpp>, most directives will be easy to grasp.
For instance, using the C<==> prefix to make shorter commands:

    ==pp include "common.pp"

    ==pp define DIR     /var/www
    ==pp define TMP     /tmp

    ==pp ifdef SOME_COMMON_SYMBOL
    ==pp define FOO     common foo
    ==pp else
    ==pp define FOO     P<DIR>
    ==pp endif

The C<==> notation is not standard POD, but it is understood by C<Pod::Parser>
and very convenient when it comes to writing things like the above block,
because there's no need to separate commands by blank lines.
Since the code is going to be processed by B<podpp> anyway, there's no problem,
and B<podpp> will always emit legitimate POD.  That is, given the following:

    ==head1 NAME
    Some data

it will re-emit:

    =head1 NAME

    Some data

thereby normalizing the output.  It is guaranteed that after a B<podpp> pass,
the output is regular POD.  If you make errors in writing the C<Pod::PP>
directives, you will not get the expected output, but it will be regular POD.

=head1 DIRECTIVES

The pre-processing directives can be given in two forms, depending on
whether you wish to process your POD files containing C<Pod::PP> directives
with the usual POD tools before or after having run B<podpp> on them:

=over 4

=item *

By using the C<=for pp> form before all commands, you ensure that regular
POD tools will simply ignore those.  This might result in incorrect
processing though, if you depend on the definition of some symbols to
produce different outputs (i.e. you would need a B<podpp> pass anyway).

=item *

By using the C<=pp> form before all commands, you require that B<podpp>
be run on your file to produce regular POD that can be then processed
via regular POD tools.

=back

Here are the supported directives, in alphabetical order:

=over 4

=item C<=pp comment> I<comment>

A comment.  Will be stripped out upon reading.

When C<Pod::PP> encounters an error whilst processing a directive, e.g.
an include with a file not found, it will leave a comment in the output,
albeit using the C<=for pp> form so that it is properly ignored by standard
POD tools.

=item C<=pp define> I<symbol> [I<value>]

Defines I<symbol> to be I<value>.  If there's no I<value>, the symbol is
simply defined to an empty value.  There may be an arbitrary amount of
spaces or tabs between I<symbol> and I<value>.

A symbol can be tested for defined-ness via C<=pp ifdef>, used in expressions
via C<=pp if>, or expanded via C<PE<lt>I<sym>E<gt>>.

=item C<=pp elif> I<expr>

Alternate condition.  There may be as many C<=pp elif> as needed, but they
must precede any C<=pp else> directive, and follow a leading C<=pp if> test.
See C<=pp if> below for the I<expr> definiton.

Naturally, within an C<=pp if> test, the expression I<expr> is evaluated only
if the C<if> condition was false.

=item C<=pp else>

The I<else> clause of the C<=pp if> or C<=pp ifdef> test.

=item C<=pp endif>

Closes the testing sequence opened by last C<=pp if> or C<=pp ifdef>.

=item C<=pp if> I<expr>

Starts a conditional text sequence.  If I<expr> evaluates to I<true>, the
remaining up to the matching C<=pp elif> or C<=pp else> or C<=pp endif>
is included in the output, otherwise it is stripped.

Within an expression, you may include any symbol, verbatim, and form any legal
Perl expression.  For instance:

    ==pp define X 4
    ==pp define LIMIT 100

    =pp if X*X < LIMIT

    Include this portion if X*X < LIMIT

    =pp else

    Include this portion if X*X >= LIMIT

    =pp endif

would yield, when processed by B<podpp>:

    Include this portion if X*X < LIMIT

since the condition is true with the current symbol values.

You may also use the C<defined()> operator in tests, as in B<cpp>:

    =pp if defined(X) || !defined(LIMIT)

A bad expression will result in an error message, but you must know that
your expressions are converted into Perl, and then are evaluated within
a C<Safe> compartment: the errors will be reported relative to the translated
Perl expressions, not to your original expressions.

=item C<=pp ifdef> I<symbol>

Tests whether a symbol is defined.  This is equivalent to:

    =pp if defined(symbol)

only it is shorter to say.

=item C<=pp ifndef> I<symbol>

Tests whether a symbol is not defined.  This is equivalent to:

    =pp if !defined(symbol)

but it is shorter to say.

=item C<=pp image> [I<E<lt>centerE<gt>>] "I<path>"

This directive is not a regular pre-processing directive in that it is
highly specialized.  It's there because I historically implemented C<Pod::PP>
to pre-process that command in my PODs.

It's a high-level macro, that is hardwired because C<Pod::PP> is not rich
enough yet to be able to support the definition of that kind of macro.

It is expanded into two POD directives: one for HTML, one for text.
An example will be better than a lengthy description:

    =pp image <center> "logo.png"

will expand into:

    =for html <P ALIGN="center"><IMG SRC="logo.png" ALT="logo"></P>

    =begin text

     [image "logo.png" not rendered]

    =end text

The I<E<lt>centerE<gt>> tag is optional, and you may use I<E<lt>rightE<gt>>
instead to right-justify your image in HTML.

=item C<=pp include> "I<file>"

Includes C<"file"> at the present location, through C<Pod::PP>.  That is,
the included file may itself use C<Pod::PP> directives.

The algorithm to find the I<file> is as follows:

1. The file is first looked for from the location of the current file being
processed.

2. If not found there, the search path is traversed.  You may supply a search
path with the B<-I> flag in B<podpp> or via the C<-incpath> of the
creation routine for C<Pod::PP>.

3. If still not found, an error is reported.

=item C<=pp require> "I<file>"

Same as an C<=pp include> directive, but the C<"file"> is included only
B<once>.  The absolute path of the file is used to determine whether it
has already been included.  For example, assuming we're in file C<dir/foo>,
and that C<dir/foo/file.pp> exists, the following:

    ==pp require "file.pp"
    ==pp require "../dir/file.pp"

will result in only B<one> inclusion of C<"file.pp">, since both I<require>
statements end up requesting the inclusion of the same path.

=item C<=pp undef> I<symbol>

Undefines the target I<symbol>.

=back

=head1 DIAGNOSTICS

C<Pod::PP> uses C<Log::Agent> to emit its diagnostics.  The B<podpp> script
leaves C<Log::Agent> in its default configuration, thereby redirecting all
the errors to STDERR.  If you use the C<Pod::PP> interface directly in a
script, you can look at configuring alternatives for the logs in L<Log::Agent>.

Whenever possible, C<Pod::PP> leaves a trail in the output marking the error.
For instance, feeding the following to B<podpp>:

    =pp include "no-such-file"

would print the following error to STDERR:

    podpp: error in Pod::PP directive 'include' at "example", line 17:
        cannot find "no-such-file"

and leave the following trail:

    =for pp comment (at "example", line 17):
        Following "=pp" directive failed: cannot find "no-such-file"
        =pp include "no-such-file"

which will be ignored by all POD tools.

=head1 INTERFACE

You will normally don't care, since you will be mostly interfacing with
C<Pod::PP> via the B<podpp> script.  This section is therefore only useful
for people wishing to use C<Pod::PP> from within a program.

Since C<Pod::PP> inherits from C<Pod::Parser>, it conforms to its
interface, in particular for the C<parse_from_filehandle()> and
C<parse_from_file()> routines.  See L<Pod::Parser> for more information.

The creation routine C<make()> takes the following mandatory arguments:

=over 4

=item C<-incpath> => I<array_ref>

The additional include search path (C<"."> is always part of the search path,
and always the first thing looked at).  The I<array_ref> provides a list
of directories to look.  For instance:

    -incpath    => ["h", "/home/ram/usr/podpp"]

would add the two directories, in the order given.

=item C<-symbols> => I<hash_ref>

Provides the intial set of defined symbols.  Each key from the I<hash_ref>
is a symbol for the pre-processor:

    -symbols    => {
        DIR     => "/var/tmp"
        TMP     => "/tmp"
    }

Given the above, the following input:

    dir is "P<DIR>" and tmp is "P<TMP>"

would become after processing:

    dir is "/var/tmp" and tmp is "/tmp"

as expected.

=back

=head1 BUGS

The C<=pp image> directive is a hack.  It should not be implemented at this
level, but it was convenient to do so.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

This software is currently unmaintained.  Please look at:

 http://www.unmaintained-free-software.org/

if you wish to take over maintenance.  I would appreciate being notified,
so that I can transfer the PAUSE (CPAN) ownership to you.

=head1 SEE ALSO

Pod::Parser(3).

