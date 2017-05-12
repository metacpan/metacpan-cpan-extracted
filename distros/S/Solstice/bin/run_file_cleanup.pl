# uses impl manager to grab a list of all used black box files and removes any files that are not in use
# important to note if an aps impl manager doesn't defined a usingFiles function but does use
# files, they will be deleted when this script runs

use strict;
use warnings;

use Solstice::ImplementationManager;
use Solstice::Database;
use Solstice::LogService;

my $manager = Solstice::ImplementationManager->new();

#grab a list of all used files
my $list = $manager->createList({
        method  => 'usingFiles'
    });

my $iterator = $list->iterator();

my $ids = [];
while(my $file = $iterator->next()){
    push @$ids, $file->getID() if defined $file;
}

my $placeholder = join(',', map({'?'} @$ids)); #build a list of "?,?,?,..." for each id

my $db = Solstice::Database->new();
$db->readQuery("SELECT *, file_id as id FROM solstice.File where file_id NOT IN ($placeholder)", @$ids);

my $files_to_remove = Solstice::List->new();
while(my $data = $db->fetchRow()){
    $files_to_remove->add(Solstice::Resource::File::BlackBox->new($data));
}

#now we have the files to clean up, so lets start cleaning
$iterator = $files_to_remove->iterator();
my $removed_ids = [];
while(my $file = $iterator->next()){
    push @$removed_ids, $file->getID();
    $file->delete();
}

my $log_service = Solstice::LogService->new();
#not sure that we want all ids here, maybe just log the # of files we removed?
$log_service->log({
        model   => 'File cleanup',
        content => 'Removed files with ids: '.join(',', @$removed_ids),
    });

1;
