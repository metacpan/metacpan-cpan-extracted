use Test::Most tests => 2;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope qw/test_sub/;

{
    my %lines;

    sub remember_line {
        my ($name) = @_;
        die "$name already taken" if $lines{$name};
        $lines{$name} = (caller)[2];
        return;
    }

    sub recall_line {
        my ($name) = @_;
        die "$name not found" if not $lines{$name};
        return $lines{$name};
    }
}


sub test_sub {} remember_line('source');

sub caller1 {
    test_sub(); BEGIN { remember_line('call1') }
}

{
    package Foo;

    sub caller2 {
        main::test_sub(); BEGIN { main::remember_line('call2') }
    }
}

caller1();
Foo::caller2();

global_tracer_cmp_easy(
    [
        {
            operation_name => 'main::test_sub',
            tags           => {
                'caller.file'    => __FILE__,
                'caller.line'    => recall_line('call1'),
                'caller.package' => 'main',
                'caller.subname' => 'main::caller1',
                'source.file'    => __FILE__,
                'source.line'    => recall_line('source'),
                'source.package' => 'main',
                'source.subname' => 'test_sub',
            },
        },
        {
            operation_name => 'main::test_sub',
            tags           => {
                'caller.file'    => __FILE__,
                'caller.line'    => recall_line('call2'),
                'caller.package' => 'Foo',
                'caller.subname' => 'Foo::caller2',
                'source.file'    => __FILE__,
                'source.line'    => recall_line('source'),
                'source.package' => 'main',
                'source.subname' => 'test_sub',
            },
        },
    ],
    'caller and source info properly put into tags'
);

reset_spans();
test_sub(); remember_line('raw_call');

global_tracer_cmp_easy(
    [
        {
            operation_name => 'main::test_sub',
            tags           => {
                'caller.file'    => __FILE__,
                'caller.line'    => recall_line('raw_call'),
                'caller.package' => 'main',
                'source.file'    => __FILE__,
                'source.line'    => recall_line('source'),
                'source.package' => 'main',
                'source.subname' => 'test_sub',
            },
        },
    ],
    'caller and source info properly put into tags'
);
