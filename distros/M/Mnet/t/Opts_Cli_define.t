
# purpose: tests Mnet::Opts::Cli define function and various option types

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 7;

# default option type
Mnet::T::test_perl({
    name    => 'default option type',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1" });
        Mnet::Opts::Cli::define({ getopt => "opt2" });
        Mnet::Opts::Cli::define({ getopt => "opt3" });
        Mnet::Opts::Cli::define({ getopt => "opt4" });
        Mnet::Opts::Cli::define({ getopt => "opt5" });
        Mnet::Opts::Cli::define({ getopt => "opt6", default => "1" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        syswrite STDOUT, "extras = @extras\n";
        warn "opt1" if $cli->opt1 ne "1";
        warn "opt2" if defined $cli->opt2;
        warn "opt3" if $cli->opt3 ne "1";
        warn "opt4" if $cli->opt4 ne "1";
        warn "opt5" if defined $cli->opt5;
        warn "opt6" if $cli->opt6 ne "1";
    perl-eof
    args    => '--opt1 --noopt2 --opt3 3 --opt4 four',
    expect  => 'extras = --noopt2 3 four',
});

# negatable option type
Mnet::T::test_perl({
    name    => 'negatable option type',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1!" });
        Mnet::Opts::Cli::define({ getopt => "opt2!" });
        Mnet::Opts::Cli::define({ getopt => "opt3!" });
        Mnet::Opts::Cli::define({ getopt => "opt4!" });
        Mnet::Opts::Cli::define({ getopt => "opt5!" });
        Mnet::Opts::Cli::define({ getopt => "opt6!", default => "1" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        syswrite STDOUT, "extras = @extras\n";
        warn "opt1" if $cli->opt1 ne "1";
        warn "opt2" if $cli->opt2 ne "0";
        warn "opt3" if $cli->opt3 ne "1";
        warn "opt4" if $cli->opt4 ne "1";
        warn "opt5" if defined $cli->opt5;
        warn "opt6" if $cli->opt6 ne "1";
    perl-eof
    args    => '--opt1 --noopt2 --opt3 3 --opt4 four',
    expect  => 'extras = 3 four',
});

# integer required option type
Mnet::T::test_perl({
    name    => 'integer required option type',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1=i" });
        Mnet::Opts::Cli::define({ getopt => "opt2=i" });
        Mnet::Opts::Cli::define({ getopt => "opt3=i" });
        Mnet::Opts::Cli::define({ getopt => "opt4=i" });
        Mnet::Opts::Cli::define({ getopt => "opt5=i" });
        Mnet::Opts::Cli::define({ getopt => "opt6=i", default => "1" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        syswrite STDOUT, "extras = @extras\n";
        warn "opt1" if defined $cli->opt1;
        warn "opt2" if defined $cli->opt2;
        warn "opt3" if $cli->opt3 ne "3";
        warn "opt4" if defined $cli->opt4;
        warn "opt5" if defined $cli->opt5;
        warn "opt6" if $cli->opt6 ne "1";
    perl-eof
    args    => '--opt1 --noopt2 --opt3 3 --opt4 four',
    expect  => 'extras = --opt1 --noopt2 --opt4 four',
});

# integer optional option type
Mnet::T::test_perl({
    name    => 'integer optional option type',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1:i" });
        Mnet::Opts::Cli::define({ getopt => "opt2:i" });
        Mnet::Opts::Cli::define({ getopt => "opt3:i" });
        Mnet::Opts::Cli::define({ getopt => "opt4:i" });
        Mnet::Opts::Cli::define({ getopt => "opt5:i" });
        Mnet::Opts::Cli::define({ getopt => "opt6:i", default => "1" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        syswrite STDOUT, "extras = @extras\n";
        warn "opt1" if $cli->opt1 ne "0";
        warn "opt2" if defined $cli->opt2;
        warn "opt3" if $cli->opt3 ne "3";
        warn "opt4" if $cli->opt4 ne "0";
        warn "opt5" if defined $cli->opt5;
        warn "opt6" if $cli->opt6 ne "1";
    perl-eof
    args    => '--opt1 --noopt2 --opt3 3 --opt4 four',
    expect  => 'extras = --noopt2 four',
});

# string required option type
Mnet::T::test_perl({
    name    => 'string required option type',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1=s" });
        Mnet::Opts::Cli::define({ getopt => "opt2=s" });
        Mnet::Opts::Cli::define({ getopt => "opt3=s" });
        Mnet::Opts::Cli::define({ getopt => "opt4=s" });
        Mnet::Opts::Cli::define({ getopt => "opt5=s" });
        Mnet::Opts::Cli::define({ getopt => "opt6=s", default => "1" });
        my $cli = Mnet::Opts::Cli->new;
        warn "opt1" if $cli->opt1 ne "--noopt2";
        warn "opt2" if defined $cli->opt2;
        warn "opt3" if $cli->opt3 ne "3";
        warn "opt4" if $cli->opt4 ne "four";
        warn "opt5" if defined $cli->opt5;
        warn "opt6" if $cli->opt6 ne "1";
    perl-eof
    args    => '--opt1 --noopt2 --opt3 3 --opt4 four',
    expect  => '',
});

# string optional option type
Mnet::T::test_perl({
    name    => 'string optional option type',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1:s" });
        Mnet::Opts::Cli::define({ getopt => "opt2:s" });
        Mnet::Opts::Cli::define({ getopt => "opt3:s" });
        Mnet::Opts::Cli::define({ getopt => "opt4:s" });
        Mnet::Opts::Cli::define({ getopt => "opt5:s" });
        Mnet::Opts::Cli::define({ getopt => "opt6:s", default => "1" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        syswrite STDOUT, "extras = @extras\n";
        warn "opt1" if $cli->opt1 ne "";
        warn "opt2" if defined $cli->opt2;
        warn "opt3" if $cli->opt3 ne "3";
        warn "opt4" if $cli->opt4 ne "four";
    perl-eof
    args    => '--opt1 --noopt2 --opt3 3 --opt4 four',
    expect  => 'extras = --noopt2',
});

# redact option
Mnet::T::test_perl({
    name    => 'redact option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "opt1:s", redact => 1 });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
    perl-eof
    args    => '--opt1 redact',
    filter  => 'grep ^inf',
    expect  => <<'    expect-eof',
        inf - Mnet::Opts::Cli new parsed opt cli opt1 = **** (redacted)
    expect-eof
});

# finished
exit;

