#
# sources/patch.pl
#
# $Author: grazz $
# $Date: 2003/07/12 12:20:22 $
#

use Config;
my $v = $Config{version};

for my $file (qw(regcomp regexec)) {
    local (*ARGV, *STDOUT);
    my ($need) = @ARGV = "./sources/$file-$v.c";

    unless (-f $need) {
	(my $msg = <<"	end") =~ s/^\s+//g;
	    ===> Whoops! <===
	    I can't make Regexp::Fields without $need.
	    If you have a source distribution for perl-$v, just
	    copy $file.c to the sources directory and rename it.
	end
	die $msg;
    }

    open STDOUT, "> rx_$file.c"
        or die "open: rx_$file.c: $!";

    warn "Patching a local $file.c for perl-$v.\n";
    require "./sources/patch-$file.pl";
    print while <>;
    close STDOUT;
}

sub patch {
    my ($txt, $when, $rx) = splice @_, 0, 3;

    if ($when eq 'before') {
	while (<>) { 
	    if (/$rx/) { print $txt, $_; return; }
	    print;
	}
	die "[$0] error: fell off the end of the file";
    }
    if ($when eq 'after') {
	while (<>) { print; last if /$rx/ }

	if (defined(my $count = shift)) {
	    while ($count--) { print scalar <> }
	}
	else {
	    while (<>) { print; last if /^$/ }
	}

	print $txt;
	return;
    }
}

1;
