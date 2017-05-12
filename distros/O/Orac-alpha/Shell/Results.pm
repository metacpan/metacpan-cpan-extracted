
#
# Support the results tags
#

# vim:ts=2:sw=2:ai:aw:

package Shell::Results;
use strict;

use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter ();
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT_OK = qw();

my @_rmarkers = []; # Package

#
# Create the results button next to the statement
# executed.  The results button is only created, if
# one does not currently exist.
#

sub create_results_btn {
	my ($self, $bl) = @_;
	$bl = $self->current->stat_num unless $bl;
	if (!$self->current->is_marked) {
		return $self->set_results_btn($bl);
	}
	return 0;
}

# Builds and places the results button on the entry widget.
sub results_button {
	my $self = shift;
	return $self->create_results_btn;
}

# 
# Determine where the markers go
#

sub set_results_btn {
	my ($self, $c, $inx ) = @_;

	$c = $self->current->stat_num unless $c;

	 # Round off the current
   my $pl = int($self->current->beg());

   #$self->check_ind_txt($pl);

   # Add just a line place for statement marker.
   # Using closure witht the button, instead of a subroutine.
   # see Advanced Perl Programming p60.
   my $mv_to_res = sub { 
      $self->move_to_results( $c )
   };


	$_rmarkers[$c] = $self->entry_txt->Button( # -text => '',
         -image => $self->icon(q{checkmark}),
         -justify => 'left',
         -height => 6,
         -width => 6,
         -highlightthickness => 2,
         -relief => 'raised',
				 -command => $mv_to_res,
      );

	$self->bind_message( $_rmarkers[$c], q{Scroll results window to statement results.} );

	$self->entry_txt->windowCreate( "$pl.0", -window => $_rmarkers[$c] );

	#
	# Move the text over, attempting to keep the alignments.
	#

	my $pxs = $_rmarkers[$c]->fpixels( $_rmarkers[$c]->reqwidth());
	$self->entry_txt->tagConfigure( qq{Indent$c}, -lmargin1 => $pxs );

	my ($abeg, $aend);
	$abeg = int( $self->current->beg );
	$aend = int( $self->current->end );

	# The statement is on the same line.
	if (($abeg - $aend) == 0 ) {
	} else {
			# Move all but the first line indented.
				$self->tag_entry( qq{Indent$c},
					qq{$abeg.0 + 1 line} , qq{$aend.0 lineend}  );
	}

	#print STDOUT qq{Indenting line: $abeg end: $aend pixels: $pxs\n};
	return;
}

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
