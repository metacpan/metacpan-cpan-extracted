use strict;
use warnings;
use Module::Build;

sub has_module {
    my $module = @_;
    my $moduleFile = $module . ".pm";
    $moduleFile =~ s/::/\//g;
    eval { require $moduleFile; };
    return !$@;
}

my %requires = (
    'Test::More'            => 0,
    'LWP'                   => 6,
    'LWP::Protocol::https'  => 6,
    'Net::SSLeay'           => 1.33,
    'Mozilla::CA'           => 0,
    'MIME::Base64'          => 0,
    'Digest::HMAC_SHA1'     => 0,
    'URI::Escape'           => 0,
    'perl'                  => '5.6.0'
);

my %recommends = (
    'IO::String'  => 0 
);

if (has_module('XML::Parser::Lite') and !has_module('XML::Parser')) {
    $recommends{'XML::Parser'} = 0;
}
else {
    $requires{'XML::Parser'} = 0;
}

my $builder = Module::Build->new(
    module_name         => 'Net::Amazon::MechanicalTurk',
    license             => 'open_source',
    dist_version_from   => 'lib/Net/Amazon/MechanicalTurk.pm',
    build_requires      => \%requires, 
    recommends          => \%recommends, 
    add_to_cleanup      => [ 'Net-Amazon-MechanicalTurk-*' ],
);

$builder->create_build_script();
