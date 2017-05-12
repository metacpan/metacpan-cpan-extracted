use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

my $opts = { also_private => [ qr/^[SU]_/, qr/^PCI_/, qr/^(sl_|plugin_)/, qr/^(commasep|noargs|oneandtwoopt|onlyonearg|onlytwoargs|privandnotice|sl|spacesep|oneortwo|oneoptarg)$/,], };

my @modules = grep { $_ ne 'POE::Component::IRC::Test::Harness' } all_modules();

plan tests => scalar @modules;

pod_coverage_ok( $_, $opts ) for @modules;
