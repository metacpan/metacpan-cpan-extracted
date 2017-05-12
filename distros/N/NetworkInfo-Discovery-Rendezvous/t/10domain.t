use strict;
use Test;
BEGIN { plan tests => 24 }
use NetworkInfo::Discovery::Rendezvous;

my $obj = undef;
my $dom1 = 'local';
my @dom2 = qw(example.com example.net);
my $dom3 = 'mycompany.com';
my @dom4 = qw(here.net there.net);
my @dom5 = qw(thisway.org thatway.org);

# create an object and pass it a scalar argument
$obj = new NetworkInfo::Discovery::Rendezvous domain => $dom1;
ok( defined $obj                                        );  #01
ok( defined $obj->{_domains_to_scan}                    );  #02
ok( ref $obj->{_domains_to_scan}, 'ARRAY'               );  #03
ok( scalar @{ $obj->{_domains_to_scan} }, 1             );  #04
ok( ${ $obj->{_domains_to_scan} }[0], $dom1             );  #05

undef $obj;
ok( $obj, undef                                         );  #06

# create an object and pass it an arrayref argument
$obj = new NetworkInfo::Discovery::Rendezvous domain => [ @dom2 ];
ok( defined $obj                                        );  #07
ok( defined $obj->{_domains_to_scan}                    );  #08
ok( ref $obj->{_domains_to_scan}, 'ARRAY'               );  #09
ok( scalar @{ $obj->{_domains_to_scan} }, 2             );  #10
ok( ${ $obj->{_domains_to_scan} }[0], $dom2[0]          );  #11
ok( ${ $obj->{_domains_to_scan} }[1], $dom2[1]          );  #12

# adding a list of values
$obj->domain($dom3, @dom4);
ok( scalar @{ $obj->{_domains_to_scan} }, 5             );  #13
ok( ${ $obj->{_domains_to_scan} }[2], $dom3             );  #14
ok( ${ $obj->{_domains_to_scan} }[3], $dom4[0]          );  #15
ok( ${ $obj->{_domains_to_scan} }[4], $dom4[1]          );  #16

# adding an arrayref
$obj->domain([ @dom5 ]);
ok( scalar @{ $obj->{_domains_to_scan} }, 7             );  #17
ok( ${ $obj->{_domains_to_scan} }[5], $dom5[0]          );  #18
ok( ${ $obj->{_domains_to_scan} }[6], $dom5[1]          );  #19

undef $obj;
ok( $obj, undef                                         );  #20

# checking error catching
$obj = new NetworkInfo::Discovery::Rendezvous;
eval { $obj->domain(\$dom1) };
ok( $@ =~ /Don't know how to deal with a scalarref./    );  #21
eval { $obj->domain({}) };
ok( $@ =~ /Don't know how to deal with a hashref./      );  #22
eval { $obj->domain(sub{}) };
ok( $@ =~ /Don't know how to deal with a coderef./      );  #23
eval { $obj->domain(\*STDIN) };
ok( $@ =~ /Don't know how to deal with a globref./      );  #24
