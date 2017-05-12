# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - 2002/04/26 at 15:30 CEST
# *

package Util::BLOB;
{
use vars qw ($VERSION);
use strict;

use Carp;
 
$VERSION = '0.1';

use Storable qw ( thaw nfreeze ); #used for BLOBs

$Util::BLOB::Storable_magicnumber = nfreeze(\'_blob_:');
$Util::BLOB::Storable_magicnumber_unpacked = unpack("H*", $Util::BLOB::Storable_magicnumber );
sub deserialise {
	my ($content) = @_;

	if ($content =~ s/^$Util::BLOB::Storable_magicnumber_unpacked//) {
		$content = pack("H*", $content );
        	eval {
        		$Storable::canonical=1;
                	$content = thaw($content);
        		$Storable::canonical=0;
                	};
                if($@) {
                	warn "Util::BLOB::deserialise: ".$@;
                        return;
                        };
		};
	return $content;
	};

sub serialise {
	my ($value) = @_;
   
        if(     (defined $value) &&
                (ref($value)) ) {
                eval {
        		$Storable::canonical=1;
                	$value = $Util::BLOB::Storable_magicnumber . nfreeze( $value );
        		$Storable::canonical=0;
                	};
                if($@) {
                	warn "Util::BLOB::serialise: ".$@;
                        return;
                        };
		$value = unpack("H*", $value );
                };
	return $value;
        };

sub isBLOB {
	my ($content) = @_;

        if(     (defined $content) &&
                (ref($content)) ) {
		return 1;
	} else {
		return ($content =~ /^$Util::BLOB::Storable_magicnumber_unpacked/);
		};
	};

1;
};

__END__

=head1 NAME

Util::BLOB - Simple interface to de/serialise perl references with Storable

=head1 SYNOPSIS

	use Util::BLOB;
	my $blobbed = serialise( $blob );
	my $blob = deserialise( $blobbed );
	print "is a BLOB"
		if(isBLOB($blobbed));

=head1 DESCRIPTION

Simple perl object/reference de/searialisation using Storable. See RDFStore::Literal(3) and RDFStore::Resource(3)

=head1 METHODS

=over 4

=item serialise ( BLOB )

Freeze the given perl object or reference to a string; the string is HEX packed to safely be converted to UTF-8 in RDFStore(3).

=item deserialise ( BLOB )

Thaw the given string to a perl object or reference; the string is HEX unpacked before being thawed.

=item isBLOB ( CONTENT )

Return true if the CONTENT passed to it is actually a BLOB (perl object reference or frozen string)

=head1 SEE ALSO

RDFStore::Literal(3) Storable(3) RDFStore::Resource(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
