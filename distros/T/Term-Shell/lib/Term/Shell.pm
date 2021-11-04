package Term::Shell;
$Term::Shell::VERSION = '0.13';
use strict;
use warnings;

use 5.014;

use Data::Dumper;
use Term::ReadLine ();

#=============================================================================
# Term::Shell API methods
#=============================================================================
sub new
{
    my $cls = shift;
    my $o   = bless {
        term => eval {

            # Term::ReadKey throws ugliness all over the place if we're not
            # running in a terminal, which we aren't during "make test", at
            # least on FreeBSD. Suppress warnings here.
            local $SIG{__WARN__} = sub { };
            Term::ReadLine->new('shell');
        }
            || undef,
        },
        ref($cls)
        || $cls;

    # Set up the API hash:
    $o->{command} = {};
    $o->{API}     = {
        args        => \@_,
        case_ignore => ( $^O eq 'MSWin32' ? 1 : 0 ),
        check_idle  => 0,                # changing this isn't supported
        class       => $cls,
        command     => $o->{command},
        cmd         => $o->{command},    # shorthand
        match_uniq  => 1,
        pager       => $ENV{PAGER}                   || 'internal',
        readline    => eval { $o->{term}->ReadLine } || 'none',
        script      => ( caller(0) )[1],
        version     => $Term::Shell::VERSION,
    };

    # Note: the rl_completion_function doesn't pass an object as the first
    # argument, so we have to use a closure. This has the unfortunate effect
    # of preventing two instances of Term::ReadLine from coexisting.
    my $completion_handler = sub {
        $o->rl_complete(@_);
    };
    if ( $o->{API}{readline} eq 'Term::ReadLine::Gnu' )
    {
        my $attribs = $o->{term}->Attribs;
        $attribs->{completion_function} = $completion_handler;
    }
    elsif ( $o->{API}{readline} eq 'Term::ReadLine::Perl' )
    {
        $readline::rl_completion_function = $readline::rl_completion_function =
            $completion_handler;
    }
    $o->find_handlers;
    $o->init;
    $o;
}

sub DESTROY
{
    my $o = shift;
    $o->fini;
}

sub cmd
{
    my $o = shift;
    $o->{line} = shift;
    if ( $o->line =~ /\S/ )
    {
        my ( $cmd, @args ) = $o->line_parsed;
        $o->run( $cmd, @args );
        unless ( $o->{command}{run}{found} )
        {
            my @c = sort $o->possible_actions( $cmd, 'run' );
            if ( @c and $o->{API}{match_uniq} )
            {
                print $o->msg_ambiguous_cmd( $cmd, @c );
            }
            else
            {
                print $o->msg_unknown_cmd($cmd);
            }
        }
    }
    else
    {
        $o->run('');
    }
}

sub stoploop { $_[0]->{stop}++ }

sub cmdloop
{
    my $o = shift;
    $o->{stop} = 0;
    $o->preloop;
    while ( defined( my $line = $o->readline( $o->prompt_str ) ) )
    {
        $o->cmd($line);
        last if $o->{stop};
    }
    $o->postloop;
}
*mainloop = \&cmdloop;

sub readline
{
    my $o      = shift;
    my $prompt = shift;
    return $o->{term}->readline($prompt)
        if $o->{API}{check_idle} == 0
        or not defined $o->{term}->IN;

    # They've asked for idle-time running of some user command.
    local $Term::ReadLine::toloop = 1;
    local *Tk::fileevent          = sub {
        my $cls = shift;
        my ( $file, $boring, $callback ) = @_;
        $o->{fh} = $file;        # save the filehandle!
        $o->{cb} = $callback;    # save the callback!
    };
    local *Tk::DoOneEvent = sub {

        # We'll totally cheat and do a select() here -- the timeout will be
        # $o->{API}{check_idle}; if the handle is ready, we'll call &$cb;
        # otherwise we'll call $o->idle(), which can do some processing.
        my $timeout = $o->{API}{check_idle};
        use IO::Select;
        if ( IO::Select->new( $o->{fh} )->can_read($timeout) )
        {
            # Input is ready: stop the event loop.
            $o->{cb}->();
        }
        else
        {
            $o->idle;
        }
    };
    $o->{term}->readline($prompt);
}

sub term { $_[0]->{term} }

# These are likely candidates for overriding in subclasses
sub init       { }             # called last in the ctor
sub fini       { }             # called first in the dtor
sub preloop    { }
sub postloop   { }
sub precmd     { }
sub postcmd    { }
sub prompt_str { 'shell> ' }
sub idle       { }
sub cmd_prefix { '' }
sub cmd_suffix { '' }

#=============================================================================
# The pager
#=============================================================================
sub page
{
    my $o        = shift;
    my $text     = shift;
    my $maxlines = shift || $o->termsize->{rows};
    my $pager    = $o->{API}{pager};

    # First, count the number of lines in the text:
    my $lines = ( $text =~ tr/\n// );

    # If there are fewer lines than the page-lines, just print it.
    if ( $lines < $maxlines or $maxlines == 0 or $pager eq 'none' )
    {
        print $text;
    }

    # If there are more, page it, either using the external pager...
    elsif ( $pager and $pager ne 'internal' )
    {
        require File::Temp;
        my ( $handle, $name ) = File::Temp::tempfile();
        select( ( select($handle), $| = 1 )[0] );
        print $handle $text;
        close $handle;
        system( $pager, $name ) == 0
            or print <<END;
Warning: can't run external pager '$pager': $!.
END
        unlink $name;
    }

    # ... or the internal one
    else
    {
        my $togo  = $lines;
        my $line  = 0;
        my @lines = split '^', $text;
        while ( $togo > 0 )
        {
            my @text = @lines[ $line .. $#lines ];
            my $ret  = $o->page_internal( \@text, $maxlines, $togo, $line );
            last if $ret == -1;
            $line += $ret;
            $togo -= $ret;
        }
        return $line;
    }
    return $lines;
}

sub page_internal
{
    my $o        = shift;
    my $lines    = shift;
    my $maxlines = shift;
    my $togo     = shift;
    my $start    = shift;

    my $line = 1;
    while ( $_ = shift @$lines )
    {
        print;
        last if $line >= ( $maxlines - 1 );    # leave room for the prompt
        $line++;
    }
    my $lines_left   = $togo - $line;
    my $current_line = $start + $line;
    my $total_lines  = $togo + $start;

    my $instructions;
    if ( $o->have_readkey )
    {
        $instructions = "any key for more, or q to quit";
    }
    else
    {
        $instructions = "enter for more, or q to quit";
    }

    if ( $lines_left > 0 )
    {
        local $| = 1;
        my $l = "---line $current_line/$total_lines ($instructions)---";
        my $b = ' ' x length($l);
        print $l;
        my $ans = $o->readkey;
        print "\r$b\r" if $o->have_readkey;
        print "\n"     if $ans =~ /q/i or not $o->have_readkey;
        $line = -1     if $ans =~ /q/i;
    }
    $line;
}

#=============================================================================
# Run actions
#=============================================================================
sub run
{
    my $o      = shift;
    my $action = shift;
    my @args   = @_;
    $o->do_action( $action, \@args, 'run' );
}

sub complete
{
    my $o      = shift;
    my $action = shift;
    my @args   = @_;
    my @compls = $o->do_action( $action, \@args, 'comp' );
    return () unless $o->{command}{comp}{found};
    return @compls;
}

sub help
{
    my $o         = shift;
    my $topic     = shift;
    my @subtopics = @_;
    $o->do_action( $topic, \@subtopics, 'help' );
}

sub summary
{
    my $o     = shift;
    my $topic = shift;
    $o->do_action( $topic, [], 'smry' );
}

#=============================================================================
# Manually add & remove handlers
#=============================================================================
sub add_handlers
{
    my $o     = shift;
    my $match = sub {
        if ( my ($ret) = shift =~ /\A(run|help|smry|comp|catch|alias)_/ )
        {
            return $ret;
        }
        return;
    };
LOOP1:
    for my $hnd (@_)
    {
        my $t = $match->($hnd);
        next LOOP1 if !defined $t;
        my $s = substr( $hnd, length($t) + 1 );

        # Add on the prefix and suffix if the command is defined
        if ( length $s )
        {
            substr( $s, 0, 0 ) = $o->cmd_prefix;
            $s .= $o->cmd_suffix;
        }
        $o->{handlers}{$s}{$t} = $hnd;
    }
LOOP2:
    for my $hnd (@_)
    {
        my $t = $match->($hnd);
        next LOOP2 if !defined $t;
        my $s = substr( $hnd, length($t) + 1 );

        # Add on the prefix and suffix if the command is defined
        if ( length $s )
        {
            substr( $s, 0, 0 ) = $o->cmd_prefix;
            $s .= $o->cmd_suffix;
        }
        if ( $o->has_aliases($s) )
        {
            my @s = $o->get_aliases($s);
            for my $alias (@s)
            {
                substr( $alias, 0, 0 ) = $o->cmd_prefix;
                $alias .= $o->cmd_suffix;
                $o->{handlers}{$alias}{$t} = $hnd;
            }
        }
    }
}

sub add_commands
{
    my $o = shift;
    while (@_)
    {
        my ( $cmd, $hnd ) = ( shift, shift );
        $o->{handlers}{$cmd} = $hnd;
    }
}

sub remove_handlers
{
    my $o = shift;
    for my $hnd (@_)
    {
        next unless $hnd =~ /^(run|help|smry|comp|catch|alias)_/o;
        my $t = $1;
        my $a = substr( $hnd, length($t) + 1 );

        # Add on the prefix and suffix if the command is defined
        if ( length $a )
        {
            substr( $a, 0, 0 ) = $o->cmd_prefix;
            $a .= $o->cmd_suffix;
        }
        delete $o->{handlers}{$a}{$t};
    }
}

sub remove_commands
{
    my $o = shift;
    for my $name (@_)
    {
        delete $o->{handlers}{$name};
    }
}

*add_handler    = \&add_handlers;
*add_command    = \&add_commands;
*remove_handler = \&remove_handlers;
*remove_command = \&remove_commands;

#=============================================================================
# Utility methods
#=============================================================================
sub termsize
{
    my $o = shift;
    my ( $rows, $cols ) = ( 24, 78 );

    # Try several ways to get the terminal size
TERMSIZE:
    {
        my $TERM = $o->{term};
        last TERMSIZE unless $TERM;

        my $OUT = $TERM->OUT;

        if ( $TERM and $o->{API}{readline} eq 'Term::ReadLine::Gnu' )
        {
            ( $rows, $cols ) = $TERM->get_screen_size;
            last TERMSIZE;
        }

        if ( $^O eq 'MSWin32' and eval { require Win32::Console } )
        {
            Win32::Console->import;

            # Win32::Console's DESTROY does a CloseHandle(), so save the object:
            $o->{win32_stdout} ||= Win32::Console->new( STD_OUTPUT_HANDLE() );
            my @info = $o->{win32_stdout}->Info;
            $cols = $info[7] - $info[5] + 1;    # right - left + 1
            $rows = $info[8] - $info[6] + 1;    # bottom - top + 1
            last TERMSIZE;
        }

        if ( eval { require Term::Size } )
        {
            my @x = Term::Size::chars($OUT);
            if ( @x == 2 and $x[0] )
            {
                ( $cols, $rows ) = @x;
                last TERMSIZE;
            }
        }

        if ( eval { require Term::Screen } )
        {
            my $screen = Term::Screen->new;
            ( $rows, $cols ) = @$screen{qw(ROWS COLS)};
            last TERMSIZE;
        }

        if ( eval { require Term::ReadKey } )
        {
            ( $cols, $rows ) = eval {
                local $SIG{__WARN__} = sub { };
                Term::ReadKey::GetTerminalSize($OUT);
            };
            last TERMSIZE unless $@;
        }

        if ( $ENV{LINES} or $ENV{ROWS} or $ENV{COLUMNS} )
        {
            $rows = $ENV{LINES}   || $ENV{ROWS} || $rows;
            $cols = $ENV{COLUMNS} || $cols;
            last TERMSIZE;
        }

        {
            local $^W;
            if ( open( my $STTY, "-|", "stty", "size" ) )
            {
                my $l = <$STTY>;
                ( $rows, $cols ) = split /\s+/, $l;
                close $STTY;
            }
        }
    }

    return { rows => $rows, cols => $cols };
}

sub readkey
{
    my $o = shift;
    $o->have_readkey unless $o->{readkey};
    $o->{readkey}->();
}

sub have_readkey
{
    my $o = shift;
    return 1 if $o->{have_readkey};
    my $IN = $o->{term}->IN;
    if ( eval { require Term::InKey } )
    {
        $o->{readkey} = \&Term::InKey::ReadKey;
    }
    elsif ( $^O eq 'MSWin32' and eval { require Win32::Console } )
    {
        $o->{readkey} = sub {
            my $c;

            # from Term::InKey:
            eval {
                # Win32::Console's DESTROY does a CloseHandle(), so save it:
                Win32::Console->import;
                $o->{win32_stdin} ||= Win32::Console->new( STD_INPUT_HANDLE() );
                my $mode = my $orig = $o->{win32_stdin}->Mode or die $^E;
                $mode &= ~( ENABLE_LINE_INPUT() | ENABLE_ECHO_INPUT() );
                $o->{win32_stdin}->Mode($mode) or die $^E;

                $o->{win32_stdin}->Flush or die $^E;
                $c = $o->{win32_stdin}->InputChar(1);
                die $^E unless defined $c;
                $o->{win32_stdin}->Mode($orig) or die $^E;
            };
            die "Not implemented on $^O: $@" if $@;
            $c;
        };
    }
    elsif ( eval { require Term::ReadKey } )
    {
        $o->{readkey} = sub {
            Term::ReadKey::ReadMode( 4, $IN );
            my $c = getc($IN);
            Term::ReadKey::ReadMode( 0, $IN );
            $c;
        };
    }
    else
    {
        $o->{readkey} = sub { scalar <$IN> };
        return $o->{have_readkey} = 0;
    }
    return $o->{have_readkey} = 1;
}
*has_readkey = \&have_readkey;

sub prompt
{
    my $o = shift;
    my ( $prompt, $default, $completions, $casei ) = @_;
    my $term = $o->{term};

    # A closure to read the line.
    my $line;
    my $readline = sub {
        my ( $sh, $gh ) = @{ $term->Features }{qw(setHistory getHistory)};
        my @history = $gh ? $term->GetHistory : ();
        $term->SetHistory() if $sh;
        $line = $o->readline($prompt);
        $line = $default
            if ( ( not defined $line or $line =~ /^\s*$/ )
            and defined $default );

        # Restore the history
        $term->SetHistory(@history) if $sh;
        $line;
    };

    # A closure to complete the line.
    my $complete = sub {
        my ( $word, $line, $start ) = @_;
        return $o->completions( $word, $completions, $casei );
    };

    if ( $term and $term->ReadLine eq 'Term::ReadLine::Gnu' )
    {
        my $attribs = $term->Attribs;
        local $attribs->{completion_function} = $complete;
        &$readline;
    }
    elsif ( $term and $term->ReadLine eq 'Term::ReadLine::Perl' )
    {
        local $readline::rl_completion_function = $complete;
        &$readline;
    }
    else
    {
        &$readline;
    }
    $line;
}

sub format_pairs
{
    my $o    = shift;
    my @keys = @{ shift(@_) };
    my @vals = @{ shift(@_) };
    my $sep  = shift || ": ";
    my $left = shift || 0;
    my $ind  = shift || "";
    my $len  = shift || 0;
    my $wrap = shift || 0;

    if ($wrap)
    {
        eval {
            require Text::Autoformat;
            Text::Autoformat->import(qw(autoformat));
        };
        if ($@)
        {
            warn(
                "Term::Shell::format_pairs(): Text::Autoformat is required "
                    . "for wrapping. Wrapping disabled" )
                if $^W;
            $wrap = 0;
        }
    }
    my $cols = shift || $o->termsize->{cols};
    $len < length($_) and $len = length($_) for @keys;
    my @text;
    for my $i ( 0 .. $#keys )
    {
        next unless defined $vals[$i];
        my $sz   = ( $len - length( $keys[$i] ) );
        my $lpad = $left ? ""        : " " x $sz;
        my $rpad = $left ? " " x $sz : "";
        my $l    = "$ind$lpad$keys[$i]$rpad$sep";
        my $wrap = $wrap & ( $vals[$i] =~ /\s/ and $vals[$i] !~ /^\d/ );
        my $form = (
            $wrap
            ? autoformat(
                "$vals[$i]",    # force stringification
                { left => length($l) + 1, right => $cols, all => 1 },
                )
            : "$l$vals[$i]\n"
        );
        substr( $form, 0, length($l), $l );
        push @text, $form;
    }
    my $text = join '', @text;
    return wantarray ? ( $text, $len ) : $text;
}

sub print_pairs
{
    my $o = shift;
    my ( $text, $len ) = $o->format_pairs(@_);
    $o->page($text);
    return $len;
}

# Handle backslash translation; doesn't do anything complicated yet.
sub process_esc
{
    my $o = shift;
    my $c = shift;
    my $q = shift;
    my $n;
    return '\\' if $c eq '\\';
    return $q   if $c eq $q;
    return "\\$c";
}

# Parse a quoted string
sub parse_quoted
{
    my $o      = shift;
    my $raw    = shift;
    my $quote  = shift;
    my $i      = 1;
    my $string = '';
    my $c;
    while ( $i <= length($raw) and ( $c = substr( $raw, $i, 1 ) ) ne $quote )
    {

        if ( $c eq '\\' )
        {
            $string .= $o->process_esc( substr( $raw, $i + 1, 1 ), $quote );
            $i++;
        }
        else
        {
            $string .= substr( $raw, $i, 1 );
        }
        $i++;
    }
    return ( $string, $i );
}

sub line
{
    my $o = shift;
    $o->{line};
}

sub line_args
{
    my $o    = shift;
    my $line = shift || $o->line;
    $o->line_parsed($line);
    $o->{line_args} || '';
}

sub line_parsed
{
    my $o    = shift;
    my $args = shift || $o->line || return ();
    my @args;

    # Parse an array of arguments. Whitespace separates, unless quoted.
    my $arg = undef;
    $o->{line_args} = undef;
    for ( my $i = 0 ; $i < length($args) ; $i++ )
    {
        my $c = substr( $args, $i, 1 );
        if ( $c =~ /\S/ and @args == 1 )
        {
            $o->{line_args} ||= substr( $args, $i );
        }
        if ( $c =~ /['"]/ )
        {
            my ( $str, $n ) = $o->parse_quoted( substr( $args, $i ), $c );
            $i += $n;
            $arg = ( defined($arg) ? $arg : '' ) . $str;
        }

        # We do not parse outside of strings
        #   elsif ($c eq '\\') {
        #       $arg = (defined($arg) ? $arg : '')
        #         . $o->process_esc(substr($args,$i+1,1));
        #       $i++;
        #   }
        elsif ( $c =~ /\s/ )
        {
            push @args, $arg if defined $arg;
            $arg = undef;
        }
        else
        {
            $arg .= substr( $args, $i, 1 );
        }
    }
    push @args, $arg if defined($arg);
    return @args;
}

sub handler
{
    my $o = shift;
    my ( $command, $type, $args, $preserve_args ) = @_;

    # First try finding the standard handler, then fallback to the
    # catch_$type method. The columns represent "action", "type", and "push",
    # which control whether the name of the command should be pushed onto the
    # args.
    my @tries = (
        [ $command,                                $type,   0 ],
        [ $o->cmd_prefix . $type . $o->cmd_suffix, 'catch', 1 ],
    );

    # The user can control whether or not to search for "unique" matches,
    # which means calling $o->possible_actions(). We always look for exact
    # matches.
    my @matches = qw(exact_action);
    push @matches, qw(possible_actions) if $o->{API}{match_uniq};

    for my $try (@tries)
    {
        my ( $cmd, $type, $add_cmd_name ) = @$try;
        for my $match (@matches)
        {
            my @handlers = $o->$match( $cmd, $type );
            next unless @handlers == 1;
            unshift @$args, $command
                if $add_cmd_name and not $preserve_args;
            return $o->unalias( $handlers[0], $type );
        }
    }
    return;
}

sub completions
{
    my $o      = shift;
    my $action = shift;
    my $compls = shift || [];
    my $casei  = shift;
    $casei = $o->{API}{case_ignore} unless defined $casei;
    $casei = $casei ? '(?i)' : '';
    return grep { $_ =~ /$casei^\Q$action\E/ } @$compls;
}

#=============================================================================
# Term::Shell error messages
#=============================================================================
sub msg_ambiguous_cmd
{
    my ( $o, $cmd, @c ) = @_;
    local $" = "\n\t";
    <<END;
Ambiguous command '$cmd': possible commands:
    @c
END
}

sub msg_unknown_cmd
{
    my ( $o, $cmd ) = @_;
    <<END;
Unknown command '$cmd'; type 'help' for a list of commands.
END
}

#=============================================================================
# Term::Shell private methods
#=============================================================================
sub do_action
{
    my $o    = shift;
    my $cmd  = shift;
    my $args = shift || [];
    my $type = shift || 'run';
    my ( $fullname, $cmdname, $handler ) = $o->handler( $cmd, $type, $args );
    $o->{command}{$type} = {
        cmd     => $cmd,
        name    => $cmd,
        found   => defined $handler ? 1 : 0,
        cmdfull => $fullname,
        cmdreal => $cmdname,
        handler => $handler,
    };
    if ( defined $handler )
    {
        # We've found a handler. Set up a value which will call the postcmd()
        # action as the subroutine leaves. Then call the precmd(), then return
        # the result of running the handler.
        $o->precmd( \$handler, \$cmd, $args );
        my $postcmd = Term::Shell::OnScopeLeave->new(
            sub {
                $o->postcmd( \$handler, \$cmd, $args );
            }
        );
        return $o->$handler(@$args);
    }
}

sub uniq
{
    my $o = shift;
    my %seen;
    $seen{$_}++ for @_;
    my @ret;
    for (@_) { push @ret, $_ if $seen{$_}-- == 1 }
    @ret;
}

sub possible_actions
{
    my $o      = shift;
    my $action = shift;
    my $type   = shift;
    my $casei  = $o->{API}{case_ignore} ? '(?i)' : '';
    my @keys   = grep { $_ =~ /$casei^\Q$action\E/ }
        grep { exists $o->{handlers}{$_}{$type} }
        keys %{ $o->{handlers} };
    return @keys;
}

sub exact_action
{
    my $o      = shift;
    my $action = shift;
    my $type   = shift;
    my $casei  = $o->{API}{case_ignore} ? '(?i)' : '';
    my @key    = grep { $action =~ /$casei^\Q$_\E$/ }
        grep { exists $o->{handlers}{$_}{$type} }
        keys %{ $o->{handlers} };
    return () unless @key == 1;
    return $key[0];
}

sub is_alias
{
    my $o      = shift;
    my $action = shift;
    exists $o->{handlers}{$action}{alias} ? 1 : 0;
}

sub has_aliases
{
    my $o      = shift;
    my $action = shift;
    my @a      = $o->get_aliases($action);
    @a ? 1 : 0;
}

sub get_aliases
{
    my $o      = shift;
    my $action = shift;
    my @a      = eval {
        my $hndlr = $o->{handlers}{$action}{alias};
        return () unless $hndlr;
        $o->$hndlr();
    };
    $o->{aliases}{$_} = $action for @a;
    @a;
}

sub unalias
{
    my $o    = shift;
    my $cmd  = shift;    # i.e 'foozle'
    my $type = shift;    # i.e 'run'
    return () unless $type;
    return ( $cmd, $cmd, $o->{handlers}{$cmd}{$type} )
        unless exists $o->{aliases}{$cmd};
    my $alias = $o->{aliases}{$cmd};

    # I'm allowing aliases to call handlers which have been removed. This
    # means I can set up an alias of '!' for 'shell', then delete the 'shell'
    # command, so that you can only access it through '!'. That's why I'm
    # checking the {handlers} entry _and_ building a string.
    my $handler = $o->{handlers}{$alias}{$type} || "${type}_${alias}";
    return ( $cmd, $alias, $handler );
}

sub find_handlers
{
    my $o   = shift;
    my $pkg = shift || $o->{API}{class};

    # Find the handlers in the given namespace:
    my %handlers;
    {
        ## no critic
        no strict 'refs';
        my @r = keys %{ $pkg . "::" };
        $o->add_handlers(@r);
    }

    # Find handlers in its base classes.
    {
        ## no critic
        no strict 'refs';
        my @isa = @{ $pkg . "::ISA" };
        for my $pkg (@isa)
        {
            $o->find_handlers($pkg);
        }
    }
}

sub rl_complete
{
    my $o = shift;
    my ( $word, $line, $start ) = @_;

    # If it's a command, complete 'run_':
    if ( $start == 0 or substr( $line, 0, $start ) =~ /^\s*$/ )
    {
        my @compls = $o->complete( '', $word, $line, $start );
        return @compls if $o->{command}{comp}{found};
    }

    # If it's a subcommand, send it to any custom completion function for the
    # function:
    else
    {
        my $command = ( $o->line_parsed($line) )[0];
        my @compls  = $o->complete( $command, $word, $line, $start );
        return @compls if $o->{command}{comp}{found};
    }

    ();
}

#=============================================================================
# Two action handlers provided by default: help and exit.
#=============================================================================
sub smry_exit { "exits the program" }

sub help_exit
{
    <<'END';
Exits the program.
END
}

sub run_exit
{
    my $o = shift;
    $o->stoploop;
}

sub smry_help { "prints this screen, or help on 'command'" }

sub help_help
{
    <<'END';
Provides help on commands...
END
}

sub comp_help
{
    my ( $o, $word, $line, $start ) = @_;
    my @words = $o->line_parsed($line);
    return []
        if ( @words > 2 or @words == 2 and $start == length($line) );
    sort $o->possible_actions( $word, 'help' );
}

sub run_help
{
    my $o   = shift;
    my $cmd = shift;
    if ($cmd)
    {
        my $txt = $o->help( $cmd, @_ );
        if ( $o->{command}{help}{found} )
        {
            $o->page($txt);
        }
        else
        {
            my @c = sort $o->possible_actions( $cmd, 'help' );
            if ( @c and $o->{API}{match_uniq} )
            {
                local $" = "\n\t";
                print <<END;
Ambiguous help topic '$cmd': possible help topics:
    @c
END
            }
            else
            {
                print <<END;
Unknown help topic '$cmd'; type 'help' for a list of help topics.
END
            }
        }
    }
    else
    {
        print "Type 'help command' for more detailed help on a command.\n";
        my ( %cmds, %docs );
        my %done;
        my %handlers;
        for my $h ( keys %{ $o->{handlers} } )
        {
            next unless length($h);
            next
                unless grep { defined $o->{handlers}{$h}{$_} }
                qw(run smry help);
            my $dest = exists $o->{handlers}{$h}{run} ? \%cmds : \%docs;
            my $smry = do { my $x = $o->summary($h); $x ? $x : "undocumented" };
            my $help =
                exists $o->{handlers}{$h}{help}
                ? (
                exists $o->{handlers}{$h}{smry}
                ? ""
                : " - but help available"
                )
                : " - no help available";
            $dest->{"    $h"} = "$smry$help";
        }
        my @t;
        push @t, "  Commands:\n" if %cmds;
        push @t,
            scalar $o->format_pairs(
            [ sort keys %cmds ],
            [ map { $cmds{$_} } sort keys %cmds ],
            ' - ', 1
            );
        push @t, "  Extra Help Topics: (not commands)\n" if %docs;
        push @t,
            scalar $o->format_pairs(
            [ sort keys %docs ],
            [ map { $docs{$_} } sort keys %docs ],
            ' - ', 1
            );
        $o->page( join '', @t );
    }
}

sub run_ { }

sub comp_
{
    my ( $o, $word, $line, $start ) = @_;
    my @comp = grep { length($_) } sort $o->possible_actions( $word, 'run' );
    return @comp;
}

package Term::Shell::OnScopeLeave;
$Term::Shell::OnScopeLeave::VERSION = '0.13';
sub new
{
    return bless [ @_[ 1 .. $#_ ] ], ref( $_[0] ) || $_[0];
}

sub DESTROY
{
    my $o = shift;
    for my $c (@$o)
    {
        $c->();
    }

    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Term::Shell - A simple command-line shell framework.

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    package MyShell;
    use base qw(Term::Shell);

    sub run_command1  { print "command 1!\n"; }
    sub smry_command1 { "what does command1 do?" }
    sub help_command1 {
        <<'END';
    Help on 'command1', whatever that may be...
    END
    }

    sub run_command2 { print "command 2!\n"; }

    package main;
    my $shell = MyShell->new;
    $shell->cmdloop;

=head1 DESCRIPTION

Term::Shell lets you write simple command-line shells. All the boring details
like command-line parsing, terminal handling, and tab completion are handled
for you.

The base class comes with two commands pre-defined: exit and help.

To write a shell with an C<exec> command, do something like this:

   package MyShell;
   use base qw(Term::Shell); # or manually edit @MyShell::ISA.

   sub run_exec {
       my ($o, $cmd, @args) = @_;
       if ($cmd ne $0) {
           print "I'm sorry you're leaving us...\n";
       }
       exec $cmd, @args;
       exit 1;
   }

When Term::Shell needs to handle the C<exec> command, it will invoke this
method. That's all there is to it! You write handlers, and Term::Shell handles
the gory details.

=head1 Using Term::Shell Shells

How do you bring your shell to life? Assuming the package C<MyShell> contains
your actions, just do this:

   use MyShell;
   my $shell = MyShell->new;

   # Setup code here (if you wish)

   # Invoke the shell
   $shell->cmdloop;

   # Cleanup code here (if you wish)

Most people put the setup code in the shell itself, so you can usually get
away with this:

   use MyShell;
   MyShell->new->cmdloop;

It's that simple! All the actions and command handlers go in C<MyShell.pm>,
and your main program is simple. In fact, it's so simple that some people like
to write both the actions and the invocation in the same file:

   package main;
   MyShell->new->cmdloop;

   package MyShell;
   use base qw(Term::Shell);

   # Actions here

Adding commands to your shell is just as easy, if not easier.

=head1 Adding Commands to Your Shell

For every command C<foo>, Term::Shell needs a method called C<run_foo()>,
where 'foo' is what the user will type in. The method will be called with the
Term::Shell object as the first parameter, followed by any arguments the user
typed after the command.

Several prefixes other than C<run_> are supported; each prefix tells
Term::Shell to call that handler under different circumstances. The following
list enumerates all the "special" prefixes. Term::Shell will ignore any method
that doesn't start with a prefix listed here.

=over 4

=item 1

run_foo()

Adds the command C<foo> to the list of supported commands. The method's return
value is saved by Term::Shell, but is not used.

The method is called with the Term::Shell object as its first argument,
followed by any arguments the user typed in.

Special case: if you provide a method C<run_()>, Term::Shell will call it
whenever the user enters a blank line. A blank line is anything which matches
the regular expression C</^\s*$/>.

=item 2

help_foo()

Adds the command C<foo> to the list of help topics. This means the user may
enter 'help foo' and get a help screen. It should return a single string to be
displayed to the user.

The method is called with the Term::Shell object as its first argument,
followed by any arguments the user typed in after 'help foo'. You can
implement hierarchical help documents by using the arguments.

If you do not provide a C<help_foo()> method, typing 'help foo' produces an
error message.

=item 3

smry_foo()

Should return a one-line summary of C<foo>, to be displayed in the help screen.

This method is called with the Term::Shell object as its first argument, and
no other arguments.

If you do not provide a C<smry_foo()> method, then the string 'undocumented'
is used instead.

=item 4

comp_foo()

Provides custom tab-completion for C<foo>. That means if the user types 'foo '
and then hits <TAB>, this method will be called. It should return an array
reference containing a list of possible completions.

This method is called with the Term::Shell object as its first argument,
followed by the three arguments:

=over 4

=item 1

$word

The word the user is trying to complete.

=item 2

$line

The line as typed by the user so far.

=item 3

$start

The offset into $line where $word starts.

=back

If you do not provide C<comp_foo()>, Term::Shell will always return no
completions for C<foo>.

Special case: if you provide C<comp_()>, Term::Shell will call it when the
user is trying to complete the name of a command. Term::Shell provides a
default C<comp_()> method, which completes the actions that you have written
handlers for. If you want to provide tab-completion for commands that do not
have handlers, override C<comp_()>.

=item 5

alias_foo()

Returns a list of aliases for C<foo>. When one of the aliases is used instead
of C<foo>, the corresponding handler for C<foo> is called.

=item 6

catch_run()

catch_help()

catch_comp()

catch_smry()

Called when an undefined action is entered by the user. Normally when the
user enters an unrecognized command, Term::Shell will print an error message
and continue.

This method is called with the Term::Shell object, the command typed by the
user, and then the arguments which would normally be passed to the real
handler.

The C<catch_> methods may do anything the original function would have done.
If you want, you can implement all the commands in it, but that means you're
doing more work than you have to. Be lazy.

=back

=head2 When you want something done right...

You sometimes have to do it yourself. Introducing add_handlers(). Naturally,
it adds a handler to the list of defined handlers in the shell.

Term::Shell can't always find the commands you want to implement by searching
the inheritance tree. Having an AUTOLOAD() method, for instance, will break
this system. In that situation, you may wish to tell Term::Shell about the
extra commands available using add_handlers():

   package MyShell;
   use base qw(Term::Shell);

   sub AUTOLOAD {
       if ($AUTOLOAD =~ /::run_fuzz$/) {
           # code for 'fuzz' command
       }
       elsif ($AUTOLOAD =~ /::run_foozle$/) {
           # code for 'foozle' command
       }
   }

   sub init {
       my $o = shift;
       $o->add_handlers("run_fuzz", "run_foozle");
   }

There are other ways to do this. You could write a C<catch_run> routine and do
the same thing from there. You'd have to override C<comp_> so that it would
complete on "foozle" and "fuzz". The advantage to this method is that it adds
the methods to the list of commands, so they show up in the help menu I<and>
you get completion for free.

=head1 Removing Commands from Your Shell

You're probably thinking "just don't write them". But remember, you can
inherit from another shell class, and that parent may define commands you want
to disable. Term::Shell provides a simple method to make itself forget about
commands it already knows about:

=over 4

=item 1

remove_commands()

Removes all handlers associated with the given command (or list of commands).

For example, Term::Shell comes with two commands (C<exit> and C<help>)
implemented with seven handlers:

=over 4

=item 1

smry_exit()

=item 2

help_exit()

=item 3

run_exit()

=item 4

smry_help()

=item 5

help_help()

=item 6

comp_help()

=item 7

run_help()

=back

If you want to create a shell that doesn't implement the C<help> command,
your code might look something like this example:

   package MyShell;
   use base qw(Term::Shell);

   sub init {
       my $o = shift;
       $o->remove_commands("help");
   }

   # ... define more handlers here ...

=item 2

remove_handlers()

Removes the given handler (or handlers) from the list of defined commands. You
have to specify a full handler name, including the 'run_' prefix. You can
obviously specify any of the other prefixes too.

If you wanted to remove the help for the C<exit> command, but preserve the
command itself, your code might look something like this:

   package MyShell;
   use base qw(Term::Shell);

   sub init {
       my $o = shift;
       $o->remove_handlers("help_exit");
   }

   # ... define more handlers here ...

=back

=head2 Cover Your Tracks

If you do remove built in commands, you should be careful not to let
Term::Shell print references to them. Messages like this are guaranteed to
confuse people who use your shell:

   shell> help
   Unknown command 'help'; type 'help' for a list of commands.

Here's the innocuous looking code:

   package MyShell;
   use base qw(Term::Shell);

   sub init {
       my $o = shift;
       $o->remove_commands("help");
   }

   MyShell->new->cmdloop;

The problem is that Term::Shell has to print an error message, and by default
it tells the user to use the C<help> command to see what's available. If you
remove the C<help> command, you still have to clean up after yourself and tell
Term::Shell to change its error messages:

=over 4

=item 1

msg_unknown_cmd()

Called when the user has entered an unrecognized command, and no action was
available to satisfy it. It receives the object and the command typed by the
user as its arguments. It should return an error message; by default, it is
defined thusly:

   sub msg_unknown_cmd {
       my ($o, $cmd) = @_;
       <<END;
   Unknown command '$cmd'; type 'help' for a list of commands.
   END
   }

=item 2

msg_ambiguous_cmd()

Called when the user has entered a command for which more than handler exists.
(For example, if both "quit" and "query" are commands, then "qu" is an
ambiguous command, because it could be either.) It receives the object, the
command, and the possible commands which could complete it. It should return
an error message; by default it is defined thusly:

   sub msg_ambiguous_cmd {
       my ($o, $cmd, @c) = @_;
       local $" = "\n\t";
       <<END;
   Ambiguous command '$cmd': possible commands:
           @c
   END
   }

=back

=head1 The Term::Shell API

Shell classes can use any of the methods in this list. Any other methods in
Term::Shell may change.

=over 4

=item 1

new()

Creates a new Term::Shell object. It currently does not use its arguments. The
arguments are saved in '$o->{API}{args}', in case you want to use them later.

   my $sh = Term::Shell->new(@arbitrary_args);

=item 2

cmd()

   cmd($txt);

Invokes C<$txt> as if it had been typed in at the prompt.

   $sh->cmd("echo 1 2 3");

=item 3

cmdloop()

mainloop()

Repeatedly prompts the user, reads a line, parses it, and invokes a handler.
Uses C<cmd()> internally.

   MyShell->new->cmdloop;

mainloop() is a synonym for cmdloop(), provided for backwards compatibility.
Earlier (unreleased) versions of Term::Shell have only provided mainloop().
All documentation and examples use cmdloop() instead.

=item 4

init()

fini()

Do any initialization or cleanup you need at shell creation (init()) and
destruction (fini()) by defining these methods.

No parameters are passed.

=item 5

preloop()

postloop()

Do any initialization or cleanup you need at shell startup (preloop()) and
shutdown (postloop()) by defining these methods.

No parameters are passed.

=item 6

precmd()

postcmd()

Do any initialization or cleanup before and after calling each handler.

The parameters are:

=over 4

=item 1

$handler

A reference to the name of the handler that is about to be executed.

Passed by reference so you can control which handler will be called.

=item 2

$cmd

A reference to the command as the user typed it.

Passed by reference so you can set the command. (If the handler is a "catch_"
command, it can be fooled into thinking the user typed some other command, for
example.)

=item 3

$args

The arguments as typed by the user. This is passed as an array reference so
that you can manipulate the arguments received by the handler.

=back

   sub precmd {
       my $o = shift;
       my ($handler, $cmd, @args) = @_;
       # ...
   }

=item 7

stoploop()

Sets a flag in the Term::Shell object that breaks out of cmdloop(). Note that
cmdloop() resets this flag each time you call it, so code like this will work:

   my $sh = MyShell->new;
   $sh->cmdloop;    # an interactive session
   $sh->cmdloop;    # prompts the user again

Term::Shell's built-in run_exit() command just calls stoploop().

=item 8

idle()

If you set C<check_idle> to a non-zero number (see L<The Term::Shell Object>)
then this method is called every C<check_idle> seconds. The idle() method
defined in Term::Shell does nothing -- it exists only to be redefined in
subclasses.

   package MyShell;
   use base qw(Term::Shell);

   sub init {
       my $o = shift;
       $o->{API}{check_idle} = 0.1; # 10/s
   }

   sub idle {
       print "Idle!\n";
   }

=item 9

prompt_str()

Returns a string to be used as the prompt. prompt_str() is called just before
calling the readline() method of Term::ReadLine. If you do not override this
method, the string `shell> ' is used.

   package MyShell;
   use base qw(Term::Shell);

   sub prompt_str { "search> " }

=item 10

prompt()

Term::Shell provides this method for convenience. It's common for a handler to
ask the user for more information. This method makes it easy to provide the
user with a different prompt and custom completions provided by you.

The prompt() method takes the following parameters:

=over 4

=item 1

$prompt

The prompt to display to the user. This can be any string you want.

=item 2

$default

The default value to provide. If the user enters a blank line (all whitespace
characters) then the this value will be returned.

Note: unlike ExtUtils::MakeMaker's prompt(), Term::Shell's prompt() does not
modify $prompt to indicate the $default response. You have to do that
yourself.

=item 3

$completions

An optional list of completion values. When the user hits <TAB>, Term::Shell
prints the completions which match what they've typed so far. Term::Shell does
not enforce that the user's response is one of these values.

=item 4

$casei

An optional boolean value which indicates whether the completions should be
matched case-insensitively or not. A true value indicates that C<FoO> and
C<foo> should be considered the same.

=back

prompt() returns the unparsed line to give you maximum flexibility. If you
need the line parsed, use the line_parsed() method on the return value.

=item 11

cmd_prefix()

cmd_suffix()

These methods should return a prefix and suffix for commands, respectively.
For instance, an IRC client will have a prefix of C</>. Most shells have an
empty prefix and suffix.

=item 12

page()

   page($txt)

Prints C<$txt> through a pager, prompting the user to press a key for the next
screen full of text.

=item 13

line()

line_parsed()

Although C<run_foo()> is called with the parsed arguments from the
command-line, you may wish to see the raw command-line. This is available
through the line() method. If you want to retrieve the parsed line again, use
line_parsed().

line_parsed() accepts an optional string parameter: the line to parse. If you
have your own line to parse, you can pass it to line_parsed() and get back a
list of arguments. This is useful inside completion methods, since you don't
get a parsed list there.

=item 14

run()

If you want to run another handler from within a handler, and you have
pre-parsed arguments, use run() instead of cmd(). cmd() parses its parameter,
whereas run() takes each element as a separate parameter.

It needs the name of the action to run and any arguments to pass to the
handler.

Term::Shell uses this method internally to invoke command handlers.

=item 15

help()

If you want to get the raw text of a help message, use help(). It needs the
name of the help topic and any arguments to pass to the handler.

Term::Shell uses this method internally to invoke help handlers.

=item 16

summary()

If you want to get the summary text of an action, use summary(). It needs the
name of the action.

Term::Shell uses this method internally to display the help page.

=item 17

possible_actions()

You will probably want this method in comp_foo(). possible_actions() takes a
word and a list, and returns a list of possible matches. Term::Shell uses this
method internally to decide which handler to run when the user enters a
command.

There are several arguments, but you probably won't use them all in the simple
cases:

=over 4

=item 1

$needle

The (possible incomplete) word to try to match against the list of actions
(the haystack).

=item 2

$type

The type with which to prefix C<$action>. This is useful when completing a
real action -- you have to specify whether you want it to look for "run_" or
"help_" or something else. If you leave it blank, it will use C<$action>
without prefixing it.

=item 3

$strip

If you pass in a true value here, possible_actions() will remove an initial
C<$type> from the beginning of each result before returning the results. This
is useful if you want to know what the possible "run_" commands are, but you
don't want to have the "run_" in the final result.

If you do not specify this argument, it uses '0' (the default is not to strip
the results).

=item 4

$haystack

You can pass in a reference to a list of strings here. Each string will be
compared with C<$needle>.

If you do not specify this argument, it uses the list of handlers. This is how
Term::Shell matches commands typed in by the user with command handlers
written by you.

=back

=item 18

print_pairs()

This overloaded beast is used whenever Term::Shell wants to print a set of
keys and values. It handles wrapping long values, indenting the whole thing,
inserting the separator between the key and value, and all the rest.

There are lots of parameters, but most of them are optional:

=over 4

=item 1

$keys

A reference to a list of keys to print.

=item 2

$values

A reference to a list of values to print.

=item 3

$sep

The string used to separate the keys and values. If omitted, ': ' is used.

=item 4

$left

The justification to be used to line up the keys. If true, the keys will be
left-justified. If false or omitted, the keys will be right-justified.

=item 5

$ind

A string used to indent the whole paragraph. Internally, print_pairs() uses
length(), so you shouldn't use tabs in the indent string. If omitted, the
empty string is used (no indent).

=item 6

$len

An integer which describes the minimum length of the keys. Normally,
print_pairs() calculates the longest key and assigns the column width to be
as wide as the longest key plus the separator. You can force the column width
to be larger using $len. If omitted, 0 is used.

=item 7

$wrap

A boolean which indicates whether the value should be text-wrapped using
Text::Autoformat. Text is only ever wrapped if it contains at least one space.
If omitted, 0 is used.

=item 8

$cols

An integer describing the number of columns available on the current terminal.
Normally 78 is used, or the environment variable COLUMNS, but you can override
the number here to simulate a right-indent.

=back

=item 19

term()

Returns the underlying C<Term::ReadLine> object used to interact with the
user. You can do powerful things with this object; in particular, you will
cripple Term::Shell's completion scheme if you change the completion callback
function.

=item 20

process_esc()

This method may be overridden to provide shell-like escaping of backslashes
inside quoted strings. It accepts two parameters:

=over 4

=item 1

$c

The character which was escaped by a backslash.

=item 2

$quote

The quote character used to delimit this string. Either C<"> or C<'>.

=back

This method should return the string which should replace the backslash and
the escaped character.

By default, process_esc() uses escaping rules similar to Perl's single-quoted
string:

=over 4

=item 1

Escaped backslashes return backslashes. The string C<"123\\456"> returns
C<123\456>.

=item 2

Escaped quote characters return the quote character (to allow quote characters
in strings). The string C<"abc\"def"> returns C<abc"def>.

=item 3

All other backslashes are returned verbatim. The string C<"123\456"> returns
C<123\456>.

=back

Term::Shell's quote characters cannot be overridden, unless you override
line_parsed(): they are C<"> or C<'>. This may change in a future version of
Term::Shell.

=item 21

add_handlers()

See L<Adding Commands to Your Shell> for information on add_handlers().

=item 22

remove_commands()

remove_handlers()

See L<Removing Commands from Your Shell> for information on remove_handlers().

=back

=head1 The Term::Shell Object

Term::Shell creates a hash based Perl object. The object contains information
like what handlers it found, the underlying Term::ReadLine object, and any
arguments passed to the constructor.

This hash is broken into several subhashes. The only two subhashes that a
Shell should ever use are $o->{API} and $o->{SHELL}. The first one contains
all the information that Term::Shell has gathered for you. The second one is a
private area where your Shell can freely store data that it might need later
on.

This section will describe all the Term::Shell object "API" attributes:

=head2 The args Attribute

This an array reference containing any arguments passed to the Term::Shell
constructor.

=head2 The case_ignore Attribute

This boolean controls whether commands should be matched without regard to
case. If this is true, then typing C<FoO> will have the same effect as typing
C<foo>.

Defaults to true on MSWin32, and false on other platforms.

=head2 The class Attribute

The class of the object. This is probably the package containing the
definition of your shell, but if someone subclasses I<your> shell, it's their
class.

=head2 The command Attribute

Whenever Term::Shell invokes an action, it stores information about the action
in the C<command> attribute. Information about the last "run" action to be
invoked is stored in $o->{API}{command}{run}. The information itself is stored
in a subhash containing these fields:

=over 4

=item name

The name of the command, as typed by the user.

=item found

The a boolean value indicating whether a handler could be found.

=item handler

The full name of the handler, if found.

=back

Note that this facility only stores information about the I<last> action to be
executed. It's good enough for retrieving the information about the last
handler which ran, but not for much else.

The following example shows a case where C<run_foo()> calls C<run_add()>, and
prints its return value (in this case, 42).

   sub run_foo {
       my $o = shift;
       my $sum = $o->run("add", 21, 21);
       print "21 + 21 = ", $sum, "\n";
   }

   sub run_add {
       my $o = shift;
       my $sum = 0;
       $sum += $_ for @_;
       print "add(): sum = $sum\n";
       return $sum;
   }

At the end of run_foo(), $o->{API}{command}{run}{handler} contains the string
C<"run_add">.

=head2 The match_uniq Attribute

This boolean controls whether the user can type in only enough of the command
to make it unambiguous. If true, then if the shell has the commands C<foo> and
C<bar> defined, the user can type C<f> to run C<foo>, and C<b> to run C<bar>.

Defaults to true.

=head2 The readline Attribute

Which Term::ReadLine module is being used. Currently, this is always one of
C<Term::ReadLine::Stub>, C<Term::ReadLine::Perl>, or C<Term::ReadLine::Gnu>.

=head2 The script Attribute

The name of the script that invoked your shell.

=head2 The version Attribute

The version of Term::Shell you are running under.

=head1 SEE ALSO

For more information about the underlying ReadLine module, see
L<Term::ReadLine>. You may also want to look at L<Term::ReadLine::Gnu> and
L<Term::ReadLine::Perl>.

For more information about the underlying formatter used by print_pairs(), see
L<Text::Autoformat>.

The API for Term::Shell was inspired by (gasp!) a Python package called
C<cmd>. For more information about this package, please look in the Python
Library Reference, either in your Python distribution or at
L<https://docs.python.org/3/library/cmd.html> .

=head1 AUTHOR

Neil Watkiss (NEILW@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001, Neil Watkiss. All Rights Reserved.

All Rights Reserved. This module is free software. It may be used,
redistributed and/or modified under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Term-Shell>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-Shell>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Term-Shell>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Term-Shell>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Term-Shell>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Term::Shell>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-term-shell at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Term-Shell>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Term-Shell>

  git clone git://git@github.com:shlomif/Term-Shell.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-Shell> or by email to
L<bug-term-shell@rt.cpan.org|mailto:bug-term-shell@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Neil Watkiss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
