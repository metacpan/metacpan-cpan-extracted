
# purpose: tests Mnet::Report::Table with Mnet::Batch

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 2;

# batch fork error
Mnet::T::test_perl({
    name    => 'batch fork error',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Batch;
        use Mnet::Report::Table;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        my $cli = Mnet::Batch::fork({});
        exit if not $cli;
        Mnet::Report::Table->new({ table => "test" });
    perl-eof
    filter  => 'grep ^ERR | sed "s/ at - line .*//"',
    expect  => 'ERR - Carp perl die, '
        . 'new Mnet::Report::Table must be created before Mnet::Batch::fork',
});

# batch csv output
Mnet::T::test_perl({
    name    => 'batch csv output',
    pre     => <<'    pre-eof',
        export BATCH=$(mktemp); ( echo 1; echo 2 ) >$BATCH
    pre-eof
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Batch;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        use Mnet::Report::Table;
        use Mnet::Test;
        our $table = Mnet::Report::Table->new({
            table   => "test",
            columns => [ data => "string", error => "error" ],
            output  => "csv:/dev/stdout",
        });
        my $line = Mnet::Batch::fork({ batch => $ENV{BATCH} });
        exit if not defined $line;
        $table->row({ data => "child" });
    perl-eof
    filter  => 'grep -v ^dbg | grep -v ^---',
    expect  => <<'    expect-eof',
        "data","error"
        "child",""
        "child",""
    expect-eof
});

# finished
exit;
