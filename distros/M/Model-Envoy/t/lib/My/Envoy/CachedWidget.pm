package My::Envoy::CachedWidget;

    use Moose;

    extends 'My::Envoy::CachedBase';

    sub dbic { 'My::DB::Result::Widget' }

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

1;