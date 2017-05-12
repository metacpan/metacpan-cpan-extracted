#-*-perl-*-

use strict;
use Net::Bind::Resolv;

print "1..42\n";

my $data1 = "domain arf.fz\nnameserver 1.2.3.4\nnameserver 4.3.2.1\n";
my $data2 = "search arf.fz fz\nnameserver 1.2.3.4\nnameserver 4.3.2.1\n";
my $data3 = "search arf.fz fz\ndomain arf.fz\nnameserver 1.2.3.4\nnameserver 4.3.2.1\n";

my $resolver;
$resolver = new Net::Bind::Resolv('arf');
okay_if(1, !defined($resolver));
okay_if(2, $resolver = new Net::Bind::Resolv '');
okay_if(3, $resolver->read_from_string($data1));
okay_if(4, $resolver->domain eq 'arf.fz');
okay_if(5, $resolver->qtynameservers == 2);

my @nameservers;
my $nameservers;
okay_if(6, @nameservers = $resolver->nameservers);
okay_if(7, $#nameservers == 1);
okay_if(8, $nameservers[0] eq '1.2.3.4');
okay_if(9, $nameservers[1] eq '4.3.2.1');
okay_if(10, $nameservers = $resolver->nameservers);
okay_if(11, $#{$nameservers} == 1);
okay_if(12, $nameservers[0] eq '1.2.3.4');
okay_if(13, $nameservers[1] eq '4.3.2.1');
okay_if(14, defined($resolver->as_string));
okay_if(15, $resolver->as_string eq $data1);
okay_if(16, !$resolver->searchlist);

okay_if(17, $resolver->clear);
okay_if(18, !defined($resolver->as_string));
okay_if(19, $resolver->domain('arf.fz'));
okay_if(20, $resolver->nameservers('1.2.3.4', '4.3.2.1'));
okay_if(21, defined($resolver->as_string));
okay_if(22, $resolver->as_string eq $data1);

okay_if(23, $resolver->clear);
okay_if(24, $resolver->read_from_string($data2));
okay_if(25, !defined($resolver->domain));

my @search;
my $search;
okay_if(26, @search = $resolver->searchlist);
okay_if(27, $#search == 1);
okay_if(28, $search[0] eq 'arf.fz');
okay_if(29, $search[1] eq 'fz');
okay_if(30, $search = $resolver->searchlist);
okay_if(31, $#{$search} == 1);
okay_if(32, $search->[0] eq 'arf.fz');
okay_if(33, $search->[1] eq 'fz');
okay_if(34, @nameservers = $resolver->nameservers);
okay_if(35, $nameservers[0] eq '1.2.3.4');
okay_if(36, $nameservers[1] eq '4.3.2.1');
okay_if(37, $resolver->as_string eq $data2);

okay_if(38, $resolver->clear);
okay_if(39, $resolver->read_from_string($data3));
okay_if(40, defined($resolver->domain));
okay_if(41, !defined($resolver->searchlist));
okay_if(42, $resolver->domain eq 'arf.fz');

sub okay_if {
  print 'not ' unless ($_[1]);
  print "ok $_[0]\n";
}
