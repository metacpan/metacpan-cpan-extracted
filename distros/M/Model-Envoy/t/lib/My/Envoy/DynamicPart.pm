package My::Envoy::DynamicPart;

    use Moose;

    extends 'My::Envoy::Base';

    sub dbic { 'My::DB::Result::DynamicPart' }

    has 'id' => (
        is => 'ro',
        isa => 'Num',
        traits => ['DBIC'],
        primary_key => 1,

    );

    has 'name' => (
        is => 'rw',
        isa => 'Maybe[Str]',
        traits => ['DBIC'],
    );

    has 'widget' => (
        is => 'rw',
        isa => 'Maybe[My::Envoy::DynamicWidget]',
        traits => ['DBIC','Envoy'],
        rel => 'belongs_to',
    );

1;