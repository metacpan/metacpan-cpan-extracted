package Number::YAUID;

use utf8;
use strict;
use vars qw($AUTOLOAD $VERSION $ABSTRACT @ISA @EXPORT);

BEGIN {
	$VERSION = 1.50;
	$ABSTRACT = "A decentralized unique ID generator (int64)";
	
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		get_error_text_by_code
		get_max_inc get_max_node_id get_max_timestamp
		timestamp_to_datetime
		get_period_key_by_timestamp get_period_key_by_datetime
	);
};

bootstrap Number::YAUID $VERSION;

use DynaLoader ();
use Exporter ();

my %opt = (
	try_count  => 0,
	sleep_usec => 35000,
	node_id    => 0
);

sub new {
	my ($class, $fuid_lock, $fnode_id) =
	   (shift, shift, shift);
	my %args = (
		%opt,
		@_
	);
	
	my $node_id = delete $args{node_id};
	my $self = $class->init($fuid_lock, $fnode_id);
	
	if(ref $self)
	{
		if(my $error = $self->get_error_code())
		{
			undef $self;
			return $error;
		}
		
		foreach my $pname (keys %args)
		{
			my $sub_name = "set_$pname";
			$self->$sub_name($args{$pname}) if exists $args{$pname};
		}
		
		unless($fnode_id || !ref $self)
		{
			$self->set_node_id($node_id);
		}
	}
	else {
		return YAUID_ERROR_CREATE_OBJECT();
	}
	
	$self;
}

sub timestamp_to_datetime {
	my @parts = (localtime( $_[0] || time ))[0..5];
	
	$parts[4] += 1;
	$parts[5] += 1900;
	
	sprintf("%04d-%02d-%02d %02d:%02d:%02d", reverse @parts);
}


1;


__END__

=head1 NAME

Number::YAUID - A decentralized unique ID generator (int64)

=head1 SYNOPSIS

 
 use Number::YAUID;
 
 my $object = Number::YAUID->new("/tmp/lock.file", "/etc/node.id");
 # OR
 #my $object = Number::YAUID->new("/tmp/lock.file", undef, node_id => 321);
 die get_error_text_by_code($object) unless ref $object;
 
 print "Max inc on sec: ", get_max_inc(), "\n";
 print "Max node id: ", get_max_node_id(), "\n";
 print "Max timestamp: ", get_max_timestamp(), "\n";
 
 foreach (0..5000)
 {
 	my $key = $object->get_key();
 	die get_error_text_by_code($object->get_error_code()) if $object->get_error_code();
 	
 	print "key: ", $key, "\n";
 	print "\ttimestamp: ", timestamp_to_datetime( $object->get_timestamp_by_key($key) ), "\n";
  	print "\tnode id: "  , $object->get_node_id_by_key($key)  , "\n";
 	print "\tinc id: "   , $object->get_inc_id_by_key($key)   , "\n";
 }
 

=head1 DESCRIPTION

Id generation at a node should not require coordination with other nodes. Ids should be roughly time-ordered when sorted lexicographically.

=head1 METHODS

=head2 new

 my $object = Number::YAUID->new(<file path to lockfile>, <file path to node id>[, params args]);

 my %p_args = (
 	try_count  => 0,     # count of key get attempts, 0 = unlimited
 	sleep_usec => 35000, # sleep 0.35 sec if limit key inc expired on current second
 	node_id    => 321    # current node id
 );
 
 my $object = Number::YAUID->new("/tmp/lock.file", undef, %p_args);
 
Create and prepare base structure. Return object or undef if something went wrong.

=head2 get_key

 my $key = $object->get_key();

Return a unique ID

=head2 get_period_key_by_datetime

 my $key = get_period_key_by_datetime(<from datetime>, <to datetime>, <from node ID>, <to node ID>);

=over 4

=item from datetime

YYYY-MM-DD hh:mm:ss

=item to datetime

YYYY-MM-DD hh:mm:ss if <to datetime> = 0, then <to datetime> = <from datetime>

=item from node ID

1 to get_max_node_id() if <from node ID> = 0, then <from node ID> = 1

=item to node ID

1 to get_max_node_id() if <to node ID> = 0, then <to node ID> = get_max_node_id()

=back

Return arrey ref where [0] = min, [1] = max unique ID

=head2 get_period_key_by_timestamp

 my $key = get_period_key_by_timestamp(<from timestamp>, <to timestamp>, <from node ID>, <to node ID>);

=over 4

=item from timestamp

timestamp

=item to timestamp

timestamp if <to timestamp> = 0, then <to timestamp> = <from timestamp>

=item from node ID

1 to get_max_node_id() if <from node ID> = 0, then <from node ID> = 1

=item to node ID

1 to get_max_node_id() if <to node ID> = 0, then <to node ID> = get_max_node_id()

=back

Return arrey ref where [0] = min, [1] = max unique ID

=head2 get_error_code

 $object->get_error_code();

Return error code.

=head2 get_error_text_by_code

 get_error_text_by_code(<error code>);

Return description by error code

=head2 get_timestamp_by_key

 $object->get_timestamp_by_key(<key>);

Return timestamp from a key

=head2 get_node_id_by_key

 $object->get_node_id_by_key(<key>);

Return node id from a key

=head2 get_inc_id_by_key

 $object->get_inc_id_by_key(<key>);

Return inc id from a key

=head2 timestamp_to_datetime

 timestamp_to_datetime(<timestamp>);

Convert timestamp to datetime (YYYY-MM-DD hh:mm:ss)

=head1 DESTROY

 undef $obj;

Free mem and destroy object.

=head1 AUTHOR

Alexander Borisov <lex.borisov@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alexander Borisov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
