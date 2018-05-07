package My::Part;

    use Moose;
    with 'Model::Envoy::Storage::DBIC';

    use My::DB;

    sub dbic { 'My::DB::Result::Part' }

    my $schema;

    sub _schema {
        $schema ||= My::DB->db_connect('/tmp/dbic');
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
        isa => 'Maybe[My::Widget]',
        traits => ['DBIC'],
        rel => 'belongs_to',
    );

1;