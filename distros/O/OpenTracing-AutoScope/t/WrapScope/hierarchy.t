use Test::Most tests => 1;
use Test::OpenTracing::Integration;
use OpenTracing::GlobalTracer;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope qw[ root l1_a l1_b l1_c l2_a l2_b l2_c ];

sub root {
    l1_a();
    l1_b();
    l1_b();
    l1_c();
}

sub l1_a {
    l2_a();
}

sub l1_b {
    l2_b();
}

sub l1_c {
    l2_a();
    l2_c();
}

sub l2_a { }
sub l2_b { }
sub l2_c { }

root();

global_tracer_is_tree([
    {
        operation_name => 'main::root',
        children       => [
            {
                operation_name => 'main::l1_a',
                children       => [ { operation_name => 'main::l2_a' } ]
            },
            {
                operation_name => 'main::l1_b',
                children       => [ { operation_name => 'main::l2_b' } ]
            },
            {
                operation_name => 'main::l1_b',
                children       => [ { operation_name => 'main::l2_b' } ]
            },
            {
                operation_name => 'main::l1_c',
                children       => [
                    { operation_name => 'main::l2_a' },
                    { operation_name => 'main::l2_c' },
                ]
            },
        ],
    }
  ],
  'spans have correct parents');


sub global_tracer_is_tree {
    my ($tree_exp, $test_name) = @_;

    my (%spans, @roots);
    my @structs = sort { $a->{level} <=> $b->{level} } $TRACER->get_spans_as_struct;
    foreach my $struct (@structs) {
        my $id        = $struct->{span_id};
        my $parent_id = $struct->{parent_id};
        my $name      = $struct->{operation_name};

        my %span = (operation_name => $name);
        $spans{$id} = \%span;

        if ($parent_id) {
            push @{ $spans{$parent_id}{children} }, \%span;
        }
        else {
            push @roots, \%span;
        }
    }
    is_deeply \@roots, $tree_exp, $test_name
        or diag explain \@roots;
}
