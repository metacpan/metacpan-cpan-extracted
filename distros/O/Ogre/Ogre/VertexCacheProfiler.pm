package Ogre::VertexCacheProfiler;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::VertexCacheProfiler::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'CacheType' => [qw(
		FIFO
		LRU
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
