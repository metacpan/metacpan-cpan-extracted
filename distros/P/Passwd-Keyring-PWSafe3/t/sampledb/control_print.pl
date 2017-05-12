use strict;
use Crypt::PWSafe3 1.04;

my $vault = new Crypt::PWSafe3(file => 'test.psafe3', password => '10101010');
 
binmode STDOUT, ":utf8";

my @records = $vault->getrecords();
foreach my $record (@records) {
    print "*************************************************************\n";
    print "UUID: ", $record->uuid, "\n";
    print "Title: ", $record->title, "\n";
    print "Group: ", $record->group, "\n";
    print "User: ", $record->user, "\n";
    print "URL: ", $record->url, "\n";
    print "Password: ", $record->passwd, "\n";
    print "Notes: ", $record->notes, "\n";
}

#foreach my $uuid ($vault->looprecord) {
#   # either change a record
#   $vault->modifyrecord($uuid, passwd => 'p1');
#
#   # or just access it directly
#   print $vault->{record}->{$uuid}->title;
#}

# add a new record
# $vault->newrecord(user => 'u1', passwd => 'p1', title => 't1');

# modify an existing record
# $vault->modifyrecord($uuid, passwd => 'p1');

# replace a record (aka edit it)
# my $record = $vault->getrecord($uuid);
# $record->title('t2');
# $record->passwd('foobar');
# $vault->addrecord($record);

# mark the vault as modified (not required if
# changes were done with ::modifyrecord()
# $vault->markmodified();

# save the vault
# $vault->save();

