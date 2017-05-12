



package Parse::Gnaw::Blocks::LetterDimensions2;

our $VERSION = '0.001';

#BEGIN {print "Parse::Gnaw::Blocks::Letter\n";}

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Storable 'dclone';

use Parse::Gnaw::LinkedListConstants;

use       Parse::Gnaw::Blocks::Letter;
use base "Parse::Gnaw::Blocks::Letter";
use       Parse::Gnaw::Blocks::LetterConstants;

=head1 NAME

Parse::Gnaw::Blocks::LetterDimensions2 - a linked list element that holds a single scalar payload.
This one assumes linked list is in a 2 dimensional structure


=head2 new

=cut

sub new{
	my $pkg=shift(@_);
	$pkg->SUPER::new(@_);

}




=head2 get_raw_address

This is a subroutine. Do NOT call this as a method. This will allow it to handle undef values.

	my $retval = get_raw_address($letterobj);

Given a letter object, get the string that looks like

	Parse::Gnaw::Blocks::Letter=ARRAY(0x850cea4)

and return something like 

	0x850cea4

=cut


my $blank_obj=[];
#print "blank_obj is '$blank_obj'\n"; die;
my $blank_str=$blank_obj.'';
my $blank_len=length($blank_str);
my $BLANK = '.'x($blank_len-5);


sub get_raw_address{
	my ($ltrobj)=@_;

	unless(defined($ltrobj)){
		return $BLANK;
	}

	my $string=$ltrobj.'';
	$string=~m{(\(0x[0-9a-f]+\))} or croak "could not get_raw_address";
	my $addr=$1;

	return $addr;

}

=head2 display

Dump out a represenation of a letter that is part of a 2-d linked list

=cut
#BEGIN { warn "letterdimensions2 declaring display() function";}
sub display{
	my ($centerobj)=@_;

	my $letpkg = ref($centerobj);
	my $self  = get_raw_address($centerobj);

	my $left  = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV]);
	my $right = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT]);

	my $above = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[1]->[LETTER__CONNECTION_PREV]);
	my $below = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[1]->[LETTER__CONNECTION_NEXT]);

	my $uple  = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[2]->[LETTER__CONNECTION_PREV]);
	my $lowri = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[2]->[LETTER__CONNECTION_NEXT]);

	my $upri  = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[3]->[LETTER__CONNECTION_PREV]);
	my $lowle = get_raw_address($centerobj->[LETTER__CONNECTIONS]->[3]->[LETTER__CONNECTION_NEXT]);

	print "\n";
	print "\t letterobject: ".$centerobj."\n";
	print "\t payload: '".($centerobj->[LETTER__DATA_PAYLOAD])."'\n";
	print "\t location: ".($centerobj->[LETTER__WHERE_LETTER_CAME_FROM])."\n";
	print "\t"."connections:\n";

	print "\t\t".$uple .$above.$upri."\n";
	print "\t\t".$left .$self .$right."\n";
	print "\t\t".$lowle.$below.$lowri."\n";
}








1;

