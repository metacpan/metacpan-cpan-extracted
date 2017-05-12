use inc::Module::Install;

name        'Net-Scan-SSH-Server-SupportedAuth';
all_from    'lib/Net/Scan/SSH/Server/SupportedAuth.pm';

requires 'UNIVERSAL::require'    => 0;
requires 'Net::SSH::Perl'        => '1.30';

build_requires 'Test::More'      => 0;
build_requires 'Test::Base'      => 0;

use_test_base;
auto_install;
WriteAll;

{
    my @mods;
    for my $mod (qw(Math::BigInt::GMP)) {
        eval qq( require $mod );
        push @mods, $mod if $@;
    }
    if (@mods) {
        print '  ','*'x69,"\n";
        print "  * recommend to install following module(s).\n";
        print "  *   - $_\n" for @mods;
        print '  ','*'x69,"\n";
    }
}
