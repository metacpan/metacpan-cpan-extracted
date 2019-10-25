
# purpose: tests Mnet::Opts::Cli::Cache functionality

# required modules
use warnings;
use strict;
use Test::More tests => 12;

# use current perl for tests
my $perl = $^X;

# check cache get returns undef if cli options not parsed
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli::Cache;
    my \$opts = Mnet::Opts::Cli::Cache::get();
    warn "defined" if defined \$opts;
' -- 2>&1`, '', 'get with undef input and no cli parsing');

# check cache get returns empty input hash if cli opts not parsed
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli::Cache;
    my \$opts = Mnet::Opts::Cli::Cache::get({});
    warn "defined" if not defined \$opts;
    warn "ref" if not ref \$opts eq "HASH";
    warn "keys" if keys \%\$opts;
' -- 2>&1`, '', 'get with empty input hash and no cli parsing');

# check cache get returns input opts if cli opts not parsed
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli::Cache;
    my \$opts = Mnet::Opts::Cli::Cache::get({ test => 1 });
    warn "test" if not \$opts->{test};
' -- 2>&1`, '', 'get with input hash opt and no cli parsing');

# check cache get returns empty hash for undef input with no cli opts to parse
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Cli::Cache;
    Mnet::Opts::Cli->new;
    my \$opts = Mnet::Opts::Cli::Cache::get();
    warn "defined" if not defined \$opts;
    warn "ref" if ref \$opts ne "HASH";
    warn "keys" if keys \%\$opts;
' -- 2>&1`, '', 'get with undef input and no cli opts set');

# check cache get returns empty input hash with no cli opts to parse
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Cli::Cache;
    Mnet::Opts::Cli->new;
    my \$opts = Mnet::Opts::Cli::Cache::get({});
    warn "defined" if not defined \$opts;
    warn "ref" if ref \$opts ne "HASH";
    warn "keys" if keys \%\$opts;
' -- 2>&1`, '', 'get with empty input hash and no cli opts set');

# check cache get returns input opts if cli opts not parsed
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli::Cache;
    my \$opts = Mnet::Opts::Cli::Cache::get({ test => 1 });
    warn "test" if not \$opts->{test};
' -- 2>&1`, '', 'get input hash opt with no cli opts');

# check cache get returns parsed Mnet cli opt
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Cli::Cache;
    Mnet::Opts::Cli->new;
    my \$opts = Mnet::Opts::Cli::Cache::get({});
    warn "not defined" if not defined \$opts->{quiet};
' -- --quiet 2>&1`, '', 'get with empty input hash and Mnet cli opt set');

# check cache get doesn't return parsed non-Mnet cli opt
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Cli::Cache;
    Mnet::Opts::Cli::define({ getopt => "sample" });
    Mnet::Opts::Cli->new;
    my \$opts = Mnet::Opts::Cli::Cache::get({});
    warn "defined" if defined \$opts->{sample};
' -- --sample 2>&1`, '', 'get with empty input hash and non-Mnet cli opt set');

# check cache get overlays input opts over parsed cli opts
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Cli::Cache;
    Mnet::Opts::Cli::define({ getopt => "sample" });
    Mnet::Opts::Cli->new;
    my \$opts = Mnet::Opts::Cli::Cache::get({ sample => "2" });
    warn "defined" if \$opts->{sample} ne "2";
' -- --sample 2>&1`, '', 'get with input hash override of cli opt');

# check Mnet::Opts::Cli::Cache::get returns extra args
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Cli::Cache;
    Mnet::Opts::Cli::define({ getopt => "sample" });
    my (\$cli_opts, \@cli_extras) = Mnet::Opts::Cli->new;
    my (\$cache_opts, \@cache_extras) = Mnet::Opts::Cli::Cache::get({});
    warn "extras" if \$cache_extras[0] ne "extras";
' -- --sample extras 2>&1`, '', 'get with extra args');

# check that changes to a cached options don't propogate
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    my (\$old_opts, \@old_extras) = Mnet::Opts::Cli->new;
    \$old_opts->{invalid} = 1;
    \@old_extras = (1);
    my (\$new_opts, \@new_extras) = Mnet::Opts::Cli::Cache::get({});
    warn "opts" if exists \$new_opts->{invalid};
    warn "extras" if exists \$new_extras[0];
' -- 2>&1`, '', 'isolated cache options');

# check that changes to a cached Mnet::Opts::Cli->new objects don't propogate
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    my (\$old_opts, \@old_extras) = Mnet::Opts::Cli->new;
    \$old_opts->{invalid} = 1;
    \@old_extras = (1);
    my (\$new_opts, \@new_extras) = Mnet::Opts::Cli->new;
    warn "opts" if exists \$new_opts->{invalid};
    warn "extras" if exists \$new_extras[0];
' -- 2>&1`, '', 'isolated Mnet::Opts::Cli objects');

# finished
exit;

