# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

# SmartHash.pm - Hash with default values.
# 
# SmartHash objects can also be given a callback method parameter to call when
# values are changed.  This allows wrapping objects to implement "is dirty?"
# mechanisms.
#
# Change call back methods will be passed the object reference, the key name,
# the old value, and the new value.  Callback methods are called AFTER the value
# has been changed.
#
# @author  Matt Luker
# @version $Revision: 1327 $

# SmartHash.pm - Hash with default values.
# 
# Copyright (C) 2003, Matt Luker
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# kostya@redstarhackers.com
# 
# TTGOG

package RSH::SmartHash;

use 5.008;
use strict;
use warnings;

require Tie::Hash;

our @ISA = qw(Tie::Hash);

use RSH::Exception;

# ******************** PUBLIC Class Methods ********************

sub merge_hashes {
	my @hash_refs = @_;

	if (scalar(@hash_refs) == 0) { die new RSH::CodeException message => 'Please supply a hash reference.'; }

	for (my $i = 1; $i < scalar(@hash_refs); $i++) {
		if (ref($hash_refs[$i]) ne 'HASH') { next; }
		foreach my $key (keys %{$hash_refs[$i]}) {
			if (defined($key) && defined($hash_refs[$i]->{$key})) {
				$hash_refs[0]->{$key} = $hash_refs[$i]->{$key};
			}
		}
	}

	return $hash_refs[0];
}
	

# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;
	my %params = @_;

	my $default_vals = $params{default};
	my $vals = $params{values};
	my $change_callback = $params{change_callback};
	my $dirty = $params{dirty};

	my $self = {};
	$self->{default} = $default_vals;
	$self->{hash} = $vals;
	if ( (defined($change_callback)) &&
		 (ref($change_callback ne 'CODE')) ) {
		$change_callback = undef;
	}

	$self->{change_callback} = $change_callback;

	if (not defined($dirty)) {
		$dirty = 0;
	}

	$self->{dirty} = $dirty;
		
	bless $self, $class;
	return $self;
}

sub TIEHASH {
	return (new @_);
}

# ******************** PUBLIC Instance Methods ********************

# ******************** Hash Tie Methods ********************

sub STORE {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $old_val = $self->{hash}{$key};
	$self->{hash}{$key} = $val;
	if ( defined($old_val) && 
		 defined($val) && 
		 (ref($old_val) eq ref($val)) && 
		 defined(($old_val ne $val)) &&
		 ($old_val ne $val) ) {

		$self->{dirty} = 1;
		if (defined($self->{change_callback})) {
			&{$self->{change_callback}}($self, $key, $old_val, $val);
		}
	} elsif ( (not defined($old_val)) && (not defined($val) ) ) {
		# NOTHING
	} else {
		# one is defined and one isn't, which is different--so ...
		$self->{dirty} = 1;
		if (defined($self->{change_callback})) {
			&{$self->{change_callback}}($self, $key, $old_val, $val);
		}
	}
}

sub FETCH {
	my $self = shift;
	my $key = shift;

	if (defined($self->{hash}{$key})) { return $self->{hash}{$key}; }
	else { return $self->{default}{$key}; }

}

sub FIRSTKEY {
	my $self = shift;

	my $a = keys %{$self->{hash}};
	each %{$self->{hash}};
}

sub NEXTKEY {
	my $self = shift;
	my $last_key = shift;
	each %{$self->{hash}};
}

sub EXISTS {
	my $self = shift;
	my $key = shift;

	if (not exists($self->{hash}{$key})) { return exists($self->{default}{$key}); }
	else { return exists($self->{default}{$key}); }
}

sub DELETE {
	my $self = shift;
	my $key = shift;

	delete $self->{hash}{$key};
}

sub CLEAR {
	my $self = shift;

	$self->{hash} = {};
}

# ******************** Regular Instance Methods ********************

sub default_hash {
	my $self = shift;

	return $self->{default};
}

# is_dirty
#
# Read-only accessor for the object's dirty flag.  The dirty flag is set
# whenever a value is changed for the object's hash values.
#
sub is_dirty {
	my $self = shift;

	return $self->{dirty};
}

# dirty
#
# Read-write accessor for the dirty state of this object.
#
# params:
#  val - new dirty state
#
sub dirty {
	my $self = shift;
	my $val = shift;

	if (defined($val)) { $self->{dirty} = ($val && 1); }

	return $self->{dirty};
}

# merge
#
# Merges the values of a hash reference into this object.
#
sub merge {
	my $self = shift;
	
	merge_hashes($self, @_);
}

# rollback_value
#
# Rollback the value.   Works like the Tie STORE, but does not call the 
# change callback method (prevents an endless loop).
#
sub rollback_value {
	my $self = shift;
	my $key = shift;
	my $old_val = shift;

	$self->{hash}{$key} = $old_val;
}

# #################### SmartHash.pm ENDS ####################
1;
# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.4  2004/04/09 06:18:26  kostya
#  Added quote escaping capabilities.
#
#  Revision 1.3  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.2  2003/10/14 22:49:32  kostya
#  Added the merge functions for combining settings.
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
# 
# ------------------------------------------------------------------------------

__END__
