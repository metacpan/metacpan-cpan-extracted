use ExtUtils::MakeMaker;

$|=1;

print <<EOF;

0) build no interface
1) irman interface (requires libirman)
2) lirc interface (requires lirc)
3) both interfaces

EOF

print "which interfaces to build> "; $ints = <STDIN>;

push @DIR, "Irman" if $ints & 1;
push @DIR, "Lirc"  if $ints & 2;

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text RCU.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'RCU',
    'VERSION_FROM' => 'RCU.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
    DIR		=> \@DIR,
);
