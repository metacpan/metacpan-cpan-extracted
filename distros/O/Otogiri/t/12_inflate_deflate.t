use strict;
use warnings;
use utf8;
use Test::More;

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

subtest basic => sub {
    my $db = Otogiri->new( 
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''],
        inflate => sub {
            my $row = shift;
            $row->{data} = $json->decode($row->{data}) if defined $row->{data};
            $row;
        },
        deflate => sub {
            my $row = shift;
            $row->{data} = $json->encode($row->{data}) if defined $row->{data};
            $row;
        }
    );

    my $sql = <<'EOF';
CREATE TABLE free_data (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    data       TEXT
);
EOF

    $db->do($sql);
    $db->insert(free_data => {
        data => {
            name     => 'ytnobody', 
            age      => 32,
            favolite => [qw/Soba Zohni Akadashi/],
        },
    });
    my $row = $db->single(free_data => {id => $db->last_insert_id});
    
    is $row->{data}{name}, 'ytnobody';
    is $row->{data}{age}, 32;
    is_deeply $row->{data}{favolite}, [qw/Soba Zohni Akadashi/];
};

subtest row_obj => sub {
    my $db = Otogiri->new( 
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''],
        inflate => sub {
            my ($row, $table) = @_;
            Otogiri::Test::Row->new($table, %$row);
        },
    );

    my $sql = <<'EOF';
CREATE TABLE member (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT    NOT NULL,
    age        INTEGER NOT NULL DEFAULT 20,
    sex        TEXT    NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER
);
EOF

    $db->do($sql);

    my $param = {
        name       => 'ytnobody', 
        age        => 32,
        sex        => 'male',
        created_at => time,
    };
    
    $db->insert(member => $param);
    my $member = $db->single(member => {id => $db->last_insert_id});

    isa_ok $member, 'Otogiri::Test::Row';
    is $member->name, 'ytnobody';
    is $member->age, 32;
    is $member->sex, 'male';
};


subtest inflate_for_select => sub {
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
            $row;
        }
    );

    my $sql = <<'EOF';
CREATE TABLE free_data2 (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    data       TEXT
);
EOF

    $db->do($sql);
    $db->fast_insert(free_data2 => {
        data => {
            name     => 'ytnobody', 
            favolite => [qw/Soba Zohni Akadashi/],
        },
    });
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
    is_deeply $row1->{data}{favolite}, [qw/Soba Zohni Akadashi/];

    is $row2->{data}{name}, 'tsucchi';
    is $row2->{data}{table_name_in_inflate}, 'free_data2';
    is $row2->{data}{table_name_in_deflate}, 'free_data2';
    is_deeply $row2->{data}{favolite}, [qw/Ramen Sushi/];

    my $iter = $db->select('free_data2');
    while (my $iter_row = $iter->next) {
        my $index = $iter->fetched_count - 1;
        is_deeply($iter_row, $rows[$index]);
    }
    is $iter->fetched_count, 2;
};

done_testing;
