use strict;
use warnings;
use Storable;
use Storable::AMF0;
use Benchmark;
use Data::Dumper;
use ExtUtils::testlib;
use lib "$ENV{HOME}/PerlIO-XS/lib";
# use mylib ;
use PerlIO::XS; # read_file write_file
use Carp;
use constant TIMES => 51;

#print Dumper(\@INC);
#read_file( '1028552550.dat', $s, 0 );
#write_file( '_1.dat', $s, 0 );


my $orig=Storable::retrieve('1028552550.dat');
#$orig->{_id}=$orig->{id};
$orig->{zzz1}=Storable::dclone($orig);
$orig->{zzz2}=Storable::dclone($orig);
$orig->{zzz3}=Storable::dclone($orig);

*snstore=\&Storable::nstore;
*afreeze=\&Storable::AMF0::freeze;
*anstore_old=\&Storable::AMF0::nstore;

*sretrieve=\&Storable::retrieve;
*athaw=\&Storable::AMF0::thaw;
*aretrieve_old = \&Storable::AMF0::retrieve;

my %our_store;
sub anstore($$) {
    my $object = shift;
    my $file   = shift;
    open my $fh, ">:raw", $file or croak "Can't open file \"$file\" for write.";

    my $freeze = \afreeze($object);
    unless (defined $$freeze ){
	croak "Bad object";
    }
    else  {
	print $fh $$freeze if defined $$freeze;
    };
}
sub aretrieve($) {
    my $file = shift;
    open my $fh, "<:raw", $file or croak "Can't open file \"$file\" for read.";
    my $buf;
    sysread $fh, $buf, (( sysseek $fh, 0, 2 ), sysseek $fh, 0,0)[0] ;
    return athaw($buf);
}




Benchmark::cmpthese(TIMES, {
	stor	 => sub{ snstore($orig, 'stor.dat') },
	amf0_orig=> sub{ anstore($orig, 'amf0orig.dat') },
	amf0_orig_old=> sub{ anstore_old($orig, 'amf0orig_old.dat') },
	amf0	 => sub{ open(my $fh, '>:raw', 'amf0.dat'); print $fh afreeze($orig) },
	amf0sys	 => sub{ open(my $fh, '>:raw', 'amf0s.dat'); syswrite($fh, afreeze($orig)) },
	some_plain => sub{ write_file( 'amf0_some.dat', afreeze( $orig ), 0)},
	some_ref   => sub{ my $s = \afreeze( $orig ) ; write_file( 'amf0_some_.dat', $s, 0)}, 
}) if 1;

my($a, $as, $ass, $s);
my ($aref ) = \(my $aaa='');


Benchmark::cmpthese(TIMES, {
	stor	=> sub{ $s=sretrieve('stor.dat') },
	amf0_orig=> sub{ $s=aretrieve('amf0orig.dat') },
	amf0_orig_old=> sub{ $s=aretrieve_old('amf0orig_old.dat') },
	amf0	=> sub{ open(my $fh, '<:raw', 'amf0.dat'); local $/; $a=athaw(<$fh>) },
	amf0sys	=> sub{ open(my $fh, '<:raw', 'amf0s.dat'); sysread($fh, my $amf, -s $fh); $as=athaw($amf) },
	amf0sysseek => 
	sub{ 
		open(my $fh, '<:raw', 'amf0s.dat'); 
		sysread($fh, my $amf, (sysseek($fh, 0, 2), sysseek($fh, 0, 0))[0]); 
		$ass=athaw($amf);
   	},
	some_plain => sub{ read_file( 'amf0_some.dat', $aaa, 0); athaw($aaa);},
	some_ref   => sub{ read_file( 'amf0_some_.dat', $aref, 0); athaw($$aref);}, 
});

#use Test::Deep;
#cmp_deeply($s, $orig, "Storable read back");    
#cmp_deeply($a, $orig, "AMF0 read back");
#cmp_deeply($as, $orig, "AMF0 sysread back");
#cmp_deeply($ass, $orig, "AMF0 sysread/sysseek back");
