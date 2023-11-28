use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Generic::Duration;
# ABSTRACT: Generic representation of a Neo4j temporal duration value
$Neo4j::Types::Generic::Duration::VERSION = '2.00';

use parent 'Neo4j::Types::Duration';


sub new {
	# uncoverable pod - see Generic.pod
	my ($class, $params) = @_;
	
	$params->{$_} ||= 0 for qw( months days seconds nanoseconds );
	return bless $params, __PACKAGE__;
}


sub months { shift->{months} }
sub days { shift->{days} }
sub seconds { shift->{seconds} }
sub nanoseconds { shift->{nanoseconds} }


1;
