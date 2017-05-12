# -*- perl -*-
#
# $Id: base.t,v 1.2 1999/01/08 19:39:25 joe Exp $
#

print "Base test: Loading the modules.\n";
my @modules = qw(Net::Nessus::Message Net::Nessus::Client);

print "1..", scalar(@modules), "\n";
my $i = 0;
foreach my $module (@modules) {
    eval "require $module";
    ++$i;
    if ($@) {
	print "not ok $i\n";
	print STDERR "$@\n";
    } else {
	print "ok $i\n";
    }
}
