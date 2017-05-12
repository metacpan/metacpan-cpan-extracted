use strict;
use warnings;

use Test::More qw(no_plan);
use Net::Evernote;
use FindBin;

use lib $FindBin::Bin;
use Common qw(:DEFAULT $config);

my $evernote = Net::Evernote->new({
    authentication_token => $$config{'authentication_token'},
    use_sandbox => 1,
});

my $notebookName = 'test_notebook-new'. time;
my $notebookGuid;

# create a notebook
{
    my $notebook = $evernote->createNotebook({
        name => $notebookName,
    });

    $notebookGuid = $notebook->guid;

    isnt($notebookGuid, '', "Notebook created with GUID ${notebookGuid}");

}

# put a note in the notebook
{
    my $note = $evernote->createNote({
        title         => 'test title',
        content       => 'test content',
        notebook_guid => $notebookGuid,
    });

    ok($note->guid && $note->notebookGuid eq $notebookGuid , 'Note created in new notebook');

    $note->delete;
    my $notebook = $evernote->getNotebook({ guid => $notebookGuid });
    ok($notebook->guid eq $notebookGuid, "Notebook retrieved");
}

# delete the notebook
{
    my $notebook = $evernote->getNotebook({ guid => $notebookGuid });
    # @return The Update Sequence Number for this change within the account.
    # I guess this means a positive value = success ?
    my $deleted = $notebook->delete;
    ok(!!$deleted, "Notebook deleted");

    # try to get the notebook again
    my $deleted_notebook = $evernote->getNotebook({ guid => $notebookGuid });
    is($deleted_notebook, undef, "Notebook not retrieved after deletion");
}


