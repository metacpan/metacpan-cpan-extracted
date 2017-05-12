use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;
use File::Basename;

sub trim { 
    my $s = shift; 
    $s =~ s/^\s+|\s+$//g; 
    return $s 
};

# This script tests insert, update, attachFile and deleteRecord

plan skip_all => "no config" unless TestUtil::config;
plan skip_all => "test_insert is false" unless TestUtil::getProp("test_insert");

my $timestamp = TestUtil::getTimestamp;
my $lorem = TestUtil::lorem;
my $today = TestUtil::today;

my $groupName = getProp('group_name');
ok ($groupName, "assignment group is $groupName");
my $shortDescription = "Test $timestamp script $0";
my $fullDescription = "$lorem\n$timestamp";

my $sn = TestUtil::getSession();
my $incident = $sn->table("incident");

#
# Create an incident
#
my %result = $incident->insert(
    short_description => $shortDescription,
    description => $fullDescription,
    assignment_group => $groupName,
    impact => 3);

my $sysid = $result{sys_id};
my $number = $result{number};

ok ($sysid, "inserted sys_id=$sysid");
ok ($number =~ /^INC\d+$/, "inserted number=$number");

my $rec1 = $incident->get($sysid);
ok ($rec1->{impact} == 3, "original impact is 3");

# 
# Attach a file
#
SKIP: {
    my $attachment = getProp('attachment');
    my $mimetype = getProp('attachment_type');
    skip "file attachment test skipped", 1 unless $attachment;
    
    note "attachment name is $attachment";
    my @attachments;
    my ($parsename, $parsepath, $suffix ) = 
        File::Basename::fileparse($attachment, "\.[^.]*");
    if ($mimetype) {
        # attach with manual type specification
        ok ($mimetype, "attachment type is $mimetype");        
        my $attachname = "attach1" . $suffix;
        $incident->attachFile($sysid, $attachment, $attachname, $mimetype);
        push @attachments, $attachname;
    }
    # attach with auto type detection
    $incident->attachFile($sysid, $attachment);
    push @attachments, $parsepath . $suffix;
    my $sys_attachment = $sn->table('sys_attachment');
    my @attach_recs = $sys_attachment->getRecords(table_name => 'incident', table_sys_id => $sysid);
    ok (scalar(@attach_recs) == scalar(@attachments), scalar(@attachments) . ' attachments detected');
}

# 
# Add two work notes and one comments
#
$incident->addWorkNote($sysid, 'Work note one');
$incident->addWorkNote($sysid, 'Work note two');
$incident->addComment($sysid, $lorem);
my @worknotes = $incident->getWorkNotes($sysid);
ok (@worknotes == 2, "two work notes created");
foreach my $note (@worknotes) {
    my $value = $note->{value};
    ok ($value =~ /^Work note \w+$/, "Note: $value");
}
my @comments = $incident->getComments($sysid);
ok (@comments == 1, "one comment created");
my $commentText = $comments[0]->{value};
ok (trim($commentText) eq trim($lorem), "comment value matches");

#
# Update the incident
#
$incident->update(sys_id => $sysid, impact => 1);
my $rec2 = $incident->get($sysid);
ok ($rec2->{impact} == 1, "updated impact is 1");

#
# Date filter test (look for records created today)
#
my $filter = "sys_created_on>=$today";
note "filter=$filter";

my @recs = $incident->getRecords($filter);

ok (@recs > 0, scalar(@recs) . " records created today ($today) retrieved");
my $dcount = 0;
foreach my $rec (@recs) {
    my $number = $rec->{number};
    my $created = $rec->{sys_created_on};
    note "$number $created";
    ++$dcount if substr($created, 0, 10) eq $today;
}
ok ($dcount eq @recs, "$dcount created today");

# 
# Delete the incident
#
SKIP: {
    skip "deleteRecord test skipped", 1 unless getProp('test_delete');
    $incident->deleteRecord(sys_id => $sysid);
    my $rec3 = $incident->get($sysid);
    ok (!$rec3, "incident deleted");    
  };

done_testing;

1;
