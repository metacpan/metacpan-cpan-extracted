use strict;
use warnings;
use Test::More qw(no_plan);

use FindBin;
use lib $FindBin::Bin;
use Net::Evernote;

use Common qw(:DEFAULT $config);

my $evernote = Net::Evernote->new({
    authentication_token => $$config{'authentication_token'},
    use_sandbox => 1,
});

my $tag_name = 'test tag-' . time;
my ($tagGuid, $note_guid);

# create a tag
{
    my $tag = $evernote->createTag({'name' => $tag_name });
    ok($tag->name eq $tag_name, "Tag name retrieved");
    $tagGuid = $tag->guid;
    isnt($tagGuid, '', "Tag has GUID (${tagGuid})");
}

# create a note and apply the tag
{
    my $note = $evernote->createNote({
        title     => 'tag tester',
        content   => 'tag test content',
        tag_guids => [$tagGuid],
    });

    $note_guid = $note->guid;
}

# retrieve the tag and it's notes
{
    my $tag = $evernote->getTag({
        guid => $tagGuid, 
    });

    is($tag->guid, $tagGuid, "Tag retrieved by GUID (${tagGuid})");

    my $note = $evernote->getNote({
        guid => $note_guid,
    });

    my $tagGuids = $note->tagGuids;

    # only set one...check that
    my $firstTagGuid = $$tagGuids[0];
    is($firstTagGuid, $tagGuid, "Tag successfully attached to note");

    # delete tag and note
    my $deleted_note = $note->delete;
    my $deleted = $tag->delete;

    ok(!!$deleted, "Tag deleted");

   my $deleted_tag = $evernote->getTag({ guid => $tagGuid });
   is($deleted_tag, undef, "Tag not retrieved after deletion");
}


