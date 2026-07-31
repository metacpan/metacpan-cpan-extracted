package Router::Ragel;

our $VERSION = '0.05';

use 5.010;
use strict;
use warnings;
use Carp 'croak';
use Digest::MD5 'md5_hex';
use Inline C => <<\code;
void match(SV *self, SV *path_sv) {
    /* SvROK alone is not enough: av_fetch on a non-AV body is undefined and
       does crash (a qr// among others). Slot 2 must be a real IV: we jump to
       whatever is in it. */
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Router::Ragel: match() requires a router object");
    SV** elem_ptr = av_fetch((AV*)SvRV(self), 2, 0);
    if (!elem_ptr || !SvIOK(*elem_ptr))
        croak("Router::Ragel: compile() not called");
    void (*func)(SV*, SV*) = (void (*)(SV*, SV*))INT2PTR(void*, SvIV(*elem_ptr));
    func(self, path_sv);
}
code
use Inline::Filters::Ragel ();

my $instance_counter = 0;
# Slots: 0 = routes [[pattern, data], ...], 1 = instance id, 2 = compiled match function ptr
sub new {
    my $class = shift;
    croak "Router::Ragel: new() takes no arguments" if @_;
    bless [ [], $instance_counter++, undef ], $class;
}

# Adding a route invalidates any previously compiled matcher so match() croaks
# until the user re-runs compile(), instead of silently dispatching to a stale DFA.
sub add {
    my $self = shift;
    croak "Router::Ragel: add() takes a pattern and an optional data value" if @_ > 2;
    $self->[2] = undef;
    push @{$self->[0]}, [@_[0,1]];
    $self;
}

# Slot 2 is a code address, valid only in the process that compiled it. Ship
# the routes and let the consumer recompile.
sub STORABLE_freeze { ($VERSION, $_[0][0]) }
sub STORABLE_thaw {
    my ($self, undef, undef, $routes) = @_;
    @$self = ($routes, $instance_counter++, undef);
    return;
}

# Type aliases for placeholder constraints. Anything not in this map is passed
# through to Ragel verbatim, so users can write e.g. ':id<[0-9]{4}>'.
my %TYPE_ALIAS = (
    int => '[0-9]+',
    string => '[^/]+',
    hex => '[0-9a-fA-F]+',
);

sub _bad_type { croak "Router::Ragel: $_[1] in <type> of pattern '$_[0]'" }

# A <type> body is spliced into the generated machine, and Ragel grammar is not
# just a regex dialect: it can embed C and start new statements. Accept only the
# documented subset so a typo fails here instead of reaching the C compiler.
# Not a sandbox; patterns are trusted input (see SECURITY in the docs).
my %TYPE_FORBIDDEN = map { $_ => 1 } split //, '%$@#;=}';
sub _validate_type {
    my ($pattern, $type) = @_;
    my $len = length $type;
    my ($i, $depth) = (0, 0);
    while ($i < $len) {
        my $c = substr($type, $i, 1);
        if ($c eq '\\') {
            _bad_type($pattern, 'trailing backslash') if $i + 1 >= $len;
            $i += 2;
        } elsif ($c eq "'" || $c eq '"') {
            my ($j, $closed) = ($i + 1, 0);
            while ($j < $len) {
                my $d = substr($type, $j, 1);
                if ($d eq '\\') { $j += 2; next }
                $j++;
                if ($d eq $c) { $closed = 1; last }
            }
            _bad_type($pattern, "unterminated $c string") unless $closed;
            $i = $j;
        } elsif ($c eq '[') {
            my ($j, $closed) = ($i + 1, 0);
            while ($j < $len) {
                my $d = substr($type, $j, 1);
                if ($d eq '\\') { $j += 2; next }
                $j++;
                if ($d eq ']') { $closed = 1; last }
            }
            _bad_type($pattern, 'unterminated character class') unless $closed;
            $i = $j;
        } elsif ($c eq '{') { # only ever a repetition quantifier
            my $close = index($type, '}', $i + 1);
            _bad_type($pattern, "unterminated '{'") if $close < 0;
            my $q = substr($type, $i + 1, $close - $i - 1);
            _bad_type($pattern, "'{' may only introduce a repetition quantifier")
                unless $q =~ /\A(?:[0-9]+|[0-9]*,[0-9]*)\z/ && $q =~ /[0-9]/;
            $i = $close + 1;
        } else {
            _bad_type($pattern, "'$c' is not allowed") if $TYPE_FORBIDDEN{$c};
            _bad_type($pattern, 'control character') if $c lt ' ' || $c eq "\x7f";
            if ($c eq '(') { $depth++ }
            elsif ($c eq ')') { _bad_type($pattern, "unbalanced ')'") if --$depth < 0 }
            $i++;
        }
    }
    _bad_type($pattern, "unbalanced '('") if $depth;
    return;
}

# Translate one path segment into a Ragel expression, expanding inline ':name'
# and ':name<type>' placeholders. Side-effects: increments $$cap_ref per
# placeholder. Croaks on malformed placeholder syntax.
sub _segment_to_ragel {
    my ($pattern, $seg, $cap_ref) = @_;
    my $out = '';
    my $i = 0;
    my $len = length $seg;
    while ($i < $len) {
        if (substr($seg, $i, 1) eq ':') {
            $i++;
            my $name_start = $i;
            $i++ while $i < $len && substr($seg, $i, 1) =~ /\w/;
            croak "Router::Ragel: empty placeholder name in pattern '$pattern'"
                if $i == $name_start;
            my $class = '[^/]+';
            if ($i < $len && substr($seg, $i, 1) eq '<') {
                my $close = index($seg, '>', $i + 1);
                if ($close < 0) {
                    # Segments are split off on '/' before this runs, so a '/'
                    # inside a <type> arrives as a type that never closes; a '>'
                    # left elsewhere in the pattern is the tell.
                    croak "Router::Ragel: unterminated '<' in placeholder of pattern '$pattern'"
                        . (index($pattern, '>') >= 0
                            ? " ('/' is not allowed inside a <type>)" : '');
                }
                my $type = substr($seg, $i + 1, $close - $i - 1);
                $type =~ s/\A\s+|\s+\z//g;
                croak "Router::Ragel: empty type expression '<>' in pattern '$pattern'"
                    if $type eq '';
                croak "Router::Ragel: '<' is not allowed inside <type> in pattern '$pattern'"
                    if index($type, '<') >= 0;
                _validate_type($pattern, $type) unless exists $TYPE_ALIAS{$type};
                $class = $TYPE_ALIAS{$type} // $type;
                $i = $close + 1;
            }
            my $ci = $$cap_ref++;
            # $class needs its own parens: action operators bind tighter than
            # concatenation and union, so a multi-term type would otherwise
            # instrument its last term only, leaving the slot unset for the
            # branches that miss it.
            $out .= "( ($class) >start_capture${ci} %end_capture${ci} )";
        } else {
            my $next = index($seg, ':', $i);
            $next = $len if $next < 0;
            my $lit = substr($seg, $i, $next - $i);
            $lit =~ s/(['\\])/\\$1/g;
            $out .= "'$lit'";
            $i = $next;
        }
    }
    $out;
}

# Inline's exception names neither this module nor the route that broke. Only a
# pattern with a <type> can produce invalid Ragel (literal segments are quoted
# and escaped), so list those.
sub _have_ragel {
    require Config;
    my @exts = $^O eq 'MSWin32' ? ('.exe', '.bat', '') : ('');
    for my $dir (grep length, split /\Q$Config::Config{path_sep}\E/, $ENV{PATH} // '') {
        for my $ext (@exts) {
            return 1 if -f "$dir/ragel$ext" && -x _;
        }
    }
    return 0;
}

sub _bind_error {
    my ($why, $routes) = @_;
    chomp $why;
    my @suspect = grep index($_, '<') >= 0, map $_->[0], @$routes;
    my $hint;
    # Rule the toolchain out first: blaming the patterns when ragel is merely
    # absent sends people off to edit working code.
    if (!_have_ragel()) {
        $hint = "The 'ragel' binary is not on PATH. Router::Ragel needs it, a C"
              . ' compiler and make at run time; see the REQUIREMENTS section.';
    } elsif (!@suspect) {
        $hint = 'No pattern uses a <type>, so this is most likely a toolchain problem'
              . ' (is the C compiler working?)';
    } else {
        my $shown = @suspect > 20 ? 20 : @suspect;
        $hint = "Check the <type> expressions in:\n"
              . join('', map "    $_\n", @suspect[0 .. $shown - 1])
              . (@suspect > $shown ? '    ... and ' . (@suspect - $shown) . " more\n" : '');
        chomp $hint;
    }
    "Router::Ragel: could not build the state machine: $why\n"
        . "(ragel/compiler diagnostics were written to STDERR.)\n$hint";
}

# machine id -> compiled match function pointer, for this process
my %COMPILED;

sub compile {
    my $self = shift;
    my $routes = $self->[0];
    @$routes or croak "Router::Ragel: no routes added before compile()";
    my @ragel_routes;
    my @num_placeholders;
    my @capture_base;
    # Capture slots are allocated globally across all routes, not reset per
    # route: overlapping routes share DFA transitions and fire each other's
    # capture actions, so per-route slots would let a losing route clobber a
    # shared index. Disjoint ranges keep the winner's captures intact.
    my $capture_index = 0;
    for my $i (0 .. $#$routes) {
        my $pattern = $routes->[$i][0];
        croak "Router::Ragel: undefined or empty pattern" if !defined $pattern || $pattern eq '';
        croak "Router::Ragel: pattern must start with '/' (got '$pattern')" unless substr($pattern, 0, 1) eq '/';
        croak "Router::Ragel: NUL byte in pattern" if index($pattern, "\0") >= 0;
        # Matching is on the SV's bytes: a pattern above 255 has no byte form.
        croak "Router::Ragel: pattern must be a byte string, encode it first (got '$pattern')"
            if $pattern =~ /[^\x00-\xff]/;
        my @segments = split '/', $pattern, -1; # -1 preserves trailing empty (so '/foo/' is distinct from '/foo')
        shift @segments; # leading '' from the mandatory leading slash
        my $ragel_pattern = '';
        my $route_base = $capture_index;
        push @capture_base, $route_base;
        for my $j (0 .. $#segments) {
            my $seg = $segments[$j];
            $ragel_pattern .= " '/' ";
            if ($seg eq '' && $j < $#segments) {
                croak "Router::Ragel: consecutive slashes in pattern '$pattern'";
            } elsif ($seg ne '') {
                $ragel_pattern .= _segment_to_ragel($pattern, $seg, \$capture_index);
            }
            # Trailing empty segment (from "/foo/") falls through: just the '/' separator emitted above.
        }
        $ragel_pattern .= ' %route'.$i;
        push @ragel_routes, "route$i = $ragel_pattern;";
        push @num_placeholders, $capture_index - $route_base;
    }

    # Name the machine after the patterns, not a per-process counter: identical
    # route sets then share one library, so a cache warmed at build time hits at
    # run time however many routers were built first. (Route data lives on the
    # Perl object, so it plays no part.)
    my $machine_id = md5_hex(join "\0", $VERSION, map $_->[0], @$routes);
    if (defined(my $func_ptr = $COMPILED{$machine_id})) {
        $self->[2] = $func_ptr;
        return $self;
    }

    my $max_captures = $capture_index;   # total capture slots across all routes
    my $routes_str = join "\n", @ragel_routes;
    my $route_list_str = join " | ", map "route$_", 0 .. $#$routes;
    # Only the capture loop reads these tables, so skip emitting them (like the
    # capture decls/loop below) when there are no captures to read.
    my $num_placeholders_str = $max_captures
        ? 'static const int num_placeholders[] = {'. (join ', ', @num_placeholders).'};'
        : '';
    my $capture_base_str = $max_captures
        ? 'static const int capture_base[] = {'. (join ', ', @capture_base).'};'
        : '';
    my $capture_actions =
        join "\n",
        map "action start_capture$_ { capture_start[$_] = p - data; }\naction end_capture$_ { capture_end[$_] = p - data; }",
        0 .. $max_captures - 1;
    # Precedence on overlap: when several routes accept the same input their
    # %route finish actions all fire in the combined accept state in ascending
    # (add) order, so the LAST-added matching route's assignment is the one that
    # sticks. This is the documented behaviour, see "Route precedence" in the docs.
    my $route_actions = join "\n", map "action route$_ { route_index = $_; }", 0 .. $#$routes;
    # Capture slots are left uninitialized: every action of the matched route
    # has fired by the time route_index is set (Ragel replays a start action it
    # skipped as a pending-in action, so a type matching empty still sets both
    # ends), and each route reads only its own range. The positions are another
    # matter -- an ambiguous boundary can land an end before its start, see
    # "Captures" in the docs. Declarations stay ahead of the first statement and
    # out of the for-init so the machine still builds under C89.
    my $capture_decls = $max_captures
        ? "IV capture_start[$max_captures];\n    IV capture_end[$max_captures];\n"
        . "    IV cap_from, cap_to;\n    int cap_i, cap_n, cap_base;\n    SV **pat_ref;"
        : '';
    # Bound the pair against the path, not just against each other: this reads
    # memory, so it should not rest on an argument about which actions fire.
    my $capture_loop = $max_captures ? <<'C' : '';
        cap_base = capture_base[route_index];
        cap_n = num_placeholders[route_index];
        for (cap_i = 0; cap_i < cap_n; cap_i++) {
            cap_from = capture_start[cap_base + cap_i];
            cap_to = capture_end[cap_base + cap_i];
            if (cap_from < 0 || cap_to < cap_from || (STRLEN)cap_to > len) {
                pat_ref = av_fetch(route, 0, 0);
                croak("Router::Ragel: ambiguous capture boundary in pattern '%s'"
                      " -- the state machine cannot split this segment; separate"
                      " the placeholders with a literal",
                      (pat_ref && SvOK(*pat_ref)) ? SvPV_nolen(*pat_ref) : "?");
            }
            Inline_Stack_Push(sv_2mortal(newSVpvn(data + cap_from,
                                                  (STRLEN)(cap_to - cap_from))));
        }
C
    # static: Inline binds only non-static functions, and this one takes the
    # router apart unchecked. store_func_ptr shares the translation unit.
    my $code = <<code;
%%{
    machine router_$machine_id;
    $capture_actions
    $route_actions
    $routes_str
    main := ( $route_list_str );
}%%
static void match_${machine_id}(SV *self, SV *path_sv) {
    STRLEN len;
    const char *data = SvPV(path_sv, len);
    const char *p = data;
    const char *pe = data + len;
    const char *eof = pe;
    int cs;
    int route_index = -1;
    SV **slot;
    AV *routes;
    SV **rslot;
    AV *route;
    SV **data_ref;
    $num_placeholders_str
    $capture_base_str
    $capture_decls
    Inline_Stack_Vars;
    %% write data;
    %% write init;
    %% write exec;
    Inline_Stack_Reset;
    if (route_index != -1 && cs >= router_${machine_id}_first_final && p == pe) {
        /* add() always builds [pattern, data] pairs; a thawed or hand-edited
           route table need not, and this walk would deref NULL. */
        slot = av_fetch((AV*)SvRV(self), 0, 0);
        routes = (slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV)
               ? (AV*)SvRV(*slot) : NULL;
        rslot = routes ? av_fetch(routes, route_index, 0) : NULL;
        route = (rslot && SvROK(*rslot) && SvTYPE(SvRV(*rslot)) == SVt_PVAV)
              ? (AV*)SvRV(*rslot) : NULL;
        data_ref = route ? av_fetch(route, 1, 0) : NULL;
        if (!data_ref)
            croak("Router::Ragel: corrupt route table");
        Inline_Stack_Push(sv_2mortal(SvREFCNT_inc(*data_ref)));
$capture_loop    }
    Inline_Stack_Done;
}
IV _func_ptr() {
    return PTR2IV(&match_${machine_id});
}
code
    eval { Inline->bind(C => $code, filters => [ [ Ragel => '-CeG2' ] ]); 1 }
        or croak _bind_error($@, $routes);
    # _func_ptr only reports an address; storing it here means no bound XSUB
    # can stamp "compiled" onto an arbitrary arrayref.
    $self->[2] = _func_ptr();
    $COMPILED{$machine_id} = $self->[2];
    $self;
}

1;
