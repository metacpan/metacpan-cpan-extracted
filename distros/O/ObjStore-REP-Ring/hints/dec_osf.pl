package MY;

$self->{OPTIMIZE} =~ /-g/ and $debug=1;

$self->{CC}="cxx -xtaso";
$self->{LD}="cxx -taso";   
$self->{LIBS}=["-L$ENV{OS_ROOTDIR}/lib -loscol -los -losthr"];
$self->{FULLPERL}='perl32';

check_perl32();
check_cxx_version();

sub check_perl32() {
	my $out=`perl32 -e 'print 1+1'`;
	die "cant run perl32\n" if @?;
	return if $out eq "2";
	die "your perl32 might be buggy. 1+1=$out ?\n";
}

sub check_cxx_version {
	my $out=`cxx -V`;
	die "cant run cxx\n" if @?;
	return if $out=~/\QV5.5-004/;

	warn "$out\n";

 	die "Your compiler Version wont work\n" if $out=~/\QT5.6-009/;

	warn "Compiler version untested\n";
}

# MakeMaker overrides

sub const_config {
        my $out=shift->SUPER::const_config;
        $out=~s/^(LDDLFLAGS)(.*)-s/$1$2/m if $debug;    # remove -s for debugging
        $out;
}

sub test {
	my $out=shift->SUPER::test;
	$out=~s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=0/g;  # I have NO idea, what symbols are missing
	$out;
}

sub c_o {
	my $out=shift->SUPER::c_o;

	# wish, joshua didn't call his C++ files .c. So we need to modify
	# our .c.o rule to tell cxx, that our .c files really are C++ source

	$out=~s/\$\*\.c/-x cxx \$*.c/;
	$out;

}

sub cflags {

	my $out=shift->SUPER::cflags(@_);
	$out=~s/-std//;             # cxx5.5-004 doesn't want this.
	$out=~s/-fprm d//;          # cxx5.5-004 bug: if given cxx forgets to pass args to cc :-)
	$out;
}


# MY::postamble allready defined by Makefile.PL.
# we are going to redefine it. Save old method.

BEGIN { $HINTS::old_postamble = \&postamble; }

sub postamble {
	my $out = &$HINTS::old_postamble(@_);

	#
	# add -xtaso flag to the ossg rule
	#

	$out=~s/^(\t\s*)ossg(\s)/$1ossg -xtaso$2/gm;   # add -xtaso to ossg rule
	$out;
}

