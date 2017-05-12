package Pod::Weaver::Section::TestSectionReplacer;

use Moose;
with 'Pod::Weaver::Role::SectionReplacer';

sub default_section_name { 'TEST SECTION' }
sub default_section_aliases { [ 'TEST SECTION ALIAS' ] }

no Moose;
1;
