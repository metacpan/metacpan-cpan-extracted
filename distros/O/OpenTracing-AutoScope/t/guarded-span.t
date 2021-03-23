use Test::Most;
use Test::Deep qw/true false/;
use Test::OpenTracing::Integration;
use OpenTracing::AutoScope;
use OpenTracing::GlobalTracer;
use OpenTracing::Implementation::Test;

OpenTracing::GlobalTracer->set_global_tracer(
    OpenTracing::Implementation::Test->bootstrap_tracer );

{
    my $scope = OpenTracing::AutoScope->start_guarded_span('test1');
    global_tracer_cmp_easy(
      [{ operation_name => 'test1', has_finished => false }],
      'span is not finished prematurely' );
}
global_tracer_cmp_easy(
  [{ operation_name => 'test1', has_finished => true }],
  'span is finished when out of scope' );
reset_spans();


my $outer_scope;
{ $outer_scope = OpenTracing::AutoScope->start_guarded_span('test_outer') }
global_tracer_cmp_easy(
  [{ operation_name => 'test_outer', has_finished => true }],
  'span finished when variable survives the scope' );
reset_spans();


{
    my $l1 = OpenTracing::AutoScope->start_guarded_span('l1');
    global_tracer_cmp_easy(
      [{ operation_name => 'l1', has_finished => false }],
      'nested scopes - lvl1' );
    {
        my $l2 = OpenTracing::AutoScope->start_guarded_span('l2');
        global_tracer_cmp_easy(
            [
                { operation_name => 'l1', has_finished => false },
                { operation_name => 'l2', has_finished => false },
            ],
            'nested scopes - lvl2'
        );
        {
            my $l3 = OpenTracing::AutoScope->start_guarded_span('l3');
            global_tracer_cmp_easy(
                [
                    { operation_name => 'l1', has_finished => false },
                    { operation_name => 'l2', has_finished => false },
                    { operation_name => 'l3', has_finished => false },
                ],
                'nested scopes - lvl3'
            );
        }
        global_tracer_cmp_easy(
            [
                { operation_name => 'l1', has_finished => false },
                { operation_name => 'l2', has_finished => false },
                { operation_name => 'l3', has_finished => true },
            ],
            'nested scopes - lvl3 done'
        );
    }
    global_tracer_cmp_easy(
        [
            { operation_name => 'l1', has_finished => false },
            { operation_name => 'l2', has_finished => true },
            { operation_name => 'l3', has_finished => true },
        ],
        'nested scopes - lvl2 done'
    );
}
global_tracer_cmp_easy(
    [
        { operation_name => 'l1', has_finished => true },
        { operation_name => 'l2', has_finished => true },
        { operation_name => 'l3', has_finished => true },
    ],
    'nested scopes - all done'
);
reset_spans();


{
    OpenTracing::AutoScope->start_guarded_span('detached');
    global_tracer_cmp_easy(
      [{ operation_name => 'detached', has_finished => false }],
      'unassigned span is not finished prematurely' );
}
global_tracer_cmp_easy(
  [{ operation_name => 'detached', has_finished => true }],
  'unassigned span is finished when out of scope' );
reset_spans();


for (1..3) {
    OpenTracing::AutoScope->start_guarded_span("span$_");
}
global_tracer_cmp_easy(
    [
        { operation_name => 'span1', has_finished => true },
        { operation_name => 'span2', has_finished => true },
        { operation_name => 'span3', has_finished => true },
    ],
    'spans inside a lopp'
);
reset_spans();

sub sub_base {
    OpenTracing::AutoScope->start_guarded_span;
    sub_tagged(1);
    sub_tagged(2);
}

sub sub_tagged {
    OpenTracing::AutoScope->start_guarded_span(tags => { num => $_[0] });
}

sub_base();
sub { OpenTracing::AutoScope->start_guarded_span }->();
sub {
    local *__ANON__ = 'named_anon';
    OpenTracing::AutoScope->start_guarded_span;
}->();
global_tracer_cmp_easy(
    [
        { operation_name => 'main::sub_base',   has_finished => true },
        { operation_name => 'main::sub_tagged', has_finished => true, tags => { num => 1 } },
        { operation_name => 'main::sub_tagged', has_finished => true, tags => { num => 2 } },
        { operation_name => 'main::__ANON__',   has_finished => true },
        { operation_name => 'main::named_anon', has_finished => true },
    ],
    'sub names as default operations'
);

TODO: { local $TODO = "Calling close more than once ... undefined behavior.";

warning_like {
    OpenTracing::AutoScope->start_guarded_span('manual_close');

    OpenTracing::GlobalTracer->get_global_tracer
                             ->get_scope_manager
                             ->get_active_scope->close();

} qr/already closed/,
'manually closing AutoScope does cause a warning on scope end';

}

done_testing();
