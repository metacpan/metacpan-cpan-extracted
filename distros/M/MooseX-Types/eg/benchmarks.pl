use strict;
use warnings;

{
    package MXT;

    use MooseX::Types -declare => [qw( HasCoercion NonInline )];
    use MooseX::Types::Moose qw( Int Num Value );

    subtype HasCoercion, as Int;
    coerce HasCoercion,
        from Num,
        via { return int( $_[0] ) };

    subtype NonInline,
        as Value,
        where { $_ eq 'foo' || $_ eq 'bar' };
}

{
    package T;

    use Moose::Util::TypeConstraints;

    our $arrayref   = find_type_constraint('ArrayRef');
    our $int        = find_type_constraint('Int');
    our $str        = find_type_constraint('Str');
    our $non_inline = subtype(
        as 'Value',
        where { $_ eq 'foo' || $_ eq 'bar' },
    );
}

use Benchmark qw( cmpthese timethese );

use MooseX::Types::Moose qw( ArrayRef Int Str );
MXT->import( qw( HasCoercion NonInline ) );

my @items = ( undef, 42, 42.123, 'foo', [], {}, $T::arrayref );

sub plain_moose {
    for my $item (@items) {
        $T::arrayref->check($item);
        $T::int->check($item);
        $T::str->check($item);
        $T::non_inline->check($item);
    }
}

sub moosex_types_is {
    for my $item (@items) {
        is_ArrayRef($item);
        is_Int($item);
        is_Str($item);
        is_NonInline($item);
    }
}

sub moosex_types_check {
    for my $item (@items) {
        ArrayRef()->check($item);
        Int()->check($item);
        Str()->check($item);
        NonInline()->check($item);
    }
}

print "\n";

cmpthese(
    50_000,
    {
        'HasCoercion()->coerce' => sub {
            HasCoercion()->coerce($_) for @items;
        },
        'to_HasCoercion' => sub {
            to_HasCoercion($_) for @items;
        },
    },
);

print "\n";

cmpthese(
    50_000,
    {
        'plain Moose'                 => \&plain_moose,
        'MooseX::Types is_*'          => \&moosex_types_is,
        'MooseX::Types Type()->check' => \&moosex_types_check,
    },
);
