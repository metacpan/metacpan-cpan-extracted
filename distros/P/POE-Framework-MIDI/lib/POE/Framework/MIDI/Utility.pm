# $Id: Utility.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

package POE::Framework::MIDI::Utility;
use strict;
my $VERSION = '0.1a';
use vars qw/@ISA @EXPORT/;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(%Volume %Length %Note @Note); 

# Defaults copied directly from Sean Burke's MIDI::Simple.
my %Volume = ( # I've simply made up these values from more or less nowhere.
# You no like?  Change 'em at runtime, or just use "v64" or whatever,
# to specify the volume as a number 1-127.
 'ppp'   =>   1,  # pianississimo
 'pp'    =>  12,  # pianissimo
 'p'     =>  24,  # piano
 'mp'    =>  48,  # mezzopiano
 'm'     =>  64,  # mezzo / medio / meta` / middle / whatever
 'mezzo' =>  64,
 'mf'    =>  80,  # mezzoforte
 'f'     =>  96,  # forte
 'ff'    => 112,  # fortissimo
 'fff'   => 127,  # fortississimo
);

my %Length = ( # this list should be rather uncontroversial.
 # The numbers here are multiples of a quarter note's length
 # The abbreviations are:
 #    qn for "quarter note",
 #    dqn for "dotted quarter note",
 #    ddqn for "double-dotted quarter note",
 #    tqn for "triplet quarter note", etc.
 'wn' => 4,     'dwn' => 6,     'ddwn' => 7,       'twn' => (8/3),
 'hn' => 2,     'dhn' => 3,     'ddhn' => 3.5,     'thn' => (4/3),
 'qn' => 1,     'dqn' => 1.5,   'ddqn' => 1.75,    'tqn' => (2/3),
 'en' =>  .5,   'den' =>  .75,  'dden' =>  .75,    'ten' => (1/3),
 'sn' =>  .25,  'dsn' =>  .375, 'ddsn' =>  .4375,  'tsn' => (1/6),
 # Yes, these fractions could lead to round-off errors, I suppose.
 # But note that 96 * all of these == a WHOLE NUMBER!!!!!

# Dangit, tsn for "thirty-second note" clashes with pre-existing tsn for
# "triplet sixteenth note"
#For 32nd notes, tha values'd be:
#        .125             .1875           .21875            (1/12)
#But hell, just access 'em as:
#         d12               d18           d21                d8
#(assuming Tempo = 96)

);

my %Note = (
 'C'  =>  0,
 'Cs' =>  1, 'Df' =>  1, 'Csharp' =>  1, 'Dflat' =>  1,
 'D'  =>  2,
 'Ds' =>  3, 'Ef' =>  3, 'Dsharp' =>  3, 'Eflat' =>  3,
 'E'  =>  4,
 'F'  =>  5,
 'Fs' =>  6, 'Gf' =>  6, 'Fsharp' =>  6, 'Gflat' =>  6,
 'G'  =>  7,
 'Gs' =>  8, 'Af' =>  8, 'Gsharp' =>  8, 'Aflat' =>  8,
 'A'  =>  9,
 'As' => 10, 'Bf' => 10, 'Asharp' => 10, 'Bflat' => 10,
 'B'  => 11,
);

my @Note = qw(C Df  D Ef  E   F Gf  G Af  A Bf  B);
# These are for converting note numbers to names, via, e.g., $Note[2]
# These must be a subset of the keys to %Note.

sub new
{
	my ($self,$class) = ({},shift);
	bless $self,$class;
	return $self;	
}


sub volumes_hash
{
	return \%Volume;	
}

sub lengths_hash
{
	return \%Length;	
}

sub notename_hash
{
	return \%Note;	
}

sub notename_to_number
{
	my ($self,$notename) = @_;
	my $notenames = $self->notename_hash;
	return $notenames->{$notename};		
}

sub notes
{
	return \@Note;	
}

sub notenumber_to_name
{
	my($self,$notenum) = @_;
	if($notenum > 11)
	{
		warn $notenum . "out of bounds! notes are numbered 0 to 11";	
		return;
	}
	
	my $notenames = $self->notename_hash;
	my %names = %$notenames;
	my %nums = reverse %names;
	return $nums{$notenum}; 
}

1;

=head1 NAME

POE::Framework::MIDI::Utility

=head1 SYNOPSIS

Utility functions

=head1 AUTHOR

	Steve McNabb
	CPAN ID: JUSTSOMEGUY
	steve@justsomeguy.com
	http://justsomeguy.com/code/POE/POE-Framework-MIDI 

=head1 COPYRIGHT

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut
