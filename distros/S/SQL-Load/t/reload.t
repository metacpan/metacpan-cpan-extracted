use Test::More;
use SQL::Load;
use File::Temp qw/tempdir/;

my $dir = tempdir(CLEANUP => 1);

save('data.sql', 'SELECT * FROM foo;');

my $sql_load = SQL::Load->new($dir);

my $sql_1 = $sql_load->load('data')->first;
is(
    $sql_1,
    'SELECT * FROM foo;',
    'Test if select is foo'
);

save('data.sql', 'SELECT * FROM baz;');

my $sql_2 = $sql_load->load('data')->first;
is(
    $sql_2,
    'SELECT * FROM foo;',
    'Test if select is foo because get from tmp'
);

my $sql_3 = $sql_load->load('data', 1)->first;
is(
    $sql_3,
    'SELECT * FROM baz;',
    'Test if select is baz'
);

save('data.sql', 'SELECT * FROM bar;');

my $sql_4 = $sql_load->reload('data')->first;
is(
    $sql_4,
    'SELECT * FROM bar;',
    'Test if select is bar'
);

sub save {
    my ($file, $data) = @_;
    
    open(FH, '>', $dir . '/' . $file) or die $!;
    print FH $data;
    close(FH);
}

done_testing;
