
package DBConfig;

use DBI;
use Tangram qw(:core :compat_quiet);
local $/;

my $config = $ENV{TANGRAM_CONFIG} || 't/CONFIG';

open CONFIG, "$config"
    or die "Cannot open $config, reason: $!";

my ($tx, $subsel, $ttype);
($cs, $user, $passwd, $tx, $subsel, $ttype)
    = split "\n", <CONFIG>;

if ($tx =~ m/(\d)/) {
    $no_tx = !$1;
}
if ($subsel =~ m/(\d)/) {
    $no_subselects = !$1;
}
if ($ttype =~ m/table_type\s*=\s*(.*)/) {
    $table_type = $1;
}

$vendor = (split ':', $cs)[1];;
$dialect = "Tangram::$vendor";  # deduce dialect from DBI driver
eval "use $dialect";
($dialect = 'Tangram::Relational'), eval("use $dialect") if $@;
print $Tangram::TRACE "Vendor driver $dialect not found - using ANSI SQL ($@)\n"
    if $@ and $Tangram::TRACE;
if ($Tangram::TRACE) {
    print $Tangram::TRACE "DBConfig.pm: dialect = $dialect, cparm = $cs, "
	.($user ? "$user" : "(no user)").", "
	    .($passwd ? ("x" x (length $passwd)) : "(no passwd)")."\n";
}


our $AUTOLOAD;
sub AUTOLOAD {
    shift if UNIVERSAL::isa($_[0], __PACKAGE__);
    $AUTOLOAD =~ s{.*::}{};
    return $$AUTOLOAD;
}

sub cparm {
    return ($cs, $user, $passwd);
}

sub setup {
    my $class = shift if UNIVERSAL::isa($_[0], __PACKAGE__);
    $class ||= __PACKAGE__;
    my $schema = shift;
    my ($dsn, $u, $p) = $class->cparm;
    my $dbh = DBI->connect($dsn, $u, $p);
    eval {
	local $dbh->{RaiseError};
	local $dbh->{PrintError};
	Tangram::Relational->retreat($schema, $dbh);
    };
    Tangram::Relational->deploy($schema, $dbh);
}

1;
