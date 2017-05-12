#-*-perl-*-

use strict;
use Net::Bind::Resolv;

print "1..11\n";

my $data1 = "; a comment line\n; another one\ndomain arf.fz\nnameserver 1.2.3.4\nnameserver 4.3.2.1\n";
my $data2 = "domain arf.fz\nnameserver 1.2.3.4\nnameserver 4.3.2.1\n";

my $resolver;

okay_if(1, $resolver = new Net::Bind::Resolv '');
okay_if(2, $resolver->read_from_string($data1));
okay_if(3, $resolver->as_string eq $data2);

my $add1 = ("a comment line\nanother one");
okay_if(4, $resolver->comments($add1));
$add1 = "; $add1";
$add1 =~ s/\n/\n; /g;
okay_if(5, $resolver->as_string eq "$add1\n$data2");

$add1 = "a comment line";
my $add2 = "another one";
okay_if(6, $resolver->comments($add1, $add2));
$add1 = "; $add1\n$add2";
$add1 =~ s/\n/\n; /g;
okay_if(7, $resolver->as_string eq "$add1\n$data2");

$add1 = [("a comment line\nanother one")];
okay_if(8, $resolver->comments($add1));
$add1 = $add1->[0];
$add1 = "; $add1";
$add1 =~ s/\n/\n; /g;
okay_if(9, $resolver->as_string eq "$add1\n$data2");

$add1 = "a comment line";
$add2 = "another one";
okay_if(10, $resolver->comments([$add1, $add2]));
$add1 = "; $add1\n$add2";
$add1 =~ s/\n/\n; /g;
okay_if(11, $resolver->as_string eq "$add1\n$data2");

sub okay_if {
  print 'not ' unless ($_[1]);
  print "ok $_[0]\n";
}
