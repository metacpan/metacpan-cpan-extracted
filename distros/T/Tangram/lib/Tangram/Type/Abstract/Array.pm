

use strict;

use Tangram::Type::Abstract::Coll;

package Tangram::Type::Abstract::Array;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Coll );

use Carp;

sub demand
{
	my ($self, $def, $storage, $obj, $member, $class) = @_;

	my (@coll, @lost);

	if (my $prefetch = $storage->{PREFETCH}{$class}{$member}{$storage->export_object($obj)})
	{
	    print $Tangram::TRACE "demanding ".$storage->id($obj)
		.".$member from prefetch\n" if $Tangram::TRACE;
		@coll = @$prefetch;
	}
	else
	{
	    print $Tangram::TRACE "demanding ".$storage->id($obj)
		.".$member from storage\n" if $Tangram::TRACE;
		my $cursor = $self->cursor($def, $storage, $obj, $member);

		for (my $item = $cursor->select(); $item; $item = $cursor->next)
		{
			my $slot = shift @{ $cursor->{-residue} };
			if (defined $slot) {
                           $coll[$slot] = $item;
                       } else {
                           warn "object ".$storage->id($item)." has no slot in array ".$storage->id($obj)."/$member!";
			   push @lost, $item
                       }
		}
		# last-ditch effort to automatically DTRT
		if (@lost) {
		    foreach(@coll) {
			if (!defined $_) {
			    $_ = shift @lost;
			}
			last unless @lost;
		    }
		    push @coll, @lost;
		}
	}

	$self->set_load_state($storage, $obj, $member, [ map { ($_) ? $storage->id($_) : undef } @coll ]);

	return \@coll;
}

sub get_export_cols
{
  return (); # arrays are not stored on object's table
}

sub save_content
  {
	my ($obj, $field, $context) = @_;

	# has collection been loaded? if not, then it hasn't been modified
	my $tied = tied $obj->{$field};

	my $storage = $context->{storage};
      	  if ($tied and $tied->can("storage")
	      and $tied->storage == $storage ) {
	      #print STDERR "not saving $obj -> {$field} (tied = $tied)\n";
	      return;
	  }

	foreach my $item (@{ $obj->{$field} }) {
	  $storage->insert($item)
		unless $storage->id($item);
	}
  }

sub deep_save_content
  {
	my ($obj, $field, $context) = @_;

	# has collection been loaded? if not, then it hasn't been modified
	return if tied $obj->{$field};

	my $storage = $context->{storage};

	foreach my $item (@{$obj->{$field}}) {
	  $storage->_save($item, $context->{SAVING});
	}
  }

# XXX - never reached by test suite
sub check_content
  {
	my ($obj, $field, $coll, $class) = @_;

	foreach my $item ($obj->{$field}) {
	  Tangram::Type::Abstract::Coll::bad_type($obj, $field, $class, $item)
		unless $item->isa($class);
	}
  }

sub get_exporter
  {
	my ($self, $context) = @_;
	my $save_content = $self->{deep_update} ? \&deep_save_content : \&save_content;
	my $field = $self->{name};

	return sub {
	  my ($obj, $context) = @_;
	  $save_content->($obj, $self->{name}, $context);
	  $context->{storage}->defer(sub { $self->defered_save(shift, $obj, $field, $self) } );
	  ();
	}
  }

sub defered_save
  {
	use integer;
	
	my ($self, $storage, $obj, $field, $def) = @_;
	
	return if tied $obj->{$field}; # collection has not been loaded, thus not modified
	
	my $coll_id = $storage->id($obj);
	
	my ($ne, $modify, $add, $remove) =
	  $self->get_save_closures($storage, $obj, $def, $storage->id($obj));
	
	my $new_state = $obj->{$field} || [];
	my $new_size = @$new_state;
	
	my $old_state = $self->get_load_state($storage, $obj, $field) || [];
	my $old_size = @$old_state;
	
	my ($common, $changed) = Tangram::Type::Abstract::Coll::array_diff($new_state, $old_state, $ne);
	
	for my $slot (@$changed)
	  {
		$modify->($slot, $new_state->[$slot], $old_state->[$slot]);
	  }
	
	for my $slot ($old_size .. ($new_size-1))
	  {
		$add->($slot, $new_state->[$slot]);
	  }
	
	if ($old_size > $new_size)
	  {
		$remove->($new_size, $old_size);
	  }
	
	$self->set_load_state($storage, $obj, $field, [ @$new_state ] );	
	
	$storage->tx_on_rollback( sub { $self->set_load_state($storage, $obj, $field, $old_state) } );
  }

1;
