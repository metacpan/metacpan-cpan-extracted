use strict ;
 
BEGIN { print "1..8\n"; };
END {print "not ok 1\n" unless $::loaded;};

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}
 
sub docat
{
    my $file = shift;
    local $/ = undef;
    open(CAT,$file) || die "Cannot open $file:$!";
    my $result = <CAT>;
    close(CAT);
    return $result;
};

umask(0);

use DBMS;


$::loaded = 1;
print "ok 1\n";

my %c;

ok 2, my $db5 = tie %c,"DBMS",'test3',&DBMS::XSMODE_CREAT,0;

#inc() method
eval {
	$c{count}=0;
	for(1..100) { 
		die unless $db5->inc('count'); 
	};
};
ok 3, !$@;

ok 4, ($c{count}==100);

#dec() method
eval {
	for(1..100) { 
		die unless defined $db5->dec('count'); 
	};
};
ok 5, !$@;

ok 6, ($c{count}==0);


# clear
# NOTE: the one on the DBMS server side can not obviously removed
eval {
	%c=()
		if defined $db5 and tied(%c);
};
ok 7, !$@;

eval {
	# NOTE: the one on the DBMS server side can not obviously removed
	%c=()
		if defined $db5 and tied(%c);
	undef $db5;
	die unless untie %c;
};
ok 8, !$@;
