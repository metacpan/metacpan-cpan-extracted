package My::Envoy::Widget;

    use Moose;

    extends 'My::Envoy::Base';

    sub dbic { 'My::DB::Result::Widget' }

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

    has 'no_storage' => (
        is => 'rw',
        isa => 'Maybe[Str]',
        traits => ['Envoy'],
    );

    has 'parts' => (
        is => 'rw',
        isa => 'ArrayRef[My::Envoy::Part]',
        traits => ['Envoy','DBIC'],
        rel => 'has_many',
    );

    has 'no_envoy' => (
        is => 'rw',
        isa => 'Str'
    );

1;