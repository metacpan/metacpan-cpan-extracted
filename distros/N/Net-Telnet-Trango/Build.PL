use strict;
use warnings;
use Module::Build;
use File::Spec;

# $RedRiver: Build.PL,v 1.9 2009/07/08 17:36:55 andrew Exp $

my $cfg_file = File::Spec->catfile( 't', 'tests.cfg' );

my $builder = Module::Build->new(
    module_name       => 'Net::Telnet::Trango',
    license           => 'perl',
    dist_author       => 'Andrew Fresh <andrew@cpan.org>',
    dist_version_from => 'lib/Net/Telnet/Trango.pm',
    requires          => {
        'perl'        => '5.6.1',
        'Net::Telnet' => '0',
    },
    build_requires => {
        'Test::More'  => '0',
    },
    add_to_cleanup     => [ 'Net-Telnet-Trango-*', $cfg_file ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    create_html        => 1,
    dynamic_config     => 1,
    auto_features      => {
        YAML_support => {
            description => "Use YAML.pm to write META.yml files",
            requires    => { YAML => ' >= 0.35, != 0.49_01 ' },
        },
        manpage_support => {
            description => "Create Unix man pages",
            requires    => { 'Pod::Man' => 0 },
        },
        HTML_support => {
            description => "Create HTML documentation",
            requires    => { 'Pod::Html' => 0 },
        },
    },
);

get_config();

$builder->create_build_script();

sub get_config {
    my %cfg;
    print <<EOB;

Net::Telnet::Trango needs some additional information and setup to
perform it\'s full suite of tests. 

These tests MAY change settings on the units it connects to, so please
do not use equipment that is in production.

To skip these tests, hit "return".

EOB

    get_ap_config( \%cfg );

    get_sudb_config( \%cfg ) if $cfg{AP} && $cfg{AP_PASSWD};

    get_su_config( \%cfg );

    if ( open T, ">$cfg_file" ) {
        while ( my ( $key, $value ) = each %cfg ) {
            print T $key, "\t", $value, "\n";
        }
        close T;
    }

}

sub get_ap_config {
    my $cfg = shift;

    print 'To run the AP tests, we need an IP and a password of an AP.', "\n";

    $cfg->{AP} = $builder->prompt( "AP IP: ", $cfg->{AP} ) || return;
    $cfg->{AP_PASSWD} = $builder->prompt( "AP Password:", $cfg->{AP_PASSWD} )
        || return;
}

sub get_sudb_config {
    my $cfg = shift;

    print <<EOL;
To run the SUDB tests, we need an suid and mac address of an 
SU that can reliably link to the AP.
EOL

    $cfg->{SU_ID}  = $builder->prompt( "SU ID: ", $cfg->{SU_ID} )  || return;
    $cfg->{SU_MAC} = $builder->prompt( "SU MAC:", $cfg->{SU_MAC} ) || return;
}

sub get_su_config {
    my $cfg = shift;

    print 'To run the SU tests, we need an IP and a password of an SU.', "\n";

    $cfg->{SU} = $builder->prompt( "SU IP: ", $cfg->{SU} ) || return;
    $cfg->{SU_PASSWD} = $builder->prompt( "SU Password:", $cfg->{SU_PASSWD} )
        || return;
}

