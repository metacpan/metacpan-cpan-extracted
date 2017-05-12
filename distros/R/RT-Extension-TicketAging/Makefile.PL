use inc::Module::Install;

RTx ('RT-Extension-TicketAging');
license('perl');
all_from('lib/RT/Extension/TicketAging.pm');

{ # check RT version
    my @v = split /\./, "$RT::VERSION";
    unless (($v[0]>=3 && $v[1]>=7) || $v[0]>3) {
        die "Extension needs RT 3.7.0 at least, you have $RT::VERSION";
    }
}

requires('Hook::LexWrap');
requires('File::Temp');

build_requires('Test::More' => 0.62);  # for simple code ref comparison
auto_install();

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
my $sbin_path = $RT::SbinPath || "$RT::BasePath/sbin" || "/opt/rt3/sbin";
my $bin_path = $RT::BinPath || "$RT::BasePath/bin" || "/opt/rt3/bin";

substitute(
    {
        RT_LIB_PATH  => $lib_path,
        RT_BIN_PATH  => $bin_path,
        RT_SBIN_PATH => $sbin_path,
    },
    qw(t/utils.pl sbin/rt-aging),
);

WriteAll();
