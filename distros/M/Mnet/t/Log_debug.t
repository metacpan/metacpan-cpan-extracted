
# purpose: tests Mnet::Log debug

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 4;

# debug default disabled
Mnet::T::test_perl({
    name    => 'debug default disabled',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        Mnet::Log->new->debug('debug method');
        DEBUG('debug function');
    perl-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug --noquiet',
});

# debug object option
Mnet::T::test_perl({
    name    => 'debug object option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        Mnet::Log->new({ debug => 1 })->debug('debug method');
        DEBUG('debug function');
    perl-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - main debug method
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug --noquiet',
});

# debug pragma option
Mnet::T::test_perl({
    name    => 'debug pragma option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Debug;
        my $cli = Mnet::Opts::Cli->new;
        Mnet::Log->new->debug('debug method');
        DEBUG('debug function');
    perl-eof
    filter  => 'grep -v "Mnet::Version" | grep -v "dbg - Mnet::Opts::Cli"',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - Mnet::Opts::Cli new parsed opt use debug = 1
        dbg - main debug method
        dbg - main debug function
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug --noquiet',
});

# debug cli option
Mnet::T::test_perl({
    name    => 'debug cli option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        Mnet::Log->new->debug('debug method');
        DEBUG('debug function');
    perl-eof
    args    => '--debug',
    filter  => 'grep -v "Mnet::Version" | grep -v "dbg - Mnet::Opts::Cli"',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - Mnet::Opts::Cli new parsed opt cli debug = 1
        dbg - main debug method
        dbg - main debug function
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--noquiet',
});

# finished
exit;

