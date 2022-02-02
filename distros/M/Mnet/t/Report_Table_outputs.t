
# purpose: tests Mnet::Report::Table output options

# required modules
use warnings;
use strict;
use JSON;
use Mnet::T;
use Test::More tests => 15;

# init perl used for tests
my $perl = <<'perl-eof';
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Report::Table;
    use Mnet::Test;
    my ($cli, @extras) = Mnet::Opts::Cli->new;
    our $table = Mnet::Report::Table->new({
        columns => [ test => "string" ],
        log_id  => "id",
        output  => $extras[0],
    });
    $table->row({ test => "value" });
perl-eof

# csv output to named file
Mnet::T::test_perl({
    name    => 'csv output to named file',
    perl    => $perl,
    args    => '--quiet csv:/dev/stdout',
    expect  => '"test"' . "\n" . '"value"',
    debug   => '--debug --noquiet',
});

# csv output to default stdout
Mnet::T::test_perl({
    name    => 'csv output to default stdout',
    perl    => $perl,
    args    => '--quiet csv',
    expect  => '"test"' . "\n" . '"value"',
    debug   => '--debug --noquiet',
});

# dump output to named file
Mnet::T::test_perl({
    name    => 'dump to named file',
    perl    => $perl,
    args    => '--quiet dump:test:/dev/stdout',
    expect  => '$test = {"test" => "value"};',
    debug   => '--debug --noquiet',
});

# dump output to default stdout
Mnet::T::test_perl({
    name    => 'dump to default stdout',
    perl    => $perl,
    args    => '--quiet dump:test',
    expect  => '$test = {"test" => "value"};',
    debug   => '--debug --noquiet',
});

# dump output to default var
Mnet::T::test_perl({
    name    => 'dump to default var',
    perl    => $perl,
    args    => '--quiet dump',
    expect  => '$dump = {"test" => "value"};',
    debug   => '--debug --noquiet',
});

# json output to named file
Mnet::T::test_perl({
    name    => 'json to named file',
    perl    => $perl,
    args    => '--quiet json:test:/dev/stdout',
    expect  => 'test = {"test":"value"};',
    debug   => '--debug --noquiet',
});

# json output to default stdout
Mnet::T::test_perl({
    name    => 'json to default stdout',
    perl    => $perl,
    args    => '--quiet json:test',
    expect  => 'test = {"test":"value"};',
    debug   => '--debug --noquiet',
});

# json output to default var
Mnet::T::test_perl({
    name    => 'json to default var',
    perl    => $perl,
    args    => '--quiet json',
    expect  => 'json = {"test":"value"};',
    debug   => '--debug --noquiet',
});

# sql output to named file
Mnet::T::test_perl({
    name    => 'sql output to named file',
    perl    => $perl,
    args    => '--quiet sql:test_table:/dev/stdout',
    expect  => 'INSERT INTO "test_table" ("test") '. "VALUES ('value');",
    debug   => '--debug --noquiet',
});

# sql output to default stdout
Mnet::T::test_perl({
    name    => 'sql output to default stdout',
    perl    => $perl,
    args    => '--quiet sql:test_table',
    expect  => 'INSERT INTO "test_table" ("test") '. "VALUES ('value');",
    debug   => '--debug --noquiet',
});

# sql output to quoted table
Mnet::T::test_perl({
    name    => 'sql output to quoted table',
    perl    => $perl,
    args    => '--quiet sql:\"test^table\":/dev/stdout',
    expect  => 'INSERT INTO "test^table" ("test") '. "VALUES ('value');",
    debug   => '--debug --noquiet',
});

# sql output to quoted table only
Mnet::T::test_perl({
    name    => 'sql output to quoted table only',
    perl    => $perl,
    args    => '--quiet sql:\"test^table\"',
    expect  => 'INSERT INTO "test^table" ("test") '. "VALUES ('value');",
    debug   => '--debug --noquiet',
});

# sql output to default table
Mnet::T::test_perl({
    name    => 'sql output to default table',
    perl    => $perl,
    args    => '--quiet sql',
    expect  => 'INSERT INTO "table" ("test") '. "VALUES ('value');",
    debug   => '--debug --noquiet',
});

# tsv output to named file
Mnet::T::test_perl({
    name    => 'csv output to named file',
    perl    => $perl,
    args    => '--quiet tsv:/dev/stdout',
    expect  => 'test' . "\n" . 'value',
    debug   => '--debug --noquiet',
});

# tsv output to default stdout
Mnet::T::test_perl({
    name    => 'tsv output to default stdout',
    perl    => $perl,
    args    => '--quiet tsv',
    expect  => 'test' . "\n" . 'value',
    debug   => '--debug --noquiet',
});

# finished
exit;
