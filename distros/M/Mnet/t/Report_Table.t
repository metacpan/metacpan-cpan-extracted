
# purpose: tests Mnet::Report::Table end_errors method functionality

# required modules
#   JSON required in Mnet::Report::Table, best to find our here if missing
use warnings;
use strict;
use JSON;
use Test::More tests => 6;

# use current perl for tests
my $perl = $^X;

# init perl code used to test end_error method
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_report = "$perl -e '". '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    # use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Cli;
    use Mnet::Report::Table;
    use Mnet::Test;
    my ($cli, @extras) = Mnet::Opts::Cli->new;
    my $columns = [ int => "integer", err => "error", str => "string" ];
    push @$columns, ( time => "time" ) if $cli->test;
    our $table = Mnet::Report::Table->new({
        columns => $columns,
        log_id  => "id",
        output  => $extras[0],
    });
    $table->row({ int => 5, str => "1\r".chr(39)."2\n\"" });
' . "' --";

# csv output
Test::More::is(`echo; $perl_report --quiet csv:/dev/stdout 2>&1`, '
"int","err","str"
"5","","1 \'2 """
', 'csv output in specified order');

# dump output
Test::More::is(`echo; $perl_report --quiet dump:test:/dev/stdout 2>&1`, '
$test = {"err" => undef,"int" => 5,"str" => "1\r\'2\n\""};
', 'dump output in alphabetical order');

# default log output with log_id
Test::More::is(`echo; $perl_report 2>&1`, '
 -  - Mnet::Log -e started
inf id Mnet::Report::Table row {
inf id Mnet::Report::Table row    int => 5
inf id Mnet::Report::Table row    err => undef
inf id Mnet::Report::Table row    str => "1\r\'2\n\""
inf id Mnet::Report::Table row }
 -  - Mnet::Log finished with no errors
', 'default log output in specified order with log_id');

# json output, skipped if JSON module is not available
my $sed = "sed 's/int\":\"5\",/int\":5,/'";
Test::More::is(`echo; $perl_report --quiet json:test:/dev/stdout 2>&1 | $sed`,'
test = {"err":null,"int":5,"str":"1\r\'2\n\""};
', 'json output in alphabetical order');

# sql output
Test::More::is(`echo; $perl_report --quiet sql:"test":/dev/stdout 2>&1`, '
INSERT INTO "test" ("int","err","str") '
. "VALUES ('5','','1'+CHAR(10)+'''2'+CHAR(13)+'\"');
", 'sql output in specified order');

# test output
#   sed is used because epoch local time can vary, by timezone or something
$perl_report =~ s/use Mnet::Log;//;
Test::More::is(`$perl_report --test 2>&1|sed 's/....\\/..\\/.. ..:..:../DT/'`,'
Mnet::Report::Table row = {
  int  => 5
  err  => undef
  str  => "1\r\'2\n\""
  time => "DT"
}
', 'test output in specified order');

# finished
exit;
