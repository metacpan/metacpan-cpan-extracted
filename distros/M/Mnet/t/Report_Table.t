
# purpose: tests Mnet::Report::Table end_errors method functionality

# required modules
use warnings;
use strict;
use JSON;
use Mnet::T;
use Test::More tests => 6;

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
    my $columns = [ int => "integer", err => "error", str => "string" ];
    push @$columns, ( time => "time", epoch => "epoch" ) if $cli->test;
    our $table = Mnet::Report::Table->new({
        columns => $columns,
        log_id  => "id",
        output  => $extras[0],
    });
    $table->row({ int => 5, str => "1\r".chr(39)."2\n\"" });
perl-eof

# csv output in specified order
Mnet::T::test_perl({
    name    => 'csv output in specified order',
    perl    => $perl,
    args    => '--quiet csv:/dev/stdout',
    expect  => <<'    expect-eof',
        "int","err","str"
        "5","","1 '2 """
    expect-eof
    debug   => '--debug --noquiet',
});

# dump output in alphabetical order
Mnet::T::test_perl({
    name    => 'dump output in alphabetical order',
    perl    => $perl,
    args    => '--quiet dump:test:/dev/stdout',
    expect  => <<'    expect-eof',
        $test = {"err" => undef,"int" => 5,"str" => "1\r'2\n\""};
    expect-eof
    debug   => '--debug --noquiet',
});

# default log output in specified order with log_id
Mnet::T::test_perl({
    name    => 'default log output in specified order with log_id',
    perl    => $perl,
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf id Mnet::Report::Table row {
        inf id Mnet::Report::Table row    int => 5
        inf id Mnet::Report::Table row    err => undef
        inf id Mnet::Report::Table row    str => "1\r'2\n\""
        inf id Mnet::Report::Table row }
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# json output in alphabetical order
Mnet::T::test_perl({
    name    => 'json output in alphabetical order',
    perl    => $perl,
    args    => '--quiet json:test:/dev/stdout',
    filter  => <<'    filter-eof',
        sed 's/int":"5",/int":5,/'
    filter-eof
    expect  => <<'    expect-eof',
        test = {"err":null,"int":5,"str":"1\r'2\n\""};
    expect-eof
    debug   => '--debug --noquiet',
});

# sql output in specified order
Mnet::T::test_perl({
    name    => 'sql output in specified order',
    perl    => $perl,
    args    => '--quiet sql:"test":/dev/stdout',
    expect  =>
        'INSERT INTO "test" ("int","err","str") '
        . "VALUES ('5','','1'+CHAR(10)+'''2'+CHAR(13)+'\"');",
    debug   => '--debug --noquiet',
});

# test output in specified order
Mnet::T::test_perl({
    name    => 'test output in specified order',
    perl    => $perl,
    args    => '--test',
    filter  => 'grep "^inf id" | sed "s/....\\/..\\/.. ..:..:../DT/"',
    expect  => <<'    expect-eof',
        inf id Mnet::Report::Table row {
        inf id Mnet::Report::Table row    int   => 5
        inf id Mnet::Report::Table row    err   => undef
        inf id Mnet::Report::Table row    str   => "1\r'2\n\""
        inf id Mnet::Report::Table row    time  => "DT"
        inf id Mnet::Report::Table row    epoch => 1
        inf id Mnet::Report::Table row }
    expect-eof
    debug   => '--debug',
});

# finished
exit;
