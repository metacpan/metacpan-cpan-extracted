package SNMP::Class::Cache;

=head1 NAME

SNMP::Class::Cache - An SNMP::Class::ResultSet which is also a live SNMP::Class session. 

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

The SNMP::Class::Cache class can be used as a combination of an L<SNMP::Class> session object and an L<SNMP::Class::ResultSet> object. This roughly means that the same object can be used both for querying and storing the results of SNMP queries. 

 #create a session as usual
 my $s = SNMP::Class::Cache({DestHost => $myhost1}); 

 #add the ifTable to the Cache 
 $s->add("ifTable");

 #use it like an ordinary ResultSet
 print $s->ifTable->find(ifDescr=>'eth0')->ifSpeed;
 
 #Check whether the ifTable tree has been walked already
 print "ifTable already there" if ( $s->has("ifTable") );

 #or, get a list of the stuff already added to our resultset
 print join(',',$s->modules);
  

=cut

#This class is both a resultset and a live session
#the order of inheritance is important, because
#we want to try the already stored results first
use base qw(SNMP::Class::ResultSet SNMP::Class );


use Class::Std;
use warnings;
use strict;
use Carp qw(cluck confess carp croak);
use Data::Dumper;

use Log::Log4perl qw(:easy);
my $logger = get_logger();


my %module :ATTR;

=head1 METHODS

=head2 add

Walks the supplied object id's and adds the results to the resultset. The object id's can be many, e.g.

 $s->add('system','interfaces') 

=cut

sub add {
	my $self = shift(@_) or confess "missing self argument";
	LOOP: while (my $module = shift(@_)) {
		my $temp;
		if (eval { $temp = $self->SUPER::walk($module) }) {
			$logger->debug("fetched contents of $module");
			if ($temp->is_empty) {
				carp $self->get_name," does not seem to have any $module instances";
				next LOOP;
			} 
			$module{ident $self}->{$module} = 1;
			$self->append($temp);
		} else {
			cluck "attempt to walk $module failed";
			$logger->debug("error getting contents of $module");
		}
	}

}

=head2 has

Returns true if the name supplied as argument has been walked in a previous add operation. Note that there is exact string comparison between the argument of the previous add call and the argument of the current has call. So, ifTable and .1.3.6.1.2.1.2.2 won't match. This behavior may change in the future.

=cut

sub has {
	my $self = shift(@_) or confess "Incorrect call to has_module : this is a method";
	my $module = shift(@_) or croak "Missing 1st argument to has";	
	
	return 1 if (defined($module{ident $self}->{$module}));
	return;
}

=head2 modules

Returns a list of all the previous arguments that have ever been supplied to the add method of the current object. 

=cut

sub modules {
	my $self = shift(@_) or confess "Incorrect call to modules : this is a method";
	return (sort keys %{$module{ident $self}});
}
	


#sub get {
#	my $self = shift(@_) or confess "Incorrect call to get_module: this is a method";
#	my $module = shift(@_) or croak "Missing 1st argument to get_module";		
#	
#	if($self->has($module)) {
#		return $module{ident $self}->{$module};
#	} else {
#		cluck "call to get_module($module) on an object that has no $module";
#		return;
#	}
#}

#sub AUTOMETHOD {
#	my $self = shift(@_) or confess("Incorrect call to AUTOMETHOD");
#	my $id = shift(@_) or confess("Second argument (id) to AUTOMETHOD missing");
#	my $subname = $_;   # Requested subroutine name is passed via $_;
#	$logger->debug("AUTOMETHOD called as $subname");  
#	
#	if (SNMP::Class::Utils::is_valid_oid($subname)) {
#		$logger->debug("ResultSet: $subname seems like a valid OID ");
#	}
#	else {
#		$logger->debug("$subname doesn't seem like a valid OID. Returning...");
#		return;
#	}
#	
#	#we are in an object that is both a resultset and a live session.
#	#question: do we need to query the managed node for the object $subname,
#	#or do we have it cached already? Let's check. If we don't have it, we
#	#will try to append it. 
#
#	if($self->SNMP::Class::ResultSet::label($subname)->is_empty) {
#		$logger->debug("No $subname entries in the resultset...we'll try to walk first");
#		my $result = $self->walk($subname);
#		$self->append($result);
#	}
#	
#	#our work is done. We'll just return so that the Class::Std can delegate control to SNMP::Class::ResultSet::AUTOMETHOD
#	return;
#
#}
	

1;	
