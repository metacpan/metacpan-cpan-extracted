#
#
#
# vim:set ts=2 sw=2 ai aw:
package Shell::Current;
use strict;
use Carp;

my $total = 0;

sub new {
	my $proto = shift; 
	my $class = ref($proto) || $proto;
	my $parent = shift;

	my $self  = {
			beg       => undef,
			cmark     => undef,
			display   => undef,
			end       => undef,
			msg       => undef,
			is_marked => undef,
			stat_num  => $total,
			statement => undef,
			status    => undef,
			entry			=> undef,
			term			=> sub { $parent->options->statement_term },
		};
	$total++;
	bless($self, $class);
	return $self;
}

sub _clear_current {
	my $self = shift;
	print STDERR qq{Current statement cleared\n};
	foreach (keys %$self) {
		next if (/entry/ or /term/);
		$self->{$_}  = undef;
	}
}

#
# Look forward in the index to the first non-space.
#

sub search_forward {
	my ($self, $beg, $end) = @_;

	$beg = $self->entry->index( 'current' ) unless $beg;
	$end = q{end} unless $end;

	my $term = q{\w};
	#my $term = &{$self->term} . q{$};
	return $self->entry->search( 
			-forwards,
      -regexp, 
      q{--},
			$term,
      $beg,
      $end,
   );
}


sub search_backward {
	my $self = shift;
	my $cur_inx = shift;
	my $term = &{$self->term} . q{$};

	my $start_inx = $self->entry->index( qq{$cur_inx - 1 chars} );
	my $end_inx = q{1.0};
	$self->end($start_inx);
	print STDERR qq{Search backward: $term Index $cur_inx $start_inx $end_inx\n};

	# Search the statement.
	return $self->entry->search( 
		-backwards, 
		-regexp, 
		q{--},
		$term,
		$start_inx,
		$end_inx,
	);
}

#
# Populates the current structure with information from
# the current entry text widget.
#

sub populate {
   my ($self, $cinx) = @_;
   my $stinx;
	 my ($beg, $end, $crnt);

		# Clear the previous statement from the object.
		_clear_current($self);

	 $cinx = 'insert' unless $cinx;
	 # Determine where we are.

   $crnt = $self->entry->index( $cinx );

	# Finds the end of the last statement, however
	# includes all the white space between the last
	# statement end, and the current statement.
	my $inx = $self->search_backward($crnt);

   # The buffer could have more than one statement in it.
   # Find the last statement. Look for the new statement on
   # the next line.
   $beg = $inx? $self->entry->index( qq{$inx + 1 chars} ): q{1.0};

	 # Get the current statement.
	 $self->beg($beg);
	 $end = $self->end;
	 $self->stat_num($total++);

	 # Search forward to find the real begining of the statement.
	 my $real_beg = $self->search_forward( $beg, $end );
   my $st = $self->statement($self->entry->get( $real_beg, $end));

	 print qq{Populate: Statement: $st Begin: $beg/$real_beg End: $end\n};
	 $self->beg($real_beg);

	 return $st;
}

sub destory { $total-- };

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $option = $AUTOLOAD;
	$option =~ s/.*:://;
	
	unless (exists $self->{$option}) {
		croak "Can't access '$option' field in object of class $type";
	}
	if (@_) {
		return $self->{$option} = shift;
	} else {
		return $self->{$option};
	}
	croak qq{This line shouldn't ever be seen}; #'
}

1;
