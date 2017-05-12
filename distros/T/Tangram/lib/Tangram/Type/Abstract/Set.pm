

use strict;

use Tangram::Type::Abstract::Coll;

package Tangram::Type::Abstract::Set;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Coll );

use Carp;

# Support for classes that lazily create Set::Objects for instance vars.
# -- ks.perl@kurtstephens.com 2004/03/30
sub __lazy_members
{
  $_[0] ? $_[0]->members : ();
}


sub get_exporter
  {
	my ($self, $context) = @_;
	my $field = $self->{name};
	
	return $self->{deep_update} ?
	  sub {
	      # XXX - not tested by test suite
		my ($obj, $context) = @_;
		
		# has collection been loaded? if not, then it hasn't been modified
		return if tied $obj->{$field};
		
		my $storage = $context->{storage};
		
		foreach my $item ( __lazy_members($obj->{$field}) ) {
		  $storage->_save($item, $context->{SAVING});
		}
		
		print $Tangram::TRACE "Tangram::Type::Abstract::Set: defering members save of $obj.$field\n" if $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 1;
		$storage->defer(sub { $self->defered_save(shift, $obj, $field, $self) } );
		
		return ();
	  }
	: sub {
	  my ($obj, $context) = @_;
	  
	  # has collection been loaded? if not, then it hasn't been modified
	  my $tied = tied $obj->{$field};

	  my $storage = $context->{storage};
	  
      	  if ($tied and $tied->can("storage")
	      and $tied->storage == $storage ) {
	      #print STDERR "not saving $obj -> {$field} (tied = $tied)\n";
	      return;
	  }
	  
	  if (my $s = $obj->{$field}) {
	      if (!UNIVERSAL::isa($s, "Set::Object")) {
		  die "Data error in ${obj}"."->{$field}; expected "
		      ."Set, got $s"
	      } else {
		  foreach my $item ( $s->members ) {
		      $storage->insert($item)
			  unless $storage->id($item);
		  }
	      }
	  }

	  print $Tangram::TRACE "Tangram::Type::Abstract::Set: defering members save of $obj.$field\n" if $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 1;
	  $storage->defer(sub { $self->defered_save(shift, $obj, $field, $self) } );
	  
	  return ();
	}
  }

sub update
{
    my ($self, $storage, $obj, $member, $insert, $remove) = @_;

    return unless defined $obj->{$member};

    my $coll_id = $storage->id($obj);
    my $old_state = $self->get_load_state($storage, $obj, $member);
    if ( $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 2 ) {
	require YAML;
	print $Tangram::TRACE
	    ("Tangram::Type::Abstract::Set->update(".ref($obj).
	     "[$coll_id].$member); old state: ".YAML::Dump($old_state));
    }
    my %new_state = ();

    foreach my $item ( __lazy_members($obj->{$member}) ) {
	my $item_id = $storage->id($item)
	    || croak "member $item has no id";

	unless (exists $old_state->{$item_id}) {
	    print $Tangram::TRACE "Tangram::Type::Abstract::Set->update(".ref($obj).
		"[$coll_id].$member): adding $item_id\n"
		if ( $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 2 );
	    $insert->($storage->{export_id}->($item_id), $item_id);
	}

	$new_state{$item_id} = 1;
    }

    my $gone;
    foreach my $del (keys %$old_state) {
	next if $new_state{$del};
	print $Tangram::TRACE "Tangram::Type::Abstract::Set->update(".ref($obj).
	    "[$coll_id].$member): removing $del\n"
		if ( $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 2 );
	$remove->($storage->{export_id}->($del), $del);
	$gone++;
    }
    print $Tangram::TRACE "Tangram::Type::Abstract::Set->update(".ref($obj).
	"[$coll_id].$member): removed $gone rows\n"
	    if ( $Tangram::TRACE and $gone and $Tangram::DEBUG_LEVEL > 2 );

    $self->set_load_state($storage, $obj, $member, \%new_state);
    $storage->tx_on_rollback
	( sub {
	      $self->set_load_state($storage, $obj, $member, $old_state);
	  } );

    if ( $Tangram::TRACE  and $Tangram::DEBUG_LEVEL > 2 ) {
	print $Tangram::TRACE
	    ("Tangram::Type::Abstract::Set->update(".ref($obj).
	     "[$coll_id].$member); new: ".YAML::Dump(\%new_state));
    }
}

sub remember_state
{
	my ($self, $def, $storage, $obj, $member, $set) = @_;

	my %new_state;
	for my $member ( __lazy_members($set) ) {
	    my $id = $storage->id($member);
	    $id && ($new_state{ $id } = 1);
	}

	if ( $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 2 ) {
	    require 'YAML.pm';
	    print $Tangram::TRACE
		"Tangram::Type::Abstract::Set->remember(".ref($self)."[".$storage->id($obj)."].$member); new: ".YAML::Dump(\%new_state);
	}
	$self->set_load_state($storage, $obj, $member, \%new_state);

}

sub content
{
	shift;
	__lazy_members(shift); #?#?
}

1;
