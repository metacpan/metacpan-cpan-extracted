#!/usr/bin/perl
#
# stats2list.pl 
# version 1.00, 1-6-08
#
die "missing directory\n"
	unless @ARGV &&
		-d $ARGV[0] &&
		opendir(D,$ARGV[0]);
my @files = sort {$b cmp $a} grep {!/^\./ && !/~$/} readdir(D);
closedir D;
my $dir = shift;
$dir .= '/' unless $dir =~ m|/$|;
(my $realdir = $dir) =~ s|public[^/]*/||;
print q|<ul>
|;
foreach(@files) {
  my $name = ($_ =~ /\./) ? $` : $_;
  print qq|<li><a href="${realdir}$_">$name</a>\n|;
}
print q|</ul>
|;

