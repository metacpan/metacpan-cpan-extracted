use strict;
use Test;
BEGIN { plan tests => 24 }
use NetworkInfo::Discovery::Nmap;

my $obj = undef;
my $port1 = '8080';
my @port2 = qw(1-25 26-50);
my $port3 = '8668';
my @port4 = qw(137-139 201-208);
my @port5 = qw(6000-6063 6666-6669);

# create an object and pass it a scalar argument
$obj = new NetworkInfo::Discovery::Nmap ports => $port1;
ok( defined $obj                                        );  #01
ok( defined $obj->{_ports_to_scan}                      );  #02
ok( ref $obj->{_ports_to_scan}, 'ARRAY'                 );  #03
ok( scalar @{ $obj->{_ports_to_scan} }, 1               );  #04
ok( ${ $obj->{_ports_to_scan} }[0], $port1              );  #05

undef $obj;
ok( $obj, undef                                         );  #06

# create an object and pass it an arrayref argument
$obj = new NetworkInfo::Discovery::Nmap ports => [ @port2 ];
ok( defined $obj                                        );  #07
ok( defined $obj->{_ports_to_scan}                      );  #08
ok( ref $obj->{_ports_to_scan}, 'ARRAY'                 );  #09
ok( scalar @{ $obj->{_ports_to_scan} }, 2               );  #10
ok( ${ $obj->{_ports_to_scan} }[0], $port2[0]           );  #11
ok( ${ $obj->{_ports_to_scan} }[1], $port2[1]           );  #12

# adding a list of values
$obj->ports($port3, @port4);
ok( scalar @{ $obj->{_ports_to_scan} }, 5               );  #13
ok( ${ $obj->{_ports_to_scan} }[2], $port3              );  #14
ok( ${ $obj->{_ports_to_scan} }[3], $port4[0]           );  #15
ok( ${ $obj->{_ports_to_scan} }[4], $port4[1]           );  #16

# adding an arrayref
$obj->ports([ @port5 ]);
ok( scalar @{ $obj->{_ports_to_scan} }, 7               );  #17
ok( ${ $obj->{_ports_to_scan} }[5], $port5[0]           );  #18
ok( ${ $obj->{_ports_to_scan} }[6], $port5[1]           );  #19

undef $obj;
ok( $obj, undef                                         );  #20

# checking error catching
$obj = new NetworkInfo::Discovery::Nmap;
eval { $obj->ports(\$port1) };
ok( $@ =~ /Don't know how to deal with a scalarref./    );  #21
eval { $obj->ports({}) };
ok( $@ =~ /Don't know how to deal with a hashref./      );  #22
eval { $obj->ports(sub{}) };
ok( $@ =~ /Don't know how to deal with a coderef./      );  #23
eval { $obj->ports(\*STDIN) };
ok( $@ =~ /Don't know how to deal with a globref./      );  #24
