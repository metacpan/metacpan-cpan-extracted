# $Id: Makefile.PL,v 1.1 2005/02/14 16:08:39 dk Exp $
use ExtUtils::MakeMaker;

use strict;

my %config = map { 
	my $a = `php-config --$_`;
	die "Error: php-config --$_ failed\n" unless $a;
	chomp $a;
	$_ => $a;
} qw(includes prefix version);

$config{version} =~ s/^(\d+).*/$1/;

WriteMakefile(
    NAME       => 'PHP',
    VERSION_FROM => 'PHP.pm', 
    LIBS      => ["-L$config{prefix}/lib -lphp$config{version}" ],
    INC       => $config{includes}, 
    OBJECT    => "PHP\$(OBJ_EXT) array\$(OBJ_EXT)",
    CCFLAGS   => '-Wall',
);
