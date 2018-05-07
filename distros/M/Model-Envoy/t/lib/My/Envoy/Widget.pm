package My::Envoy::Widget;

    use Moose;
    with 'Model::Envoy';

    use My::DB;

    sub dbic { 'My::DB::Result::Widget' }

    my $schema;

    sub _schema {
        $schema ||= My::DB->db_connect('/tmp/envoy');
    }

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

    has 'no_storage' => (
        is => 'rw',
        isa => 'Maybe[Str]',
    );

    has 'parts' => (
        is => 'rw',
        isa => 'ArrayRef[My::Envoy::Part]',
        traits => ['DBIC','Envoy'],
        rel => 'has_many',
        coerce => 1,
    );

1;