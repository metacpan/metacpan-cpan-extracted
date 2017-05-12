#
#===============================================================================
#
#         FILE:  02parse.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06.04.2009 04:59:35 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 9;                      # last test to print

use Data::Dumper;

use_ok('SOAP::DirectI::Parse');


sub slurp {
    local $/;
    open my $fh, '<', shift or die "Cannot open file $!";
    <$fh>;
}

for my $f ( glob('t/data/*.xml'), glob('data/*.xml') ) {
    my $fbase = $f;
    $fbase =~ s/.xml$//;

    my $xml  = slurp( $f );
    my $data = eval slurp( "$fbase.dat" );
    my $sig  = eval slurp( "$fbase.sig" );

    my $o = SOAP::DirectI::Parse->new();

    eval {
	$o->parse_xml_string( $xml );
    };

    my ($d, $s) = $o->fetch_data_and_signature();

    if ( not $data ) {
	open my $fh, '>', "$fbase.dat";
	$d = Dumper $d;
	$d =~ s/\$VAR1 = //;
	print $fh $d;
	close $fh;
    }
    if ( not $sig ) {
	open my $fh, '>', "$fbase.sig";
	$s = Dumper $s;
	$s =~ s/\$VAR1 = //;
	print $fh $s;
	close $fh;
    }

    is_deeply( $data, $d, "data for $s->{name}"		);
    is_deeply( $sig , $s, "signature for $s->{name}"	);
}
