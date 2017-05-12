use strict;
use warnings;
use Test::More;
use MooseX::Types::DBIx::Class qw(
    ResultSet
    ResultSource
    Row
    Schema
);

{
    package Test::Schema::Fluffles;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('fluffles');
    __PACKAGE__->add_columns(qw( fluff_factor ));
}

{
    package Test::Schema::Falafels;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('falafels');
    __PACKAGE__->add_columns(qw( falafel_factor ));
}

{
    package Test::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw(
        Fluffles
        Falafels
    ));
}

{
    package My::Moose::Class;

    use Moose;
    use MooseX::Types::DBIx::Class qw(Schema ResultSet ResultSource Row);
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(Int);
    use Moose::Util::TypeConstraints;
    use MooseX::Types -declare => [qw(VeryFluffy SomewhatFluffy PickyFluffiness)];

    has str_schema      => ( is => 'rw', isa => Schema['Test::Schema']   );
    has regex_schema    => ( is => 'rw', isa => Schema[qr/schema/i]      );
    has other_schema    => ( is => 'rw', isa => Schema[qr/Other/]        );
    has falafels_rs     => ( is => 'rw', isa => ResultSet['Falafels']    );
    has fluffles_or_falafels => ( isa => ResultSet [ 'Falafels', 'Fluffles' ], is => 'rw' );
    has fluffles_source => ( is => 'rw', isa => ResultSource['Fluffles'] );
    has falafel_row     => ( is => 'rw', isa => Row['Falafels']          );
    has any_row         => ( isa => Row, is => 'rw'                      );

    subtype VeryFluffy,     as Row['Fluffles'], where { $_->fluff_factor > 500 };
    subtype SomewhatFluffy, as Row['Fluffles'], where { $_->fluff_factor > 50 };

    has very_fluffy_fluffle      => ( is => 'rw', isa => VeryFluffy     );
    has somewhate_fluffy_fluffle => ( is => 'rw', isa => SomewhatFluffy );

    subtype PickyFluffiness,
        as Parameterizable[Row['Fluffles'], Int],
        where {
            my($row, $threshold) = @_;
            return Row(['Fluffles'])->check($row) && $row->fluff_factor == $threshold;
        };
    has picky_fluffy_fluffle => ( is => 'rw', isa => PickyFluffiness[100] );
}

my $schema = Test::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;
$schema->resultset('Falafels')->create({ falafel_factor => 10 });
$schema->resultset('Fluffles')->create({ fluff_factor => 100 });
$schema->resultset('Fluffles')->create({ fluff_factor => 99 });

my $o = My::Moose::Class->new;

$o->str_schema($schema);
is $o->str_schema, $schema, 'Schema set successfully (Str Check)';

$o->regex_schema($schema);
is $o->regex_schema, $schema, 'Schema set successfully (Regex Check)';

ok ! eval { $o->other_schema($schema); 1 }, 'Non-matching schema rejected';
like $@, qr/does not pass the type constraint/, 'non-matching schema has type-constraint error';

ok ! eval { $o->other_schema(bless {}, "Other"); 1 }, 'Fake schema rejected';
like $@, qr/does not pass the type constraint/, 'Fake schema has type-constraint error';

$o->falafels_rs($schema->resultset('Falafels'));
is $o->falafels_rs, $schema->resultset('Falafels'), 'Parameterizable resultset';

ok !eval {$o->falafels_rs($schema->resultset('Fluffles')); 1 }, 'Incorrect resultset rejected';
like $@, qr/does not pass the type constraint/, 'non-matching resultset has type-constraint error';

$o->fluffles_source($schema->resultset('Fluffles')->result_source);
is $o->fluffles_source, $schema->resultset('Fluffles')->result_source, 'Parameterizable result source';

ok !eval {$o->fluffles_source($schema->resultset('Falafels')->result_source); 1 }, 'Incorrect result source rejected';
like $@, qr/does not pass the type constraint/, 'non-matching result source has type-constraint error';

my $falafel_row = $schema->resultset('Falafels')->first;
$o->falafel_row($falafel_row);
is $o->falafel_row, $falafel_row, 'Parameterizable row';

my $fluffles_row = $schema->resultset('Fluffles')->first;
ok !eval {$o->falafel_row($fluffles_row); 1 }, 'Incorrect row rejected';
like $@, qr/does not pass the type constraint/, 'non-matching row has type-constraint error';

ok !eval {$o->falafel_row(undef); 1 }, 'Undefined row rejected';
like $@, qr/does not pass the type constraint/, 'non-matching row has type-constraint error';

ok !eval {$o->falafel_row("abc"); 1 }, 'Non-object row rejected';
like $@, qr/does not pass the type constraint/, 'non-matching row has type-constraint error';

$o->any_row($fluffles_row);
is $o->any_row, $fluffles_row, 'any_row accepts Fluffles';

$o->any_row($falafel_row);
is $o->any_row, $falafel_row, 'any_row accepts Falafels';

ok !eval {$o->any_row("abc"); 1 }, 'Non-object row rejected';
like $@, qr/does not pass the type constraint/, 'non-matching row has type-constraint error';

$o->somewhate_fluffy_fluffle($fluffles_row);
is $o->somewhate_fluffy_fluffle, $fluffles_row, 'subtyped parameterizable row';

ok ! eval { $o->very_fluffy_fluffle( $fluffles_row ); 1 }, 'somewhat fluffy fluffle fails very_fluffy_fluffle constraint';
like $@, qr/does not pass the type constraint/, 'somewhat-fluffy fluffle has appropriate type-constraint error';

$o->picky_fluffy_fluffle($fluffles_row);
is $o->picky_fluffy_fluffle, $fluffles_row, 'sub-subtyped parameterizable row';

$fluffles_row = $schema->resultset('Fluffles')->search({ fluff_factor => 99 })->first;
ok ! eval { $o->picky_fluffy_fluffle( $fluffles_row ); 1 }, 'somewhat (less) fluffy fluffle fails picky_fluffy_fluffle constraint';
like $@, qr/does not pass the type constraint/, 'somewhat (less) fluffy fluffle has appropriate type-constraint error';

$o->fluffles_or_falafels($schema->resultset('Fluffles'));
$o->fluffles_or_falafels($schema->resultset('Falafels'));
is $o->fluffles_or_falafels, $schema->resultset('Falafels'), 'Parameterizable resultset (multiple choice)';

done_testing;

