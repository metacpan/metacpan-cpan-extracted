package Parser::AAMVA::License;

$VERSION = "0.55";
use strict;
use warnings;
use Carp;

=head1 NAME
Parser::AAMVA::License - AAMVA Driver's License Magnetic Stripe Parser
=cut

my @track1fields = ( 'state', 'city', 'name', 'address' );

my @track2fields = ( 'id', 'license', 'exyy', 'exmm', 'bcc', 'byy', 'bmm', 'bdd', 'dlx' );

my @track3fields = ('cdsversion',   'jdversion',    'postalcode', 'dlclass',
					'restrictions', 'endorsements', 'sex',        'height',
					'weight',       'haircolor',    'eyecolor',   'did'
					);

my $exyear; 
my $dim;

sub haircolor
{
	# Hair Color per Ansi D20
	my $self = shift;
	my %hc   = (
		'BAL' => 'Bald',
		'BLK' => 'Black',
		'BLN' => 'Blond',
		'BRO' => 'Brown',
		'GRY' => 'Grey',
		'RED' => 'Red/Auburn',
		'SDY' => 'Sandy',
		'WHI' => 'White',
		'UNK' => 'Unknown'
	);
	return $hc{ $self->{'haircolor'} };
}

sub monthdays
{
	my $year  = shift;
	my $month = shift;
	 
	if ( $month == 4 || $month == 6 || $month == 9 || $month == 11 )
	{
		return 30;
	}
	if ( $month == 2 )
	{
		if ( ( $year / 4 ) == int( $year / 4 ) )
		{
			return 29;
		}
		else
		{
			return 28;
		}
	}
	return 31;
}

sub parse_magstripe
{
	my $self = shift;
	my $i;
	my @results;
	my $n;
	
	if ( $self->{'track1'})
	{
	 @results = ( $self->{'track1'} =~ m/^\%?([A-Z]{2})([^\^]{1,13})\^?([^\^]{1,35})\^?([^\^]+)\^?\?/i );
	
 	 for ( $i = 0 ; $i < scalar @track1fields ; $i++ )
	 {
	  $self->{ $track1fields[$i] } = $results[$i];
	 }
	
	 ( $self->{'lname'}, $self->{'fname'}, $self->{'middle'} ) =	split( /\$/, $self->{'name'} );
	
	 ( $self->{'address1'}, $self->{'address2'} ) = split(/\$/,$self->{'address'});
	 
	 foreach $n ('lname','fname','middle','address1','address2')
	 {
	 	$self->{$n}=stripblanks($self->{$n});
	 }
	}
	else
	{carp "Track one is empty";}
	
	if ( $self->{'track2'})
	{	
	 @results = ( $self->{'track2'} =~ m/;?(6[0-9]{5})([0-9]+)=([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([^=]{0,5})=\??/i );

	 for ( $i = 0 ; $i < scalar @track2fields ; $i++ )
	 {
	  $self->{ $track2fields[$i] } = $results[$i];
	 }
	 $self->{'license'} .= $self->{'dlx'};
	 $self->{'birthyear'}=$self->{'bcc'}.$self->{'byy'};
	 $self->{'birthmonth'}=$self->{'bmm'};	 
	 $self->{'birthday'}=$self->{'bdd'};	 	 
     $self->{'birthdate'}=sprintf('%4d-%02d-%02d',$self->{'birthyear'},$self->{'birthmonth'},$self->{'birthday'});
	
	 $exyear=2000+($self->{'exyy'}+1);
	
	 $dim = monthdays($exyear, $self->{'bmm'});
	
	 if ($self->{'exmm'}==88)
	 {
	  $self->{'expdate'}=sprintf('%4d-%02d-%02d',$exyear,$self->{'bmm'},$dim);
     }	
	 else
 	 {
 	  $self->{'expdate'}=sprintf('%4d-%02d-%02d',$self->{'exyy'}+2000,$self->{'exmm'},$dim);
 	 }	 
	}
	
	if ( $self->{'track3'})
	{
	 @results = ( $self->{'track3'} =~ m/%?([0-9]{1})([0-9]{1})([A-Z0-9 ]{11})([A-Z0-9 ]{2})([A-Z0-9 ]{10})([A-Z0-9 ]{4})([1-2]{1})([0-9]{3})([0-9]{3})([A-Z ]{3})([A-Z ]{3})(.*)\?/i  );
	  
	 for ( $i = 0 ; $i < scalar @track3fields ; $i++ )
	 {
 		$self->{ $track3fields[$i] } = $results[$i];
 	 }
    }	
}

sub stripblanks
{
 my $s=shift;
 if ($s)
 {$s=~s/ +$//;
  $s=~s/^ +//;
 }
 return $s;
}


sub loadtrack
{
 my $self=shift;
 my $trackno=shift;
 my $track=shift;
 
 $track =~ s/\r|\n//gs;
 $self->{"track$trackno"}=$track;
}

my %jids=(
		636033=>'Alabama',
		636059=>'Alaska',
		604427=>'American Samoa',
		636026=>'Arizona',
		636021=>'Arkansas',
		636014=>'California',
		636020=>'Colorado',
		636006=>'Connecticut',
		636011=>'Delaware',
		636043=>'District of Columbia',
		636010=>'Florida',
		636055=>'Georgia',
		636019=>'Guam',
		636047=>'Hawaii',
		636050=>'Idaho',
		636035=>'Illinois',
		636037=>'Indiana',
		636018=>'Iowa',
		636022=>'Kansas',
		636046=>'Kentucky',
		636007=>'Louisiana',
		636041=>'Maine',
		636003=>'Maryland',
		636002=>'Massachusetts',
		636032=>'Michigan',
		636038=>'Minnesota',
		636051=>'Mississippi',
		636030=>'Missouri',
		636008=>'Montana',
		636054=>'Nebraska',
		636049=>'Nevada',
		636039=>'New Hampshire',
		636036=>'New Jersey',
		636009=>'New Mexico',
		636001=>'New York',
		636004=>'North Carolina',
		636034=>'North Dakota',
		636023=>'Ohio',
		636058=>'Oklahoma',
		636029=>'Oregon',
		636025=>'Pennsylvania',
		636052=>'Rhode Island',
		636005=>'South Carolina',
		636042=>'South Dakota',
		636027=>'State Dept(USA)',
		636053=>'Tennessee',
		636015=>'Texas',
		636062=>'US Virgin Islands',
		636040=>'Utah',
		636024=>'Vermont',
		636000=>'Virginia',
		636045=>'Washington',
		636061=>'West Virginia',
		636031=>'Wisconsin',
		636060=>'Wyoming',
		636028=>'British Columbia',
		636048=>'Manitoba',
		636012=>'Ontario',
		636017=>'New Brunswick',
		636016=>'Newfoundland',
		636013=>'Nova Scotia',
		604426=>'Prince Edward Island',
		604428=>'Quebec',
		636044=>'Saskatchewan',
		604429=>'Yukon',
		636056=>'Coahuila',
		636057=>'Hidalgo '
);

sub country
{
 my $self=shift;
 return $jids{$self->{'id'}};
}

my %country=(
			636033=>'USA',
			636059=>'USA',
			604427=>'USA',
			636026=>'USA',
			636021=>'USA',
			636014=>'USA',
			636020=>'USA',
			636006=>'USA',
			636011=>'USA',
			636043=>'USA',
			636010=>'USA',
			636055=>'USA',
			636019=>'USA',
			636047=>'USA',
			636050=>'USA',
			636035=>'USA',
			636037=>'USA',
			636018=>'USA',
			636022=>'USA',
			636046=>'USA',
			636007=>'USA',
			636041=>'USA',
			636003=>'USA',
			636002=>'USA',
			636032=>'USA',
			636038=>'USA',
			636051=>'USA',
			636030=>'USA',
			636008=>'USA',
			636054=>'USA',
			636049=>'USA',
			636039=>'USA',
			636036=>'USA',
			636009=>'USA',
			636001=>'USA',
			636004=>'USA',
			636034=>'USA',
			636023=>'USA',
			636058=>'USA',
			636029=>'USA',
			636025=>'USA',
			636052=>'USA',
			636005=>'USA',
			636042=>'USA',
			636027=>'USA',
			636053=>'USA',
			636062=>'USA',
			636040=>'USA',
			636024=>'USA',
			636000=>'USA',
			636045=>'USA',
			636061=>'USA',
			636031=>'USA',
			636060=>'USA',
			636028=>'CAN',
			636048=>'CAN',
			636012=>'CAN',
			636017=>'CAN',
			636016=>'CAN',
			636013=>'CAN',
			604426=>'CAN',
			604428=>'CAN',
			636044=>'CAN',
			604429=>'CAN',
			636056=>'MEX',
			636057=>'MEX'
);

sub new 
{
 my $that = shift;
 my $class = ref($that) || $that;
 my $self = {
 			track1=>undef,
 			track2=>undef,
 			track3=>undef
 };
 bless $self, $class;
 return $self;
};

1;

=head1 DESCRIPTION

License is a parser/decoder for the American Association of Motor Vehicle Administrators(AAMVA) format that is used to encode the magnetic stripe found on Driver's Licenses in the US and Canada. Most data is available both in its raw and decoded form. You should refer to the latest specification at
www.aamva.org for details on the field contents. Starting and ending sentinals in the track data are optional.

Load the tracks you have available, only track 1 is mandatory. Not all magnetic stripe readers can read track 3.

=head1 SYNOPSIS

	$track1='%ORSPRINGFIELD ^ SIMPSON $HOMER$J ^ 742 EVERGREEN TERR ^?';	# % and ? are sentinals. 
	$track2 =';6360291234567890123=180119550512=?';   					# ; and ? are sentinals.
	
	$p = new Parse::AAMVA::License;
	
	$p->loadtrack( 1, $track1 );
	$p->loadtrack( 2, $track2 );
	$p->loadtrack( 3, $track3 );
	
	$p->parse_magstripe;

=head1 FIELDS

 	Field Name		AAMVA Field #			Track
  	
 	state			State/Province 2 		1 
 	city			City Name 3			1 
	fname 			First Name 4  			1 
	lname 			Last Name 4  			1 
	middle 			Middle Name 4  			1 
 	address1 		Address Line 1 5  		1 
 	address2 		Address Line 2 5  		1 
 	id			ISO Id 2			2 
 	license 		License Number 3/7 		2 Includes overflow from field 7 
 	expdate 		Expiration 5 			2 YYYY-MM-DD (1) 
 	birthdate 		Birth Date 6 			2 YYYY-MM-DD 
 	cdsversion 		CDS Version 2 			3 
 	jdversion 		Juris. Version 3 		3 
 	postalcode 		Postal/Zip Code 4 		3 
 	dlclass 		License Class 5 		3 
 	restrictions		Lic. Restrictions 6 		3 
 	endorsements		Lic. Endorsements 7 		3 
 	sex 			Sex 1=Male, 2=Female 8 		3 
 	height 			Height in in. or cm. 9 		3 (2) 
 	weight 			Weight in lbs or kg. 10 	3 (2) 
 	haircolor 		Hair Color 11 			3 (3) 
 	eyecolor 		Eye Color 12 			3 
 	did 			Optionally defined by
 					jurisdiction 13,14,15 	3

(1). If expiration date year is 2077, license never expires.
Otherwise, this field represents the last valid date.

(2). Height is in inches or cm depending on country.
Weight is in pounds or kg. Call the country method
to determine country of origin: USA, MEX or CAN.

(3). This the raw hair color, e.g. BRO. For a description,
call the haircolor method.

=head1 METHODS

=over 12

=item $p->loadtrack(tracknumber,string);

 Load the magnetic stripe track

=item $p->parse_magstripe

 Parse loaded magstripe data. Returns null.
 
=item $p->country

Attempts to determine country of origin from the ISO ID. Returns CAN, MEX or USA.
 
=item $p->haircolor

 Returns the ANSI D20 hair color definition
 BAL Bald
 BLK Black
 BLN Blond
 BRO Brown
 GRY Grey
 RED Red/Auburn
 SDY Sandy
 WHI White
 UNK Unknown
 
=back

=head1 ACCESSING FIELDS

 Decoded fields are accessed directly via an anonymous hash:
 Ex. print $p->{license};

=head1 EXAMPLE

 $p=new Parse:AAMVA:License;
 $p->loadtrack(1,$track1);
 $p->loadtrack(2,$track2);
 $p->loadtrack(3,$track3);
 $p->parse_magstripe;

 print "Name: ".$p->{fname}.' '.$p->{lname};
 print "Birth Date: ".$p->{birthdate};

=head1 AUTHOR
Curt Evans, C<< <bitflurry at gmail.com> >>

=head1 COPYRIGHT

Copyright Curt Evans, 2014.
This program is free software; you can redistribute it and/or
modify it under the terms of either:
a) the GNU General Public License;
either version 2 of the License, or (at your option) any later
version. You should have received a copy of the GNU General
Public License along with this program; see the file COPYING.
If not, write to the Free Software Foundation, Inc., 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA
b) the Perl Artistic License.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
=cut
