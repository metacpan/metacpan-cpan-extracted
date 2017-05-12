#-*-perl-*-

use strict;
use Net::Bind::Resolv;

print "1..47\n";

my $good1 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/255.0.0.0\noptions debug\n";
my $good2 = "search arf.fz fz\nnameserver 1.2.3.4\n";
my $bad1 = "domain arf-.fz\nnameserver 1000.2.3.4\nsortlist 1.0.0.0/255..0.0\noptions debug ndots:1\n";
my $bad2 = "search arf.fz -arf.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/255.0.0.0\noptions arf\n";
my $bad3 = "domain thisistoolongforbindbecauseonesectionisoversixtythreecharecterslong.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/255.0.0.0\noptions debug ndots:1\n";
my $bad4 = "domain arf.fz\nnameserver a.2.3.4\nsortlist 1.0.0.0/255.0.0.0\noptions debug ndots:1\n";
my $bad5 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist 1..0.0/255.0.0.0\noptions debug ndots:1\n";
my $bad6 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/255..0.0\noptions debug ndots:1\n";
my $bad7 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/255.a.0.0\noptions debug ndots:1\n";
my $bad8 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/2550.0.0.0\noptions debug ndots:1\n";
my $bad9 = "domain arf.fz\nnameserver 1.2.3.4\nsortlist 1.0.0.0/2550.0.0.0\noptions debug ndots:a\n";

my $resolver;
okay_if(1, $resolver = new Net::Bind::Resolv '');

okay_if(2, $resolver->read_from_string($good1));
okay_if(3, $resolver->default_policy_check);

okay_if(4, $resolver->clear);
okay_if(5, $resolver->read_from_string($good2));
okay_if(6, $resolver->default_policy_check);

okay_if(7, $resolver->clear);
okay_if(8, $resolver->read_from_string($bad1));
okay_if(9, !$resolver->check_domain);
okay_if(10, !$resolver->check_searchlist);
okay_if(11, !$resolver->check_nameservers);
okay_if(12, !$resolver->check_sortlist);
okay_if(13, $resolver->check_options);

okay_if(14, $resolver->clear);
okay_if(15, $resolver->read_from_string($bad2));
okay_if(16, !$resolver->check_searchlist);
okay_if(17, !$resolver->check_domain);
okay_if(18, $resolver->check_nameservers);
okay_if(19, $resolver->check_sortlist);
okay_if(20, !$resolver->check_options);

okay_if(21, $resolver->clear);
okay_if(22, $resolver->read_from_string($bad3));
okay_if(23, !$resolver->default_policy_check);

okay_if(24, $resolver->clear);
okay_if(25, $resolver->read_from_string($bad4));
okay_if(26, !$resolver->default_policy_check);

okay_if(27, $resolver->clear);
okay_if(28, $resolver->read_from_string($bad5));
okay_if(29, !$resolver->default_policy_check);

okay_if(30, $resolver->clear);
okay_if(31, $resolver->read_from_string($bad6));
okay_if(32, !$resolver->default_policy_check);

okay_if(33, $resolver->clear);
okay_if(34, $resolver->read_from_string($bad7));
okay_if(35, !$resolver->default_policy_check);

okay_if(36, $resolver->clear);
okay_if(37, $resolver->read_from_string($bad8));
okay_if(38, !$resolver->default_policy_check);

okay_if(39, $resolver->clear);
okay_if(40, $resolver->read_from_string($bad9));
okay_if(41, !$resolver->default_policy_check);
okay_if(42, !$resolver->check);

okay_if(43, $resolver->clear);
okay_if(44, $resolver->read_from_string($good1));
okay_if(45, $resolver->check);

my $check = sub { return 1 };
okay_if(46, $resolver->check($check));
$check = sub { return 0 };
okay_if(47, !$resolver->check($check));

sub okay_if {
  print 'not ' unless ($_[1]);
  print "ok $_[0]\n";
}
