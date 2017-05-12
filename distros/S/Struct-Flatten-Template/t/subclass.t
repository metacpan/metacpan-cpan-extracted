package MyClass;

use Moose;
extends 'Struct::Flatten::Template';

override 'process_ARRAY' => sub {
    my ( $self, $struct, $template ) = @_;

    for ( my $i = 0; $i <= $#{$template}; $i++ ) {
        last if $i > $#{$struct};
        $self->process( $struct->[$i], $template->[$i], $i );
    }
};

package main;

use Test::Most;

my $tmpl = {
    foo => { bar => \{ column => 0 } },
    baz => [ \{ column => 1 }, \{ column => 2 }, ],
};

my $struct = {
    foo  => { bar => 'a', },
    baz  => [qw/ b c d /],
    boom => 10,
};

my @row;

sub handler {
    my ( $obj, $val, $args ) = @_;

    my $col = $args->{column};

    if ( defined $row[$col] ) {
        push @{ $row[$col] }, $val;
    } else {
        $row[$col] = [$val];
    }
}

isa_ok my $p = MyClass->new(
    handler  => \&handler,
    template => $tmpl,
    ),
    'Struct::Flatten::Template';

$p->run($struct);

is_deeply
    \@row,
    [ [qw/a/], [qw/b/], [qw/c/] ],
    'expected result';

done_testing;
