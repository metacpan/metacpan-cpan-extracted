use inc::Module::Install;

RTx('RT-Extension-LDAPImport');
license('perl');

requires('Test::More');
requires('Net::LDAP');
requires('Class::Accessor');

author_tests('xt');
feature "Proper Testing" =>
    -default => 0,
    recommends('Net::LDAP::Server::Test')
    ;

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );

# Straight from perldoc perlvar
use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

substitute(
    {
        RT_LIB_PATH  => $lib_path,
        PERL         => $ENV{PERL} || $secure_perl_path,
    },
    {
        sufix => '.in'
    },
    qw(bin/rtldapimport),
);
substitute(
    {
        RT_LIB_PATH  => $lib_path,
    },
    {
        sufix => '.in'
    },
    q(xt/lib/RT/Extension/LDAPImport/Test.pm),
);

sign;
&auto_install();
&WriteAll;
