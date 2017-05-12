use Test::More tests => 17;

use File::Temp;
use Rose::DBx::Garden;
use Rose::DBx::TestDB;
use Path::Class;
use Rose::HTML::Form;
use Rose::HTMLx::Form::Field::Serial;

Rose::HTML::Form->field_type_class(
    serial => 'Rose::HTMLx::Form::Field::Serial' );

my $debug = $ENV{PERL_DEBUG} || 0;

my $db = Rose::DBx::TestDB->new;

# create a schema that tests out all our column types

ok( $db->dbh->do(
        qq{
CREATE TABLE foo (
    id       integer primary key autoincrement,
    name     varchar(16),
    static   char(8),
    my_int   integer not null default 0,
    my_dec   float
    );
}
    ),
    "table foo created"
);

{

    package MyMetadata;
    use base qw( Rose::DB::Object::Metadata );

    # we override just this method since we don't actually need/want to
    # connect to the db, as the standard init_db() would. We need to
    # re-use our existing $db.
    sub init_db {
        my ($self) = shift;
        $self->{'db_id'} = $db->{'id'};
        return $db;
    }

    package MyRDBO;
    use base qw( Rose::DB::Object );

    sub meta_class {'MyMetadata'}

    package MyRDBOBase;

    sub new { bless {}, shift }
}

ok( my $garden = Rose::DBx::Garden->new(
        db              => $db,
        find_schemas    => 0,
        garden_prefix   => 'MyRDBO',
        base_class      => 'MyRDBOBase',
        force_install   => 1,
        column_to_label => sub {
            my ( $garden_obj, $col_name ) = @_;
            return join(
                ' ', map { ucfirst($_) }
                    split( m/_/, $col_name )
            );
        },
        include_autoinc_form_fields => 1,
        module_preamble             => qq/#FIRST LINE\n/,
        module_postamble            => qq/#LAST LINE\n/,
        debug                       => 1,
    ),
    "garden obj created"
);

my $dir
    = $debug
    ? '/tmp/rose_garden'
    : File::Temp->newdir( 'rose_garden_XXXX', TMPDIR => 1 );

diag("temp dir==$dir");
ok( $garden->make_garden("$dir"), "make_garden" );

#push( @INC, $dir );

# get db name as $garden made it
my $dbname = $db->database;
$dbname =~ s!.*/!!g;
$dbname =~ s/\W/_/g;
$dbname = ucfirst($dbname);

# are the files there?
ok( -s file( $dir, 'MyRDBO.pm' ), "base class exists" );
ok( -s file( $dir, 'MyRDBO', $dbname, 'Foo.pm' ), "table class exists" );
ok( -s file( $dir, 'MyRDBO', $dbname, 'Foo', 'Form.pm' ),
    "form class exists" );
ok( -s file( $dir, 'MyRDBO', $dbname, 'Foo', 'Manager.pm' ),
    "manager class exists" );

# do they compile?

for my $class (
    (   "MyRDBO",                 "MyRDBO::Form",
        "MyRDBO::${dbname}::Foo", "MyRDBO::${dbname}::Foo::Form",
        "MyRDBO::${dbname}::Foo::Manager"
    )
    )
{

    # have to clean up the symbol table manually
    # since these classes were created at runtime and are
    # not in %INC.

    if ( $class eq "MyRDBO::${dbname}::Foo::Manager" ) {
        no strict 'refs';
        local *symtable = $class . '::';
        delete $symtable{'get_foo'};
        delete $symtable{'get_foo_iterator'};
        delete $symtable{'get_foo_count'};
        delete $symtable{'delete_foo'};
        delete $symtable{'update_foo'};
        delete $symtable{'object_class'};
    }

    eval "use $class";
    ok( !$@, "require $class" );
    diag($@) and next if $@;

    if ( $class eq "MyRDBO::${dbname}::Foo" ) {
        isa_ok( $class->new, "MyRDBOBase" );
    }

    if ( $class eq "MyRDBO::${dbname}::Foo::Form" ) {
        ok( my $form = $class->new, "new $class" );
        is( $form->field('my_int')->label, 'My Int', "label callback works" );
        is( $form->field('my_int')->isa('Rose::HTML::Form::Field::Integer'),
            1, "my_int -> Integer field" );
        diag( $form->field('id') );

    SKIP: {
            my $rdbo_vers = $Rose::DB::Object::VERSION;
            $rdbo_vers =~ s/_\d+$//;
            if ( $rdbo_vers < '0.766' ) {
                skip( " -- change requested in default column mapping", 1 );
            }

            is( $form->field('id')->isa('Rose::HTMLx::Form::Field::Serial'),
                1, "id field is serial" );
        }

    }
}
