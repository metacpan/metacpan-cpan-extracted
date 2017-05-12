use strict;
use Test::More;
use Module::ThirdParty;

plan tests => 25;

# checking with a few known 3rd party module
for my $module (qw(SVN::Core CAIDA::NetGeoClient Perl::API SWISH::API)) {
    ok( is_3rd_party($module) , "$module is a known third-party module" );
}

# checking with a few core modules
for my $module (qw(strict Exporter Symbol IPC::Open3)) {
    ok( ! is_3rd_party($module) , "$module isn't a known third-party module (core)" );
}

# checking with a few CPAN modules
for my $module (qw(DBI Net::Pcap PDF::API2 Spreadsheet::WriteExcel XML::LibXML)) {
    ok( ! is_3rd_party($module) , "$module isn't a known third-party module (CPAN)" );
}

# checking with non-existant modules
for my $module (qw(No::Such::Module Realistic::Name::ButNo::Luck)) {
    ok( ! is_3rd_party($module) , "$module isn't a known third-party module (non-existant)" );
}

# getting module information for a known 3rd party module
my $info = undef;
is( $info, undef                                                , "getting module info for Perl::API");
$info = module_information('Perl::API');
ok( defined $info                                               , " - \$info is defined" );
is( ref $info, 'HASH'                                           , " - \$info is a HASH ref" );
is( $info->{name}, 'Perl::API'                                  , " - checking name" );
is( $info->{url}, 'http://search.cpan.org/dist/Perl-API/'       , " - checking url" );
is( $info->{author}, 'Gisle Aas'                                , " - checking author" );
is( $info->{author_url}, 'http://gisle.aas.no/'                 , " - checking author_url" );
is_deeply( $info->{modules}, [qw(Perl::API)]                    , " - checking modules" );

# getting module information for a core module
$info = undef;
is( $info, undef                                                , "getting module info for Text::ParseWords");
$info = module_information('Text::ParseWords');
is( $info, undef                                                , " - \$info is undefined" );

