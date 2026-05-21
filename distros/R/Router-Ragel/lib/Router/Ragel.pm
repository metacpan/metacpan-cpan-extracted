package Router::Ragel;

our $VERSION = '0.02';

use strict;
use warnings;
use Carp 'croak';
use Inline C => <<\code;
void match(SV *self, SV *path_sv) {
    SV** elem_ptr = av_fetch((AV*)SvRV(self), 2, 0);
    if (!elem_ptr || !SvOK(*elem_ptr))
        croak("Router::Ragel: compile() not called");
    void (*func)(SV*, SV*) = (void (*)(SV*, SV*))INT2PTR(void*, SvIV(*elem_ptr));
    func(self, path_sv);
}
code
use Inline::Filters::Ragel ();

my $instance_counter = 0;
# Slots: 0 = routes [[pattern, data], ...], 1 = instance id, 2 = compiled match function ptr
sub new { bless [ [], $instance_counter++, undef ], shift }

# Adding a route invalidates any previously compiled matcher so match() croaks
# until the user re-runs compile(), instead of silently dispatching to a stale DFA.
sub add { my $self = shift; $self->[2] = undef; push @{$self->[0]}, [@_[0,1]]; $self }

# Type aliases for placeholder constraints. Anything not in this map is passed
# through to Ragel verbatim, so users can write e.g. ':id<[0-9]{4}>'.
my %TYPE_ALIAS = (
    int => '[0-9]+',
    string => '[^/]+',
    hex => '[0-9a-fA-F]+',
);

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
                croak "Router::Ragel: unterminated '<' in placeholder of pattern '$pattern'"
                    if $close < 0;
                my $type = substr($seg, $i + 1, $close - $i - 1);
                $type =~ s/\A\s+|\s+\z//g;
                croak "Router::Ragel: empty type expression '<>' in pattern '$pattern'"
                    if $type eq '';
                croak "Router::Ragel: '<' is not allowed inside <type> in pattern '$pattern'"
                    if index($type, '<') >= 0;
                $class = $TYPE_ALIAS{$type} // $type;
                $i = $close + 1;
            }
            my $ci = $$cap_ref++;
            $out .= "( $class >start_capture${ci} %end_capture${ci} )";
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

sub compile {
    my $self = shift;
    my $routes = $self->[0];
    @$routes or croak "Router::Ragel: no routes added before compile()";
    my $instance_id = $self->[1];
    my @ragel_routes;
    my @num_placeholders;
    my $max_captures = 0;
    for my $i (0 .. $#$routes) {
        my $pattern = $routes->[$i][0];
        croak "Router::Ragel: undefined or empty pattern" if !defined $pattern || $pattern eq '';
        croak "Router::Ragel: pattern must start with '/' (got '$pattern')" unless substr($pattern, 0, 1) eq '/';
        croak "Router::Ragel: NUL byte in pattern" if index($pattern, "\0") >= 0;
        my @segments = split '/', $pattern, -1; # -1 preserves trailing empty (so '/foo/' is distinct from '/foo')
        shift @segments; # leading '' from the mandatory leading slash
        my $ragel_pattern = '';
        my $capture_index = 0;
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
        push @num_placeholders, $capture_index;
        $max_captures = $capture_index if $capture_index > $max_captures;
    }
    my $routes_str = join "\n", @ragel_routes;
    my $route_list_str = join " | ", map "route$_", 0 .. $#$routes;
    my $num_placeholders_str = 'static const int num_placeholders[] = {'. (join ', ', @num_placeholders).'};';
    my $capture_actions =
        join "\n",
        map "action start_capture$_ { capture_start[$_] = p - data; }\naction end_capture$_ { capture_end[$_] = p - data; }",
        0 .. $max_captures - 1;
    my $route_actions = join "\n", map "action route$_ { route_index = $_; }", 0 .. $#$routes;
    # Capture arrays left uninitialized: when route_index is set, every capture
    # action of the matched route has fired. Ragel concatenation guarantees the
    # route's %route action fires only after the inner [^/]+ submachines reach
    # their finishing transitions (which carry the %end_capture actions).
    my $capture_decls = $max_captures
        ? "int capture_start[$max_captures];\n    int capture_end[$max_captures];"
        : '';
    my $capture_loop = $max_captures ? <<'C' : '';
        int n = num_placeholders[route_index];
        for (int i = 0; i < n; i++) {
            SV *sv = newSVpvn(data + capture_start[i], capture_end[i] - capture_start[i]);
            Inline_Stack_Push(sv_2mortal(sv));
        }
C
    Inline->bind(C => <<code, filters => [ [ Ragel => '-CeG2' ] ]);
%%{
    machine router_$instance_id;
    $capture_actions
    $route_actions
    $routes_str
    main := ( $route_list_str );
}%%
void match_${instance_id}(SV *self, SV *path_sv) {
    STRLEN len;
    const char *data = SvPV(path_sv, len);
    int cs;
    const char *p = data;
    const char *pe = data + len;
    const char *eof = pe;
    int route_index = -1;
    $num_placeholders_str
    $capture_decls
    %% write data;
    %% write init;
    %% write exec;
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    if (route_index != -1 && cs >= router_${instance_id}_first_final && p == pe) {
        SV **data_ref = av_fetch((AV*)SvRV(*av_fetch((AV*)SvRV(*av_fetch((AV*)SvRV(self), 0, 0)), route_index, 0)), 1, 0);
        Inline_Stack_Push(sv_2mortal(SvREFCNT_inc(*data_ref)));
        $capture_loop
    }
    Inline_Stack_Done;
}
void store_func_ptr(SV *self) {
    void* func_ptr = (void*)&match_${instance_id};
    SV* ptr_sv = newSViv(PTR2IV(func_ptr));
    AV* self_av = (AV*)SvRV(self);
    av_store(self_av, 2, ptr_sv);
}
code
    store_func_ptr($self);
    $self;
}

1;
