
# purpose: tests Mnet::Log perl die and warn handlers

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 10;

# init perl code for these tests
my $perl = "
    use warnings;
    use strict;
    use Mnet::Log qw( INFO WARN FATAL );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli->new;
";

# perl compile warning
Mnet::T::test_perl({
    name    => 'perl compile warning',
    perl    => "$perl; foo;",
    filter  => "sed 's/at .* line .*/at .../'",
    expect  => <<'    expect-eof',
        Bareword "foo" not allowed while "strict subs" in use at ...
        Execution of - aborted due to compilation errors.
    expect-eof
    debug   => '--debug',
});

# perl runtime warning
Mnet::T::test_perl({
    name    => 'perl runtime warning',
    perl    => "$perl; my \$x = 1 + undef;",
    filter  => "sed 's/at .* line .*/at .../' | grep -v ANON",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        ERR - main perl warn, Use of uninitialized value in addition (+) at ...
        err - main perl warn,  at ...
        err - main perl warn, $? = 0
        --- - Mnet::Log finished, errors
    expect-eof
    debug   => '--debug',
});

# perl warn command
Mnet::T::test_perl({
    name    => 'perl warn command',
    perl    => "$perl; warn 'warn command';",
    filter  => "sed 's/at .* line .*/at .../' | grep -v ANON",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        ERR - main perl warn, warn command at ...
        err - main perl warn,  at ...
        err - main perl warn, $? = 0
        --- - Mnet::Log finished, errors
    expect-eof
    debug   => '--debug',
});

# perl die command
Mnet::T::test_perl({
    name    => 'perl die command',
    perl    => "$perl; die 'die command';",
    filter  => "sed 's/at .* line .*/at .../' | grep -v ANON",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        ERR - main perl die, die command at ...
        err - main perl die,  at ...
        err - main perl die, $? = 0
        --- - Mnet::Log finished, errors
    expect-eof
    debug   => '--debug',
});

# eval with perl warn
Mnet::T::test_perl({
    name    => 'eval with perl warn',
    perl    => "$perl; eval { warn 'eval warn'; my \$x = 1 + undef; }",
    filter  => "sed 's/at .* line .*/at .../' | grep -v ANON | grep -v called",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        ERR - main perl warn, eval warn at ...
        err - main perl warn,  at ...
        err - main perl warn, $? = 0
        ERR - main perl warn, Use of uninitialized value in addition (+) at ...
        --- - Mnet::Log finished, errors
    expect-eof
    debug   => '--debug',
});

# eval with perl sig warn handler
Mnet::T::test_perl({
    name    => 'eval with perl sig warn handler',
    perl    => "$perl; eval{ local \$SIG{__WARN__} = sub{}; warn 'eval warn' }",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# eval with perl die
Mnet::T::test_perl({
    name    => 'eval with perl die',
    perl    => "$perl; eval { die 'eval die' }; INFO(\$@)",
    filter  => "sed 's/at .* line .*/at .../'",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - main eval die at ...
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# eval with fatal function call
Mnet::T::test_perl({
    name    => 'eval with fatal function call',
    perl    => "$perl; eval{ FATAL('eval fatal');warn 'eval warn' }; INFO(\$@)",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - main eval fatal
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# eval with fatal method call
Mnet::T::test_perl({
    name    => 'eval with fatal method call',
    perl    => "$perl; eval{ Mnet::Log->new->fatal('eval fatal'); }; INFO(\$@)",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - main eval fatal
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# eval with warn call
Mnet::T::test_perl({
    name    => 'eval with fatal method call',
    perl    => "$perl; eval{ WARN('eval warn'); }",
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        WRN - main eval warn
        --- - Mnet::Log finished, errors
    expect-eof
    debug   => '--debug',
});

# finished
exit;

