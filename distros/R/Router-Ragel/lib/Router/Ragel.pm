# ABSTRACT: Router module using Ragel finite state machine
package Router::Ragel;
$Router::Ragel::VERSION = '0.01';
use strict;
use warnings;
use Inline C => <<\code;
void match(SV *self, SV *path_sv) {
    SV** elem_ptr = av_fetch((AV*)SvRV(self), 2, 0);
    void (*func)(SV*, SV*) = (void (*)(SV*, SV*))INT2PTR(void*, SvIV(*elem_ptr));
    func(self, path_sv);
}
code
use Inline::Filters::Ragel ();

my $instance_counter = 0;
sub new { bless [ [], $instance_counter++, undef ], shift } # $self is an arrayref with routes at index 0
sub add { push @{shift->[0]}, [shift, shift] } # routes are [pattern, data] tuples

sub compile {
    my $self = shift;
    my $instance_id = $self->[1];
    my @routes = @{$self->[0]};
    my @ragel_routes;
    my @num_placeholders;
    my $max_captures = 0;
    for my $i (0 .. $#routes) {
        my $route = $self->[0][$i];
        my $pattern = $route->[0]; # pattern is now at index 0
        my @segments = split '/', $pattern;
        shift @segments if $segments[0] eq ''; # Remove leading empty segment
        my $ragel_pattern = "''";
        my $capture_index = 0;
        for my $seg (@segments) {
            $ragel_pattern .= " '/'+ ";
            if ($seg =~ /^:(.+)$/) {
                $ragel_pattern .= "( [^/]+ >start_capture${capture_index} %end_capture${capture_index} )";
                $capture_index++;
            } else {
                $seg =~ s/'/\\'/ag;
                $ragel_pattern .= "'$seg'";
            }
        }
        $ragel_pattern .= ' %route'.$i;
        push @ragel_routes, "route$i = $ragel_pattern;";
        push @num_placeholders, $capture_index;
        $max_captures = $capture_index if $capture_index > $max_captures;
    }
    my $routes_str = join "\n", @ragel_routes;
    my $route_list_str = join " | ", map "route$_", 0 .. $#routes;
    my $num_placeholders_str = 'static int num_placeholders[] = {'. (join ', ', @num_placeholders).'};';
    my $capture_actions =
        join "\n",
        map "action start_capture$_ { capture_start[$_] = p - data; }\naction end_capture$_ { capture_end[$_] = p - data; }",
        0 .. $max_captures - 1;
    my $route_actions = join "\n", map "action route$_ { route_index = $_; }", 0 .. $#routes;
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
    int capture_start[$max_captures] = {-1};
    int capture_end[$max_captures] = {-1};
    %% write data;
    %% write init;
    %% write exec;
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    if (route_index != -1 && cs >= router_${instance_id}_first_final && p == pe) {
        SV **data_ref = av_fetch((AV*)SvRV(*av_fetch((AV*)SvRV(*av_fetch((AV*)SvRV(self), 0, 0)), route_index, 0)), 1, 0);
        Inline_Stack_Push(sv_mortalcopy(*data_ref));
        int n = num_placeholders[route_index];
        for (int i = 0; i < n; i++) {
            if (capture_start[i] != -1 && capture_end[i] != -1) {
                SV *sv = newSVpvn(data + capture_start[i], capture_end[i] - capture_start[i]);
                Inline_Stack_Push(sv_2mortal(sv));
            } else {
                Inline_Stack_Push(&PL_sv_undef);
            }
        }
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
    1;
}

1;
