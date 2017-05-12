use strict;
use Test;
BEGIN { plan tests => 24 }
use NetworkInfo::Discovery::Nmap;

my $obj = undef;
my $net1 = '192.168.1.0/24';
my @net2 = qw(192.168.2.0/24 192.168.3.0/24);
my $net3 = '192.168.4.0/24';
my @net4 = qw(192.168.5.0/24 192.168.6.0/24);
my @net5 = qw(192.168.6.0/24 192.168.7.0/24);

# create an object and pass it a scalar argument
$obj = new NetworkInfo::Discovery::Nmap hosts => $net1;
ok( defined $obj                                        );  #01
ok( defined $obj->{_hosts_to_scan}                      );  #02
ok( ref $obj->{_hosts_to_scan}, 'ARRAY'                 );  #03
ok( scalar @{ $obj->{_hosts_to_scan} }, 1               );  #04
ok( ${ $obj->{_hosts_to_scan} }[0], $net1               );  #05

undef $obj;
ok( $obj, undef                                         );  #06

# create an object and pass it an arrayref argument
$obj = new NetworkInfo::Discovery::Nmap hosts => [ @net2 ];
ok( defined $obj                                        );  #07
ok( defined $obj->{_hosts_to_scan}                      );  #08
ok( ref $obj->{_hosts_to_scan}, 'ARRAY'                 );  #09
ok( scalar @{ $obj->{_hosts_to_scan} }, 2               );  #10
ok( ${ $obj->{_hosts_to_scan} }[0], $net2[0]            );  #11
ok( ${ $obj->{_hosts_to_scan} }[1], $net2[1]            );  #12

# adding a list of values
$obj->hosts($net3, @net4);
ok( scalar @{ $obj->{_hosts_to_scan} }, 5               );  #13
ok( ${ $obj->{_hosts_to_scan} }[2], $net3               );  #14
ok( ${ $obj->{_hosts_to_scan} }[3], $net4[0]            );  #15
ok( ${ $obj->{_hosts_to_scan} }[4], $net4[1]            );  #16

# adding an arrayref
$obj->hosts([ @net5 ]);
ok( scalar @{ $obj->{_hosts_to_scan} }, 7               );  #17
ok( ${ $obj->{_hosts_to_scan} }[5], $net5[0]            );  #18
ok( ${ $obj->{_hosts_to_scan} }[6], $net5[1]            );  #19

undef $obj;
ok( $obj, undef                                         );  #20

# checking error catching
$obj = new NetworkInfo::Discovery::Nmap;
eval { $obj->hosts(\$net1) };
ok( $@ =~ /Don't know how to deal with a scalarref./    );  #21
eval { $obj->hosts({}) };
ok( $@ =~ /Don't know how to deal with a hashref./      );  #22
eval { $obj->hosts(sub{}) };
ok( $@ =~ /Don't know how to deal with a coderef./      );  #23
eval { $obj->hosts(\*STDIN) };
ok( $@ =~ /Don't know how to deal with a globref./      );  #24
