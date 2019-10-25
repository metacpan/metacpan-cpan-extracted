
# purpose: tests Mnet::Opts::Cli define function and various option types

# required modules
use warnings;
use strict;
use Test::More tests => 7;

# use current perl for tests
my $perl = $^X;

# check default option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1" });
    Mnet::Opts::Cli::define({ getopt => "opt2" });
    Mnet::Opts::Cli::define({ getopt => "opt3" });
    Mnet::Opts::Cli::define({ getopt => "opt4" });
    Mnet::Opts::Cli::define({ getopt => "opt5" });
    Mnet::Opts::Cli::define({ getopt => "opt6", default => "1" });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "extras = \@extras\n";
    warn "opt1" if \$cli->opt1 ne "1";
    warn "opt2" if defined \$cli->opt2;
    warn "opt3" if \$cli->opt3 ne "1";
    warn "opt4" if \$cli->opt4 ne "1";
    warn "opt5" if defined \$cli->opt5;
    warn "opt6" if \$cli->opt6 ne "1";
' -- --opt1 --noopt2 --opt3 3 --opt4 four 2>&1`,
'extras = --noopt2 3 four
', 'default option type');

# check negatable option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1!" });
    Mnet::Opts::Cli::define({ getopt => "opt2!" });
    Mnet::Opts::Cli::define({ getopt => "opt3!" });
    Mnet::Opts::Cli::define({ getopt => "opt4!" });
    Mnet::Opts::Cli::define({ getopt => "opt5!" });
    Mnet::Opts::Cli::define({ getopt => "opt6!", default => "1" });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "extras = \@extras\n";
    warn "opt1" if \$cli->opt1 ne "1";
    warn "opt2" if \$cli->opt2 ne "0";
    warn "opt3" if \$cli->opt3 ne "1";
    warn "opt4" if \$cli->opt4 ne "1";
    warn "opt5" if defined \$cli->opt5;
    warn "opt6" if \$cli->opt6 ne "1";
' -- --opt1 --noopt2 --opt3 3 --opt4 four 2>&1`,
'extras = 3 four
', 'negatable option type');

# check integer required option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1=i" });
    Mnet::Opts::Cli::define({ getopt => "opt2=i" });
    Mnet::Opts::Cli::define({ getopt => "opt3=i" });
    Mnet::Opts::Cli::define({ getopt => "opt4=i" });
    Mnet::Opts::Cli::define({ getopt => "opt5=i" });
    Mnet::Opts::Cli::define({ getopt => "opt6=i", default => "1" });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "extras = \@extras\n";
    warn "opt1" if defined \$cli->opt1;
    warn "opt2" if defined \$cli->opt2;
    warn "opt3" if \$cli->opt3 ne "3";
    warn "opt4" if defined \$cli->opt4;
    warn "opt5" if defined \$cli->opt5;
    warn "opt6" if \$cli->opt6 ne "1";
' -- --opt1 --noopt2 --opt3 3 --opt4 four 2>&1`,
'extras = --opt1 --noopt2 --opt4 four
', 'integer required option type');

# check integer optional option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1:i" });
    Mnet::Opts::Cli::define({ getopt => "opt2:i" });
    Mnet::Opts::Cli::define({ getopt => "opt3:i" });
    Mnet::Opts::Cli::define({ getopt => "opt4:i" });
    Mnet::Opts::Cli::define({ getopt => "opt5:i" });
    Mnet::Opts::Cli::define({ getopt => "opt6:i", default => "1" });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "extras = \@extras\n";
    warn "opt1" if \$cli->opt1 ne "0";
    warn "opt2" if defined \$cli->opt2;
    warn "opt3" if \$cli->opt3 ne "3";
    warn "opt4" if \$cli->opt4 ne "0";
    warn "opt5" if defined \$cli->opt5;
    warn "opt6" if \$cli->opt6 ne "1";
' -- --opt1 --noopt2 --opt3 3 --opt4 four 2>&1`,
'extras = --noopt2 four
', 'integer optional option type');

# check string required option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1=s" });
    Mnet::Opts::Cli::define({ getopt => "opt2=s" });
    Mnet::Opts::Cli::define({ getopt => "opt3=s" });
    Mnet::Opts::Cli::define({ getopt => "opt4=s" });
    Mnet::Opts::Cli::define({ getopt => "opt5=s" });
    Mnet::Opts::Cli::define({ getopt => "opt6=s", default => "1" });
    my \$cli = Mnet::Opts::Cli->new;
    warn "opt1" if \$cli->opt1 ne "--noopt2";
    warn "opt2" if defined \$cli->opt2;
    warn "opt3" if \$cli->opt3 ne "3";
    warn "opt4" if \$cli->opt4 ne "four";
    warn "opt5" if defined \$cli->opt5;
    warn "opt6" if \$cli->opt6 ne "1";
' -- --opt1 --noopt2 --opt3 3 --opt4 four 2>&1`,
'', 'string required option type');

# check string optional option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1:s" });
    Mnet::Opts::Cli::define({ getopt => "opt2:s" });
    Mnet::Opts::Cli::define({ getopt => "opt3:s" });
    Mnet::Opts::Cli::define({ getopt => "opt4:s" });
    Mnet::Opts::Cli::define({ getopt => "opt5:s" });
    Mnet::Opts::Cli::define({ getopt => "opt6:s", default => "1" });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "extras = \@extras\n";
    warn "opt1" if \$cli->opt1 ne "";
    warn "opt2" if defined \$cli->opt2;
    warn "opt3" if \$cli->opt3 ne "3";
    warn "opt4" if \$cli->opt4 ne "four";
' -- --opt1 --noopt2 --opt3 3 --opt4 four 2>&1`,
'extras = --noopt2
', 'string optional option type');

# check string optional option type
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1:s", redact => 1 });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
' -- --opt1 redact 2>&1 | grep ^inf`,
'inf - Mnet::Opts::Cli new parsed opt cli opt1 = **** (redacted)
', 'redact option');

# finished
exit;

