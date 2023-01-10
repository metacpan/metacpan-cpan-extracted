use strict;
use warnings;
#use Data::Dumper;		$::Data::Dumper::Sortkeys = 1;
use FindBin				qw( $Bin );
use lib $Bin;

use Test::More			qw( no_plan );
#-----------------------------------------------------------------------
use Passwd::Unix;

#=======================================================================
sub pwd {
	my ( $pth ) = @_;

	open( my $fhd, '>', $pth );
	print $fhd <<EOT;
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
EOT

}
#=======================================================================
sub psh {
	my ( $pth ) = @_;

	open( my $fhd, '>', $pth );
	print $fhd <<EOT;
root:TEST:15982:0:99999:7:::
daemon:*:15982:0:99999:7:::
bin:*:15982:0:99999:7:::
sys:*:15982:0:99999:7:::
sync:*:15982:0:99999:7:::
EOT

}
#=======================================================================
sub grp {
	my ( $pth ) = @_;

	open( my $fhd, '>', $pth );
	print $fhd <<EOT;
root:x:0:root
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
EOT

}
#=======================================================================
sub gsh {
	my ( $pth ) = @_;

	open( my $fhd, '>', $pth );
	print $fhd <<EOT;
root:x:0:root
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
EOT

}
#=======================================================================

pwd( q[passwd]  );
psh( q[shadow]  );
grp( q[group]   );
gsh( q[gshadow] );



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my $pux = Passwd::Unix->new(
	passwd		=> q[passwd],
	shadow		=> q[shadow],
	group		=> q[group],
	gshadow		=> q[gshadow],
	algorithm	=> q[sha256],
	backup		=> 0,
	compress	=> 0,
	warnings	=> 1,
);
#+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
ok( ref $pux eq q[Passwd::Unix], "Load with specified parameters." );
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok( 
	$pux->{ alg } eq q[sha256],
	"Correct algorithm option"
);
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok( 
	$pux->{ cmp } == 0,
	"Correct compression option"
);
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok( 
	$pux->{ cmp } == 0,
	"Correct backup option"
);
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my $usr = join( q[:], sort $pux->users );
#+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
ok( 
	$usr eq	q[bin:daemon:root:sync:sys],
	"List of users from passwd"
);
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$usr = join( q[:], sort $pux->users_from_shadow );
#+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
ok( 
	$usr eq	q[bin:daemon:root:sync:sys],
	"List of users from shadow"
);
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#die ::Dumper( $pux );

