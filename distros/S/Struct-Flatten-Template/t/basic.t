use Test::Most;

use_ok('Struct::Flatten::Template');

my $tmpl = {
    foo => { bar => \{ column => 0, title => 'X', path_is => [qw/ foo HASH ? HASH /] } },
    baz => [ \{ column => 1, indexed => 1, title => 'Y', path_is => [qw/ baz HASH ? ARRAY /]  }, ],
};

my $struct = {
    foo  => { bar => 'a', },
    baz  => [qw/ b c d /],
    boom => 10,
};

my @head;
my @row;

sub handler {
    my ( $obj, $val, $args ) = @_;

    note( explain [ $val, $args ] );

    my $col = $args->{column};

    if ( $obj->is_testing ) {

        $head[$col] = $args->{title};

    } else {

        $col += $args->{_index} if $args->{indexed};
        $row[$col] = $val;
    }

    if ($args->{path_is}) {

      my @expected = @{$args->{path_is}};
      $expected[-2] = $args->{_index};

      is_deeply($args->{_path}, \@expected, '_path');

    }

}

isa_ok my $p = Struct::Flatten::Template->new(
    handler  => \&handler,
    template => $tmpl,
    ),
    'Struct::Flatten::Template';

$p->test();

is_deeply
    \@head,
    [qw/ X Y /],
    'expected result from test';

$p->run($struct);

is_deeply
    \@row,
    [qw/ a b c d/],
    'expected result from run';

done_testing;
