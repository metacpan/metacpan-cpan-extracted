package Parse::AFP::MCF1::DataGroup;
use base 'Parse::AFP::Base';

use constant FORMAT => (
    CodedFontLocalId		=> 'C',
    _				=> 'a',
    CodedFontResourceSectionId	=> 'C',
    _				=> 'a',
    CodedFontName		=> 'a8',
    CodePageName		=> 'a8',
    FontCharacterSetName	=> 'a8',
    CharacterRotation		=> 'n',
);
use constant ENCODED_FIELDS => ('CodedFontName');
use constant ENCODING => 'cp500';

1;
