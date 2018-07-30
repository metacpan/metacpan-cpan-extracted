package My::Envoy::DynamicWidget;

    use Moose;

    extends 'My::Envoy::Base';

    sub dbic { 'My::DB::Result::DynamicWidget' }

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