use lib (qw(t));
use Test::More tests => 2 + 1;

use File::Temp ( 'tempdir' );
use Rose::DBx::TestDB;
use Path::Class;
use Rose::HTML::Form;
use Rose::DBx::Object::Loader::FormMaker;
use Cwd;
use Test::Form;

my $debug = $ENV{PERL_DEBUG} || 0;

my $db = Rose::DBx::TestDB->new;

# create a schema that tests out all our column types
#
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

ok(
my $formmaker = Rose::DBx::Object::Loader::FormMaker->new(
        db                => $db,
	class_prefix      => qq[Test::DB],
	form_prefix       => qq[Test::Form],
	form_base_classes => qq[Test::Form],
	base_tabindex     => 15,
    )
, "form maker object created" );


my $dir = tempdir(
    '/tmp/rdbolf_XXXX', 
    CLEANUP => 1
);

my @classes = $formmaker->make_modules(module_dir => $dir);

#
# use lib wouldn't work with a variable so i'm unshifting onto @INC
#
unshift(@INC, $dir);

foreach my $class (@classes) {
    next unless $class =~ m/Test::Form/;
    use_ok($class);
}
