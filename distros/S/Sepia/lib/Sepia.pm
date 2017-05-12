package Sepia;

=head1 NAME

Sepia - Simple Emacs-Perl Interface

=head1 SYNOPSIS

From inside Emacs:

   M-x load-library RET sepia RET
   M-x sepia-repl RET

At the prompt in the C<*sepia-repl*> buffer:

   main @> ,help

For more information, please see F<Sepia.html> or F<sepia.info>, which
come with the distribution.

=head1 DESCRIPTION

Sepia is a set of features to make Emacs a better tool for Perl
development.  This package contains the Perl side of the
implementation, including all user-serviceable parts (for the
cross-referencing facility see L<Sepia::Xref>).  This document is
aimed as Sepia developers; for user documentation, see
L<Sepia.html> or L<sepia.info>.

Though not intended to be used independent of the Emacs interface, the
Sepia module's functionality can be used through a rough procedural
interface.

=cut

$VERSION = '0.992';
BEGIN {
    if ($] >= 5.012) {
        eval 'no warnings "deprecated"'; # undo some of the 5.12 suck.
    }
    # Not as useful as I had hoped...
    sub track_requires
    {
        my $parent = caller;
        (my $child = $_[1]) =~ s!/!::!g;
        $child =~ s/\.pm$//;
        push @{$REQUIRED_BY{$child}}, $parent;
        push @{$REQUIRES{$parent}}, $child;
    }
    BEGIN { sub TRACK_REQUIRES () { $ENV{TRACK_REQUIRES}||0 } };
    unshift @INC, \&Sepia::track_requires if TRACK_REQUIRES;
}
use strict;
use B;
use Sepia::Debug;               # THIS TURNS ON DEBUGGING INFORMATION!
use Cwd 'abs_path';
use Scalar::Util 'looks_like_number';
use Text::Abbrev;
use File::Find;
use Storable qw(store retrieve);

use vars qw($PS1 %REPL %RK %REPL_DOC %REPL_SHORT %PRINTER
            @res $REPL_LEVEL $REPL_QUIT $PACKAGE $SIGGED
            $WANTARRAY $PRINTER $STRICT $COLUMNATE $ISEVAL $STRINGIFY
            $LAST_INPUT $READLINE @PRE_EVAL @POST_EVAL @PRE_PROMPT
            %REQUIRED_BY %REQUIRES);

BEGIN {
    eval q{ use List::Util 'max' };
    if ($@) {
        *Sepia::max = sub {
            my $ret = shift;
            for (@_) {
                $ret = $_ if $_ > $ret;
            }
            $ret;
        };
    }
}

=head2 Hooks

Like Emacs, Sepia's behavior can be modified by placing functions on
various hooks (arrays).  Hooks can be manipulated by the following
functions:

=over

=item C<add_hook(@hook, @functions)> -- Add C<@functions> to C<@hook>.

=item C<remove_hook(@hook, @functions)> -- Remove named C<@functions> from C<@hook>.

=item C<run_hook(@hook)> -- Run the functions on the named hook.

Each function is called with no arguments in an eval {} block, and
its return value is ignored.

=back

Sepia currently defines the following hooks:

=over

=item C<@PRE_PROMPT> -- Called immediately before the prompt is printed.

=item C<@PRE_EVAL> -- Called immediately before evaluating user input.

=item C<@POST_EVAL> -- Called immediately after evaluating user input.

=back

=cut

sub run_hook(\@)
{
    my $hook = shift;
    no strict 'refs';
    for (@$hook) {
        eval { $_->() };
    }
}

sub add_hook(\@@)
{
    my $hook = shift;
    for my $h (@_) {
        push @$hook, $h unless grep $h eq $_, @$hook;
    }
}

sub remove_hook(\@@)
{
    my $hook = shift;
    @$hook = grep { my $x = $_; !grep $_ eq $x, @$hook } @$hook;
}

=head2 Completion

Sepia tries hard to come up with a list of completions.

=over

=item C<$re = _apropos_re($pat)>

Create a completion expression from user input.

=cut

sub _apropos_re($;$)
{
    # Do that crazy multi-word identifier completion thing:
    my $re = shift;
    my $hat = shift() ? '' : '^';
    return qr/.*/ if $re eq '';
    if (wantarray) {
        map {
            s/(?:^|(?<=[A-Za-z\d]))(([^A-Za-z\d])\2*)/[A-Za-z\\d]*$2+/g;
            qr/$hat$_/;
        } split /:+/, $re, -1;
    } else {
        if ($re !~ /[^\w\d_^:]/) {
            $re =~ s/(?<=[A-Za-z\d])(([^A-Za-z\d])\2*)/[A-Za-z\\d]*$2+/g;
        }
        qr/$re/;
    }
}

my %sigil;
BEGIN {
    %sigil = qw(ARRAY @ SCALAR $ HASH %);
}

=item C<$val = filter_untyped>

Return true if C<$_> is the name of a sub, file handle, or package.

=item C<$val = filter_typed $type>

Return true if C<$_> is the name of something of C<$type>, which
should be either a glob slot name (e.g. SCALAR) or the special value
"VARIABLE", meaning an array, hash, or scalar.

=cut


sub filter_untyped
{
    no strict;
    local $_ = /^::/ ? $_ : "::$_";
    defined *{$_}{CODE} || defined *{$_}{IO} || (/::$/ && %$_);
}

## XXX: Careful about autovivification here!  Specifically:
##     defined *FOO{HASH} # => ''
##     defined %FOO       # => ''
##     defined *FOO{HASH} # => 1
sub filter_typed
{
    no strict;
    my $type = shift;
    local $_ = /^::/ ? $_ : "::$_";
    if ($type eq 'SCALAR') {
        defined $$_;
    } elsif ($type eq 'VARIABLE') {
        defined $$_ || defined *{$_}{HASH} || defined *{$_}{ARRAY};
    } else {
        defined *{$_}{$type}
    }
}

=item C<$re_out = maybe_icase $re_in>

Make C<$re_in> case-insensitive if it looks like it should be.

=cut

sub maybe_icase
{
    my $ch = shift;
    return '' if $ch eq '';
    $ch =~ /[A-Z]/ ? $ch : '['.uc($ch).$ch.']';
}

=item C<@res = all_abbrev_completions $pattern>

Find all "abbreviated completions" for $pattern.

=cut

sub all_abbrev_completions
{
    use vars '&_completions';
    local *_completions = sub {
        no strict;
        my ($stash, @e) = @_;
        my $ch = '[A-Za-z0-9]*';
        my $re1 = "^".maybe_icase($e[0]).$ch.join('', map {
            '_'.maybe_icase($_).$ch
        } @e[1..$#e]);
        $re1 = qr/$re1/;
        my $re2 = maybe_icase $e[0];
        $re2 = qr/^$re2.*::$/;
        my @ret = grep !/::$/ && /$re1/, keys %{$stash};
        my @pkgs = grep /$re2/, keys %{$stash};
        (map("$stash$_", @ret),
         @e > 1 ? map { _completions "$stash$_", @e[1..$#e] } @pkgs :
             map { "$stash$_" } @pkgs)
    };
    map { s/^:://; $_ } _completions('::', split //, shift);
}

sub apropos_re
{
    my ($icase, $re) = @_;
    $re =~ s/_/[^_]*_/g;
    $icase ? qr/^$re.*$/i : qr/^$re.*$/;
}

sub all_completions
{
    my $icase = $_[0] !~ /[A-Z]/;
    my @parts = split /:+/, shift, -1;
    my $re = apropos_re $icase, pop @parts;
    use vars '&_completions';
    local *_completions = sub {
        no strict;
        my $stash = shift;
        if (@_ == 0) {
            map { "$stash$_" } grep /$re/, keys %{$stash};
        } else {
            my $re2 = $icase ? qr/^$_[0].*::$/i : qr/^$_[0].*::$/;
            my @pkgs = grep /$re2/, keys %{$stash};
            map { _completions "$stash$_", @_[1..$#_] } @pkgs
        }
    };
    map { s/^:://; $_ } _completions('::', @parts);
}

=item C<@res = filter_exact_prefix @names>

Filter exact matches so that e.g. "A::x" completes to "A::xx" when
both "Ay::xx" and "A::xx" exist.

=cut

sub filter_exact_prefix
{
    my @parts = split /:+/, shift, -1;
    my @res = @_;
    my @tmp;
    my $pre = shift @parts;
    while (@parts && (@tmp = grep /^\Q$pre\E(?:::|$)/, @res)) {
        @res = @tmp;
        $pre .= '::'.shift @parts;
    }
    @res;
}

=item C<@res = lexical_completions $type, $str, $sub>

Find lexicals of C<$sub> (or a parent lexical environment) of type
C<$type> matching C<$str>.

=cut

sub lexical_completions
{
    eval q{ use PadWalker 'peek_sub' };
    # "internal" function, so don't warn on failure
    return if $@;
    *lexical_completions = sub {
        my ($type, $str, $sub) = @_;
        $sub = "$PACKAGE\::$sub" unless $sub =~ /::/;
        # warn "Completing $str of type $type in $sub\n";
        no strict;
        return unless defined *{$sub}{CODE};
        my $pad = peek_sub(\&$sub);
        if ($type) {
            map { s/^[\$\@&\%]//;$_ } grep /^\Q$type$str\E/, keys %$pad;
        } else {
            map { s/^[\$\@&\%]//;$_ } grep /^.\Q$str\E/, keys %$pad;
        }
    };
    goto &lexical_completions;
}

=item C<@compls = completions($string [, $type [, $sub ] ])>

Find a list of completions for C<$string> with glob type C<$type>,
which may be "SCALAR", "HASH", "ARRAY", "CODE", "IO", or the special
value "VARIABLE", which means either scalar, hash, or array.
Completion operates on word subparts separated by [:_], so
e.g. "S:m_w" completes to "Sepia::my_walksymtable".  If C<$sub> is
given, also consider its lexical variables.

=item C<@compls = method_completions($expr, $string [,$eval])>

Complete among methods on the object returned by C<$expr>.  The
C<$eval> argument, if present, is a function used to do the
evaluation; the default is C<eval>, but for example the Sepia REPL
uses C<Sepia::repl_eval>.  B<Warning>: Since it has to evaluate
C<$expr>, method completion can be extremely problematic.  Use with
care.

=cut

sub completions
{
    my ($type, $str, $sub) = @_;
    my $t;
    my %h = qw(@ ARRAY % HASH & CODE * IO $ SCALAR);
    my %rh;
    @rh{values %h} = keys %h;
    $type ||= '';
    $t = $type ? $rh{$type} : '';
    my @ret;
    if ($sub && $type ne '') {
        @ret = lexical_completions $t, $str, $sub;
    }
    if (!@ret) {
        @ret = grep {
            $type ? filter_typed $type : filter_untyped
        } all_completions $str;
    }
    if (!@ret && $str !~ /:/) {
        @ret = grep {
            $type ? filter_typed $type : filter_untyped
        } all_abbrev_completions $str;
    }
    @ret = map { s/^:://; "$t$_" } filter_exact_prefix $str, @ret;
#     ## XXX: Control characters, $", and $1, etc. confuse Emacs, so
#     ## remove them.
    grep {
        length $_ > 0 && !/^\d+$/ && !/^[^\w\d_]$/ && !/^_</ && !/^[[:cntrl:]]/
    } @ret;
}

sub method_completions
{
    my ($x, $fn, $eval) = @_;
    $x =~ s/^\s+//;
    $x =~ s/\s+$//;
    $eval ||= 'CORE::eval';
    no strict;
    return unless ($x =~ /^\$/ && ($x = $eval->("ref($x)")))
        || $eval->('%'.$x.'::');
    unless ($@) {
        my $re = _apropos_re $fn;
        ## Filter out overload methods "(..."
        return sort { $a cmp $b } map { s/.*:://; $_ }
            grep { defined *{$_}{CODE} && /::$re/ && !/\(/ }
                methods($x, 1);
    }
}

=item C<@matches = apropos($name [, $is_regex])>

Search for function C<$name>, either in all packages or, if C<$name>
is qualified, only in one package.  If C<$is_regex> is true, the
non-package part of C<$name> is a regular expression.

=cut

sub my_walksymtable(&*)
{
    no strict;
    my ($f, $st) = @_;
    local *_walk = sub {
        local ($stash) = @_;
        &$f for keys %$stash;
        _walk("$stash$_") for grep /(?<!main)::$/, keys %$stash;
    };
    _walk($st);
}

sub apropos
{
    my ($it, $re, @types) = @_;
    my $stashp;
    if (@types) {
        $stashp = grep /STASH/, @types;
        @types = grep !/STASH/, @types;
    } else {
        @types = qw(CODE);
    }
    no strict;
    if ($it =~ /^(.*::)([^:]+)$/) {
        my ($stash, $name) = ($1, $2);
        if (!%$stash) {
            return;
        }
        if ($re) {
            my $name = qr/^$name/;
            map {
                "$stash$_"
            }
            grep {
                my $stashnm = "$stash$_";
                /$name/ &&
                    (($stashp && /::$/)
                     || scalar grep {
                         defined($_ eq 'SCALAR' ? $$stashnm : *{$stashnm}{$_})
                     } @types)
            } keys %$stash;
        } else {
            defined &$it ? $it : ();
        }
    } else {
        my @ret;
        my $findre = $re ? qr/$it/ : qr/^\Q$it\E$/;
        my_walksymtable {
            push @ret, "$stash$_" if /$findre/;
        } '::';
        map { s/^:*(?:main:+)*//;$_ } @ret;
    }
}

=back

=head2 Module information

=over

=item C<@names = mod_subs($pack)>

Find subs in package C<$pack>.

=cut

sub mod_subs
{
    no strict;
    my $p = shift;
    my $stash = \%{"$p\::"};
    if (%$stash) {
        grep { defined &{"$p\::$_"} } keys %$stash;
    }
}

=item C<@decls = mod_decls($pack)>

Generate a list of declarations for all subroutines in package
C<$pack>.

=cut

sub mod_decls
{
    my $pack = shift;
    no strict 'refs';
    my @ret = map {
	my $sn = $_;
	my $proto = prototype(\&{"$pack\::$sn"});
	$proto = defined($proto) ? "($proto)" : '';
	"sub $sn $proto;";
    } mod_subs($pack);
    return wantarray ? @ret : join '', @ret;
}

=item C<$info = module_info($module, $type)>

Emacs-called function to get module information.

=cut

sub module_info
{
    eval q{ require Module::Info; import Module::Info };
    if ($@) {
        undef;
    } else {
        no warnings;
        *module_info = sub {
            my ($m, $func) = @_;
            my $info;
            if (-f $m) {
                $info = Module::Info->new_from_file($m);
            } else {
                (my $file = $m) =~ s|::|/|g;
                $file .= '.pm';
                if (exists $INC{$file}) {
                    $info = Module::Info->new_from_loaded($m);
                } else {
                    $info = Module::Info->new_from_module($m);
                }
            }
            if ($info) {
                return $info->$func;
            }
        };
        goto &module_info;
    }
}

=item C<$file = mod_file($mod)>

Find the likely file owner for module C<$mod>.

=cut

sub mod_file
{
    my $m = shift;
    $m =~ s/::/\//g;
    while ($m && !exists $INC{"$m.pm"}) {
        $m =~ s#(?:^|/)[^/]+$##;
    }
    $m ? $INC{"$m.pm"} : undef;
}

=item C<@mods = package_list>

Gather a list of all distributions on the system.

=cut

our $INST;
sub inst()
{
    unless ($INST) {
        require ExtUtils::Installed;
        $INST = new ExtUtils::Installed;
    }
    $INST;
}

sub package_list
{
    sort { $a cmp $b } inst()->modules;
}

=item C<@mods = module_list>

Gather a list of all packages (.pm files, really) installed on the
system, grouped by distribution. XXX UNUSED

=cut

sub inc_re
{
    join '|', map quotemeta, sort { length $b <=> length $a } @INC;
}

sub module_list
{
    @_ = package_list unless @_;
    my $incre = inc_re;
    $incre = qr|(?:$incre)/|;
    my $inst = inst;
    map {
        [$_, sort map {
            s/$incre\///; s|/|::|g;$_
        } grep /\.pm$/, $inst->files($_)]
    } @_;
}

=item C<@paths = file_list $module>

List the absolute paths of all files (except man pages) installed by
C<$module>.

=cut

sub file_list
{
    my @ret = eval { grep /\.p(l|m|od)$/, inst->files(shift) };
    @ret ? @ret : ();
}

=item C<@mods = doc_list>

Gather a list of all documented packages (.?pm files, really)
installed on the system, grouped by distribution. XXX UNUSED

=back

=cut

sub doc_list
{
    @_ = package_list unless @_;
    my $inst = inst;
    map {
        [$_, sort map {
            s/.*man.\///; s|/|::|g;s/\..?pm//; $_
        } grep /\..pm$/, $inst->files($_)]
    } @_;
}

=head2 Miscellaneous functions

=over

=item C<$v = core_version($module)>

=cut

sub core_version
{
    eval q{ require Module::CoreList };
    if ($@) {
        '???';
    } else {
        *core_version = sub { Module::CoreList->first_release(@_) };
        goto &core_version;
    }
}

=item C<[$file, $line, $name] = location($name)>

Return a [file, line, name] triple for function C<$name>.

=cut

sub location
{
    no strict;
    map {
        if (my ($pfx, $name) = /^([\%\$\@]?)(.+)/) {
            if ($pfx) {
                warn "Sorry -- can't lookup variables.";
            } else {
                # XXX: svref_2object only seems to work with a package
                # tacked on, but that should probably be done elsewhere...
                $name = 'main::'.$name unless $name =~ /::/;
                my $cv = B::svref_2object(\&{$name});
                if ($cv && defined($cv = $cv->START) && !$cv->isa('B::NULL')) {
                    my ($file, $line) = ($cv->file, $cv->line);
                    if ($file !~ /^\//) {
                        for (@INC) {
                            if (!ref $_ && -f "$_/$file") {
                                $file = "$_/$file";
                                last;
                            }
                        }
                    }
                    my ($shortname) = $name =~ /^(?:.*::)([^:]+)$/;
                    return [Cwd::abs_path($file), $line, $shortname || $name]
                }
            }
        }
        []
    } @_;
}

=item C<lexicals($subname)>

Return a list of C<$subname>'s lexical variables.  Note that this
includes all nested scopes -- I don't know if or how Perl
distinguishes inner blocks.

=cut

sub lexicals
{
    my $cv = B::svref_2object(\&{+shift});
    return unless $cv && ($cv = $cv->PADLIST);
    my ($names, $vals) = $cv->ARRAY;
    map {
        my $name = $_->PV; $name =~ s/\0.*$//; $name
    } grep B::class($_) ne 'SPECIAL', $names->ARRAY;
}

=item C<$lisp = tolisp($perl)>

Convert a Perl scalar to some ELisp equivalent.

=cut

sub tolisp($)
{
    my $thing = @_ == 1 ? shift : \@_;
    my $t = ref $thing;
    if (!$t) {
        if (!defined $thing) {
            'nil'
        } elsif (looks_like_number $thing) {
            ''.(0+$thing);
        } else {
            ## XXX Elisp and perl have slightly different
            ## escaping conventions, so we do this crap instead.
            $thing =~ s/["\\]/\\$1/g;
            qq{"$thing"};
        }
    } elsif ($t eq 'GLOB') {
        (my $name = $$thing) =~ s/\*main:://;
        $name;
    } elsif ($t eq 'ARRAY') {
        '(' . join(' ', map { tolisp($_) } @$thing).')'
    } elsif ($t eq 'HASH') {
        '(' . join(' ', map {
            '(' . tolisp($_) . " . " . tolisp($thing->{$_}) . ')'
        } keys %$thing).')'
    } elsif ($t eq 'Regexp') {
        "'(regexp . \"" . quotemeta($thing) . '")';
#     } elsif ($t eq 'IO') {
    } else {
        qq{"$thing"};
    }
}

=item C<printer(\@res)>

Print C<@res> appropriately on the current filehandle.  If C<$ISEVAL>
is true, use terse format.  Otherwise, use human-readable format,
which can use either L<Data::Dumper>, L<YAML>, or L<Data::Dump>.

=cut

%PRINTER = (
    dumper => sub {
        eval q{ require Data::Dumper };
        local $Data::Dumper::Deparse = 1;
        local $Data::Dumper::Indent = 0;
        local $_;
        my $thing = @res > 1 ? \@res : $res[0];
        eval {
            $_ = Data::Dumper::Dumper($thing);
        };
        if (length $_ > ($ENV{COLUMNS} || 80)) {
            $Data::Dumper::Indent = 1;
            eval {
                $_ = Data::Dumper::Dumper($thing);
            };
        }
        s/\A\$VAR1 = //;
        s/;\Z//;
        $_;
    },
    plain => sub {
        "@res";
    },
    dumpvar => sub {
        if (eval q{require 'dumpvar.pl';1}) {
            dumpvar::veryCompact(1);
            $PRINTER{dumpvar} = sub { dumpValue(\@res) };
            goto &{$PRINTER{dumpvar}};
        }
    },
    yaml => sub {
        eval q{ require YAML };
        if ($@) {
            $PRINTER{dumper}->();
        } else {
            YAML::Dump(\@res);
        }
    },
    dump => sub {
        eval q{ require Data::Dump };
        if ($@) {
            $PRINTER{dumper}->();
        } else {
            Data::Dump::dump(\@res);
        }
    },
    peek => sub {
        eval q{
            require Devel::Peek;
            require IO::Scalar;
        };
        if ($@) {
            $PRINTER{dumper}->();
        } else {
            my $ret = new IO::Scalar;
            my $out = select $ret;
            Devel::Peek::Dump(@res == 1 ? $res[0] : \@res);
            select $out;
            $ret;
        }
    }
);

sub ::_()
{
    if (wantarray) {
        @res
    } else {
        $_
    }
}

sub printer
{
    local *res = shift;
    my $res;
    @_ = @res;
    $_ = @res == 1 ? $res[0] : @res == 0 ? undef : [@res];
    my $str;
    if ($ISEVAL) {
        $res = "@res";
    } elsif (@res == 1 && !$ISEVAL && $STRINGIFY
                 && UNIVERSAL::can($res[0], '()')) {
        # overloaded?
        $res = "$res[0]";
    } elsif (!$ISEVAL && $COLUMNATE && @res > 1 && !grep ref, @res) {
        $res = columnate(@res);
        print $res;
        return;
    } else {
        $res = $PRINTER{$PRINTER}->();
    }
    if ($ISEVAL) {
        print ';;;', length $res, "\n$res\n";
    } else {
        print "$res\n";
    }
}

BEGIN {
    $PS1 = "> ";
    $PACKAGE = 'main';
    $WANTARRAY = '@';
    $PRINTER = 'dumper';
    $COLUMNATE = 1;
    $STRINGIFY = 1;
}

=item C<prompt()> -- Print the REPL prompt.

=cut

sub prompt()
{
    run_hook @PRE_PROMPT;
    "$PACKAGE $WANTARRAY$PS1"
}

sub Dump
{
    eval {
        Data::Dumper->Dump([$_[0]], [$_[1]]);
    };
}

=item C<$flowed = flow($width, $text)> -- Flow C<$text> to at most C<$width> columns.

=cut

sub flow
{
    my $n = shift;
    my $n1 = int(2*$n/3);
    local $_ = shift;
    s/(.{$n1,$n}) /$1\n/g;
    $_
}

=back

=head2 Persistence

=over

=item C<load \@keyvals> -- Load persisted data in C<@keyvals>.

=item C<$ok = saveable $name> -- Return whether C<$name> is saveable.

Saving certain magic variables leads to badness, so we avoid them.

=item C<\@kvs = save $re> -- Return a list of name/value pairs to save.

=back

=cut

sub load
{
    my $a = shift;
    no strict;
    for (@$a) {
        *{$_->[0]} = $_->[1];
    }
}

my %BADVARS;
undef @BADVARS{qw(%INC @INC %SIG @ISA %ENV @ARGV)};

# magic variables
sub saveable
{
    local $_ = shift;
    return !/^.[^c-zA-Z]$/ # single-letter stuff (match vars, $_, etc.)
        && !/^.[\0-\060]/         # magic weirdness.
        && !/^._</        # debugger info
        && !exists $BADVARS{$_}; # others.
}

sub save
{
    my ($re) = @_;
    my @save;
    $re = qr/(?:^|::)$re/;
    no strict;                  # no kidding...
    my_walksymtable {
        return if /::$/
            || $stash =~ /^(?:::)?(?:warnings|Config|strict|B)\b/;
        if (/$re/) {
            my $name = "$stash$_";
            if (defined ${$name} and saveable '$'.$_) {
                push @save, [$name, \$$name];
            }
            if (defined *{$name}{HASH} and saveable '%'.$_) {
                push @save, [$name, \%{$name}];
            }
            if (defined *{$name}{ARRAY} and saveable '@'.$_) {
                push @save, [$name, \@{$name}];
            }
        }
    } '::';
    print STDERR "$_->[0] " for @save;
    print STDERR "\n";
    \@save;
}

=head2 REPL shortcuts

The function implementing built-in REPL shortcut ",X" is named C<repl_X>.

=over

=item C<define_shortcut $name, $sub [, $doc [, $shortdoc]]>

Define $name as a shortcut for function $sub.

=cut

sub define_shortcut
{
    my ($name, $doc, $short, $fn);
    if (@_ == 2) {
        ($name, $fn) = @_;
        $short = $name;
        $doc = '';
    } elsif (@_ == 3) {
        ($name, $fn, $doc) = @_;
        $short = $name;
    } else {
        ($name, $fn, $short, $doc) = @_;
    }
    $REPL{$name} = $fn;
    $REPL_DOC{$name} = $doc;
    $REPL_SHORT{$name} = $short;
    abbrev \%RK, keys %REPL;
}

=item C<alias_shortcut $new, $old>

Alias $new to do the same as $old.

=cut

sub alias_shortcut
{
    my ($new, $old) = @_;
    $REPL{$new} = $REPL{$old};
    $REPL_DOC{$new} = $REPL_DOC{$old};
    ($REPL_SHORT{$new} = $REPL_SHORT{$old}) =~ s/^\Q$old\E/$new/;
    abbrev %RK, keys %REPL;
}

=item C<define_shortcuts()>

Define the default REPL shortcuts.

=cut

sub define_shortcuts
{
    define_shortcut 'help', \&Sepia::repl_help,
        'help [CMD]',
            'Display help on all commands, or just CMD.';
    define_shortcut 'cd', \&Sepia::repl_chdir,
        'cd DIR', 'Change directory to DIR';
    define_shortcut 'pwd', \&Sepia::repl_pwd,
        'Show current working directory';
    define_shortcut 'methods', \&Sepia::repl_methods,
        'methods X [RE]',
            'List methods for reference or package X, matching optional pattern RE';
    define_shortcut 'package', \&Sepia::repl_package,
        'package PKG', 'Set evaluation package to PKG';
    define_shortcut 'who', \&Sepia::repl_who,
        'who PKG [RE]',
            'List variables and subs in PKG matching optional pattern RE.';
    define_shortcut 'wantarray', \&Sepia::repl_wantarray,
        'wantarray [0|1]', 'Set or toggle evaluation context';
    define_shortcut 'format', \&Sepia::repl_format,
        'format [TYPE]', "Set output formatter to TYPE (one of 'dumper', 'dump', 'yaml', 'plain'; default: 'dumper'), or show current type.";
    define_shortcut 'strict', \&Sepia::repl_strict,
        'strict [0|1]', 'Turn \'use strict\' mode on or off';
    define_shortcut 'quit', \&Sepia::repl_quit,
        'Quit the REPL';
    alias_shortcut 'exit', 'quit';
    define_shortcut 'restart', \&Sepia::repl_restart,
        'Reload Sepia.pm and relaunch the REPL.';
    define_shortcut 'shell', \&Sepia::repl_shell,
        'shell CMD ...', 'Run CMD in the shell';
    define_shortcut 'eval', \&Sepia::repl_eval,
        'eval EXP', '(internal)';
    define_shortcut 'size', \&Sepia::repl_size,
        'size PKG [RE]',
            'List total sizes of objects in PKG matching optional pattern RE.';
    define_shortcut define => \&Sepia::repl_define,
        'define NAME [\'DOC\'] BODY',
            'Define NAME as a shortcut executing BODY';
    define_shortcut undef => \&Sepia::repl_undef,
        'undef NAME', 'Undefine shortcut NAME';
    define_shortcut test => \&Sepia::repl_test,
        'test FILE...', 'Run tests interactively.';
    define_shortcut load => \&Sepia::repl_load,
        'load [FILE]', 'Load state from FILE.';
    define_shortcut save => \&Sepia::repl_save,
        'save [PATTERN [FILE]]', 'Save variables matching PATTERN to FILE.';
    define_shortcut reload => \&Sepia::repl_reload,
        'reload [MODULE | /RE/]', 'Reload MODULE, or all modules matching RE.';
    define_shortcut freload => \&Sepia::repl_full_reload,
        'freload MODULE', 'Reload MODULE and all its dependencies.';
    define_shortcut time => \&Sepia::repl_time,
        'time [0|1]', 'Print timing information for each command.';
    define_shortcut lsmod => \&Sepia::repl_lsmod,
        'lsmod [PATTERN]', 'List loaded modules matching PATTERN.';
}

=item C<repl_strict([$value])>

Toggle strict mode.  Requires L<PadWalker> and L<Devel::LexAlias>.

=cut

sub repl_strict
{
    eval q{ use PadWalker qw(peek_sub set_closed_over);
            use Devel::LexAlias 'lexalias';
    };
    if ($@) {
        print "Strict mode requires PadWalker and Devel::LexAlias.\n";
    } else {
        *repl_strict = sub {
            my $x = as_boolean(shift, $STRICT);
            if ($x && !$STRICT) {
                $STRICT = {};
            } elsif (!$x) {
                undef $STRICT;
            }
        };
        goto &repl_strict;
    }
}

sub repl_size
{
    eval q{ require Devel::Size };
    if ($@) {
        print "Size requires Devel::Size.\n";
    } else {
        *Sepia::repl_size = sub {
            my ($pkg, $re) = split ' ', shift, 2;
            if ($re) {
                $re =~ s!^/|/$!!g;
            } elsif (!$re && $pkg =~ /^\/(.*?)\/?$/) {
                $re = $1;
                undef $pkg;
            } elsif (!$pkg) {
                $re = '.';
            }
            my (@who, %res);
            if ($STRICT && !$pkg) {
                @who = grep /$re/, keys %$STRICT;
                for (@who) {
                    $res{$_} = Devel::Size::total_size($Sepia::STRICT->{$_});
                }
            } else {
                no strict 'refs';
                $pkg ||= 'main';
                @who = who($pkg, $re);
                for (@who) {
                    next unless /^[\$\@\%\&]/; # skip subs.
                    next if $_ eq '%SIG';
                    $res{$_} = eval "no strict; package $pkg; Devel::Size::total_size \\$_;";
                }
            }
            my $len = max(3, map { length } @who) + 4;
            my $fmt = '%-'.$len."s%10d\n";
            # print "$pkg\::/$re/\n";
            print 'Var', ' ' x ($len + 2), "Bytes\n";
            print '-' x ($len-4), ' ' x 9, '-' x 5, "\n";
            for (sort { $res{$b} <=> $res{$a} } keys %res) {
                printf $fmt, $_, $res{$_};
            }
        };
        goto &repl_size;
    }
}

=item C<repl_time([$value])>

Toggle command timing.

=cut

my ($time_res, $TIME);
sub time_pre_prompt_bsd
{
    printf "(%.2gr, %.2gu, %.2gs) ", @{$time_res} if defined $time_res;
};

sub time_pre_prompt_plain
{
    printf "(%.2gs) ", $time_res if defined $time_res;
}

sub repl_time
{
    $TIME = as_boolean(shift, $TIME);
    if (!$TIME) {
        print STDERR "Removing time hook.\n";
        remove_hook @PRE_PROMPT, 'Sepia::time_pre_prompt';
        remove_hook @PRE_EVAL, 'Sepia::time_pre_eval';
        remove_hook @POST_EVAL, 'Sepia::time_post_eval';
        return;
    }
    print STDERR "Adding time hook.\n";
    add_hook @PRE_PROMPT, 'Sepia::time_pre_prompt';
    add_hook @PRE_EVAL, 'Sepia::time_pre_eval';
    add_hook @POST_EVAL, 'Sepia::time_post_eval';
    my $has_bsd = eval q{ use BSD::Resource 'getrusage';1 };
    my $has_hires = eval q{ use Time::HiRes qw(gettimeofday tv_interval);1 };
    my ($t0);
    if ($has_bsd) {                    # sweet!  getrusage!
        my ($user, $sys, $real);
        *time_pre_eval = sub {
            undef $time_res;
            ($user, $sys) = getrusage();
            $real = $has_hires ? [gettimeofday()] : $user+$sys;
        };
        *time_post_eval = sub {
            my ($u2, $s2) = getrusage();
            $time_res = [$has_hires ? tv_interval($real, [gettimeofday()])
                             : $s2 + $u2 - $real,
                         ($u2 - $user), ($s2 - $sys)];
        };
        *time_pre_prompt = *time_pre_prompt_bsd;
    } elsif ($has_hires) {      # at least we have msec...
        *time_pre_eval = sub {
            undef $time_res;
            $t0 = [gettimeofday()];
        };
        *time_post_eval = sub {
            $time_res = tv_interval($t0, [gettimeofday()]);
        };
        *time_pre_prompt = *time_pre_prompt_plain;
    } else {
        *time_pre_eval = sub {
            undef $time_res;
            $t0 = time;
        };
        *time_post_eval = sub {
            $time_res = (time - $t0);
        };
        *time_pre_prompt = *time_pre_prompt_plain;
    }
}

sub repl_help
{
    my $width = $ENV{COLUMNS} || 80;
    my $args = shift;
    if ($args =~ /\S/) {
        $args =~ s/^\s+//;
        $args =~ s/\s+$//;
        my $full = $RK{$args};
        if ($full) {
            my $short = $REPL_SHORT{$full};
            my $flow = flow($width - length $short - 4, $REPL_DOC{$full});
            $flow =~ s/(.)\n/"$1\n".(' 'x (4 + length $short))/eg;
            print "$short    $flow\n";
        } else {
            print "$args: no such command\n";
        }
    } else {
        my $left = 1 + max map length, values %REPL_SHORT;
        print "REPL commands (prefixed with ','):\n";

        for (sort keys %REPL) {
            my $flow = flow($width - $left, $REPL_DOC{$_});
            $flow =~ s/(.)\n/"$1\n".(' ' x $left)/eg;
            printf "%-${left}s%s\n", $REPL_SHORT{$_}, $flow;
        }
    }
}

sub repl_define
{
    local $_ = shift;
    my ($name, $doc, $body);
    if (/^\s*(\S+)\s+'((?:[^'\\]|\\.)*)'\s+(.+)/) {
        ($name, $doc, $body) = ($1, $2, $3);
    } elsif (/^\s*(\S+)\s+(\S.*)/) {
        ($name, $doc, $body) = ($1, $2, $2);
    } else {
        print "usage: define NAME ['doc'] BODY...\n";
        return;
    }
    my $sub = eval "sub { do { $body } }";
    if ($@) {
        print "usage: define NAME ['doc'] BODY...\n\t$@\n";
        return;
    }
    define_shortcut $name, $sub, $doc;
    # %RK = abbrev keys %REPL;
}

sub repl_undef
{
    my $name = shift;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    my $full = $RK{$name};
    if ($full) {
        delete $REPL{$full};
        delete $REPL_SHORT{$full};
        delete $REPL_DOC{$full};
        abbrev \%RK, keys %REPL;
    } else {
        print "$name: no such shortcut.\n";
    }
}

sub repl_format
{
    my $t = shift;
    chomp $t;
    if ($t eq '') {
        print "printer = $PRINTER, columnate = @{[$COLUMNATE ? 1 : 0]}\n";
    } else {
        my %formats = abbrev keys %PRINTER;
        if (exists $formats{$t}) {
            $PRINTER = $formats{$t};
        } else {
            warn "No such format '$t' (dumper, dump, yaml, plain).\n";
        }
    }
}

sub repl_chdir
{
    chomp(my $dir = shift);
    $dir =~ s/^~\//$ENV{HOME}\//;
    $dir =~ s/\$HOME/$ENV{HOME}/;
    if (-d $dir) {
        chdir $dir;
        my $ecmd = '(cd "'.Cwd::getcwd().'")';
        print ";;;###".length($ecmd)."\n$ecmd\n";
    } else {
        warn "Can't chdir\n";
    }
}

sub repl_pwd
{
    print Cwd::getcwd(), "\n";
}

=item C<who($package [, $re])>

List variables and functions in C<$package> matching C<$re>, or all
variables if C<$re> is absent.

=cut

sub who
{
    my ($pack, $re_str) = @_;
    $re_str ||= '.?';
    my $re = qr/$re_str/;
    no strict;
    if ($re_str =~ /^[\$\@\%\&]/) {
        ## sigil given -- match it
        sort grep /$re/, map {
            my $name = $pack.'::'.$_;
            (defined *{$name}{HASH} ? '%'.$_ : (),
             defined *{$name}{ARRAY} ? '@'.$_ : (),
             defined *{$name}{CODE} ? $_ : (),
             defined ${$name} ? '$'.$_ : (), # ?
         )
        } grep !/::$/ && !/^(?:_<|[^\w])/ && /$re/, keys %{$pack.'::'};
    } else {
        ## no sigil -- don't match it
        sort map {
            my $name = $pack.'::'.$_;
            (defined *{$name}{HASH} ? '%'.$_ : (),
             defined *{$name}{ARRAY} ? '@'.$_ : (),
             defined *{$name}{CODE} ? $_ : (),
             defined ${$name} ? '$'.$_ : (), # ?
         )
        } grep !/::$/ && !/^(?:_<|[^\w])/ && /$re/, keys %{$pack.'::'};
    }
}

=item C<$text = columnate(@items)>

Format C<@items> in columns such that they fit within C<$ENV{COLUMNS}>
columns.

=cut

sub columnate
{
    my $len = 0;
    my $width = $ENV{COLUMNS} || 80;
    for (@_) {
        $len = length if $len < length;
    }
    my $nc = int($width / ($len+1)) || 1;
    my $nr = int(@_ / $nc) + (@_ % $nc ? 1 : 0);
    my $fmt = ('%-'.($len+1).'s') x ($nc-1) . "%s\n";
    my @incs = map { $_ * $nr } 0..$nc-1;
    my $str = '';
    for my $r (0..$nr-1) {
        $str .= sprintf $fmt, map { defined($_) ? $_ : '' }
            @_[map { $r + $_ } @incs];
    }
    $str =~ s/ +$//m;
    $str
}

sub repl_who
{
    my ($pkg, $re) = split ' ', shift, 2;
    if ($re) {
        $re =~ s!^/|/$!!g;
    } elsif (!$re && $pkg =~ /^\/(.*?)\/?$/) {
        $re = $1;
        undef $pkg;
    } elsif (!$pkg) {
        $re = '.';
    }
    my @x;
    if ($STRICT && !$pkg) {
        @x = grep /$re/, keys %$STRICT;
        $pkg = '(lexical)';
    } else {
        $pkg ||= $PACKAGE;
        @x = who($pkg, $re);
    }
    print($pkg, "::/$re/\n", columnate @x) if @x;
}

=item C<@m = methods($package [, $qualified])>

List method names in C<$package> and its parents.  If C<$qualified>,
return full "CLASS::NAME" rather than just "NAME."

=cut

sub methods
{
    my ($pack, $qualified) = @_;
    no strict;
    my @own = $qualified ? grep {
        defined *{$_}{CODE}
    } map { "$pack\::$_" } keys %{$pack.'::'}
        : grep {
            defined &{"$pack\::$_"}
        } keys %{$pack.'::'};
    if (exists ${$pack.'::'}{ISA} && *{$pack.'::ISA'}{ARRAY}) {
        my %m;
        undef @m{@own, map methods($_, $qualified), @{$pack.'::ISA'}};
        @own = keys %m;
    }
    @own;
}

sub repl_methods
{
    my ($x, $re) = split ' ', shift;
    $x =~ s/^\s+//;
    $x =~ s/\s+$//;
    if ($x =~ /^\$/) {
        $x = $REPL{eval}->("ref $x");
        return 0 if $@;
    }
    $re ||= '.?';
    $re = qr/$re/;
    print columnate sort { $a cmp $b } grep /$re/, methods $x;
}

sub as_boolean
{
    my ($val, $cur) = @_;
    $val =~ s/\s+//g;
    length($val) ? $val : !$cur;
}

sub repl_wantarray
{
    $WANTARRAY = shift || $WANTARRAY;
    $WANTARRAY = '' unless $WANTARRAY eq '@' || $WANTARRAY eq '$';
}

sub repl_package
{
    chomp(my $p = shift);
    $PACKAGE = $p;
}

sub repl_quit
{
    $REPL_QUIT = 1;
    last repl;
}

sub repl_restart
{
    do $INC{'Sepia.pm'};
    if ($@) {
        print "Restart failed:\n$@\n";
    } else {
        $REPL_LEVEL = 0;        # ok?
        goto &Sepia::repl;
    }
}

sub repl_shell
{
    my $cmd = shift;
    print `$cmd 2>& 1`;
}

# Stolen from Lexical::Persistence, then simplified.
sub call_strict
{
    my ($sub) = @_;

    # steal any new "my" variables
    my $pad = peek_sub($sub);
    for my $k (keys %$pad) {
        unless (exists $STRICT->{$k}) {
            if ($k =~ /^\$/) {
                $STRICT->{$k} = \(my $x);
            } elsif ($k =~ /^\@/) {
                $STRICT->{$k} = []
            } elsif ($k =~ /^\%/) {
                $STRICT->{$k} = +{};
            }
        }
    }

    # Grab its lexials
    lexalias($sub, $_, $STRICT->{$_}) for keys %$STRICT;
    $sub->();
}

sub repl_eval
{
    my ($buf) = @_;
    no strict;
    # local $PACKAGE = $pkg || $PACKAGE;
    if ($STRICT) {
        my $ctx = join(',', keys %$STRICT);
        $ctx = $ctx ? "my ($ctx);" : '';
        if ($WANTARRAY eq '$') {
            $buf = 'scalar($buf)';
        } elsif ($WANTARRAY ne '@') {
            $buf = '$buf;1';
        }
        $buf = eval "sub { package $PACKAGE; use strict; $ctx $buf }";
        if ($@) {
            print "ERROR\n$@\n";
            return;
        }
        call_strict($buf);
    } else {
        $buf = "do { package $PACKAGE; no strict; $buf }";
        if ($WANTARRAY eq '@') {
            eval $buf;
        } elsif ($WANTARRAY eq '$') {
            scalar eval $buf;
        } else {
            eval $buf; undef
        }
    }
}

sub repl_test
{
    my ($buf) = @_;
    my @files;
    if ($buf =~ /\S/) {
        $buf =~ s/^\s+//;
        $buf =~ s/\s+$//;
        if (-f $buf) {
            push @files, $buf;
        } elsif (-f "t/$buf") {
            push @files, $buf;
        }
    } else {
        find({ no_chdir => 1,
               wanted => sub {
                   push @files, $_ if /\.t$/;
            }}, Cwd::getcwd() =~ /t\/?$/ ? '.' : './t');
    }
    if (@files) {
        # XXX: this is cribbed from an EU::MM-generated Makefile.
        system $^X, qw(-MExtUtils::Command::MM -e),
            "test_harness(0, 'blib/lib', 'blib/arch')", @files;
     } else {
        print "No test files for '$buf' in ", Cwd::getcwd, "\n";
    }
}

sub repl_load
{
    my ($file) = split ' ', shift;
    $file ||= "$ENV{HOME}/.sepia-save";
    load(retrieve $file);
}

sub repl_save
{
    my ($re, $file) = split ' ', shift;
    $re ||= '.';
    $file ||= "$ENV{HOME}/.sepia-save";
    store save($re), $file;
}

sub modules_matching
{
    my $pat = shift;
    if ($pat =~ /^\/(.*)\/?$/) {
        $pat = $1;
        $pat =~ s#::#/#g;
        $pat = qr/$pat/;
        grep /$pat/, keys %INC;
    } else {
        my $mod = $pat;
        $pat =~ s#::#/#g;
        exists $INC{"$pat.pm"} ? "$pat.pm" : ();
    }
}

sub full_reload
{
    my %save_inc = %INC;
    local %INC;
    for my $name (modules_matching $_[0]) {
        print STDERR "full reload $name\n";
        require $name;
    }
    my @ret = keys %INC;
    while (my ($k, $v) = each %save_inc) {
        $INC{$k} ||= $v;
    }
    @ret;
}

sub repl_full_reload
{
    chomp (my $pat = shift);
    my @x = full_reload $pat;
    print "Reloaded: @x\n";
}

sub repl_reload
{
    chomp (my $pat = shift);
    # for my $name (modules_matching $pat) {
    #     delete $INC{$PAT};
    #     eval "require $name";
    #     if (!$@) {
    #     (my $mod = $name) =~ s/
    if ($pat =~ /^\/(.*)\/?$/) {
        $pat = $1;
        $pat =~ s#::#/#g;
        $pat = qr/$pat/;
        my @rel;
        for (keys %INC) {
            next unless /$pat/;
            if (!do $_) {
                print "$_: $@\n";
            }
            s#/#::#g;
            s/\.pm$//;
            push @rel, $_;
        }
    } else {
        my $mod = $pat;
        $pat =~ s#::#/#g;
        $pat .= '.pm';
        if (exists $INC{$pat}) {
            delete $INC{$pat};
            eval 'require $mod';
            import $mod unless $@;
            print "Reloaded $mod.\n"
        } else {
            print "$mod not loaded.\n"
        }
    }
}

sub repl_lsmod
{
    chomp (my $pat = shift);
    $pat ||= '.';
    $pat = qr/$pat/;
    my $first = 1;
    my $fmt =  "%-20s%8s  %s\n";
    # my $shorten = join '|', sort { length($a) <=> length($b) } @INC;
    # my $ss = sub {
    #     s/^(?:$shorten)\/?//; $_
    # };
    for (sort keys %INC) {
        my $file = $_;
        s!/!::!g;
        s/\.p[lm]$//;
        next if /^::/ || !/$pat/;
        if ($first) {
            printf $fmt, qw(Module Version File);
            printf $fmt, qw(------ ------- ----);
            $first = 0;
        }
        printf $fmt, $_, (UNIVERSAL::VERSION($_)||'???'), $INC{$file};
    }
    if ($first) {
        print "No modules found.\n";
    }
}

=item C<sig_warn($warning)>

Collect C<$warning> for later printing.

=item C<print_warnings()>

Print and clear accumulated warnings.

=cut

my @warn;

sub sig_warn
{
    push @warn, shift
}

sub print_warnings
{
    if (@warn) {
        if ($ISEVAL) {
            my $tmp = "@warn";
            print ';;;'.length($tmp)."\n$tmp\n";
        } else {
            for (@warn) {
                # s/(.*) at .*/$1/;
                print "warning: $_\n";
            }
        }
    }
}

sub repl_banner
{
    print <<EOS;
I need user feedback!  Please send questions or comments to seano\@cpan.org.
Sepia version $Sepia::VERSION.
Type ",h" for help, or ",q" to quit.
EOS
}

=item C<repl()>

Execute a command interpreter on standard input and standard output.
If you want to use different descriptors, localize them before
calling C<repl()>.  The prompt has a few bells and whistles, including:

=over 4

=item Obviously-incomplete lines are treated as multiline input (press
'return' twice or 'C-c' to discard).

=item C<die> is overridden to enter a debugging repl at the point
C<die> is called.

=back

Behavior is controlled in part through the following package-globals:

=over 4

=item C<$PACKAGE> -- evaluation package

=item C<$PRINTER> -- result printer (default: dumper)

=item C<$PS1> -- the default prompt

=item C<$STRICT> -- whether 'use strict' is applied to input

=item C<$WANTARRAY> -- evaluation context

=item C<$COLUMNATE> -- format some output nicely (default = 1)

Format some values nicely, independent of $PRINTER.  Currently, this
displays arrays of scalars as columns.

=item C<$REPL_LEVEL> -- level of recursive repl() calls

If zero, then initialization takes place.

=item C<%REPL> -- maps shortcut names to handlers

=item C<%REPL_DOC> -- maps shortcut names to documentation

=item C<%REPL_SHORT> -- maps shortcut names to brief usage

=back

=back

=cut

sub repl_setup
{
    $| = 1;
    if ($REPL_LEVEL == 0) {
        define_shortcuts;
        -f "$ENV{HOME}/.sepiarc" and eval qq#package $Sepia::PACKAGE; do "$ENV{HOME}/.sepiarc"#;
        warn ".sepiarc: $@\n" if $@;
    }
    Sepia::Debug::add_repl_commands;
    repl_banner if $REPL_LEVEL == 0;
}

$READLINE = sub { print prompt(); <STDIN> };

sub repl
{
    repl_setup;
    local $REPL_LEVEL = $REPL_LEVEL + 1;

    my $in;
    my $buf = '';
    $SIGGED = 0;

    my $nextrepl = sub { $SIGGED++; };

    local (@_, $_);
    local *CORE::GLOBAL::die = \&Sepia::Debug::die;
    local *CORE::GLOBAL::warn = \&Sepia::Debug::warn;
    my @sigs = qw(INT TERM PIPE ALRM);
    local @SIG{@sigs};
    $SIG{$_} = $nextrepl for @sigs;
 repl: while (defined(my $in = $READLINE->())) {
            if ($SIGGED) {
                $buf = '';
                $SIGGED = 0;
                print "\n";
                next repl;
            }
            $buf .= $in;
            $buf =~ s/^\s*//;
            local $ISEVAL;
            if ($buf =~ /^<<(\d+)\n(.*)/) {
                $ISEVAL = 1;
                my $len = $1;
                my $tmp;
                $buf = $2;
                while ($len && defined($tmp = read STDIN, $buf, $len, length $buf)) {
                    $len -= $tmp;
                }
            }
            ## Only install a magic handler if no one else is playing.
            local $SIG{__WARN__} = $SIG{__WARN__};
            @warn = ();
            unless ($SIG{__WARN__}) {
                $SIG{__WARN__} = 'Sepia::sig_warn';
            }
            if (!$ISEVAL) {
                if ($buf eq '') {
                    # repeat last interactive command
                    $buf = $LAST_INPUT;
                } else {
                    $LAST_INPUT = $buf;
                }
            }
            if ($buf =~ /^,(\S+)\s*(.*)/s) {
                ## Inspector shortcuts
                my $short = $1;
                if (exists $Sepia::RK{$short}) {
                    my $ret;
                    my $arg = $2;
                    chomp $arg;
                    $Sepia::REPL{$Sepia::RK{$short}}->($arg, wantarray);
                } else {
                    if (grep /^$short/, keys %Sepia::REPL) {
                        print "Ambiguous shortcut '$short': ",
                            join(', ', sort grep /^$short/, keys %Sepia::REPL),
                                "\n";
                    } else {
                        print "Unrecognized shortcut '$short'\n";
                    }
                    $buf = '';
                    next repl;
                }
            } else {
                ## Ordinary eval
                run_hook @PRE_EVAL;
                @res = $REPL{eval}->($buf);
                run_hook @POST_EVAL;
                if ($@) {
                    if ($ISEVAL) {
                        ## Always return results for an eval request
                        Sepia::printer \@res, wantarray;
                        Sepia::printer [$@], wantarray;
                        # print_warnings $ISEVAL;
                        $buf = '';
                    } elsif ($@ =~ /(?:at|before) EOF(?:$| at)/m) {
                        ## Possibly-incomplete line
                        if ($in eq "\n") {
                            print "Error:\n$@\n*** cancel ***\n";
                            $buf = '';
                        } else {
                            print ">> ";
                        }
                    } else {
                        print_warnings;
                        # $@ =~ s/(.*) at eval .*/$1/;
                        # don't complain if we're abandoning execution
                        # from the debugger.
                        unless (ref $@ eq 'Sepia::Debug') {
                            print "error: $@";
                            print "\n" unless $@ =~ /\n\z/;
                        }
                        $buf = '';
                    }
                    next repl;
                }
            }
            if ($buf !~ /;\s*$/ && $buf !~ /^,/) {
                ## Be quiet if it ends with a semicolon, or if we
                ## executed a shortcut.
                Sepia::printer \@res, wantarray;
            }
            $buf = '';
            print_warnings;
        }
    exit if $REPL_QUIT;
    wantarray ? @res : $res[0]
}

sub perl_eval
{
    tolisp($REPL{eval}->(shift));
}

=head2 Module browsing

=over

=item C<$status = html_module_list([$file [, $prefix]])>

Generate an HTML list of installed modules, looking inside of
packages.  If C<$prefix> is missing, uses "about://perldoc/".  If
$file is given, write the result to $file; otherwise, return it as a
string.

=item C<$status = html_package_list([$file [, $prefix]])>

Generate an HTML list of installed top-level modules, without looking
inside of packages.  If C<$prefix> is missing, uses
"about://perldoc/".  $file is the same as for C<html_module_list>.

=back

=cut

sub html_module_list
{
    my ($file, $base) = @_;
    $base ||= 'about://perldoc/';
    my $inst = inst();
    return unless $inst;
    my $out;
    open OUT, ">", $file || \$out or return;
    print OUT "<html><body>";
    my $pfx = '';
    my %ns;
    for (package_list) {
        push @{$ns{$1}}, $_ if /^([^:]+)/;
    }
    # Handle core modules.
    my %fs;
    undef $fs{$_} for map {
        s/.*man.\///; s|/|::|g; s/\.\d(?:pm)?$//; $_
    } grep {
        /\.\d(?:pm)?$/ && !/man1/ && !/usr\/bin/ # && !/^(?:\/|perl)/
    } $inst->files('Perl');
    my @fs = sort keys %fs;
    print OUT qq{<h2>Core Modules</h2><ul>};
    for (@fs) {
        print OUT qq{<li><a href="$base$_">$_</a>};
    }
    print OUT '</ul><h2>Installed Modules</h2><ul>';

    # handle the rest
    for (sort keys %ns) {
        next if $_ eq 'Perl';   # skip Perl core.
        print OUT qq{<li><b>$_</b><ul>} if @{$ns{$_}} > 1;
        for (sort @{$ns{$_}}) {
            my %fs;
            undef $fs{$_} for map {
                s/.*man.\///; s|/|::|g; s/\.\d(?:pm)?$//; $_
            } grep {
                /\.\d(?:pm)?$/ && !/man1/
            } $inst->files($_);
            my @fs = sort keys %fs;
            next unless @fs > 0;
            if (@fs == 1) {
                print OUT qq{<li><a href="$base$fs[0]">$fs[0]</a>};
            } else {
                print OUT qq{<li>$_<ul>};
                for (@fs) {
                    print OUT qq{<li><a href="$base$_">$_</a>};
                }
                print OUT '</ul>';
            }
        }
        print OUT qq{</ul>} if @{$ns{$_}} > 1;
    }

    print OUT "</ul></body></html>\n";
    close OUT;
    $file ? 1 : $out;
}

sub html_package_list
{
    my ($file, $base) = @_;
    return unless inst();
    my %ns;
    for (package_list) {
        push @{$ns{$1}}, $_ if /^([^:]+)/;
    }
    $base ||= 'about://perldoc/';
    my $out;
    open OUT, ">", $file || \$out or return;
    print OUT "<html><body><ul>";
    my $pfx = '';
    for (sort keys %ns) {
        if (@{$ns{$_}} == 1) {
            print OUT
                qq{<li><a href="$base$ns{$_}[0]">$ns{$_}[0]</a>};
        } else {
            print OUT qq{<li><b>$_</b><ul>};
            print OUT qq{<li><a href="$base$_">$_</a>}
                for sort @{$ns{$_}};
            print OUT qq{</ul>};
        }
    }
    print OUT "</ul></body></html>\n";
    close OUT;
    $file ? 1 : $out;
}

sub apropos_module
{
    my $re = _apropos_re $_[0], 1;
    my $inst = inst();
    my %ret;
    my $incre = inc_re;
    for ($inst->files('Perl', 'prog'), package_list) {
        if (/\.\d?(?:pm)?$/ && !/man1/ && !/usr\/bin/ && /$re/) {
            s/$incre//;
            s/.*man.\///;
            s|/|::|g;
            s/^:+//;
            s/\.\d?(?:p[lm])?$//;
            undef $ret{$_} 
        }
    }
    sort keys %ret;
}

sub requires
{
    my $mod = shift;
    my @q = $REQUIRES{$mod};
    my @done;
    while (@q) {
        my $m = shift @q;
        push @done, $m;
        push @q, @{$REQUIRES{$m}};
    }
    @done;
}

sub users
{
    my $mod = shift;
    @{$REQUIRED_BY{$mod}}
}

1;
__END__

=head1 TODO

See the README file included with the distribution.

=head1 SEE ALSO

Sepia's public GIT repository is located at L<http://repo.or.cz/w/sepia.git>.

There are several modules for Perl development in Emacs on CPAN,
including L<Devel::PerlySense> and L<PDE>.  For a complete list, see
L<http://emacswiki.org/cgi-bin/wiki/PerlLanguage>.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

Bug reports welcome, patches even more welcome.

=head1 COPYRIGHT

Copyright (C) 2005-2011 Sean O'Rourke.  All rights reserved, some
wrongs reversed.  This module is distributed under the same terms as
Perl itself.

=cut
