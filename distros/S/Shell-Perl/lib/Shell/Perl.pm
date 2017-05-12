package Shell::Perl;

use strict;
use warnings;

our $VERSION = '0.004';

use base qw(Class::Accessor); # soon use base qw(Shell::Base);
Shell::Perl->mk_accessors(qw(
    out_type
    dumper
    context
    package
    perl_version
    term
    ornaments
    library
    on_quit
)); # XXX use_strict

use lib ();
use Getopt::Long 2.43 qw(:config no_auto_abbrev no_ignore_case bundling_values);
use version 0.77;

use Term::ReadLine;
use Shell::Perl::Dumper;

# out_type defaults to one of 'D', 'DD', 'Y', 'P';
# dumper XXX
# context defaults to 'list'
# package defaults to __PACKAGE__ . '::sandbox'
# XXX use_strict defaults to 0

sub new {
    my $self = shift;
    my $sh = $self->SUPER::new({
                           context => 'list', # print context
                           on_quit => 'exit',
                           perl_version => $],
                           @_ });
    $sh->_init;
    return $sh;
}

my %dumper_for = (
   'D' => 'Shell::Perl::Data::Dump',
   'DD' => 'Shell::Perl::Data::Dumper',
   'Y' => 'Shell::Perl::Dumper::YAML',
   'Data::Dump' => 'Shell::Perl::Data::Dump',
   'Data::Dumper' => 'Shell::Perl::Data::Dumper',
   'YAML' => 'Shell::Perl::Dumper::YAML',
   'DDS' => 'Shell::Perl::Data::Dump::Streamer',

   'P' => 'Shell::Perl::Dumper::Plain',
   'plain' => 'Shell::Perl::Dumper::Plain',
);

sub _init {
    my $self = shift;

    # loop until you find one available alternative for dump format
    my $dumper_class;
    for my $format ( qw(D DD DDS Y P) ) {
        if ($dumper_for{$format}->is_available) {
            #$self->print("format: $format\n");
            $self->set_out($format);
            last
        } # XXX this is not working 100% - and I have no clue about it
    }

    # Set library paths
    if ($self->library) {
        warn "Setting library paths (@{$self->library})\n";
        lib->import(@{ $self->library });
    }

    $self->set_package( __PACKAGE__ . '::sandbox' );

    $self->_set_on_quit( $self->on_quit );
}

sub _shell_name {
    require File::Basename;
    return File::Basename::basename($0);
}

sub print {
    my $self = shift;
    print {$self->term->OUT} @_;
}

## # XXX remove: code and docs
## sub out {
##     my $self = shift;
##
##     # XXX I want to improve this: preferably with an easy way to add dumpers
##     if ($self->context eq 'scalar') {
##         $self->print($self->dumper->dump_scalar(shift), "\n");
##     } else { # list
##         $self->print($self->dumper->dump_list(@_), "\n");
##     }
## }

# XXX I want to improve this: preferably with an easy way to add dumpers

=begin private

=item B<_print_scalar>

    $sh->_print_scalar($answer);

That corresponds to the 'print' in the read-eval-print
loop (in scalar context). It outputs the evaluation result
after passing it through the current dumper.

=end private

=cut

sub _print_scalar { # XXX make public, document
    my $self = shift;
    $self->print($self->dumper->dump_scalar(shift));
}

=begin private

=item B<_print_scalar>

    $sh->_print_list(@answers);

That corresponds to the 'print' in the read-eval-print
loop (in list context). It outputs the evaluation result
after passing it through the current dumper.

=end private

=cut

sub _print_list { # XXX make public, document
    my $self = shift;
    $self->print($self->dumper->dump_list(@_));
}

sub _warn {
    shift;
    my $shell_name = _shell_name;
    warn "$shell_name: ", @_, "\n";
}

sub set_out {
    my $self = shift;
    my $type = shift;
    my $dumper_class = $dumper_for{$type};
    if (!defined $dumper_class) {
        $self->_warn("unknown dumper $type");
        return;
    }
    if ($dumper_class->is_available) {
        $self->dumper($dumper_class->new);
        $self->out_type($type);
    } else {
        $self->_warn("can't load dumper $dumper_class");
    }
}

sub _ctx {
    my $context = shift;

    if ($context =~ /^(s|scalar|\$)$/i) {
        return 'scalar';
    } elsif ($context =~ /^(l|list|@)$/i) {
        return 'list';
    } elsif ($context =~ /^(v|void|_)$/i) {
        return 'void';
    } else {
        return undef;
    }
}

sub set_ctx {
    my $self    = shift;
    my $context = _ctx $_[0];

    if ($context) {
        $self->context($context);
    } else {
        $self->_warn("unknown context $_[0]");
    }
}

sub set_package {
    my $self    = shift;
    my $package = shift;

    if ($package =~ /( [a-zA-Z_] \w*  :: )* [a-zA-Z_] \w* /x) {
        $self->package($package);

        no strict 'refs';
        *{ "${package}::quit" } = *{ "${package}::exit" } = sub { $self->{quitting} = 1 };

    } else {
        $self->_warn("bad package name $package");
    }
}

my %on_quit = (
    'exit'   => sub { exit 0 },
    'return' => sub {},
);

sub _quit_handler {
    my $handler = shift;

    if (exists $on_quit{$handler}) {
        return $on_quit{$handler};
    }
    elsif (ref $handler eq 'CODE') {
        return $handler;
    }
    return undef;
}

sub _set_on_quit {
    my $self    = shift;
    my $handler = _quit_handler($_[0]);

    if ($handler) {
        $self->on_quit($handler);
    }
    else {
        $self->_warn("bad on_quit handler $_[0]");
        $self->on_quit($on_quit{'exit'});
    }
}

# $err = _check_perl_version($version);
sub _check_perl_version {
    my $version = shift;
    my $ver = eval { version->parse($version) };
    if ($@) {
        (my $err = $@) =~ s/at \S+ line \d+.$//;
        return $err;
    }
    # Current perl
    my $v = $^V || version->parse($]);
    if ($ver > $v) {
        return "This is only $v";
    }
    return undef; # good
}

sub set_perl_version {
    my $self = shift;
    my $version = shift;

    if (!defined $version) {
        $self->perl_version($]);
    }
    elsif ($version eq q{''} || $version eq q{""}) {
        $self->perl_version('');
    }
    else {
        my $err = _check_perl_version($version);
        if ($err) {
            $self->_warn("bad perl_version ($version): $err");
        }
        else {
            $self->perl_version($version);
        }
    }
}

use constant HELP =>
    <<'HELP';
Shell commands:           (begin with ':')
  :e(x)it or :q(uit) - leave the shell
  :set out (D|DD|DDS|Y|P) - setup the output format
  :set ctx (scalar|list|void|s|l|v|$|@|_) - setup the eval context
  :set package <name> - set package in which shell eval statements
  :set perl_version <version> - set perl version to eval statements
  :reset - reset the environment
  :dump history <file> - (experimental) print the history to STDOUT or a file
  :h(elp) - get this help screen

HELP

sub help {
    print HELP;
}

# :reset is a nice idea - but I wanted more like CPAN reload
# I retreated the current implementation of :reset
#    because %main:: is used as the evaluation package
#    and %main:: = () is too severe by now

sub reset {
    my $self = shift;
    my $package = $self->package;
    return if $package eq 'main'; # XXX don't reset %main::
    no strict 'refs';
    %{"${package}::"} = ();
    #%main:: = (); # this segfaults at my machine
}

sub prompt_title {
    my $self = shift;
    my $shell_name = _shell_name;
    my $sigil = { scalar => '$', list => '@', void => '' }->{$self->{context}};
    return "$shell_name $sigil> ";
}

sub _readline {
    my $self = shift;
    return $self->term->readline($self->prompt_title);
}

sub _history_file { # XXX
    require Path::Class;
    require File::HomeDir;
    return Path::Class::file( File::HomeDir->my_home, '.pirl-history-xxx' );
}

sub _read_history { # XXX belongs to Shell::Perl::ReadLine
    my $term = shift;
    my $h    = _history_file;
    #warn "read history from $h\n"; # XXX
    if ( $term->Features->{readHistory} ) {
        $term->ReadHistory( "$h" );
    } elsif ( $term->Features->{setHistory} ) {
        if ( -e $h ) {
            my @h = $h->slurp( chomp => 1 );
            $term->SetHistory( @h );
        }
    } else {
        # warn "Your ReadLine doesn't support setHistory\n";
    }

}

sub _write_history { # XXX belongs to Shell::Perl::ReadLine
   my $term = shift;
   my $h    = _history_file;
   #warn "write history to $h\n"; # XXX
   if ( $term->Features->{writeHistory} ) {
       $term->WriteHistory( "$h" );
   } elsif ( $term->Features->{getHistory} ) {
       my @h = $term->GetHistory;
       $h->spew_lines(\@h);
   } else {
       # warn "Your ReadLine doesn't support getHistory\n";
   }
}

sub _new_term {
    my $self = shift;
    my $name = shift;
    my $term = Term::ReadLine->new( $name );
    $term->ornaments($self->ornaments) if $term->Features->{ornaments};
    _read_history( $term );
    return $term;
}

sub run {
    my $self = shift;
    my $shell_name = _shell_name;
    $self->term( my $term = $self->_new_term( $shell_name ) );
    my $prompt = "$shell_name > ";

    print "Welcome to the Perl shell. Type ':help' for more information\n\n";

    local $self->{quitting} = 0;

    REPL: while ( defined ($_ = $self->_readline) ) {

        # trim
        s/^\s+//g;
        s/\s+$//g;

        # Shell commands start with ':' followed by something else
        # which is not ':', so we can use things like '::my_subroutine()'.
        if (/^:[^:]/) {
            last REPL if /^:(exit|quit|q|x)/;
            $self->set_out($1) if /^:set out (\S+)/;
            $self->set_ctx($1) if /^:set ctx (\S+)/;
            $self->set_package($1) if /^:set package (\S+)/;
            $self->set_perl_version($1) if /^:set perl_version(?: (\S+))?/;
            $self->reset if /^:reset/;
            $self->help if /^:h(elp)?/;
            $self->dump_history($1) if /^:dump history(?:\s+(\S*))?/;
            # unknown shell command ?!
            next REPL;
        }

        my $context;
        $context = _ctx($1) if s/#(s|scalar|\$|l|list|\@|v|void|_)\z//;
        $context = $self->context unless $context;
        if ( $context eq 'scalar' ) {
            my $out = $self->eval($_);
            if ($@) { warn "ERROR: $@"; next }
            $self->_print_scalar($out);
        } elsif ( $context eq 'list' ) {
            my @out = $self->eval($_);
            if ($@) { warn "ERROR: $@"; next }
            $self->_print_list(@out);
        } elsif ( $context eq 'void' ) {
            $self->eval($_);
            if ($@) { warn "ERROR: $@"; next }
        } else {
            # XXX should not happen
        }
        last if $self->{quitting};

    }
    return $self->quit;

}

sub _package_stmt {
    my $package = shift->package;
    ("package $package");
}

sub _use_perl_stmt {
    my $perl_version = shift->perl_version;
    $perl_version ? ("use $perl_version") : ();
}

# $shell->eval($exp)
sub eval {
    my $self = shift;
    my $exp = shift;

    my $preamble = join ";\n", (
        $self->_package_stmt,
        $self->_use_perl_stmt,
        "no strict qw(vars subs)",
        "",    # for the trailing ;
    );

    # XXX gotta restore $_, etc.
    return eval <<CHUNK;
       $preamble
#line 1
       $exp
CHUNK
    # XXX gotta save $_, etc.
}

sub quit {
    my $self = shift;
    _write_history( $self->term );
    $self->print( "Bye.\n" ); # XXX
    return $self->on_quit->();
}

sub run_with_args {
    my $self = shift;

    # XXX do something with @ARGV (Getopt)
    my %options = ( ornaments => 1 );
    if ( @ARGV ) {
        # only require Getopt::Long if there are actually command line arguments
        require Getopt::Long;
        Getopt::Long::GetOptions( \%options, 'ornaments!', 'version|v', 'library|I=s@' );
    }

    my $shell = Shell::Perl->new(%options);
    if ( $options{version} ) {
        $shell->_show_version;
    } else {
        $shell->run;
    }
}

sub _show_version {
    my $self = shift;
    printf "This is %s, version %s (%s, using Shell::Perl %s)\n",
           _shell_name,
           $main::VERSION,
           $0,
           $Shell::Perl::VERSION;
    exit 0;
}

sub dump_history {
    my $self = shift;
    my $file = shift;

    if ( !$self->term->Features->{getHistory} ) {
        print "Your Readline doesn't support getHistory\n";
        return;
    }

    if ( $file ) {
        open( my $fh, ">>", $file )
            or do { warn "Couldn't open '$file' for history dump\n"; return; };
        for ( $self->term->GetHistory ) {
            print $fh $_, "\n";
        }
        close $fh;

        print "Dumped history to '$file'\n\n";
    } else {
        print $_, "\n" for($self->{term}->GetHistory);
        print "\n";
    }
    return 1;
}

1;

# OUTPUT Data::Dump, Data::Dumper, YAML, others
# document: use a different package when eval'ing
# reset the environment
# implement shell commands (:quit, :set, :exit, etc.)
# how to implement array contexts?
#    IDEA:    command  ":set ctx scalar | list | void"
#             terminators "#s" "#l" "#v" "#$" #@ #_
# allow multiline entries. how?

##sub set {} # sets up the instance variables of the shell
##
##sub run {} # run the read-eval-print loop
##
##sub read {} # read a chunk
##
##sub readline {} # read a line
##
##sub eval {}
##
##sub print {}
##
##sub warn {}
##
##sub help { shift->print(HELP) }
##
##sub out { ? }

__END__

=pod

=encoding utf-8

=head1 NAME

Shell::Perl - A read-eval-print loop in Perl

=head1 SYNOPSYS

    use Shell::Perl;
    Shell::Perl->run_with_args;

=head1 DESCRIPTION

This is the implementation of a command-line interpreter for Perl.
I wrote this because I was tired of using B<irb> when
needing a calculator with a real language within. Ah,
that and because it was damn easy to write it.

This module is the heart of the B<pirl> script provided with
B<Shell-Perl> distribution, along with this module.

=head2 EXAMPLE SESSION

    $ pirl
    Welcome to the Perl shell. Type ':help' for more information


    pirl @> 1+1
    2

    pirl @> use YAML qw(Load Dump);
    ()

    pirl @> $data = Load("--- { a: 1, b: [ 1, 2, 3] }\n");
    { a => 1, b => [1, 2, 3] }

    pirl @> $var = 'a 1 2 3'; $var =~ /(\w+) (\d+) (\d+)/
    ("a", 1, 2)

    pirl @> :q

=head2 COMMANDS

Most of the time, the shell reads Perl statements, evaluates them
and outputs the result.

There are a few commands (started by ':') that are handled
by the shell itself.

=over 4

=item :h(elp)

Handy for remembering what the shell commands are.

=item :q(uit)

Leave the shell. The Perl statement C<exit> will work too.

SYNONYMS: :exit, :x

=item :set out (D|DD|DDS|Y|P)

Changes the dumper for the expression results used before
output. The current supported are:

=over 4

=item D

C<Data::Dump>

=item DD

C<Data::Dumper>, the good and old core module

=item DDS

C<Data::Dump::Streamer>

=item Y

C<YAML>

=item P

a plain dumper ("$ans" or "@ans")

=back

When creating the shell, the dump format is searched
among the available ones in the order "D", "DD", "DDS", "Y"
and "P". That means L<Data::Dump> is preferred and will
be used if available/installed. Otherwise, L<Data::Dumper>
is tried, and so on.

Read more about dumpers at L<Shell::Perl::Dumper>.

=item :set ctx (scalar|list|void|s|l|v|$|@|_)

Changes the default context used to evaluate the entered expression.
The default is C<'list'>.

Intuitively, 'scalar', 's' and '$' are synonyms, just
like 'list', 'l', and '@' or 'void', 'v', '_'.

There is a nice way to override the default context in a given expression.
Just a '#' followed by one of 'scalar|list|void|s|l|v|$|@|_' at the end
of the expression.

    pirl @> $var = 'a 1 2 3'; $var =~ /(\w+) (\d+) (\d+)/
    ("a", 1, 2)

    pirl @> $var = 'a 1 2 3'; $var =~ /(\w+) (\d+) (\d+)/ #scalar
    1

=item :set perl_version

Changes the perl version (and current feature bundle)
used to evaluate each statement. Usage examples are:

    :set perl_version 5.008
    :set perl_version v5.10
    :set perl_version        # current perl version, $]

Default is to use the current perl version, which works like C<eval "use $];">.

Set to an empty string, as in

    :set perl_version ''

for the behavior of pirl 0.0023 or earlier.

=item :reset

Resets the environment, erasing the symbols created
at the current evaluation package. See the
section L<"ABOUT EVALUATION">.

=back

=head2 METHODS

Remember this is an alpha version, so the API may change
and that includes the methods documented here. So consider
this section as implementation notes for a while.

In later versions, some of these information may be promoted
to a public status. Others may be hidden or changed and
even disappear without further notice.

=over 4

=item B<new>

    $sh = Shell::Version->new;

The constructor.

=item B<run_with_args>

    Shell::Perl->run_with_args;

Starts the read-eval-print loop after reading
options from C<@ARGV>. It is a class method.

If an option B<-v> or B<--version> is provided,
instead of starting the REPL, it prints
the script identification and exits with 0.

   $ pirl -v
   This is pirl, version 0.0017 (bin/pirl, using Shell::Perl 0.0017)

=item B<run>

    $sh->run;

The same as C<run_with_args> but with no code for
interpreting command-line arguments. It is an instance method,
so that C<< Shell::Perl->run_with_args >> is kind of:

    Shell::Perl->new->run;

=item B<eval>

    $answer = $sh->eval($exp);
    @answer = $sh->eval($exp);

Evaluates the user input given in C<$exp> as Perl code and returns
the result. That is the 'eval' part of the
read-eval-print loop.

=item B<print>

    $sh->print(@args);

Prints a list of args at the output stream currently used
by the shell.

=item B<help>

    $sh->help;

Outputs the help as provided by the command ":help".

=item B<reset>

    $sh->reset;

Does nothing by now, but it will.

=item B<dump_history>

    $sh->dump_history();
    $sh->dump_history($file);

Prints the readline history to C<STDOUT> or the optional file.
Used to implement experimental command ":dump history".

This is experimental code and should change in the future.
More control should be added and integrated with other
terminal features.

=item B<set_ctx>

    $sh->set_ctx($context);

Assigns to the current shell context. The argument
must be one of C< ( 'scalar', 'list', 'void',
's', 'l', 'v', '$', '@', '_' ) >.

=item B<set_package>

    $sh->set_package($package);

Changes current evaluation package. Doesn't change if the
new package name is malformed.

=item B<set_perl_version>

    $sh->set_perl_version($version);

Changes perl version used to evaluate statements.

=item B<set_out>

    $sh->set_out($dumper);

Changes the current dumper used for printing
the evaluation results. Actually must be one of
"D" (for Data::Dump), "DD" (for Data::Dumper),
"DDS" (for Data::Dump::Streamer),
"Y" (for YAML) or "P" (for plain string interpolation).

=item B<prompt_title>

    $prompt = $sh->prompt_title;

Returns the current prompt which changes with
executable name and context. For example,
"pirl @>", "pirl $>", and "pirl >".

=item B<quit>

    $sh->quit;

This method is invoked when these commands and
statements are parsed by the REPL:

    :q
    :quit
    :x
    :exit
    quit
    exit

It runs the shutdown procedures for a smooth
termination of the shell. For example, it
saves the terminal history file.

=back

=head1 GORY DETAILS

=head2 ABOUT EVALUATION

When the statement read is evaluated, this is done
at a different package, which is C<Shell::Perl::sandbox>
by default.

So:

    $ perl -Mlib=lib bin/pirl
    Welcome to the Perl shell. Type ':help' for more information

    pirl @> $a = 2;
    2

    pirl @> :set out Y # output in YAML

    pirl @> \%Shell::Perl::sandbox::
    ---
    BEGIN: !!perl/glob:
      PACKAGE: Shell::Perl::sandbox
      NAME: BEGIN
    a: !!perl/glob:
      PACKAGE: Shell::Perl::sandbox
      NAME: a
      SCALAR: 2

This package serves as an environment for the current
shell session and :reset can wipe it away.

    pirl @> :reset

    pirl @> \%Shell::Perl::sandbox::
    ---
    BEGIN: !!perl/glob:
      PACKAGE: Shell::Perl::sandbox
      NAME: BEGIN


=head1 TO DO

There is a lot to do, as always. Some of the top priority tasks are:

=over 4

=item *

Accept multiline statements;.

=item *

Refactor the code to promote easy customization of features.

=back

=head1 BUGS

It is a one-line evaluator by now.

I don't know what happens if you eval within an eval.
I don't expect good things to come. (Lorn who prodded
me about this will going to find it out and then
I will tell you.)

There are some quirks with Term::Readline (at least on Windows).

There are more bugs. I am lazy to collect them all and list them now.

Please report bugs via Github L<https://github.com/aferreira/pirl/issues>.

=head1 SEE ALSO

This project is hosted at Github:

    https://github.com/aferreira/pirl

To know about interactive Perl interpreters, there are two
FAQS contained in L<perlfaq3> which are good starting points.
Those are

    How can I use Perl interactively?
    http://perldoc.perl.org/perlfaq3.html#How-can-I-use-Perl-interactively%3f

    Is there a Perl shell?
    http://perldoc.perl.org/perlfaq3.html#How-can-I-use-Perl-interactively%3f

Also:

=over 4

=item *

L<Devel::REPL>

=item *

L<Reply>

=item *

L<A comparison of various REPLs|http://shadow.cat/blog/matt-s-trout/mstpan-17/>

=back

=head1 AUTHORS

Adriano R. Ferreira, E<lt>ferreiraE<64>cpan.orgE<gt>

Caio Marcelo, E<lt>cmarceloE<64>gmail.comE<gt>

Ron Savage, E<lt>ronE<64>savage.net.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007–2017 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
