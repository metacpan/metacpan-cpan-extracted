package Mock::Person::EN;

use base qw(Exporter);
use strict;
use utf8;
use warnings;

use List::Util 1.33 qw(none);
use Readonly;

# Constants.
Readonly::Scalar our $SPACE => q{ };
Readonly::Array our @EXPORT_OK => qw(first_male first_female middle_female
	last_male last_female middle_male middle_female name name_male
	name_female);

# Variables.
our $TYPE = 'two';

our $VERSION = 0.05;

# First and middle male names.
our @first_male = our @middle_male = qw(
Aaron
Adam
Aidan
Alex
Alfie
Andrew
Anthony
Ashley
Ben
Bradley
Brandon
Callum
Calum
Cameron
Charlie
Chris
Connor
Conor
Craig
Curtis
Dan
Daniel
Danny
Darren
David
Declan
Dylan
Edward
Elliot
Ethan
George
Harrison
Harry
Henry
Jack
Jacob
Jake
James
Jamie
Jason
Jay
Joe
John
Jonathan
Jordan
Joseph
Josh
Joshua
Kane
Kieran
Kyle
Lee
Leon
Lewis
Liam
Louis
Luke
Marcus
Mark
Martin
Matt
Matthew
Max
Michael
Mike
Morgan
Nathan
Oli
Oliver
Ollie
Owen
Patrick
Paul
Peter
Philip
Reece
Rhys
Richard
Robbie
Robert
Ross
Ryan
Sam
Samuel
Scott
Sean
Sebastian
Shaun
Simon
Stephen
Steve
Steven
Stuart
Taylor
Thomas
Tom
Tyler
Utku
Will
William
);

# First and middle female names.
our @first_female = our @middle_female = qw(
Abbie
Abi
Aimee
Alex
Alice
Amber
Amelia
Amy
Anna
Annie
Ashleigh
Becca
Becky
Beth
Bethan
Bethany
Caitlin
Chantelle
Charley
Charlie
Charlotte
Chelsea
Chloe
Claire
Courtney
Daisy
Danielle
Eleanor
Elizabeth
Ella
Ellie
Emily
Emma
Erin
Francesca
Freya
Gemma
Georgia
Georgina
Grace
Hannah
Hayley
Heather
Helen
Holly
Jade
Jasmine
Jennifer
Jenny
Jess
Jessica
Jodie
Kate
Katherine
Katie
Katy
Kayleigh
Kelly
Kirsty
Laura
Leah
Leanne
Lily
Lisa
Louise
Lucy
Luren
Lydia
Megan
Melissa
Mia
Millie
Mollie
Molly
Naomi
Natalie
Natasha
Niamh
Nicola
Nicole
Olivia
Paige
Phoebe
Rachael
Rachel
Rebecca
Rhiannon
Robyn
Rose
Rosie
Samantha
Sara
Sarah
Sasha
Shannon
Sophie
Stacey
Stephanie
Victoria
Zoe
);

# Last names.
our @last_male = our @last_female = qw(
Abbey
Abel
Abney
Abraham
Abrahams
Abrahamson
Abram
Abrams
Abramson
Achilles
Acker
Ackerman
Adair
Adam
Adams
Adamson
Adcock
Addison
Adkins
Aiken
Ainsworth
Aitken
Akerman
Akers
Albert
Alberts
Albertson
Albinson
Alden
Alexander
Alfredson
Alfson
Alger
Allard
Allen
Allsopp
Alvey
Alvin
Anderson
Andrews
Andrewson
Ansel
Anson
Anthonyson
Appleby
Appleton
Archer
Arkwright
Armistead
Arnold
Arrington
Arterberry
Arterbury
Arthur
Arthurson
Ash
Ashley
Ashworth
Atkins
Atkinson
Attaway
Atteberry
Atterberry
Attwater
Audley
Augustine
Austin
Auteberry
Autenberry
Auttenberg
Averill
Avery
Ayers
Aylmer
Ayton
Babcock
Babcocke
Babcoke
Backus
Badcock
Badcocke
Badcoke
Bagley
Bailey
Baines
Baker
Baldwin
Bancroft
Banister
Banks
Banner
Bannerman
Barber
Bardsley
Barker
Barlow
Barnes
Barret
Barrett
Barton
Bartram
Bass
Bates
Bateson
Battle
Batts
Baxter
Beake
Beasley
Beattie
Beck
Becket
Beckett
Beckham
Belcher
Bell
Bellamy
Benbow
Benjaminson
Bennet
Bennett
Benson
Bentley
Benton
Bernard
Berry
Beverley
Beverly
Bird
Bishop
Black
Blackbourne
Blackburn
Blackman
Blackwood
Blake
Blakeslee
Bloodworth
Bloxam
Bloxham
Blue
Blythe
Boivin
Bolton
Bond
Bone
Bonham
Bonher
Bonner
Bonney
Boon
Boone
Booner
Boothman
Botwright
Bourke
Boyce
Braddock
Bradford
Bradley
Brams
Bramson
Brand
Brandon
Brant
Brasher
Brassington
Bray
Breckenridge
Breckinridge
Brent
Brewer
Brewster
Brigham
Bristol
Bristow
Britton
Broadbent
Brock
Brook
Brooke
Brooks
Brown
Brownlow
Bryan
Bryant
Bryson
Buckley
Bullard
Bulle
Bullock
Bunker
Burke
Burnham
Burns
Burrell
Burton
Bush
Butcher
Butler
Butts
Byrd
Cannon
Cantrell
Carl
Carlisle
Carlyle
Carman
Carpenter
Carter
Cartwright
Carver
Caulfield
Causer
Causey
Chadwick
Chamberlain
Chance
Chancellor
Chandler
Chapman
Chase
Cheshire
Christians
Christianson
Christinsen
Christison
Christopher
Christophers
Christopherson
Church
Clark
Clarke
Clarkson
Clay
Clayton
Clemens
Clifford
Clifton
Cline
Clinton
Close
Coburn
Cock
Cockburn
Cocks
Coel
Coke
Cokes
Colbert
Cole
Coleman
Collingwood
Collins
Colton
Combs
Comstock
Constable
Cook
Cooke
Cookson
Coombs
Cooper
Corey
Cornell
Corra
Cory
Cotterill
Courtenay
Courtney
Cowden
Cox
Crawford
Crewe
Croft
Cropper
Cross
Crouch
Cummins
Curtis
Dabney
Dalton
Dane
Danell
Daniel
Daniell
Daniels
Danielson
Dannel
Danniel
Danniell
Darby
Darrell
Darwin
Daubney
Daugherty
David
Davidson
Davies
Davis
Davison
Dawson
Day
Deadman
Dean
Dedrick
Deering
Delaney
Denman
Dennel
Dennell
Denzil
Derby
Derrick
Derricks
Derrickson
Devereux
Devin
Devine
Dexter
Dick
Dickens
Dickenson
Dickinson
Dickman
Dickson
Disney
Dixon
Donalds
Donaldson
Downer
Draper
Dudley
Duke
Dukes
Dunn
Durand
Durant
Dustin
Dwerryhouse
Dwight
Dyer
Dyson
Eads
Earl
Earls
Easom
Eason
Easton
Eaton
Eccleston
Ecclestone
Edgar
Edison
Edwards
Edwardson
Elder
Eldred
Eldridge
Eliot
Eliott
Ellery
Elliot
Elliott
Ellis
Ellison
Ellisson
Elliston
Ellsworth
Elmer
Elwin
Elwyn
Ely
Emerson
Emmet
Emmett
Endicott
English
Ericson
Espenson
Ethans
Eustis
Evanson
Evelyn
Evered
Everett
Everill
Ewart
Fabian
Fairbairn
Fairburn
Fairchild
Fairclough
Farnham
Faulkner
Fay
Fear
Fenn
Fields
Firmin
Fisher
Fishman
Fitzroy
Fleming
Fletcher
Ford
Forest
Forester
Forney
Forrest
Foss
Foster
Fox
Frank
Franklin
Franklyn
Freeman
Frost
Fry
Frye
Fuller
Gabriels
Gabrielson
Gardenar
Gardener
Gardiner
Gardner
Gardyner
Garey
Garfield
Garland
Garner
Garnet
Garnett
Garrard
Garret
Garrett
Garrod
Garry
Gary
Geary
Georgeson
Gibb
Gibbs
Gibson
Giffard
Gilbert
Giles
Gilliam
Gladwin
Gladwyn
Glover
Goddard
Godfrey
Goffe
Goode
Goodwin
Gorbold
Gore
Granger
Grant
Granville
Gray
Green
Greene
Gregory
Grenville
Grey
Griffin
Groves
Gully
Hackett
Hadaway
Haden
Haggard
Haight
Hailey
Hale
Haley
Hall
Hallman
Hambledon
Hambleton
Hameldon
Hamilton
Hamm
Hampson
Hampton
Hancock
Hanley
Hanson
Harden
Hardwick
Hardy
Harford
Hargrave
Harlan
Harland
Harley
Harlow
Harman
Harmon
Haroldson
Harper
Harrell
Harrelson
Harris
Harrison
Hart
Hartell
Harvey
Hathaway
Hatheway
Hathoway
Haward
Hawk
Hawking
Hawkins
Hayden
Hayes
Hayley
Hayward
Haywood
Head
Headley
Heath
Hedley
Henderson
Hendry
Henry
Henryson
Henson
Hepburn
Herbert
Herberts
Herbertson
Herman
Hermanson
Hewitt
Hext
Hibbert
Hicks
Hightower
Hill
Hillam
Hilton
Hobbes
Hobbs
Hobson
Hodges
Hodson
Hogarth
Hollands
Hollins
Holme
Holmes
Holmwood
Holt
Honeycutt
Honeysett
Hooker
Hooper
Hope
Hopkins
Hopper
Hopson
Horn
Horne
Horsfall
Horton
House
Howard
Howe
Howland
Howse
Huddleson
Huddleston
Hudnall
Hudson
Huff
Hughes
Hull
Hume
Hunnisett
Hunt
Hunter
Hurst
Hutson
Huxley
Huxtable
Hyland
Ianson
Ibbot
Ibbott
Ikin
Ilbert
Ingham
Ingram
Irvin
Irvine
Irving
Irwin
Isaacson
Ivers
Jack
Jackson
Jacobs
Jacobson
Jakeman
James
Jamison
Jans
Janson
Jardine
Jarrett
Jarvis
Jeanes
Jeffers
Jefferson
Jeffery
Jeffries
Jekyll
Jenkins
Jephson
Jepson
Jernigan
Jerome
Jervis
Jewel
Jewell
Jinks
Johns
Johnson
Joiner
Jones
Jordan
Josephs
Josephson
Joyner
Judd
Kay
Keen
Keighley
Kellogg
Kelsey
Kemp
Kendal
Kendall
Kendrick
Kennard
Kerry
Kersey
Kevins
Kevinson
Key
Keys
Kidd
Killam
Kimball
Kimberley
Kimberly
King
Kingsley
Kingston
Kipling
Kirby
Kitchen
Kitchens
Knaggs
Knight
Kynaston
Lacey
Lacy
Lamar
Landon
Lane
Langdon
Langley
Larson
Law
Lawrence
Lawson
Layton
Leach
Leavitt
Ledford
Lee
Leigh
Leighton
Leon
Leonardson
Levitt
Lewin
Lewis
Leyton
Lincoln
Lindon
Lindsay
Linton
Linwood
Little
Lockwood
Loman
London
Long
Longstaff
Lovel
Lovell
Low
Lowe
Lowell
Lowry
Lucas
Lukeson
Lum
Lund
Lyndon
Lynn
Lynton
Lynwood
Lyon
Macey
Macy
Maddison
Madison
Mallory
Mann
Marchand
Mark
Marley
Marlow
Marsden
Marshall
Marston
Martel
Martell
Martin
Martins
Martinson
Mason
Massey
Masters
Masterson
Mathers
Mathews
Mathewson
Matthews
Matthewson
May
Mayer
Mayes
Maynard
Meadows
Mercer
Merchant
Merrick
Merricks
Merrickson
Merrill
Merritt
Michael
Michaels
Michaelson
Midgley
Milburn
Miles
Milford
Miller
Millhouse
Mills
Milton
Mitchell
Monday
Mondy
Montgomery
Moore
Moores
Moors
Morce
Morison
Morris
Morrish
Morrison
Morriss
Morse
Moses
Mottershead
Mounce
Murgatroyd
Muttoone
Myers
Myles
Nathans
Nathanson
Nelson
Ness
Neville
Newell
Newman
Newport
Newton
Nichols
Nicholson
Nicolson
Nielson
Nigel
Niles
Nixon
Noel
Norman
Normanson
Norris
North
Northrop
Norwood
Nowell
Nye
Oakley
Odell
Ogden
Olhouser
Oliver
Oliverson
Olson
Osborne
Osbourne
Otis
Ott
Outlaw
Outterridge
Overton
Owston
Paddon
Padmore
Page
Paget
Paige
Palmer
Parent
Paris
Parish
Parker
Parris
Parsons
Paternoster
Paterson
Patrick
Patrickson
Patterson
Patton
Paulson
Payne
Payton
Peacock
Peak
Pearce
Pearson
Peck
Pelley
Pemberton
Penny
Perkins
Perry
Peter
Peters
Peterson
Petit
Pettigrew
Peyton
Philips
Phillips
Pickering
Pickle
Pierce
Pierson
Piper
Pitts
Plank
Plaskett
Platt
Pocock
Polley
Pond
Poole
Pope
Porcher
Porter
Potter
Pound
Power
Powers
Prescott
Pressley
Preston
Proudfoot
Pryor
Purcell
Putnam
Queen
Queshire
Quick
Quickley
Quigg
Quigley
Quincey
Quincy
Radcliff
Radclyffe
Raines
Rains
Rake
Rakes
Ramsey
Randal
Randall
Randell
Ray
Rayne
Raynerson
Read
Readdie
Ready
Reed
Reeve
Reier
Rennell
Rennold
Rennoll
Revie
Rey
Reynell
Reynolds
Rhodes
Rice
Richard
Richards
Richardson
Rickard
Rider
Ridley
Rier
Rigby
Riley
Rimmer
Roach
Robbins
Robert
Roberts
Robertson
Robinson
Roderick
Rogers
Rogerson
Rollins
Rome
Romilly
Roscoe
Rose
Ross
Rounds
Rowbottom
Rowe
Rowland
Rowntree
Roy
Royce
Royceston
Roydon
Royle
Royston
Ruggles
Rupertson
Rush
Ruskin
Russel
Russell
Ryder
Rye
Ryer
Ryers
Ryley
Sackville
Sadler
Salomon
Salvage
Sampson
Samson
Samuel
Samuels
Samuelson
Sanders
Sanderson
Sandford
Sands
Sanford
Sangster
Sappington
Sargent
Saunders
Sauvage
Savage
Savege
Savidge
Sawyer
Saylor
Scarlett
School
Scott
Scriven
Scrivener
Scrivenor
Scrivens
Seabrooke
Seaver
Selby
Sempers
Senior
Sergeant
Sessions
Seward
Sexton
Seymour
Shakesheave
Sharman
Sharrow
Shaw
Shelby
Shepard
Sherburne
Sherman
Shine
Sidney
Simmons
Simms
Simon
Simons
Simonson
Simpkin
Simpson
Sims
Sinclair
Skinner
Slater
Smalls
Smedley
Smith
Smythe
Snelling
Snider
Sniders
Snyder
Snyders
Southers
Southgate
Sowards
Spalding
Sparks
Spear
Spearing
Spears
Speight
Spence
Spencer
Spooner
Spurling
Stacey
Stack
Stacks
Stacy
Stafford
Stainthorpe
Stamp
Stanton
Stark
Starr
Statham
Steed
Steele
Steffen
Stenet
Stephens
Stephenson
Stern
Stevens
Stevenson
Stidolph
Stoddard
Stone
Strange
Street
Strickland
Stringer
Stroud
Strudwick
Studwick
Styles
Sudworth
Suggitt
Summerfield
Summers
Sumner
Sutton
Sweet
Swindlehurst
Sydney
Symons
Tailor
Tanner
Tash
Tasker
Tate
Tatham
Taylor
Teel
Tennison
Tennyson
Terrell
Terry
Thacker
Thatcher
Thomas
Thompsett
Thompson
Thomson
Thorburn
Thorn
Thorne
Thorpe
Thrussell
Thurstan
Thwaite
Tifft
Timberlake
Timothyson
Tinker
Tipton
Tirrell
Tittensor
Tobias
Tobin
Tod
Todd
Toft
Tolbert
Tollemache
Toller
Towner
Townsend
Tracey
Tracy
Traiylor
Trask
Travers
Traves
Travis
Traviss
Traylor
Treloar
Trengove
Trent
Trevis
Triggs
Trueman
Truman
Tucker
Tuff
Tuft
Tupper
Turnbull
Turner
Tyler
Tyrell
Tyrrell
Tyson
Underhill
Underwood
Upton
Vance
Vann
Varley
Varnham
Verity
Vernon
Victor
Victors
Victorson
Vincent
Vipond
Virgo
Wakefield
Walker
Wallace
Waller
Wallis
Walmsley
Walsh
Walter
Walterson
Walton
Ward
Wardrobe
Ware
Warner
Warren
Warrick
Warwick
Wash
Washington
Waterman
Waters
Watkins
Watson
Way
Wayne
Weaver
Webb
Webster
Weekes
Wells
Wembley
Wescott
Wesley
West
Westbrook
Westley
Wheeler
Wheelock
Whinery
Whitaker
White
Whitney
Whittemore
Whittle
Wickham
Wilbur
Wilcox
Wilkerson
Wilkie
Wilkins
Wilkinson
Willard
William
Williams
Williamson
Willis
Willoughby
Wilmer
Wilson
Winchester
Winfield
Winship
Winslow
Winston
Winter
Winterbottom
Winthrop
Winton
Witherspoon
Wolf
Wolfe
Womack
Wood
Woodcock
Woodham
Woodhams
Woods
Woodward
Wootton
Wortham
Wragge
Wray
Wright
Wyatt
Wyght
Wyman
Wyndham
Wynne
Yap
Yates
Yong
York
Young
Younge
Yoxall
);
push @last_male, 'St John', 'Van Middlesworth';
push @last_female, 'St John', 'Van Middlesworth';

# Get random first male name.
sub first_male {
	return $first_male[rand @first_male];
}

# Get random first female name.
sub first_female {
	return $first_female[rand @first_female];
}

# Get random last male name.
sub last_male {
	return $last_male[rand @last_male];
}

# Get random last female name.
sub last_female {
	return $last_female[rand @last_female];
}

# Get random middle male name.
sub middle_male {
	return $middle_male[rand @middle_male];
}

# Get random middle female name.
sub middle_female {
	return $middle_female[rand @middle_female];
}

# Get random name.
sub name {
	my $sex = shift;
	if (! defined $sex || none { $sex eq $_ } qw(female male)) {
		if ((int(rand(2)) + 1 ) % 2 == 0) {
			return name_male();
		} else {
			return name_female();
		}
	} elsif ($sex eq 'female') {
		return name_female();
	} elsif ($sex eq 'male') {
		return name_male();
	}
}

# Get random male name.
sub name_male {
	if (defined $TYPE && $TYPE eq 'three') {
		my $first_male = first_male();
		my $middle_male = middle_male();
		while ($first_male eq $middle_male) {
			$middle_male = middle_male();
		}
		return $first_male.$SPACE.$middle_male.$SPACE.last_male();
	} else {
		return first_male().$SPACE.last_male();
	}
}

# Get random female name.
sub name_female {
	if (defined $TYPE && $TYPE eq 'three') {
		my $first_female = first_female();
		my $middle_female = middle_female();
		while ($first_female eq $middle_female) {
			$middle_female = middle_female();
		}
		return $first_female.$SPACE.$middle_female.$SPACE.last_female();
	} else {
		return first_female().$SPACE.last_female();
	}
}

1;

__END__

=encoding UTF-8

=cut

=head1 NAME

Mock::Person::EN - Generate random sets of English names.

=head1 SYNOPSIS

 use Mock::Person::EN qw(first_male first_female last_male last_female
         middle_male middle_female name name_female name_male);

 my $first_male = first_male();
 my $first_female = first_female();
 my $last_male = last_male();
 my $last_female = last_female();
 my $middle_male = middle_male();
 my $middle_female = middle_female();
 my $name = name($sex);
 my $female_name = name_female();
 my $male_name = name_male();

=head1 DESCRIPTION

Data for this module was found on these pages:

=over

=item B<Last names>

L<surnames.behindthename.com|http://surnames.behindthename.com/names/usage/english>

=item B<Middle names>

There's usually no distinction between a first and middle name in England.

=item B<First names>

Woman: L<jmenaprijmeni.cz|http://www.jmenaprijmeni.cz/anglicka-jmena-zeny>
Man: L<jmenaprijmeni.cz|http://www.jmenaprijmeni.cz/anglicka-jmena-muzi>

=back

=head1 SUBROUTINES

=over 8

=item C<first_male()>

Returns random first name of male person.

=item C<first_female()>

Returns random first name of female person.

=item C<last_male()>

Returns random last name of male person.

=item C<last_female()>

Returns random last name of female person.

=item C<middle_male()>

Returns random middle name of male person.

=item C<middle_female()>

Returns random middle name of female person.

=item C<name([$sex])>

Recieves scalar with sex of the person ('male' or 'female') and returns
scalar with generated name.
Default value of $sex variable is undef, that means random name.

=item C<name_male()>

Returns random male name.

=item C<name_female()>

Returns random female name.

=back

=head1 VARIABLES

=over 8

=item C<TYPE>

 Name type.
 Possible values are: 'two', 'three'.
 Default value is 'two'.

=back

=head1 EXAMPLE1

=for comment filename=print_random_english_name.pl

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::EN qw(name);

 # Error.
 print encode_utf8(name())."\n";

 # Output like.
 # Mark Parent

=head1 EXAMPLE2

=for comment filename=print_random_english_name_with_middle.pl

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::EN qw(name);

 # Set output name to three names.
 $Mock::Person::EN::TYPE = 'three';

 # Error.
 print encode_utf8(name())."\n";

 # Output like.
 # Jack Ryan Hatheway

=head1 EXAMPLE3

=for comment filename=list_last_male_names.pl

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::EN;

 # Get all last male names.
 my @last_males = @Mock::Person::EN::last_male;

 # Print out.
 print sort map { encode_utf8($_)."\n" } @last_males;

 # Output:
 # Abbey
 # Abel
 # Abney
 # Abraham
 # Abrahams
 # Abrahamson
 # Abram
 # Abrams
 # Abramson
 # Achilles
 # Acker
 # Ackerman
 # Adair
 # Adam
 # Adams
 # Adamson
 # Adcock
 # Addison
 # Adkins
 # Aiken
 # Ainsworth
 # Aitken
 # Akerman
 # Akers
 # Albert
 # Alberts
 # Albertson
 # Albinson
 # Alden
 # Alexander
 # Alfredson
 # Alfson
 # Alger
 # Allard
 # Allen
 # Allsopp
 # Alvey
 # Alvin
 # Anderson
 # Andrews
 # Andrewson
 # Ansel
 # Anson
 # Anthonyson
 # Appleby
 # Appleton
 # Archer
 # Arkwright
 # Armistead
 # Arnold
 # Arrington
 # Arterberry
 # Arterbury
 # Arthur
 # Arthurson
 # Ash
 # Ashley
 # Ashworth
 # Atkins
 # Atkinson
 # Attaway
 # Atteberry
 # Atterberry
 # Attwater
 # Audley
 # Augustine
 # Austin
 # Auteberry
 # Autenberry
 # Auttenberg
 # Averill
 # Avery
 # Ayers
 # Aylmer
 # Ayton
 # Babcock
 # Babcocke
 # Babcoke
 # Backus
 # Badcock
 # Badcocke
 # Badcoke
 # Bagley
 # Bailey
 # Baines
 # Baker
 # Baldwin
 # Bancroft
 # Banister
 # Banks
 # Banner
 # Bannerman
 # Barber
 # Bardsley
 # Barker
 # Barlow
 # Barnes
 # Barret
 # Barrett
 # Barton
 # Bartram
 # Bass
 # Bates
 # Bateson
 # Battle
 # Batts
 # Baxter
 # Beake
 # Beasley
 # Beattie
 # Beck
 # Becket
 # Beckett
 # Beckham
 # Belcher
 # Bell
 # Bellamy
 # Benbow
 # Benjaminson
 # Bennet
 # Bennett
 # Benson
 # Bentley
 # Benton
 # Bernard
 # Berry
 # Beverley
 # Beverly
 # Bird
 # Bishop
 # Black
 # Blackbourne
 # Blackburn
 # Blackman
 # Blackwood
 # Blake
 # Blakeslee
 # Bloodworth
 # Bloxam
 # Bloxham
 # Blue
 # Blythe
 # Boivin
 # Bolton
 # Bond
 # Bone
 # Bonham
 # Bonher
 # Bonner
 # Bonney
 # Boon
 # Boone
 # Booner
 # Boothman
 # Botwright
 # Bourke
 # Boyce
 # Braddock
 # Bradford
 # Bradley
 # Brams
 # Bramson
 # Brand
 # Brandon
 # Brant
 # Brasher
 # Brassington
 # Bray
 # Breckenridge
 # Breckinridge
 # Brent
 # Brewer
 # Brewster
 # Brigham
 # Bristol
 # Bristow
 # Britton
 # Broadbent
 # Brock
 # Brook
 # Brooke
 # Brooks
 # Brown
 # Brownlow
 # Bryan
 # Bryant
 # Bryson
 # Buckley
 # Bullard
 # Bulle
 # Bullock
 # Bunker
 # Burke
 # Burnham
 # Burns
 # Burrell
 # Burton
 # Bush
 # Butcher
 # Butler
 # Butts
 # Byrd
 # Cannon
 # Cantrell
 # Carl
 # Carlisle
 # Carlyle
 # Carman
 # Carpenter
 # Carter
 # Cartwright
 # Carver
 # Caulfield
 # Causer
 # Causey
 # Chadwick
 # Chamberlain
 # Chance
 # Chancellor
 # Chandler
 # Chapman
 # Chase
 # Cheshire
 # Christians
 # Christianson
 # Christinsen
 # Christison
 # Christopher
 # Christophers
 # Christopherson
 # Church
 # Clark
 # Clarke
 # Clarkson
 # Clay
 # Clayton
 # Clemens
 # Clifford
 # Clifton
 # Cline
 # Clinton
 # Close
 # Coburn
 # Cock
 # Cockburn
 # Cocks
 # Coel
 # Coke
 # Cokes
 # Colbert
 # Cole
 # Coleman
 # Collingwood
 # Collins
 # Colton
 # Combs
 # Comstock
 # Constable
 # Cook
 # Cooke
 # Cookson
 # Coombs
 # Cooper
 # Corey
 # Cornell
 # Corra
 # Cory
 # Cotterill
 # Courtenay
 # Courtney
 # Cowden
 # Cox
 # Crawford
 # Crewe
 # Croft
 # Cropper
 # Cross
 # Crouch
 # Cummins
 # Curtis
 # Dabney
 # Dalton
 # Dane
 # Danell
 # Daniel
 # Daniell
 # Daniels
 # Danielson
 # Dannel
 # Danniel
 # Danniell
 # Darby
 # Darrell
 # Darwin
 # Daubney
 # Daugherty
 # David
 # Davidson
 # Davies
 # Davis
 # Davison
 # Dawson
 # Day
 # Deadman
 # Dean
 # Dedrick
 # Deering
 # Delaney
 # Denman
 # Dennel
 # Dennell
 # Denzil
 # Derby
 # Derrick
 # Derricks
 # Derrickson
 # Devereux
 # Devin
 # Devine
 # Dexter
 # Dick
 # Dickens
 # Dickenson
 # Dickinson
 # Dickman
 # Dickson
 # Disney
 # Dixon
 # Donalds
 # Donaldson
 # Downer
 # Draper
 # Dudley
 # Duke
 # Dukes
 # Dunn
 # Durand
 # Durant
 # Dustin
 # Dwerryhouse
 # Dwight
 # Dyer
 # Dyson
 # Eads
 # Earl
 # Earls
 # Easom
 # Eason
 # Easton
 # Eaton
 # Eccleston
 # Ecclestone
 # Edgar
 # Edison
 # Edwards
 # Edwardson
 # Elder
 # Eldred
 # Eldridge
 # Eliot
 # Eliott
 # Ellery
 # Elliot
 # Elliott
 # Ellis
 # Ellison
 # Ellisson
 # Elliston
 # Ellsworth
 # Elmer
 # Elwin
 # Elwyn
 # Ely
 # Emerson
 # Emmet
 # Emmett
 # Endicott
 # English
 # Ericson
 # Espenson
 # Ethans
 # Eustis
 # Evanson
 # Evelyn
 # Evered
 # Everett
 # Everill
 # Ewart
 # Fabian
 # Fairbairn
 # Fairburn
 # Fairchild
 # Fairclough
 # Farnham
 # Faulkner
 # Fay
 # Fear
 # Fenn
 # Fields
 # Firmin
 # Fisher
 # Fishman
 # Fitzroy
 # Fleming
 # Fletcher
 # Ford
 # Forest
 # Forester
 # Forney
 # Forrest
 # Foss
 # Foster
 # Fox
 # Frank
 # Franklin
 # Franklyn
 # Freeman
 # Frost
 # Fry
 # Frye
 # Fuller
 # Gabriels
 # Gabrielson
 # Gardenar
 # Gardener
 # Gardiner
 # Gardner
 # Gardyner
 # Garey
 # Garfield
 # Garland
 # Garner
 # Garnet
 # Garnett
 # Garrard
 # Garret
 # Garrett
 # Garrod
 # Garry
 # Gary
 # Geary
 # Georgeson
 # Gibb
 # Gibbs
 # Gibson
 # Giffard
 # Gilbert
 # Giles
 # Gilliam
 # Gladwin
 # Gladwyn
 # Glover
 # Goddard
 # Godfrey
 # Goffe
 # Goode
 # Goodwin
 # Gorbold
 # Gore
 # Granger
 # Grant
 # Granville
 # Gray
 # Green
 # Greene
 # Gregory
 # Grenville
 # Grey
 # Griffin
 # Groves
 # Gully
 # Hackett
 # Hadaway
 # Haden
 # Haggard
 # Haight
 # Hailey
 # Hale
 # Haley
 # Hall
 # Hallman
 # Hambledon
 # Hambleton
 # Hameldon
 # Hamilton
 # Hamm
 # Hampson
 # Hampton
 # Hancock
 # Hanley
 # Hanson
 # Harden
 # Hardwick
 # Hardy
 # Harford
 # Hargrave
 # Harlan
 # Harland
 # Harley
 # Harlow
 # Harman
 # Harmon
 # Haroldson
 # Harper
 # Harrell
 # Harrelson
 # Harris
 # Harrison
 # Hart
 # Hartell
 # Harvey
 # Hathaway
 # Hatheway
 # Hathoway
 # Haward
 # Hawk
 # Hawking
 # Hawkins
 # Hayden
 # Hayes
 # Hayley
 # Hayward
 # Haywood
 # Head
 # Headley
 # Heath
 # Hedley
 # Henderson
 # Hendry
 # Henry
 # Henryson
 # Henson
 # Hepburn
 # Herbert
 # Herberts
 # Herbertson
 # Herman
 # Hermanson
 # Hewitt
 # Hext
 # Hibbert
 # Hicks
 # Hightower
 # Hill
 # Hillam
 # Hilton
 # Hobbes
 # Hobbs
 # Hobson
 # Hodges
 # Hodson
 # Hogarth
 # Hollands
 # Hollins
 # Holme
 # Holmes
 # Holmwood
 # Holt
 # Honeycutt
 # Honeysett
 # Hooker
 # Hooper
 # Hope
 # Hopkins
 # Hopper
 # Hopson
 # Horn
 # Horne
 # Horsfall
 # Horton
 # House
 # Howard
 # Howe
 # Howland
 # Howse
 # Huddleson
 # Huddleston
 # Hudnall
 # Hudson
 # Huff
 # Hughes
 # Hull
 # Hume
 # Hunnisett
 # Hunt
 # Hunter
 # Hurst
 # Hutson
 # Huxley
 # Huxtable
 # Hyland
 # Ianson
 # Ibbot
 # Ibbott
 # Ikin
 # Ilbert
 # Ingham
 # Ingram
 # Irvin
 # Irvine
 # Irving
 # Irwin
 # Isaacson
 # Ivers
 # Jack
 # Jackson
 # Jacobs
 # Jacobson
 # Jakeman
 # James
 # Jamison
 # Jans
 # Janson
 # Jardine
 # Jarrett
 # Jarvis
 # Jeanes
 # Jeffers
 # Jefferson
 # Jeffery
 # Jeffries
 # Jekyll
 # Jenkins
 # Jephson
 # Jepson
 # Jernigan
 # Jerome
 # Jervis
 # Jewel
 # Jewell
 # Jinks
 # Johns
 # Johnson
 # Joiner
 # Jones
 # Jordan
 # Josephs
 # Josephson
 # Joyner
 # Judd
 # Kay
 # Keen
 # Keighley
 # Kellogg
 # Kelsey
 # Kemp
 # Kendal
 # Kendall
 # Kendrick
 # Kennard
 # Kerry
 # Kersey
 # Kevins
 # Kevinson
 # Key
 # Keys
 # Kidd
 # Killam
 # Kimball
 # Kimberley
 # Kimberly
 # King
 # Kingsley
 # Kingston
 # Kipling
 # Kirby
 # Kitchen
 # Kitchens
 # Knaggs
 # Knight
 # Kynaston
 # Lacey
 # Lacy
 # Lamar
 # Landon
 # Lane
 # Langdon
 # Langley
 # Larson
 # Law
 # Lawrence
 # Lawson
 # Layton
 # Leach
 # Leavitt
 # Ledford
 # Lee
 # Leigh
 # Leighton
 # Leon
 # Leonardson
 # Levitt
 # Lewin
 # Lewis
 # Leyton
 # Lincoln
 # Lindon
 # Lindsay
 # Linton
 # Linwood
 # Little
 # Lockwood
 # Loman
 # London
 # Long
 # Longstaff
 # Lovel
 # Lovell
 # Low
 # Lowe
 # Lowell
 # Lowry
 # Lucas
 # Lukeson
 # Lum
 # Lund
 # Lyndon
 # Lynn
 # Lynton
 # Lynwood
 # Lyon
 # Macey
 # Macy
 # Maddison
 # Madison
 # Mallory
 # Mann
 # Marchand
 # Mark
 # Marley
 # Marlow
 # Marsden
 # Marshall
 # Marston
 # Martel
 # Martell
 # Martin
 # Martins
 # Martinson
 # Mason
 # Massey
 # Masters
 # Masterson
 # Mathers
 # Mathews
 # Mathewson
 # Matthews
 # Matthewson
 # May
 # Mayer
 # Mayes
 # Maynard
 # Meadows
 # Mercer
 # Merchant
 # Merrick
 # Merricks
 # Merrickson
 # Merrill
 # Merritt
 # Michael
 # Michaels
 # Michaelson
 # Midgley
 # Milburn
 # Miles
 # Milford
 # Miller
 # Millhouse
 # Mills
 # Milton
 # Mitchell
 # Monday
 # Mondy
 # Montgomery
 # Moore
 # Moores
 # Moors
 # Morce
 # Morison
 # Morris
 # Morrish
 # Morrison
 # Morriss
 # Morse
 # Moses
 # Mottershead
 # Mounce
 # Murgatroyd
 # Muttoone
 # Myers
 # Myles
 # Nathans
 # Nathanson
 # Nelson
 # Ness
 # Neville
 # Newell
 # Newman
 # Newport
 # Newton
 # Nichols
 # Nicholson
 # Nicolson
 # Nielson
 # Nigel
 # Niles
 # Nixon
 # Noel
 # Norman
 # Normanson
 # Norris
 # North
 # Northrop
 # Norwood
 # Nowell
 # Nye
 # Oakley
 # Odell
 # Ogden
 # Olhouser
 # Oliver
 # Oliverson
 # Olson
 # Osborne
 # Osbourne
 # Otis
 # Ott
 # Outlaw
 # Outterridge
 # Overton
 # Owston
 # Paddon
 # Padmore
 # Page
 # Paget
 # Paige
 # Palmer
 # Parent
 # Paris
 # Parish
 # Parker
 # Parris
 # Parsons
 # Paternoster
 # Paterson
 # Patrick
 # Patrickson
 # Patterson
 # Patton
 # Paulson
 # Payne
 # Payton
 # Peacock
 # Peak
 # Pearce
 # Pearson
 # Peck
 # Pelley
 # Pemberton
 # Penny
 # Perkins
 # Perry
 # Peter
 # Peters
 # Peterson
 # Petit
 # Pettigrew
 # Peyton
 # Philips
 # Phillips
 # Pickering
 # Pickle
 # Pierce
 # Pierson
 # Piper
 # Pitts
 # Plank
 # Plaskett
 # Platt
 # Pocock
 # Polley
 # Pond
 # Poole
 # Pope
 # Porcher
 # Porter
 # Potter
 # Pound
 # Power
 # Powers
 # Prescott
 # Pressley
 # Preston
 # Proudfoot
 # Pryor
 # Purcell
 # Putnam
 # Queen
 # Queshire
 # Quick
 # Quickley
 # Quigg
 # Quigley
 # Quincey
 # Quincy
 # Radcliff
 # Radclyffe
 # Raines
 # Rains
 # Rake
 # Rakes
 # Ramsey
 # Randal
 # Randall
 # Randell
 # Ray
 # Rayne
 # Raynerson
 # Read
 # Readdie
 # Ready
 # Reed
 # Reeve
 # Reier
 # Rennell
 # Rennold
 # Rennoll
 # Revie
 # Rey
 # Reynell
 # Reynolds
 # Rhodes
 # Rice
 # Richard
 # Richards
 # Richardson
 # Rickard
 # Rider
 # Ridley
 # Rier
 # Rigby
 # Riley
 # Rimmer
 # Roach
 # Robbins
 # Robert
 # Roberts
 # Robertson
 # Robinson
 # Roderick
 # Rogers
 # Rogerson
 # Rollins
 # Rome
 # Romilly
 # Roscoe
 # Rose
 # Ross
 # Rounds
 # Rowbottom
 # Rowe
 # Rowland
 # Rowntree
 # Roy
 # Royce
 # Royceston
 # Roydon
 # Royle
 # Royston
 # Ruggles
 # Rupertson
 # Rush
 # Ruskin
 # Russel
 # Russell
 # Ryder
 # Rye
 # Ryer
 # Ryers
 # Ryley
 # Sackville
 # Sadler
 # Salomon
 # Salvage
 # Sampson
 # Samson
 # Samuel
 # Samuels
 # Samuelson
 # Sanders
 # Sanderson
 # Sandford
 # Sands
 # Sanford
 # Sangster
 # Sappington
 # Sargent
 # Saunders
 # Sauvage
 # Savage
 # Savege
 # Savidge
 # Sawyer
 # Saylor
 # Scarlett
 # School
 # Scott
 # Scriven
 # Scrivener
 # Scrivenor
 # Scrivens
 # Seabrooke
 # Seaver
 # Selby
 # Sempers
 # Senior
 # Sergeant
 # Sessions
 # Seward
 # Sexton
 # Seymour
 # Shakesheave
 # Sharman
 # Sharrow
 # Shaw
 # Shelby
 # Shepard
 # Sherburne
 # Sherman
 # Shine
 # Sidney
 # Simmons
 # Simms
 # Simon
 # Simons
 # Simonson
 # Simpkin
 # Simpson
 # Sims
 # Sinclair
 # Skinner
 # Slater
 # Smalls
 # Smedley
 # Smith
 # Smythe
 # Snelling
 # Snider
 # Sniders
 # Snyder
 # Snyders
 # Southers
 # Southgate
 # Sowards
 # Spalding
 # Sparks
 # Spear
 # Spearing
 # Spears
 # Speight
 # Spence
 # Spencer
 # Spooner
 # Spurling
 # St John
 # Stacey
 # Stack
 # Stacks
 # Stacy
 # Stafford
 # Stainthorpe
 # Stamp
 # Stanton
 # Stark
 # Starr
 # Statham
 # Steed
 # Steele
 # Steffen
 # Stenet
 # Stephens
 # Stephenson
 # Stern
 # Stevens
 # Stevenson
 # Stidolph
 # Stoddard
 # Stone
 # Strange
 # Street
 # Strickland
 # Stringer
 # Stroud
 # Strudwick
 # Studwick
 # Styles
 # Sudworth
 # Suggitt
 # Summerfield
 # Summers
 # Sumner
 # Sutton
 # Sweet
 # Swindlehurst
 # Sydney
 # Symons
 # Tailor
 # Tanner
 # Tash
 # Tasker
 # Tate
 # Tatham
 # Taylor
 # Teel
 # Tennison
 # Tennyson
 # Terrell
 # Terry
 # Thacker
 # Thatcher
 # Thomas
 # Thompsett
 # Thompson
 # Thomson
 # Thorburn
 # Thorn
 # Thorne
 # Thorpe
 # Thrussell
 # Thurstan
 # Thwaite
 # Tifft
 # Timberlake
 # Timothyson
 # Tinker
 # Tipton
 # Tirrell
 # Tittensor
 # Tobias
 # Tobin
 # Tod
 # Todd
 # Toft
 # Tolbert
 # Tollemache
 # Toller
 # Towner
 # Townsend
 # Tracey
 # Tracy
 # Traiylor
 # Trask
 # Travers
 # Traves
 # Travis
 # Traviss
 # Traylor
 # Treloar
 # Trengove
 # Trent
 # Trevis
 # Triggs
 # Trueman
 # Truman
 # Tucker
 # Tuff
 # Tuft
 # Tupper
 # Turnbull
 # Turner
 # Tyler
 # Tyrell
 # Tyrrell
 # Tyson
 # Underhill
 # Underwood
 # Upton
 # Van Middlesworth
 # Vance
 # Vann
 # Varley
 # Varnham
 # Verity
 # Vernon
 # Victor
 # Victors
 # Victorson
 # Vincent
 # Vipond
 # Virgo
 # Wakefield
 # Walker
 # Wallace
 # Waller
 # Wallis
 # Walmsley
 # Walsh
 # Walter
 # Walterson
 # Walton
 # Ward
 # Wardrobe
 # Ware
 # Warner
 # Warren
 # Warrick
 # Warwick
 # Wash
 # Washington
 # Waterman
 # Waters
 # Watkins
 # Watson
 # Way
 # Wayne
 # Weaver
 # Webb
 # Webster
 # Weekes
 # Wells
 # Wembley
 # Wescott
 # Wesley
 # West
 # Westbrook
 # Westley
 # Wheeler
 # Wheelock
 # Whinery
 # Whitaker
 # White
 # Whitney
 # Whittemore
 # Whittle
 # Wickham
 # Wilbur
 # Wilcox
 # Wilkerson
 # Wilkie
 # Wilkins
 # Wilkinson
 # Willard
 # William
 # Williams
 # Williamson
 # Willis
 # Willoughby
 # Wilmer
 # Wilson
 # Winchester
 # Winfield
 # Winship
 # Winslow
 # Winston
 # Winter
 # Winterbottom
 # Winthrop
 # Winton
 # Witherspoon
 # Wolf
 # Wolfe
 # Womack
 # Wood
 # Woodcock
 # Woodham
 # Woodhams
 # Woods
 # Woodward
 # Wootton
 # Wortham
 # Wragge
 # Wray
 # Wright
 # Wyatt
 # Wyght
 # Wyman
 # Wyndham
 # Wynne
 # Yap
 # Yates
 # Yong
 # York
 # Young
 # Younge
 # Yoxall

=head1 DEPENDENCIES

L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Mock::Person>

Install the Mock::Person modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mock-Person-EN>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2013-2023

BSD 2-Clause License

=head1 VERSION

0.05

=cut
