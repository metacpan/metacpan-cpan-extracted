package Pb;

use 5.14.0;
use warnings;
use autodie ':all';

our $VERSION = '0.01'; # VERSION

use Exporter;
our @EXPORT =
(
	qw< command base_command flow >,				# base structure of the command itself
	qw< arg opt must_be one_of also >,				# for declaring command arguments and options
	qw< log_to control_via >,						# attributes of the command
	qw< verify SH CODE RUN >,						# keywords inside a flow
	qw< $FLOW %OPT >,								# variable containers that flows need access to
	qw< pwd >,										# pass-through from PerlX::bash
);

use Moo;
use CLI::Osprey;

use Safe::Isa;
use Type::Tiny;
use PerlX::bash			qw< bash pwd >;
use Import::Into;
use Sub::Install		qw< install_sub >;
use File::Basename;

use Pb::Command::Context;


sub import
{
	my $caller = caller;
	_setup_signal_handlers();
	strict->import::into($caller);
	warnings->import::into($caller);
	feature->import::into($caller, ':5.14');
	autodie->import::into({level=>1}, ':all');		# `autodie` requires a bit of magic ...
	goto \&Exporter::import;
}


# This is a global, sort of ... it has a global lifetime, certainly, but not global visibility.
# Think of it like a singleton.  Most of our methods can either be called as object methods, in
# which case they operate on the object invocant, or just as straight functions, in which case they
# operate on this guy.  `$CMD` is set by `Pb->go` (which is down at the very bottom of this file).
my $CMD;

# And this is how we implement that optional invocant.
sub _pb_args { $_[0]->$_can('_osprey_config') ? @_ : ($CMD, @_) }


###################
# CONTEXT OBJECTS #
###################

# This will be cloned and have command-specific values added to it when the flow executes.
our $FLOW = Pb::Command::Context->new;

our %OPT;											# key == option name, value == option value
our %CONTROL;										# key == command name, value == control structure


##################
# GLOBAL OPTIONS #
##################

option pretend =>
(
	is => 'ro', doc => "don't run commands; just print them",
);


###############
# SCAFFOLDING #
###############

# this will hold all the different flows
my %FLOWS;

# this is for the `base_command` (if there is one)
my $BASE_CMD;


# This takes an option def (i.e. a hashref built from the properties of an `opt` clause) and turns
# it into the arguments to an `option` call (`option` is defined by CLI::Osprey).
sub _option_args
{
	my $def = shift;
	my %props = ( is => 'ro' );
	unless ( $def->{type}->is_a_type_of('Bool') )
	{
		$props{format} = 's';
	}
	return $def->{name} => %props;
}

# This builds subcommands.  If it weren't for the fact that we need our subcommands to be able to
# have their own options, we could simply do `subcommand $name => $cmd`.  However, that creates an
# object of class CLI::Osprey::InlineSubcommand, and those can't have options. :-(
sub _install_subcommand
{
	my ($name, $action, $optdefs) = @_;
	my $pkg = $name =~ s/-/_/r;
	fatal("illegal command name [$name]") if $pkg !~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/;
	$pkg = "Pb::Subcommand::$pkg";
	eval "package $pkg { use Moo; use CLI::Osprey; }";
	install_sub({ code => $action, into => $pkg, as => 'run' });

	# handle options
	my $option = $pkg->can('option') // die("Can't install options into subcommand package! [$name]");
	$option->( _option_args($_) ) foreach @$optdefs;

	# NOTE: can pass a `desc =>` to the `subcommand` (useful for help?)
	subcommand $name => $pkg;
}

# This build the "base command," which is really just the default subcommand.
sub _install_base_command
{
	my ($action, $optdefs) = @_;
	option( _option_args($_) ) foreach @$optdefs;
	$BASE_CMD = $action;
}


# This guarantees that `END` blocks are not only called when your program `exit`s or `die`s, but
# also when it's terminated due to a signal (where possible to catch).  This is super-important for
# things like making sure pidfiles get cleaned up.  I'm pretty sure that the only times your `END`
# blocks won't get called if your program exits after this runs is for uncatchable signals (i.e.
# `KILL`) and if you call `exec`.  I'd worry more about that latter one, but it seems pretty
# unlikely in a Leadpipe context.
sub _setup_signal_handlers
{
	# This list compiled via the following methodology:
	#	*	Examine the signal(7) man page on a current (at the time) Linux version (this one just
	#		so happened to be Linux Mint 18.2, kernel 4.10.0-38-generic).
	#	*	Find all signals which are labeled either "Term" or "Core" (i.e. all signals which will
	#		actually cause your process to exit).
	#	*	Eliminate everything already in sigtrap.pm's "normal-signals" list.
	#	*	Eliminate everything already in sigtrap.pm's "error-signals" list.
	#	*	Eliminate "KILL," because you can't catch it anyway.
	#	*	Eliminate "USR1" and "USR2" on the grounds that we shouldn't assume anything about
	#		"user-defined signals."
	#	*	Whatever was leftover is the list below.
	my @EXTRA_SIGNALS = qw< ALRM POLL PROF VTALRM XCPU XFSZ IOT STKFLT IO PWR LOST UNUSED >;
	require sigtrap;
	# Because of the `untrapped`, this won't bork any signals you've previously set yourself.
	# Signals you _subsequently_ set yourself will of course override these.
	sigtrap->import( handler => sub
		{
			my $signal = shift;
			# Weirdly (or maybe not so much; I dunno), while `END` blocks don't get called if a
			# `'DEFAULT'` signal handler leads to an exit, they _do_ for custom handlers.  So this
			# `sub` literally doesn't need to do _anything_.  But, hey: while we're here, may as
			# well alert the user as to what's going down.
			$FLOW->raise_error("terminated due to signal $signal");
			say STDERR "received signal: $signal";
		},
		untrapped => 'normal-signals', 'error-signals',
		grep { exists $SIG{$_} } @EXTRA_SIGNALS
	);
}


#####################
# COMMAND STRUCTURE #
#####################


sub command
{
	state $PASSTHRU_ARGS = { map { $_ => 1 } qw< log_to flow > };
	state $CONTEXT_VAR_XLATE = { LOGFILE => 'log_to', };
	my $name = shift;

	# these are all used in the closure below
	my %args;										# arguments to this command definition
	my $argdefs = [];								# definition of args to the command invocation
	my $optdefs = [];								# definition of opts to the command invocation
	# process args: most are simple, some are trickier
	while (@_)
	{
		if ($PASSTHRU_ARGS->{$_[0]})
		{
			my $arg = shift;
			$args{$arg} = shift;
		}
		elsif ($_[0] eq 'arg')
		{
			shift;									# just the 'arg' marker
			fatal("base commands cannot take arguments (try an option instead)") if $name eq ':DEFAULT';
			my $arg = {};
			$arg->{name} = shift;
			$arg->{type} = shift;
			fatal("not a constraint [" . (ref $arg->{type} || $arg->{type}) . "]")
					unless $arg->{type}->$_isa('Type::Tiny');
			push @$argdefs, $arg;
		}
		elsif ($_[0] eq 'opt')
		{
			shift;									# just the 'opt' marker
			my $opt = {};
			$opt->{name} = shift;
			$opt->{type} = $_[0]->$_isa('Type::Tiny') ? shift : must_be('Bool');
			if ($_[0] eq 'properties')
			{
				shift;
				my $extra_props = shift;
				$opt->{$_} = $extra_props->{$_} foreach keys %$extra_props;
			}
			push @$optdefs, $opt;
		}
		elsif ($_[0] eq 'control')
		{
			shift;									# just the 'control' marker
			my $control = shift;
			fatal("`control_via' requires hashref") unless ref $control eq 'HASH';
			$CONTROL{$name} = $control;
		}
		else
		{
			fatal("unknown command attribute [$_[0]]");
		}
	}

	# Save the flow (including processing any args) under our name.  Doing args here rather than in
	# the `$subcmd` below enables the `RUN` directive to pass args as well.
	$FLOWS{$name} = sub
	{
		$FLOW->validate_args(@_, $argdefs);
		fatal($FLOW->error) if $FLOW->error;
		$args{flow}->();
	};

	my $subcmd = sub
	{
		my ($osprey) = @_;							# currently unused

		# Figure out what context vars we need to set based on our the `command` properties.
		my $context_vars = {};
		foreach ( keys %$CONTEXT_VAR_XLATE )
		{
			my $arg = $CONTEXT_VAR_XLATE->{$_};
			$context_vars->{$_} = $args{$arg} if exists $args{$arg};
		}

		# Build the context for this command based on the (skeletal) global one, doing 3 major
		# things: adding in new context vars from our `command` definition, validing any
		# command-specific opts, and processing the control structure (if any).
		my $context = $FLOW->setup_context($context_vars, $optdefs, $CONTROL{$name});
		if ($context->error)						# either an opt didn't validate or the control structure had an error
		{
			fatal($context->error);
		}
		else										# set global access vars for flows
		{
			$FLOW = $context;
			%OPT  = $FLOW->opts;
		}

		# Script args are flow args (switches were already processed by Osprey and validated above).
		$FLOWS{$name}->(@ARGV);
	};
	$name eq ':DEFAULT' ? _install_base_command($subcmd, $optdefs) : _install_subcommand($name => $subcmd, $optdefs);
}


sub base_command { unshift @_, ':DEFAULT'; &command }



sub arg ($) { arg => shift }

sub opt (@) { opt => @_ }

sub must_be ($)
{
	my $type = shift;
	# slightly cheating, but this private method handles the widest range of things that might be a
	# type (including if it's already a Type::Tiny to start with)
	my ($t) = eval { Type::Tiny::_loose_to_TypeTiny($type) };
	fatal("not a valid type [$type]") unless defined $t;
	$t->create_child_type(message => sub { ($_ // '<<undef>>') . " is not a " . $t->name });
}

sub one_of ($)
{
	require Type::Tiny::Enum;
	my $v = shift;
	Type::Tiny::Enum->new( values => $v, message => sub { ($_ // '<<undef>>') . " must be one of: " . join(', ', @$v) });
}

sub also { properties => { map { s/^-// ? ($_ => 1) : $_ } @_ } }



sub log_to ($) { log_to => shift }

sub control_via ($) { control => shift }



sub flow (&) { flow => shift }


##############
# DIRECTIVES #
##############


sub verify (&$)
{
	my ($check, $fail_msg) = @_;

	# we need to ensure verify code gets executed no matter what
	my $save_runmode = $FLOW->runmode;
	$FLOW->_set_runmode('VERIFY');
	unless ( $check->() )
	{
		# Doing the error this way is a bit roundabout, but it guarantees failure here won't create
		# a statusfile that might keep our next run from happening due to `unless_clean_exit`.
		$FLOW->start_conditions_not_met("pre-flow check failed [$fail_msg]");
		fatal($FLOW->error);
	}
	$FLOW->_set_runmode($save_runmode);
}



sub SH (@)
{
	my @cmd = @_;

	if ( $FLOW->runmode eq 'NOACTION' )
	{
		say "would run: @cmd";
		return;
	}

	# In the rare case where `--pretend` is set but `runmode` is *not* "NOACTION," don't send our
	# output to the logfile.
	push @cmd, ">>$FLOW->{LOGFILE}" if exists $FLOW->{LOGFILE} and not $OPT{pretend};

	my $exitval = bash @cmd;
	if (defined wantarray)							# someone cares about our exit value
	{
		return $exitval;
	}
	else											# just a straight `SH` directive; die unless clean exit
	{
		fatal("command [@_] exited non-zero [$exitval]") unless $exitval == 0;
	}
}



sub CODE (@)
{
	my $block = pop;
	my ($name) = @_;

	if ( $FLOW->runmode eq 'NOACTION' )
	{
		my $msg = "would run code block";
		$msg .= " [$name]" if $name;
		say $msg;
		return;
	}

	# If we have a logfile, better make sure our code block is printing to it rather than STDOUT, if
	# it prints anything.
	my $log;
	if ( my $logfile = $FLOW->logfile )
	{
		open($log, '>>', $logfile);
	}

	my $retval;
	do
	{
		local *STDOUT = $log if $log;
		$retval = $block->();
	};
	unless ($retval)
	{
		my $msg = "code block" . ($name ? " [$name]" : '') . " returned false value [" . ($retval // 'undef') . "]";
		fatal($msg);
	}
}



sub RUN (@)
{
	my ($flow, @args) = @_;
	$FLOWS{$flow}->(@args);
}


####################
# SUPPORT ROUTINES #
####################


sub fatal
{
	my ($self, $msg) = &_pb_args;
	my $me = $FLOW->{ME} // basename($0);
	say STDERR "$me: $msg";
	$FLOW->raise_error($msg);
	exit 1;
}


####################
# DEFAULT COMMANDS #
####################

subcommand help => sub { shift->osprey_help };
subcommand commands => sub
{
	my $class = shift;
	my %sc = $class->_osprey_subcommands;
	say foreach sort keys %sc;
};

subcommand info => sub
{
	my $self = shift;
	foreach (@_)
	{
		$self->fatal("no such setting [$_]") unless $FLOW->has_var($_);
		say $FLOW->{$_};
	}
};


##############
# GO GO GO!! #
##############


# This is only used when there's a base command (but Osprey needs it regardless).
sub run
{
	$BASE_CMD->(@_) if $BASE_CMD;
}

sub go
{
	shift @ARGV and $FLOW->set_debug($1) if @ARGV and $ARGV[0] =~ /^DEBUG=(\d+)$/;

	$CMD = shift->new_with_options;
	$FLOW->connect_to($CMD);						# this connects the context to the command

	$CMD->run;
}


1;



# ABSTRACT: a workflow system made from Perl and bash
# COPYRIGHT

__END__

=pod

=head1 NAME

Pb - a workflow system made from Perl and bash

=head1 VERSION

This document describes version 0.01 of Pb.

=head1 SYNOPSIS

    use Pb;
    use Types::Standard -types;

    my %HOSTS =
    (
        integration => 'foo.mydomain.com',
        staging     => 'bar.mydomain.com',
        production  => 'baz.mydomain.com',
    );

    command 'push-file' =>
        arg env  => one_of [ keys %HOSTS ],
        arg file => must_be Str,
    flow
    {
        verify { pwd eq $ENV{MY_ROOT_DIR} } 'must be run from $MY_ROOT_DIR';
        verify { -x $FLOW->{file}         } 'file must exist';

        my $host = $HOSTS{$FLOW->{env}};
        my $from = path($FLOW->{file});
        my $dir  = $from->dirname;
        SH scp => -p => $from, "$host:$dir";
        CODE sub { say "it worked!" };
    };

    Pb->go;

=head1 DESCRIPTION

If you are a devops developer--even if you're a devops developer who doesn't believe that devops is
really a thing--you spend a bunch of your time writing control scripts.  Some of them you probably
write in C<bash>, because job control is one of those things that C<bash> is actually good at.  A
lot of them you probably write in Perl, because programming is one of those things that C<bash> is
pretty terrible at.  Trying to do real programming in C<bash> is pretty horrifying, but trying to do
job control in Perl isn't much nicer: the return value of C<system> is backwards, there's no
equivalent to C<bash -e>, C<END> blocks don't get run if your script is dying due to a signal, and
so on and so forth, ad inifinitum.  None of the deficiencies of Perl in this area are very
significant on their own, but it can become death by a thousand cuts as you try to layer more and
more devops complexity onto your Perl scripts.  In the end, if you write it in C<bash>, you'll end
up wishing you'd written it in Perl, and if you write it in Perl, you'll say to yourselt at least
once before it's done: man, this part would have been easier in C<bash>.

Well, now you no longer need to choose.  Leadpipe takes Perl and C<bash> and glues them together to
form C<Pb>, a module which allows you to quickly write commands which can do one or all of the
following:

=over

=item *

Can have subcommands (reminiscent of C<git>).

=item *

Can have command-line options and command-line arguments with sophisticated validation.

=item *

Can run pre-command verification checks to ensure a known state.

=item *

Can break your command down into steps (called "directives"), where each step can be printed out
instead of performing it (in C<--pretend> mode) or performed only after verification from the user
(in C<--interactive> mode).

=item *

Shell (C<SH>) directives look (mostly) just like C<bash> commands, with quoting handled for you
easily, and you have the full range of C<bash> syntax (unlike with C<system>).

=item *

But you can also do code (C<CODE>) directives, which are pure Perl.

=item *

And run (C<RUN>) directives, which allow one subcommand to call another, retaining the environment
and context.

=item *

Will abort if any individual directive fails (like C<bash -e>).

=item *

Can automatically log to a file.

=item *

Can automatically abort if a previous instance of the script is running.

=item *

Can save the result of the script run to a file, and (optionally) refuse to run if the previous run
failed.  This can be useful in a cronjob situation where a run error needs to be cleared manually
before automated runs can resume.

=item *

Much much more.

=back

Honestly, most of the things discussed above are not original to this module.  The main value of
Leadpipe is that it glues it all together and gives you a declarative syntax that looks like Perl
(because it is), but also looks like what you're actually doing.  Syntax is provided in a similar
fashion to Moose (i.e. not using source filters or C<Devel::Declare> or even Perl's new(ish) keyword
plugin API), but L<Moo> is used rather than Moose to keep startup time quick.

The main functionality of Leadpipe is provided by the following modules:

=over

=item *

L<CLI::Osprey>

=item *

L<Type::Tiny>

=item *

L<PerlX::bash>

=item *

L<sigtrap>

=item *

L<Proc::Pidfile>

=back

If you decide not to use Leadpipe (perhaps you don't like the glitzy syntax layer), you should
definitely look at those other modules for whatever solution you're contemplating.

=head1 COMMAND DEFINITION SYNTAX

=head2 command

Declare a Pb command.

=head2 base_command

Declare a base (i.e. default) command.

=head2 arg

Declare an argument to a command.

=head2 opt

Declare an option to a command.

=head2 must_be

Specify the type (of either an argument or option).

=head2 one_of

Specify the valid values for an enum type (for either an argument or option).  Use I<instead of>
C<must_be>, not in addition to.

=head2 also

Specify additional properties (other than type) for an option.

=head2 log_to

Specify a logfile for the output of a command.

=head2 control_via

Specify a control structure.  This is where you put pidfile, statusfile, etc.

=head2 flow

Specify the code for the actual command.

=head2 verify

Make an assertion (using a code block) which must return a true value before the command will
execute.  Also specify the error message if the assertion fails.

=head2 SH

Run a command in C<bash>.  If the command does not exit with 0, the entire command will exit.

=head2 CODE

Run a code block.  If the block returns a falsey value, the entire command will exit.

=head2 RUN

Run one command inside another.  Although you pass the nested command its own arguments, all other
parts of the context (including options) are retained.

=head2 fatal

Print a fatal error and exit.

=for Pod::Coverage 	run
	go

=head1 STATUS

This module is very new, although it is being actively used for small projects.  Documentation is
skeletal and the API may change a bit before it all shakes out.  Please be cautious in adopting it
for anything mission-critical, but I would love to get any feedback you may have from trying it out
for your own experimental projects.

=head1 USAGE

Doing C<use Pb> gets you all the syntax above, plus the following global(ish) variables:

=over

=item C<$FLOW>

This is the L<Pb::Command::Context> for the currently running command.  Context variables (including
arguments) can be accessed as if C<$FLOW> were a hashref (e.g. C<< $FLOW->{file} >>), but it's
really an object with proper methods (e.g. C<< $FLOW->error >>).

=item C<%OPT>

This is the hash which contains the values of all options to the command (e.g. C<$OPT{pretend}>).

=back

You also get these functions passed through from L<PerlX::bash>:

=over

=item C<pwd>

Same as L<Cwd/cwd>.

=back

=head1 BUGS, CAVEATS and NOTES

Probably lots.  Check out C<TODO.md> in the distribution for things that are in the queue to be
done.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Pb

=head2 Bugs / Feature Requests

This module is on GitHub.  Feel free to fork and submit patches.  Please note that I develop
via TDD (Test-Driven Development), so a patch that includes a failing test is much more
likely to get accepted (or at least likely to get accepted more quickly).

If you just want to report a problem or suggest a feature, that's okay too.  You can create
an issue on GitHub here: L<http://github.com/barefootcoder/pb/issues>.

=head2 Source Code

none
L<https://github.com/barefootcoder/leadpipe>

  git clone https://github.com/barefootcoder/leadpipe.git

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
