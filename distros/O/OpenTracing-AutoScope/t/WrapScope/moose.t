use Test::Most;
use OpenTracing::Implementation 'Test';
use Test::OpenTracing::Integration;

use lib 't/lib';
use Line::Storage ':ALL';

BEGIN {
    eval { require Moose } or plan skip_all => 'Moose is not installed';
}

package Foo {
    use Moose;

    sub bar { return 1 } BEGIN { Line::Storage::remember_line('bar_def') }
}

package Some::Role {
    use Moose::Role;

    requires 'helper';

    sub stuff {
        my ($class) = @_;
        $class->helper(); BEGIN { Line::Storage::remember_line('helper_call') }
        return;
    }
}

package Some::Consumer {
    use Moose;
    with 'Some::Role';

    use OpenTracing::WrapScope 'helper';

    sub helper { } BEGIN { Line::Storage::remember_line('helper_def') }
}

use OpenTracing::WrapScope 'Foo::bar';

Foo::bar(); remember_line('bar_call');

global_tracer_cmp_easy([
    {
        operation_name => 'Foo::bar',
        tags           => {
            'caller.file'    => __FILE__,
            'caller.line'    => recall_line('bar_call'),
            'caller.package' => 'main',
            'source.file'    => __FILE__,
            'source.line'    => recall_line('bar_def'),
            'source.package' => 'Foo',
            'source.subname' => 'bar',
        }
    },
], 'basic method');

reset_spans();
Some::Consumer->stuff();

global_tracer_cmp_easy([
    {
        operation_name => 'Some::Consumer::helper',
        tags           => {
            'caller.file'    => __FILE__,
            'caller.line'    => recall_line('helper_call'),
            'caller.package' => 'Some::Role',
            'caller.subname' => 'Some::Role::stuff',
            'source.file'    => __FILE__,
            'source.line'    => recall_line('helper_def'),
            'source.package' => 'Some::Consumer',
            'source.subname' => 'helper',
        }
    },
], 'role-required method');

use OpenTracing::WrapScope 'Immutable::Class::pre';

package Immutable::Class {
    use Moose;
    use OpenTracing::WrapScope 'inside';

    sub pre    { } BEGIN { Line::Storage::remember_line('pre_def') }
    sub inside { } BEGIN { Line::Storage::remember_line('inside_def') }
    sub post   { }

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

reset_spans();

warning_like {
    OpenTracing::WrapScope::install_wrapped('Immutable::Class::post');
    Immutable::Class->post();
}
qr/Can't wrap Moose method Immutable::Class::post from an immutable class/,
    'warning when trying to alter an immutable Moose class';

reset_spans();
Immutable::Class->pre(); remember_line('pre_call');

global_tracer_cmp_easy([
    {
        operation_name => 'Immutable::Class::pre',
        tags           => {
            'caller.file'    => __FILE__,
            'caller.line'    => recall_line('pre_call'),
            'caller.package' => 'main',
            'source.file'    => __FILE__,
            'source.line'    => recall_line('pre_def'),
            'source.package' => 'Immutable::Class',
            'source.subname' => 'pre',
        }
    },
], 'method from an immutable class set to wrap before class declaration');

reset_spans();
Immutable::Class->inside(); remember_line('inside_call');

global_tracer_cmp_easy([
    {
        operation_name => 'Immutable::Class::inside',
        tags           => {
            'caller.file'    => __FILE__,
            'caller.line'    => recall_line('inside_call'),
            'caller.package' => 'main',
            'source.file'    => __FILE__,
            'source.line'    => recall_line('inside_def'),
            'source.package' => 'Immutable::Class',
            'source.subname' => 'inside',
        }
    },
], 'method from an immutable class set to wrap during class declaration');

done_testing();
