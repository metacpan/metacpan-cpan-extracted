package t::lib::Utils;
# ABSTRACT: Utilities to help testing multiple systems

use strict;
use warnings;
use vars qw( @ISA @EXPORT_OK );

use Carp;
use Exporter;
use File::Spec;
use Sys::HostIP qw/ip ips ifconfig interfaces/;
use Test::More;

@ISA       = qw(Exporter);
@EXPORT_OK = qw( mock_run_ipconfig mock_win32_hostip base_tests );

sub mock_win32_hostip {
    my $file = shift;

    {
        no warnings qw/redefine once/;
        *Sys::HostIP::_run_ipconfig = sub {
            ok( 1, 'Windows was called' );
            return mock_run_ipconfig($file);
        };
    }

    my $hostip = Sys::HostIP->new;

    return $hostip;
}

sub mock_run_ipconfig {
    my $filename = shift;
    my $file     = File::Spec->catfile( 't', 'data', $filename );

    open my $fh, '<', $file or die "Error opening $file: $!\n";
    my @output = <$fh>;
    close $fh or die "Error closing $file: $!\n";

    return @output;
}

sub base_tests {
    my $hostip = shift;

    # -- ip() --
    my $sub_ip   = ip();
    my $class_ip = $hostip->ip;

    diag("Class IP: $class_ip");
    like( $class_ip, qr/^ \d+ (?: \. \d+ ){3} $/x, 'IP by class looks ok' );
    is( $class_ip, $sub_ip, 'IP by class matches IP by sub' );

    # -- ips() --
    my $sub_ips   = ips();
    my $class_ips = $hostip->ips;
    isa_ok( $class_ips, 'ARRAY', 'scalar context ips() gets arrayref' );
    ok( 1 == grep( /^$class_ip$/, @{$class_ips} ), 'Found IP in IPs by class' );
    is( scalar @{$class_ips}, scalar @{$sub_ips},
        'Length of class and sub ips() output is equal' );
    is_deeply( [sort @{$class_ips}], [sort @{$sub_ips}],
        'IPs by class match IPs by sub' );

    # -- interfaces() --
    my $sub_interfaces = interfaces();
    my $interfaces = $hostip->interfaces;
    isa_ok( $interfaces, 'HASH', 'scalar context interfaces() gets hashref' );
    cmp_ok(
        scalar keys ( %{$interfaces} ),
        '==',
        scalar @{$class_ips},
        'Matching number of interfaces and ips',
    );
    is_deeply($interfaces, $sub_interfaces,
        'interfaces() output by class and sub are equal');

    # -- if_info() --
    my $if_info = $hostip->if_info;
    isa_ok( $if_info, 'HASH', 'scalar context if_info() gets hashref' );
    my $if_info_hostip = Sys::HostIP->new(if_info => { 'if_name' => '1.2.3.4' });
    is_deeply( $if_info_hostip->if_info, { 'if_name' => '1.2.3.4' },
        'if_info set as attribute' );
}

1;
