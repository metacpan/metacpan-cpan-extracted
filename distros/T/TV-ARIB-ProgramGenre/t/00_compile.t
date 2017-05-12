use strict;
use Test::More;

use_ok $_ for qw(
    TV::ARIB::ProgramGenre
    TV::ARIB::ProgramGenre::ChildGenre
    TV::ARIB::ProgramGenre::ChildGenre::Anime
    TV::ARIB::ProgramGenre::ChildGenre::Documentary
    TV::ARIB::ProgramGenre::ChildGenre::Drama
    TV::ARIB::ProgramGenre::ChildGenre::Expansion
    TV::ARIB::ProgramGenre::ChildGenre::Hobby
    TV::ARIB::ProgramGenre::ChildGenre::Info
    TV::ARIB::ProgramGenre::ChildGenre::Movie
    TV::ARIB::ProgramGenre::ChildGenre::Music
    TV::ARIB::ProgramGenre::ChildGenre::News
    TV::ARIB::ProgramGenre::ChildGenre::Other
    TV::ARIB::ProgramGenre::ChildGenre::Reserve
    TV::ARIB::ProgramGenre::ChildGenre::Sport
    TV::ARIB::ProgramGenre::ChildGenre::Theater
    TV::ARIB::ProgramGenre::ChildGenre::Variety
    TV::ARIB::ProgramGenre::ChildGenre::Welfare
);

done_testing;

