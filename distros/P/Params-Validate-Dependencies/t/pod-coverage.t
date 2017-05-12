# $Id: pod-coverage.t,v 1.3 2007/11/01 17:00:19 drhyde Exp $
use strict;
$^W=1;

eval "use Test::Pod::Coverage 1.00";

if($@) {
    print "1..0 # SKIP Test::Pod::Coverage 1.00 required for testing POD coverage";
} else {
    my @modules = grep { $_ ne 'Params::Validate::Dependencies::Documenter' && $_ !~ /_of/ } all_modules();
    Test::Builder->new()->plan(tests => scalar @modules);
    pod_coverage_ok(
        $_,
        $_ eq 'Data::Domain::Dependencies' ? { also_private => [qw(inspect)] } : ()
    ) foreach(@modules);
}
