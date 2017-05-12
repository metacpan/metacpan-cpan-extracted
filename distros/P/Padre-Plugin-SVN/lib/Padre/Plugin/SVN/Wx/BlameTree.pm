package Padre::Plugin::SVN::Wx::BlameTree;

use 5.008;
use strict;
use warnings;
use Encode          ();
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Locale   ();

use Wx qw(:treectrl :window wxDefaultPosition wxDefaultSize);

our $VERSION = '0.05';
our @ISA     = 'Wx::TreeCtrl';


sub new {
	my $class = shift;
	my $parent = shift;
	#my $blame= shift;
	
	
	
	my $self = $class->SUPER::new( 
		$parent,
		-1,
		Wx::wxDefaultPosition,
		#Wx::wxDefaultSize,
		[700,450],
		Wx::wxTR_HAS_BUTTONS | Wx::wxTR_HIDE_ROOT | Wx::wxTR_LINES_AT_ROOT | Wx::wxSUNKEN_BORDER | 
		Wx::wxTR_FULL_ROW_HIGHLIGHT | Wx::wxTR_NO_LINES 
		
	);
	
	$self->{root} = $self->AddRoot(
		'Root',
		-1,
		-1,
		Wx::TreeItemData->new('Data'),
	);
	
	# set alternate colour
	$self->{altColor} = Wx::Colour->new(221, 221, 221);
	
	return $self;
}


sub populate {
	my $self = shift;
	my $blame = shift;
	
	my $alt = 0;
	my $setAlt = 0;
	
	my $lastSeen = -1;
	
	for(my $i=0; $i < scalar(@$blame); $i++) {
		
		$setAlt  = ($alt % 2 == 0) ? 1 : 0;
		
		my $line = $blame->[$i];
		chomp($line);
		$line =~ s/^\s+//s;
		$line =~ m/^(\d+)\s/;
		my $revNo = $1;
#		print "\n##Revision number for this line: $revNo\n";

		# grab the next lines revno
		my $next = $self->_get_next_revNo($i, $blame);
#		print "Next Rev No: $next\n";		
		
		my $item = $self->AppendItem(
			$self->{root}, 
			$line, 
			1,
			1,
			Wx::TreeItemData->new($line)
		);
		
		# if we now have a following line that belongs to this revno
		# then keep working through the log file until
		# this is no longer the case, then set $i to the 
		# index value of $j.
		if($next > 0 && $next == $revNo) {
#			print "This belongs to the same node revNo: $revNo - next: $next\n";

#			print "Next one: $nr\n";

			# keep a track of the index for the revNo
			my $revNoIndex = $i;
		
			while( $next == $revNo ) { 
				#print "Line: $line\n";
				
				$i++;
				$line = $blame->[$i];
				$self->add_child($item,$line,$i, $revNo, $revNoIndex, $setAlt);
				
				$next = $self->_get_next_revNo($i, $blame);
#				print "Next: $next\n";
			}
			
		}
		else {
#			print "New node $next\n";
			
		}

		#if( $alt % 2 == 0 ) {
		if( $setAlt ) {
			$self->SetItemBackgroundColour( $item, $self->{altColor} );
		}
		$alt++;
		$lastSeen = $revNo;
		$self->Expand($item);
	}
	
	
}


sub add_child {
	my( $self, $parent, $line, $index, $revNo, $revNoIndex, $setAlt ) = @_;
	#print "Adding child $index, $revNo, $revNoIndex - $line\n";
	#$self->SetIndent(0);	
	my $item = $self->AppendItem(
		$parent, 
		$line, 
		1,
		1,
		Wx::TreeItemData->new($line)
	);
	if( $setAlt ) {
		$self->SetItemBackgroundColour( $item, $self->{altColor} );
	}
	my $t = Wx::TreeItemData->new;
	$t->SetData( $revNo .'-'. $revNoIndex );
	$self->SetItemData($item,$t);
	
	
}

sub _get_next_revNo {
	my($self,$index, $log) = @_;
#	print "get_next index: $index\n";
	
	my $next = -1;
	if( $index + 1 < scalar(@$log)  ) {
		my $line = $log->[$index+1];
		$line =~ s/^\s+//s;
		$line =~ m/^(\d+)\s/;
		$next = $1;
#		print "_get_next: Next: $next\n";
	}	
	return $next;
}

1;