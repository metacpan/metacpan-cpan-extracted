#-*-perl-*-

use strict;
use Net::Bind::Resolv;

print "1..24\n";

my $data1 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist greeble sfortznu\noptions debug ndots:1\n";
my $data2 = "search arf.fz fz\nnameserver 1.2.3.4\nnameserver 4.3.2.1\n";

my $resolver;

okay_if(1, $resolver = new Net::Bind::Resolv '');
okay_if(2, $resolver->read_from_string($data1));
okay_if(3, $resolver->domain eq 'arf.fz');
my @sortlist;
my $sortlist;
okay_if(4, @sortlist = $resolver->sortlist);
okay_if(5, $#sortlist == 1);
okay_if(6, $sortlist[0] eq 'greeble');
okay_if(7, $sortlist[1] eq 'sfortznu');
okay_if(8, $sortlist = $resolver->sortlist);
okay_if(9, $#{$sortlist} == 1);
okay_if(10, $sortlist->[0] eq 'greeble');
okay_if(11, $sortlist->[1] eq 'sfortznu');
my @options;
my $options;
okay_if(12, @options = $resolver->options);
okay_if(13, $#options == 1);
okay_if(14, $options[0] eq 'debug');
okay_if(15, $options[1] eq 'ndots:1');
okay_if(16, $options = $resolver->options);
okay_if(17, $#{$options} == 1);
okay_if(18, $options->[0] eq 'debug');
okay_if(19, $options->[1] eq 'ndots:1');
okay_if(20, $#{$options} == 1);
okay_if(21, $resolver->as_string eq $data1);
okay_if(22, $resolver->clear);
okay_if(23, $resolver->read_from_string($data2));
okay_if(24, !defined($resolver->domain));

sub okay_if {
  print 'not ' unless ($_[1]);
  print "ok $_[0]\n";
}
