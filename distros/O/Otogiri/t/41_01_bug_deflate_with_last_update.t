use strict;
use warnings;
use utf8;
use Test::More;
use Test::Time;

use Otogiri;
use JSON;

my $json = JSON->new->utf8(1);
my $dbfile  = ':memory:';

{
    package 
        Otogiri::Test::Row;
    our $AUTOLOAD;
    sub AUTOLOAD {
        my ($self, $val) = @_;
        my ($method) = $AUTOLOAD =~ /^(?:.+)\:\:(.+?)$/;
        return if $method =~ /^[A-Z]/;
        $self->{data}{$method} = $val if defined $val;
        $self->{data}{$method};
    }
    sub new {
        my ($class, $table, %opts) = @_;
        bless {data => {%opts}, __METADATA => {table => $table}}, $class;
    }
    sub table {
        my $self = shift;
        $self->{__METADATA}{table};
    }
    sub as_hashref {
        my $self = shift;
        $self->{data};
    }
};

subtest inflate_for_select_with_deflation_by_time => sub {
    my $db = Otogiri->new( 
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''],
        inflate => sub {
            my ($row, $table_name, $handle) = @_;
            if ( defined $row->{data} ) {
                $row->{data} = $json->decode($row->{data});
                $row->{data}{table_name_in_inflate} = $table_name;
                $row->{data}{handle_in_inflate} = $handle;
            }
            $row;
        },
        deflate => sub {
            my ($row, $table_name, $handle) = @_;
            if ( defined $row->{data} ) {
                $row->{data}{table_name_in_deflate} = $table_name;
                $row->{data}{handle_in_deflate} = ref $handle;
                $row->{data} = $json->encode($row->{data});
            }
            $row->{created_at} ||= time();
            $row;
        }
    );

    my $sql = <<'EOF';
CREATE TABLE free_data2 (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    data       TEXT,
    created_at INTEGER
);
EOF

    $db->do($sql);

    my $now = time();

    sleep 5;
    $db->fast_insert(free_data2 => {
        data => {
            name     => 'ytnobody', 
            favolite => [qw/Soba Zohni Akadashi/],
        },
    });

    sleep 5;
    $db->fast_insert(free_data2 => {
        data => {
            name     => 'tsucchi', 
            favolite => [qw/Ramen Sushi/],
        },
    });

    my @rows = $db->select('free_data2', {});
    is( @rows, 2 );
    my ($row1, $row2) = @rows;
    is $row1->{data}{name}, 'ytnobody';
    is $row1->{data}{table_name_in_inflate}, 'free_data2';
    is $row1->{data}{table_name_in_deflate}, 'free_data2';
    is ref $row1->{data}{handle_in_inflate}, 'DBIx::Otogiri';
    is $row1->{data}{handle_in_deflate},     'DBIx::Otogiri';
    is $row1->{created_at} - $now, 5;
    is_deeply $row1->{data}{favolite}, [qw/Soba Zohni Akadashi/];

    is $row2->{data}{name}, 'tsucchi';
    is $row2->{data}{table_name_in_inflate}, 'free_data2';
    is $row2->{data}{table_name_in_deflate}, 'free_data2';
    is $row2->{created_at} - $now, 10;
    is_deeply $row2->{data}{favolite}, [qw/Ramen Sushi/];

    $db->delete('free_data2', {id => 1});
    my $deleted_row = $db->single('free_data2', {id => 1});
    is $deleted_row, undef;
};

done_testing;
