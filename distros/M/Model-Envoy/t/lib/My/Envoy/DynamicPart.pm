package My::Envoy::DynamicPart;

    use Moose;

    extends 'My::Envoy::Base';

    sub dbic { 'My::DB::Result::DynamicPart' }

    has 'id' => (
        is => 'ro',
        isa => 'Num',
        traits => ['Envoy','DBIC'],
        primary_key => 1,

    );

    has 'name' => (
        is => 'rw',
        isa => 'Maybe[Str]',
        traits => ['Envoy','DBIC'],
    );

    has 'widget' => (
        is => 'rw',
        isa => 'Maybe[My::Envoy::DynamicWidget]',
        traits => ['Envoy','DBIC'],
        rel => 'belongs_to',
    );

1;