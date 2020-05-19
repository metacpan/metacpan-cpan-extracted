
# purpose: tests Mnet::Test::time function

# required modules
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 6;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# real time no cli opts
Mnet::T::test_perl({
    name    => 'real time no cli opts',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Test;
        warn "fail1" if time + 1 < Mnet::Test::time();
        warn "fail2" if time + 1 < Mnet::Test::time(2);
        warn "fail2" if time + 1 < Mnet::Test::time({});
        warn "fail4" if time + 1 < Mnet::Test::time({}, 4);
        syswrite STDOUT, "done\n";
    perl-eof
    expect  => 'done',
});

# test time no cli opts
Mnet::T::test_perl({
    name    => 'test time no cli opts',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Test;
        warn "fail1" if "1" ne Mnet::Test::time({ record => "" });
        warn "fail3" if "3" ne Mnet::Test::time({ record => "file" }, 2);
        warn "fail3" if "6" ne Mnet::Test::time({ replay => "file" }, 3);
        warn "fail4" if "10" ne Mnet::Test::time({ test => 1 }, 4);
        syswrite STDOUT, "done\n";
    perl-eof
    expect  => 'done',
});

# real time with cli opts
Mnet::T::test_perl({
    name    => 'real time with cli opts',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        use Mnet::Test;
        Mnet::Opts::Cli->new;
        warn "fail1" if time + 1 < Mnet::Test::time();
        warn "fail2" if time + 1 < Mnet::Test::time(2);
        syswrite STDOUT, "done\n";
    perl-eof
    expect  => 'done',
});

# test time --record cli opts
Mnet::T::test_perl({
    name    => 'test time --record cli opts',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        use Mnet::Test;
        Mnet::Opts::Cli->new;
        warn "fail1" if "1" ne Mnet::Test::time();
        warn "fail2" if "3" ne Mnet::Test::time(2);
        warn "fail3" if time + 1 < Mnet::Test::time({});
        syswrite STDOUT, "done\n";
    perl-eof
    args    => "--record $file",
    expect  => 'done',
});

# test time --replay cli opts
Mnet::T::test_perl({
    name    => 'test time --replay cli opts',
    pre     => "echo '\$Mnet::Test::data = {}' > $file",
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        use Mnet::Test;
        Mnet::Opts::Cli->new;
        warn "fail1" if "1" ne Mnet::Test::time();
        warn "fail2" if "3" ne Mnet::Test::time(2);
        warn "fail3" if time + 1 < Mnet::Test::time({});
        syswrite STDOUT, "done\n";
    perl-eof
    args    => "--replay $file",
    expect  => 'done',
});

# test time --test cli opts
Mnet::T::test_perl({
    name    => 'test time --test cli opts',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        use Mnet::Test;
        Mnet::Opts::Cli->new;
        warn "fail1" if "1" ne Mnet::Test::time();
        warn "fail2" if "3" ne Mnet::Test::time(2);
        warn "fail3" if time + 1 < Mnet::Test::time({});
        syswrite STDOUT, "done\n";
    perl-eof
    args    => "--test",
    expect  => 'done',
});

# finished
exit;

