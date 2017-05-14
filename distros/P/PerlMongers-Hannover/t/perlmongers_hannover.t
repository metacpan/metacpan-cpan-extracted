use strict;
use warnings;
use autodie;

use Test::More tests => 3;

use Capture::Tiny qw(capture_stdout);

require_ok('PerlMongers::Hannover');

{
    # add "lib" to Perl's path, so perldoc will see it in "plain" perl tests
    # i.e. tests run directly from perl, not via prove etc.
    $ENV{"PERL5LIB"} = $ENV{"PERL5LIB"} ? $ENV{"PERL5LIB"} . ":lib" : "lib";
    use PerlMongers::Hannover qw(info);
    my $stdout = capture_stdout { info() };

    ok(length $stdout > 0, "info() generates output");
    like($stdout, qr/Hannover Perl Mongers/, "Perl mongers name in output");
}

# vim: expandtab shiftwidth=4 softtabstop=4
