use strict;
use warnings;
use Config qw(%Config);
use PPM::Repositories qw(get list used_archs);

my $archname = shift || $Config{archname};
for my $version (qw(5.6 5.8 5.10 5.12 5.14 5.16 5.18 5.20)) {
    my $arch = $archname;
    $arch .= "-$version" unless $version eq "5.6";
    print "Perl $arch\n";
    for my $name (list($arch)) {
	my %repo = get($name, $arch);
	for my $url (qw(packlist packlist_noarch)) {
	    next unless $repo{$url};
	    printf("  %-12s %-30s %s\n", $name, $repo{desc}, $repo{$url});
	}
    }
    print "\n";
}

print "\nused_arch\n";
print "  $_\n" for used_archs();

print "\nlog4perl\n";
my %log4perl = get("log4perl");
for (sort keys %log4perl) {
    printf "  %-12s %s\n", $_, $log4perl{$_};
}
