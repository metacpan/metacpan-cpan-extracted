package Sepia::Debug;
# use Sepia;
use Carp ();                    # old Carp doesn't export shortmess.
use Text::Abbrev;
use strict;
use vars qw($pack $file $line $sub $level
            $STOPDIE $STOPWARN);

sub define_shortcut;
*define_shortcut = *Sepia::define_shortcut;

BEGIN {
    ## Just leave it on -- with $DB::trace = 0, there doesn't seem
    ## to be a performance penalty!
    ##
    ## Flags we use are (see PERLDBf_* in perl.h):
    ## 0x1	Debugging sub enter/exit (call DB::sub if defined)
    ## 0x2      per-line debugging (keep line numbers)
    ## 0x8      "preserve more data" (call DB::postponed??)
    ## 0x10     keep line ranges for sub definitions in %DB::sub
    ## 0x100    give evals informative names
    ## 0x200    give anon subs informative names
    ## 0x400    save source lines in %{"_<$filename"}
    $^P = 0x01 | 0x02 | 0x10 | 0x100 | 0x200;
    $STOPDIE = 1;
    $STOPWARN = 0;
}

sub peek_my
{
    eval q{ require PadWalker };
    if ($@) {
        +{ }
    } else {
        *peek_my = \&PadWalker::peek_my;
        goto &peek_my;
    }
}

# set debugging level
sub repl_debug
{
    debug(@_);
}

sub repl_backtrace
{
    for (my $i = 0; ; ++$i) {
        my ($pack, $file, $line, $sub) = caller($i);
        last unless $pack;
        $Sepia::SIGGED && do { $Sepia::SIGGED--; last };
        # XXX: 4 is the magic number...
        print($i == $level+4 ? "*" : ' ', " [$i]\t$sub ($file:$line)\n");
    }
}

# return value from die
sub repl_return
{
    if ($Sepia::WANTARRAY) {
        @Sepia::REPL_RESULT = $Sepia::REPL{eval}->(@_);
    } else {
        $Sepia::REPL_RESULT[0] = $Sepia::REPL{eval}->(@_);
    }
    last repl;
}

use vars qw($DIE_TO @DIE_RETURN $DIE_LEVEL);
$DIE_LEVEL = 0;

sub xreturn
{
    eval q{ use Scope::Upper ':all' };
    if ($@) {
        print "xreturn requires Sub::Uplevel.\n";
        return;
    } else {
        *xreturn = eval <<'EOS';
        sub {
            my $exp = shift;
            $exp = '""' unless defined $exp;
            my $ctx = CALLER($level+4); # XXX: ok?
            local $Sepia::WANTARRAY = want_at $ctx;
            my @res = eval_in_env($exp, peek_my($level + 4));
            print STDERR "unwind(@res)\n";
            unwind @res, SUB UP $ctx;
        };
EOS
        goto &xreturn;
    }
}

sub repl_xreturn
{
    print STDERR "XRETURN(@_)\n";
    xreturn(shift);             # XXX: doesn't return.  Problem?
    print STDERR "XRETURN: XXX\n";
    # ($DB::DIE_TO, $DB::DIE_RETURN[0]) = split ' ', $_[0], 2;
    # $DB::DIE_RETURN[0] = $Sepia::REPL{eval}->($DB::DIE_RETURN[0]);
    # last SEPIA_DB_SUB;
}

# { package DB;
#  no strict;
sub sub
{
    no strict;
    local $DIE_LEVEL = $DIE_LEVEL + 1;
    ## Set up a dynamic catch target
 SEPIA_DB_SUB: {
        return &$DB::sub;
    };
    # we're dying!
    last SEPIA_DB_SUB
        if $DIE_LEVEL > 1 && defined $DIE_TO
            && $DB::sub !~ /(?:^|::)\Q$DIE_TO\E$/;
    undef $DIE_TO;
    wantarray ? @DIE_RETURN : $DIE_RETURN[0]
}
# }

sub repl_dbsub
{
    my $arg = shift;
    if ($arg) {
        *DB::sub = \&sub;
    } else {
        undef &DB::sub;
    }
}

sub repl_lsbreak
{
    no strict 'refs';
    for my $file (sort grep /^_</ && *{"::$_"}{HASH}, keys %::) {
        $Sepia::SIGGED && do { $Sepia::SIGGED--; last };
        my ($name) = $file =~ /^_<(.*)/;
        my @pts = keys %{"::$file"};
        next unless @pts;
        print "$name:\n";
        for (sort { $a <=> $b } @pts) {
            print "\t$_\t${$file}{$_}\n"
        }
    }
}

# evaluate EXPR in environment ENV
sub eval_in_env
{
    my ($expr, $env) = @_;
    local $Sepia::ENV = $env;
    my $str = '';
    for (keys %$env) {
        next unless /^([\$\@%])(.+)/;
        $str .= "local *$2 = \$Sepia::ENV->{'$_'}; ";
    }
    $str = "do { no strict; package $Sepia::PACKAGE; $str $expr }";
    return $Sepia::WANTARRAY ? eval $str : scalar eval $str;

}

sub tie_class
{
    my $sig = substr shift, 0, 1;
    return $sig eq '$' ? 'Tie::StdScalar'
        : $sig eq '@' ? 'Tie::StdArray'
            : $sig eq '%' ? 'Tie::StdHash'
                : die "Sorry, can't tie $sig\n";
}

## XXX: this is a better approach (the local/tie business is vile),
## but it segfaults and I'm not sure why.
sub eval_in_env2
{
    my ($expr, $env, $fn) = @_;
    local $Sepia::ENV = $env;
    my @vars = grep /^([\$\@%])(.+)/, keys %$env;
    my $body = 'sub { my ('.join(',', @vars).');';
    for (@vars) {
        $body .= "Devel::LexAlias::lexalias(\$Sepia::ENV, '$_', \\$_);"
    }
    $body .= "$expr }";
    print STDERR "---\n$body\n---\n";
    $body = eval $body;
    $@ || $body->();
}

# evaluate EXP LEV levels up the stack
#
# NOTE: We need to act like &repl_eval here and consider e.g. $WANTARRAY
sub repl_upeval
{
    # if ($Sepia::WANTARRAY) {
    return eval_in_env(shift, peek_my(4+$level));
    # } else {
    #     return scalar eval_in_env(shift, peek_my(4+$level));
    # }
}

# inspect lexicals at level N, or current level
sub repl_inspect
{
    my $i = shift;
    if ($i =~ /\d/) {
        $i = 0+$i;
    } else {
        $i = $level + 3;
    }
    my $sub = (caller $i)[3];
    if ($sub) {
        my $h = peek_my($i+1);
        print "[$i] $sub:\n";
        for (sort keys %$h) {
            local @Sepia::res = $h->{$_};
            print "\t$_ = ", $Sepia::PRINTER{$Sepia::PRINTER}->(), "\n";
        }
    }
}

sub debug
{
    my $new = Sepia::as_boolean(shift, $DB::trace);
    print "debug ", $new ? "ON" : "OFF";
    if ($new == $DB::trace) {
        print " (unchanged)\n"
    } else {
        print "\n";
    }
    $DB::trace = $new;
}

sub breakpoint_file
{
    my ($file) = @_;
    return \%{$main::{"_<$file"}} if exists $main::{"_<$file"};
    if ($file !~ /^\//) {
        ($file) = grep /^_<.*\/\Q$file\E$/, keys %main::;
        return \%{$main::{$file}} if $file;
    }
    return undef;
}

sub breakpoint
{
    my ($file, $line, $cond) = @_;
    my $h = breakpoint_file $file;
    if (defined $h) {
        $h->{$line} = $cond || 1;
        return $cond ? "$file\:$line if $cond" : "$file\:$line";
    }
    return undef;
}

sub repl_break
{
    my $arg = shift;
    $arg =~ s/^\s+//;
    $arg =~ s/\s+$//;
    my ($f, $l, $cond) = $arg =~ /^(.+?):(\d+)\s*(.*)/;
    $cond = 1 unless $cond =~ /\S/;
    $f ||= $file;
    $l ||= $line;
    return unless defined $f && defined $l;
    my $bp = breakpoint($f, $l, $cond);
    print "break $bp\n" if $bp;
}

sub update_location
{
    # XXX: magic numberage.
    ($pack, $file, $line, $sub) = caller($level + shift);
}

sub show_location
{
    print "_<$file:$line>\n" if defined $file && defined $line;
}

sub repl_list
{
    my @lines = eval shift;
    @lines = $line - 5 .. $line + 5 unless @lines;
    printf '%-6d%s', $_, ${"::_<$file"}[$_-1] for @lines;
}

sub repl_delete
{
    my ($f, $l) = split /:/, shift;
    $f ||= $file;
    $l ||= $line;
    my $h = breakpoint_file $f;
    delete $h->{$l} if defined $h;
}

sub repl_finish
{
    # XXX: doesn't handle recursion, but oh, well...
    my $sub = (caller $level + 4)[3];
    if (exists $DB::sub{$sub}) {
        my ($file, $start, $end) = $DB::sub{$sub} =~ /(.*):(\d+)-(\d+)/;
        print STDERR "finish($sub): will stop at $file:$end\n";
        # XXX: $end doesn't always work, since it may not have an
        # executable statement on it.
        breakpoint($file, $end-1, 'finish');
        last repl;
    } else {
        print STDERR "yikes: @{[keys %DB::sub]}\n";
    }
}

sub repl_toplevel
{
    local $STOPDIE;
    die(bless [], __PACKAGE__);
}

sub add_repl_commands
{
    define_shortcut 'delete', \&repl_delete,
        'Delete current breakpoint.';
    define_shortcut 'debug', \&repl_debug,
        'debug [0|1]', 'Enable or disable debugging.';
    define_shortcut 'break', \&repl_break,
        'break [F:N [E]]',
        'Break at file F, line N (or at current position) if E is true.';
    define_shortcut 'lsbreak', \&repl_lsbreak,
        'List breakpoints.';
    # define_shortcut 'dbsub', \&repl_dbsub, '(Un)install DB::sub.';
    %Sepia::RK = abbrev keys %Sepia::REPL;
}

sub add_debug_repl_commands
{
    define_shortcut quit => \&repl_toplevel,
        'quit', 'Quit the debugger, returning to the top level.';
    define_shortcut toplevel => \&repl_toplevel,
        'toplevel', 'Return to the top level.';
    define_shortcut up => sub {
        $level += shift || 1;
        update_location(4);
        show_location;
    }, 'up [N]', 'Move up N stack frames.';
    define_shortcut down => sub {
        $level -= shift || 1;
        $level = 0 if $level < 0;
        update_location(4);
        show_location;
    }, 'down [N]', 'Move down N stack frames.';
    define_shortcut continue => sub {
        $level = 0;
        $DB::single = 0;
        last repl;
    }, 'Yep.';

    define_shortcut next => sub {
        my $n = shift || 1;
        $DB::single = 0;
        breakpoint $file, $line + $n, 'next';
        last repl;
    }, 'next [N]', 'Advance N lines, skipping subroutines.';

    define_shortcut step => sub {
        $DB::single = shift || 1;
        last repl;
    }, 'step [N]', 'Step N statements forward, entering subroutines.';

    define_shortcut finish => \&repl_finish,
        'finish', 'Finish the current subroutine.';

    define_shortcut list => \&repl_list,
        'list EXPR', 'List source lines of current file.';
    define_shortcut backtrace => \&repl_backtrace, 'show backtrace';
    define_shortcut inspect => \&repl_inspect,
        'inspect [N]', 'inspect lexicals in frame N (or current)';
    define_shortcut return => \&repl_return, 'return EXPR', 'return EXPR';
    # define_shortcut xreturn => \&repl_xreturn, 'xreturn EXPR',
    #     'return EXPR from the current sub.';
    define_shortcut eval => \&repl_upeval,
        'eval EXPR', 'evaluate EXPR in current frame';      # DANGER!
}

sub repl
{
    show_location;
    local %Sepia::REPL = %Sepia::REPL;
    local %Sepia::REPL_DOC = %Sepia::REPL_DOC;
    add_debug_repl_commands;
    map { define_shortcut @$_ } @_;
    local %Sepia::RK = abbrev keys %Sepia::REPL;
    # local $Sepia::REPL_LEVEL = $Sepia::REPL_LEVEL + 1;
    local $Sepia::PS1 = "*$Sepia::REPL_LEVEL*> ";
    Sepia::repl();
}

sub DB::DB
{
    return if $Sepia::ISEVAL;
    local $level = 0;
    local ($pack, $file, $line, $sub) = caller($level);
    ## Don't do anything if we're inside an eval request, even if in
    ## single-step mode.
    return unless $DB::single || exists $main::{"_<$file"}{$line};
    if ($DB::single) {
        return unless --$DB::single == 0;
    } else {
        my $cond = $main::{"_<$file"}{$line};
        if ($cond eq 'next') {
            delete $main::{"_<$file"}{$line};
        } elsif ($cond eq 'finish') {
            # remove temporary breakpoint and take one more step.
            delete $main::{"_<$file"}{$line};
            $DB::single = 1;
            return;
        } else {
            return unless $Sepia::REPL{eval}->($cond);
        }
    }
    repl();
}

my $MSG = "('\\C-c' to exit, ',h' for help)";

sub die
{
    ## Protect us against people doing weird things.
    if ($STOPDIE && !$SIG{__DIE__}) {
        my @dieargs = @_;
        local $level = 0;
        local ($pack, $file, $line, $sub) = caller($level);
        my $tmp = "@_";
        $tmp .= "\n" unless $tmp =~ /\n\z/;
        print "$tmp\tin $sub\nDied $MSG\n";
        my $trace = $DB::trace;
        $DB::trace = 1;
        repl(
            [die => sub { local $STOPDIE=0; CORE::die @dieargs },
             'Continue dying.'],
            [quit => sub { local $STOPDIE=0; CORE::die @dieargs },
             'Continue dying.']);
        $DB::trace = $trace;
    } else {
        CORE::die(Carp::shortmess @_);
    }
    1;
}

sub warn
{
    ## Again, this is above our pay grade:
    if ($STOPWARN && $SIG{__WARN__} eq 'Sepia::sig_warn') {
        my @dieargs = @_;
        my $trace = $DB::trace;
        $DB::trace = 1;
        local $level = 0;
        local ($pack, $file, $line, $sub) = caller($level);
        print "@_\n\tin $sub\nWarned $MSG\n";
        repl(
            [warn => sub { local $STOPWARN=0; CORE::warn @dieargs },
             'Continue warning.'],
            [quit => sub { local $STOPWARN=0; CORE::warn @dieargs },
             'Continue warning.']);
        $DB::trace = $trace;
    } else {
        ## Avoid showing up in location information.
        CORE::warn(Carp::shortmess @_);
    }
}

sub oops
{
    my $sig = shift;
    if ($STOPDIE) {
        my $trace = $DB::trace;
        $DB::trace = 1;
        local $level = 0;
        local ($pack, $file, $line, $sub) = caller($level);
        print "@_\n\tin $sub\nCaught signal $sig\n";
        repl(
        [die => sub { local $STOPDIE=0; CORE::die "Caught signal $sig; exiting." },
         'Just die.'],
        [quit => sub { local $STOPWARN=0; CORE::die "Caught signal $sig; exiting." },
         'Just die.']);
        $DB::trace = $trace;
    } else {
        Carp::confess "Caught signal $sig: continue at your own risk.";
    }
}

1;
