use strict;
use warnings;
use Test::More tests => 24;
use Net::Telnet::Gearman::Worker;

my @tests = (
    {
        line     => '1234 192.168.0.1 - : ',
        expected => {
            'functions'       => [],
            'client_id'       => '-',
            'file_descriptor' => '1234',
            'ip_address'      => '192.168.0.1'
        }
    },
    {
        line     => '5678 10.0.0.1 - : job',
        expected => {
            'functions'       => [qw(job)],
            'client_id'       => '-',
            'file_descriptor' => '5678',
            'ip_address'      => '10.0.0.1'
        }
    },
    {
        line     => '1111 10.0.2.1 - : job1 job2 job3',
        expected => {
            'functions'       => [qw(job1 job2 job3)],
            'client_id'       => '-',
            'file_descriptor' => '1111',
            'ip_address'      => '10.0.2.1'
        }
    },
    {
        line     => '2222 10.0.3.1 - : some:job other::job foo-job',
        expected => {
            'functions'       => [qw(some:job other::job foo-job)],
            'client_id'       => '-',
            'file_descriptor' => '2222',
            'ip_address'      => '10.0.3.1'
        }
    },
    {
        line     => '12 ::1c00:0:ec14:9900%149960024 - :',
        expected => {
            'functions'       => [],
            'client_id'       => '-',
            'file_descriptor' => '12',
            'ip_address'      => '::1c00:0:ec14:9900%149960024'
        }
    },
    {
        line     => '11 ::1c00:0:ec14:9900%149960024 - : reverse list:3418 dereg:3418',
        expected => {
            'functions'       => [qw(reverse list:3418 dereg:3418)],
            'client_id'       => '-',
            'file_descriptor' => '11',
            'ip_address'      => '::1c00:0:ec14:9900%149960024'
        }
    },
);

foreach my $test (@tests) {
    my $w = Net::Telnet::Gearman::Worker->parse_line( $test->{line} );
    foreach my $attr ( keys %{ $test->{expected} } ) {
        if ( $attr eq 'functions' ) {
            is_deeply( $w->$attr, $test->{expected}{$attr} );
        }
        else {
            is( $w->$attr, $test->{expected}{$attr} );
        }
    }
}
