
# purpose: tests Mnet::Report::Table row_on_error method functionality

# required modules
use warnings;
use strict;
use Test::More tests => 4;

# use current perl for tests
my $perl = $^X;

# init perl code used to test row_on_error method
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_row_on_error = undef;
sub perl_row_on_error {
    my $input = shift // "";
    my ($log, $die) = ("", "");
    $log = 'use Mnet::Log;' if $input =~ /log/;
    $die = 'die "died\n";' if $input =~ /die/;
    return "$perl -e '" . '
        use warnings;
        use strict;
        ' . $log . '
        # use Mnet::Log; use Mnet::Opts::Set::Debug;
        use Mnet::Opts::Cli;
        use Mnet::Report::Table;
        use Mnet::Test;
        my ($cli, @args) = Mnet::Opts::Cli->new;
        my $table = Mnet::Report::Table->new({
            columns => [ data => "string", error => "error" ],
        });
        $table->row_on_error({ data => "row_on_error" });
        ' . $die . '
        $table->row({ data => "not row_on_error" });
    ' . "' -- --test ";
}

# row_on_error method, no log, no die
$perl_row_on_error = perl_row_on_error();
Test::More::is(`echo; $perl_row_on_error 2>&1 | grep .`, '
Mnet::Report::Table row = {
  data  => "not row_on_error"
  error => undef
}
', 'row_on_error method, no log, no die');

# row_on_error method, no log, die
$perl_row_on_error = perl_row_on_error("die");
Test::More::is(`echo; $perl_row_on_error 2>&1 | grep .`, '
died
Mnet::Report::Table row = {
  data  => "row_on_error"
  error => "died"
}
', 'row_on_error method, no log, die');

# row_on_error method, log, no die
$perl_row_on_error = perl_row_on_error("log");
Test::More::is(`echo; $perl_row_on_error 2>&1 | grep .`, '
--- - Mnet::Log -e started
inf - Mnet::Opts::Cli new parsed opt cli test = 1
inf - Mnet::Report::Table row {
inf - Mnet::Report::Table row    data  => "not row_on_error"
inf - Mnet::Report::Table row    error => undef
inf - Mnet::Report::Table row }
--- - Mnet::Log finished with no errors
', 'row_on_error method, log, no die');

# row_on_error method, log, die
$perl_row_on_error = perl_row_on_error("log die");
Test::More::is(`echo; $perl_row_on_error 2>&1 | grep . | grep -v '^err'`, '
--- - Mnet::Log -e started
inf - Mnet::Opts::Cli new parsed opt cli test = 1
ERR - main perl die, died
inf - Mnet::Report::Table row {
inf - Mnet::Report::Table row    data  => "row_on_error"
inf - Mnet::Report::Table row    error => "main perl die, died"
inf - Mnet::Report::Table row }
--- - Mnet::Log finished with errors
', 'row_on_error method, log, die');

# finished
exit;
