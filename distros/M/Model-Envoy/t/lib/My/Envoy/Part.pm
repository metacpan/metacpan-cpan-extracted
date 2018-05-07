package My::Envoy::Part;

    use Moose;
    with 'Model::Envoy';

    use My::DB;

    sub dbic { 'My::DB::Result::Part' }

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

    has 'widget' => (
        is => 'rw',
        isa => 'Maybe[My::Envoy::Widget]',
        traits => ['DBIC','Envoy'],
        rel => 'belongs_to',
        coerce => 1,
    );

1;