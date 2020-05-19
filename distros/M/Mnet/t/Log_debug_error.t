
# purpose: tests Mnet::Log --debug-error

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 1;

# --debug-error after warning
Mnet::T::test_perl({
    name    => '--debug-error after warning',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( WARN );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        WARN('error');
    perl-eof
    args    => '--debug-error /dev/stdout',
    filter  => <<'    filter-eof',
        grep -e Mnet::Log -e WRN -e DEBUG -e 'opt def version' | \
        grep -v Mnet::Version | grep -v started | grep -v finished | \
        sed 's/-----*/-----/g'
    filter-eof
    expect  => <<'    expect-eof',
        WRN - main error
        --- - Mnet::Log creating --debug-error /dev/stdout
        ----- DEBUG ERROR OUTPUT STARTING -----
        dbg - Mnet::Opts::Cli new parsed opt def version = undef
        WRN - main error
        --- - Mnet::Log creating --debug-error /dev/stdout
        ----- DEBUG ERROR OUTPUT FINISHED -----
    expect-eof
    debug   => '--debug --noquiet',
});

# finished
exit;

