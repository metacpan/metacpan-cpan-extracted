use inc::Module::Install;

RTx('RT-CIFMinimal');
license('GPL Version 2');
author('Barely3am Solutions <wes@barely3am.com>');
version_from('lib/RT/CIFMinimal.pm');

{ # check RT version
    my @v = split /\./, "$RT::VERSION";
    unless ($v[0]>=3 && $v[1]>=8 && ($v[2]>=1 || $v[2]eq'HEAD')) {
        die "RT-CIFMinimal and newer needs RT 3.8.10 at least, you have $RT::VERSION";
    }
}

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

requires('Regexp::Common'               => '2.122');
requires('Regexp::Common::net::CIDR'    => '0.02');
requires('Net::Abuse::Utils'            => '0.10');
requires('JSON'                         => '2.07');
requires('XML::IODEF::Simple'           => '0.00');
requires('CIF::Client'                  => '0.01');
requires('Net::CIDR'                    => '0.11');
requires('HTML::Table'                  => '2.08');
auto_install();

tests("t/*.t t/*/*.t");

WriteAll();
