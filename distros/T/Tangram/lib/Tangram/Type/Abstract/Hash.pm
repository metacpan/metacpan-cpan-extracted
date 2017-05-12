

use strict;

package Tangram::Type::Abstract::Hash;

use Tangram::Type::Abstract::Coll;
use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Coll );

use Carp;

# XXX - not reached by test suite
sub content
{
    shift;
    @{shift()};
}

sub demand
{
    my ($self, $def, $storage, $obj, $member, $class) = @_;

    my %coll;

    if (my $prefetch = $storage->{PREFETCH}{$class}{$member}{$storage->export_object($obj)})
    {
	    print $Tangram::TRACE "demanding ".$storage->id($obj)
		.".$member from prefetch\n" if $Tangram::TRACE;
		%coll = %$prefetch;
    }
    else
    {
	    print $Tangram::TRACE "demanding ".$storage->id($obj)
		.".$member from storage\n" if $Tangram::TRACE;
		my $cursor = $self->cursor($def, $storage, $obj, $member);

		my @lost;
		for (my $item = $cursor->select; $item; $item = $cursor->next)
		{
			my $slot = shift @{ $cursor->{-residue} };
			if (!defined($slot)) {
			    warn "object ".$storage->id($item)." has no slot in hash ".$storage->id($obj)."/$member!";
			    push @lost, $item;
			} else {
			    $coll{$slot} = $item;
			}
		}
		# Try to DTRT when you've got NULL slots, though this
		# isn't much of a RT to D.
		while (@lost) {
		    my $c = 0;
		    while (!exists $coll{$c++}) { }
		    $coll{$c} = shift @lost;
		}
    }

	$self->set_load_state($storage, $obj, $member, { map { ($_ ? ($_ => ($coll{$_} && $storage->id( $coll{$_} ) ) ) : ()) } keys %coll } );

    return \%coll;
}

# XXX - not reached by test suite
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
	return unless exists $obj->{$field} && defined $obj->{$field};
	
	foreach my $item (values %{ $obj->{$field} }) {
	  $storage->insert($item)
		unless $storage->id($item);
	}
  }

sub get_exporter
  {
	my ($self, $context) = @_;
	my $field = $self->{name};

	return sub {
	  my ($obj, $context) = @_;

	  my $tied = tied $obj->{$field};

	  my $storage = $context->{storage};
      	  if ($tied and $tied->can("storage")
	      and $tied->storage == $storage ) {
	      #print STDERR "not saving $obj -> {$field} (tied = $tied)\n";
	      return;
	  }
	  return unless exists $obj->{$field} && defined $obj->{$field};
	
	  foreach my $item (values %{ $obj->{$field} }) {
		$storage->insert($item)
		  unless $storage->id($item);
	  }

	  $context->{storage}->defer(sub { $self->defered_save($obj, $field, $storage) } );
	  ();
	}
  }


1;
