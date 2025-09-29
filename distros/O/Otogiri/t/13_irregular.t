use strict;
use warnings;
use Test::More;
use Test::Exception;
use Otogiri;

my $dbfile  = ':memory:';

my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''] );

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

my $time = time;
my $param = {
    name       => 'ytnobody', 
    age        => 30,
    sex        => 'male',
    created_at => $time,
};
my $member = $db->insert(member => $param);
    
subtest broken_query => sub {
    dies_ok {    
        $db->search_by_sql(
            'SELECT * FROM membre WHERE id = ?', 
            [ $member->{id} ], 
            'member'
        );
    } 'select query to non exists table';

    my $filename = __FILE__;

    ### for MSWin32 :(
    if ($^O eq 'MSWin32') {
        $filename =~ s/\\/\\\\/g;
    }

    like $@, qr|$filename|, 'check filename that contains into comment in SQL';
};

subtest sqlmaker_injection_proof => sub {
    dies_ok { 
        $db->search('member', { name => { ';' => 'DROP TABLE member' } });
    } 'cannot pass in an unblessed ref as an argument in strict mode';
    
};

done_testing;

