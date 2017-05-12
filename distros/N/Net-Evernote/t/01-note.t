use strict;
use warnings;
use Test::More qw(no_plan);
use FindBin;
use lib $FindBin::Bin;
use Net::Evernote;
use DateTime;


use Common qw(:DEFAULT $config);

my $evernote = Net::Evernote->new({
    authentication_token => $$config{'authentication_token'},
    use_sandbox => 1,
});

my $note_title = 'test title';
my $note_tags  = [qw(evernote-perl-api-test-tag-1 evernote-perl-api-test-tag-2)];

# let's throw a date in there:
my $dt = DateTime->new(
    year   => 1981,
    month  => 4,
    day    => 4,
    hour   => 13,
    minute => 30,
    time_zone => 'EST'
);

my $epoch_time  = $dt->epoch;

my $note = $evernote->createNote({
    title     => $note_title,
    content   => 'here is some test content',
    tag_names => $note_tags,
    created   => $epoch_time*1000,
});

my $guid = $note->guid;

my $new_note = $evernote->getNote({
    guid => $guid,
});

ok($guid eq $new_note->guid, 'New note successfully retrieved');

# FIXME: content returns with markup so not testing that here
ok($note_title eq $new_note->title, 'Title of new note successfully retrieved');

ok($new_note->active == 1, 'Note is active');

my $tags = $new_note->tagNames;
ok(@$tags ~~ @$note_tags, "Tags look good");

# delete the test note
$evernote->deleteNote({
    guid => $guid
});

my $deleted_note = $evernote->getNote({
    guid => $guid,
});

ok($deleted_note->deleted ne '', "Note deleted");
ok($deleted_note->active != 1, "Note is no longer active");

# Hmmm...what to do with the tags? I don't want to accidentally delete a tag from someone's
# Evernote account that previously existed. Maybe a huge random tag or something?
