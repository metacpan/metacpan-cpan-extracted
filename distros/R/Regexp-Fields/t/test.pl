#
# re/names/t/test.pl
#
# $Author: grazz $
# $Date: 2003/08/09 13:20:02 $
#

eval {
    require Test::More;
    Test::More->import;
    1;
}
or do {
    no warnings;
    require Test;
    Test->import;

    *ok    = \&Dummy::ok;
    *is    = \&Test::ok;
    *like  = \&Test::ok;
    *isnt  = \&Dummy::isnt;
    *skip  = \&Dummy::skip;
    *diag  = \&Dummy::diag;
};

sub fail_ok {
    my $code = shift;

    if (ref($code) eq 'CODE') {
	eval { $code->() }
    }
    else {
	eval $code;
    }
    if (ref($_[0]) eq 'Regexp') {
	my $rx = shift;
	return like($@, $rx, @_);
    }
    else {
	return ok($@, @_);
    }
}

sub readonly {
    my $code = shift;
    fail_ok($code, qr/^Modification/, @_);
}


package Dummy;

sub ok   { Test::ok(shift) }
sub isnt { !main::ok(@_) }
sub skip {
    my $count = pop;
    ok(1) while $count--;
    no warnings;
    next SKIP;
}
sub diag { 
    for (@_) {
	for (split) { print "# $_\n" }
    }
}
