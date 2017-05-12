package Rinchi::Outlook;
use strict;
use 5.006;
use Carp;
use FileHandle;
use XML::DOM;
use XML::Parser;
use Class::ISA;

our @ISA = qw();

our @EXPORT = qw();
our @EXPORT_OK = qw();

our $VERSION = 0.02;

=head1 NAME

Rinchi::Outlook - A module for representing Microsoft Outlook® 11.0 Object Library objects.

=head1 SYNOPSIS

The following two examples show the use of this module to save Personal Folders 
to an XML file with the attachments saved and duplicate attachments eliminated, 
and the preparation of and index of the saved attachments. 

 use strict;
 use Win32::OLE qw(in with);
 use Win32::OLE::Const 'Microsoft Outlook 11.0 Object Library';
 use Win32::OLE::NLS qw(:LOCALE :DATE);
 use Rinchi::Outlook;
 use Digest::MD5; #  qw(md5 md5_hex md5_base64);
 
 my $document;
 my @attachments;
 my %fingerprints;
 
 #===============================================================================
 sub get_uuid() {
 # ToDo: Add routine to generate or fetch a UUID here.
   return $uuid;
 }
 
 #===============================================================================
 sub add_attachments($$) {
   my ($Item,$item) = @_;
   my $count = $Item->Attachments->{'Count'};
   foreach my $index (1..$count) {
     my $Attachment = $Item->Attachments($index);
     my $attachment = $document->createElement(Rinchi::Outlook::Attachment::TAG_NAME);
     $attachment->Class($Attachment->{'Class'});
     $attachment->DisplayName($Attachment->{'DisplayName'});
     my $filename = $Attachment->{'FileName'};
     my $ext;
     $ext = $1 if($filename =~ /(\.[0-9A-Za-z]+)$/);
     my $uuid = get_uuid();
     my $path="C:/mail/attachment/$uuid$ext";
     $attachment->FileName($filename);
     $attachment->Index($Attachment->{'Index'});
     $attachment->PathName($path);
     $attachment->Position($Attachment->{'Position'});
     $attachment->Type($Attachment->{'Type'});
     $attachment->xmi_id($uuid);
     $item->Attachments->appendChild($attachment);
     $Attachment->SaveAsFile($path);
     push @attachments,$attachment;
     print "Saving attachment \'$filename\' as \'$path\'\n";
   }
 }
 
 #===============================================================================
 sub add_items($$) {
   my ($Folder,$folder) = @_;
   my $count = $Folder->Items->{'Count'};
   foreach my $index (1..$count) {
     my $Item = $Folder->Items($index);
     my $class = $Item->{'Class'};
     my $item;
     if ($class == Rinchi::Outlook::OlObjectClass::olMail) {
 #common
       $item = $document->createElement(Rinchi::Outlook::MailItem::TAG_NAME);
       $item->BillingInformation($Item->{'BillingInformation'}) if ($Item->{'BillingInformation'});
       $item->Companies($Item->{'Companies'}) if ($Item->{'Companies'});
       $item->ConversationIndex($Item->{'ConversationIndex'}) if ($Item->{'ConversationIndex'});
       $item->ConversationTopic($Item->{'ConversationTopic'}) if ($Item->{'ConversationTopic'});
       $item->Importance($Item->{'Importance'});
       $item->Mileage($Item->{'Mileage'}) if ($Item->{'Mileage'});
       $item->NoAging('true') if ($Item->{'NoAging'});
       $item->OutlookInternalVersion($Item->{'OutlookInternalVersion'});
       $item->OutlookVersion($Item->{'OutlookVersion'});
       $item->Sensitivity($Item->{'Sensitivity'});
       $item->UnRead('true') if ($Item->{'UnRead'});
 #specific to MailItem
       $item->AlternateRecipientAllowed('true') if($Item->{'AlternateRecipientAllowed'});
       $item->AutoForwarded('true') if ($Item->{'AutoForwarded'});
       $item->BCC($Item->{'BCC'}) if ($Item->{'BCC'});
       $item->BodyFormat($Item->{'BodyFormat'});
       $item->CC($Item->{'CC'}) if ($Item->{'CC'});
       $item->DeferredDeliveryTime($Item->{'DeferredDeliveryTime'}->Date(DATE_LONGDATE)) unless(${$Item->{'DeferredDeliveryTime'}} == 39679620);
       $item->DeleteAfterSubmit('true') if ($Item->{'DeleteAfterSubmit'});
       $item->EnableSharedAttachments('true') if ($Item->{'EnableSharedAttachments'});
       $item->ExpiryTime($Item->{'ExpiryTime'}->Date(DATE_LONGDATE)) unless(${$Item->{'ExpiryTime'}} == 39679620);
       $item->FlagDueBy($Item->{'FlagDueBy'}->Date(DATE_LONGDATE)) unless(${$Item->{'FlagDueBy'}} == 39679620);
       $item->FlagIcon($Item->{'FlagIcon'}) if ($Item->{'FlagIcon'});
       $item->FlagRequest($Item->{'FlagRequest'}) if ($Item->{'FlagRequest'});
       $item->FlagStatus($Item->{'FlagStatus'}) if ($Item->{'FlagStatus'});
       $item->HasCoverSheet('true') if ($Item->{'HasCoverSheet'});
       $item->InternetCodepage($Item->{'InternetCodepage'});
       $item->IsIPFax('true') if ($Item->{'IsIPFax'});
       $item->OriginatorDeliveryReportRequested('true') if($Item->{'OriginatorDeliveryReportRequested'});
       $item->Permission($Item->{'Permission'});
       $item->PermissionService($Item->{'PermissionService'});
       $item->ReadReceiptRequested('true') if ($Item->{'ReadReceiptRequested'});
       $item->ReceivedByName($Item->{'ReceivedByName'});
       $item->ReceivedOnBehalfOfName($Item->{'ReceivedOnBehalfOfName'});
       $item->ReceivedTime($Item->{'ReceivedTime'}->Date(DATE_LONGDATE)) unless(${$Item->{'ReceivedTime'}} == 39679620);
       $item->RecipientReassignmentProhibited('true') if($Item->{'RecipientReassignmentProhibited'});
       $item->ReminderOverrideDefault('true') if($Item->{'ReminderOverrideDefault'});
       $item->ReminderPlaySound('true') if($Item->{'ReminderPlaySound'});
       $item->ReminderSet('true') if($Item->{'ReminderSet'});
       $item->ReminderSoundFile($Item->{'ReminderSoundFile'}) if($Item->{'ReminderSoundFile'});
       $item->ReminderTime($Item->{'ReminderTime'}->Date(DATE_LONGDATE)) unless(${$Item->{'ReminderTime'}} == 39679620);
       $item->RemoteStatus($Item->{'RemoteStatus'});
       $item->ReplyRecipientNames($Item->{'ReplyRecipientNames'});
       $item->SenderEmailAddress($Item->{'SenderEmailAddress'});
       $item->SenderEmailType($Item->{'SenderEmailType'});
       $item->SenderName($Item->{'SenderName'});
       $item->Sent('true') if($Item->{'Sent'});
       $item->SentOn($Item->{'SentOn'}->Date(DATE_LONGDATE)) unless(${$Item->{'SentOn'}} == 39679620);
       $item->SentOnBehalfOfName($Item->{'SentOnBehalfOfName'});
       $item->Submitted('true') if($Item->{'Submitted'});
       $item->To($Item->{'To'});
       $item->VotingOptions($Item->{'VotingOptions'}) if ($Item->{'VotingOptions'});
       $item->VotingResponse($Item->{'VotingResponse'}) if ($Item->{'VotingResponse'});
       add_attachments($Item,$item) if ($Item->Attachments->{'Count'} > 0);
     }
     if (defined($item)) {
       $item->Body(escape_xml($Item->{'Body'}));
       $item->Class($Item->{'Class'});
       $item->CreationTime($Item->{'CreationTime'}->Date(DATE_LONGDATE)) unless(${$Item->{'CreationTime'}} == 39679620);
       $item->DownloadState($Item->{'DownloadState'});
       $item->EntryID($Item->{'EntryID'});
       $item->IsConflict('true') if ($Item->{'IsConflict'});
       $item->LastModificationTime($Item->{'LastModificationTime'}->Date(DATE_LONGDATE)) unless(${$Item->{'LastModificationTime'}} == 39679620);
       $item->MarkForDownload($Item->{'MarkForDownload'});
       $item->MessageClass($Item->{'MessageClass'});
       $item->Saved('true') if ($Item->{'Saved'});
       $item->Size($Item->{'Size'});
       $item->Subject($Item->{'Subject'});
       $item->xmi_id(get_uuid());
       $folder->appendChild($item);
     }
   }
 }
 
 #===============================================================================
 sub add_folders($$) {
   my ($Folders,$folders) = @_;
   my $count = $Folders->{'Count'};
   foreach my $index (1..$count) {
     my $Folder = $Folders->Item($index);
     my $folder = $document->createElement(Rinchi::Outlook::MAPIFolder::TAG_NAME);
     $folder->AddressBookName($Folder->{'AddressBookName'});
     $folder->Description($Folder->{'Description'});
     $folder->FolderPath($Folder->{'FolderPath'});
     $folder->FullFolderPath($Folder->{'FullFolderPath'});
     $folder->Name($Folder->{'Name'});
     $folder->DefaultItemType($Folder->{'DefaultItemType'});
     $folder->Class(Rinchi::Outlook::OlObjectClass::olFolder);
     $folder->xmi_id(get_uuid());
     $folders->appendChild($folder);
     add_folders($Folder->Folders,$folder->Folders) if($Folder->Folders->{'Count'} > 0);
     add_items($Folder,$folder) if($Folder->Items->{'Count'} > 0);
   }
 }
 
 #===============================================================================
 sub top_folders($$) {
   my ($Folders,$folders) = @_;
   my $count = $Folders->{'Count'};
   foreach my $index (1..$count) {
     my $Folder = $Folders->Item($index);
     my $folder = $document->createElement(Rinchi::Outlook::MAPIFolder::TAG_NAME);
     my $name = $Folder->{'Name'};
     $folder->AddressBookName($Folder->{'AddressBookName'});
     $folder->Description($Folder->{'Description'});
     $folder->FolderPath($Folder->{'FolderPath'});
     $folder->FullFolderPath($Folder->{'FullFolderPath'});
     $folder->Name($name);
     $folder->DefaultItemType($Folder->{'DefaultItemType'});
     $folder->Class(Rinchi::Outlook::OlObjectClass::olFolder);
     $folder->xmi_id(get_uuid());
     $folders->appendChild($folder);
     add_folders($Folder->Folders,$folder->Folders) if($Folder->Folders->{'Count'} > 0 and $name eq 'Personal Folders');
   }
 }
 
 #===============================================================================
 my $Outlook;
 eval {
   $Outlook = Win32::OLE->GetActiveObject('Outlook.Application')
 };
 if ($@ || !defined($Outlook)) {
   $Outlook = Win32::OLE->new('Outlook.Application', sub {$_[0]->Quit;})
     or return undef;
 }
 my $Namespace = $Outlook->GetNameSpace("MAPI") or return undef;
 
 $document = Rinchi::Outlook::Document->new(Rinchi::Outlook::NameSpace::TAG_NAME);
 my $namespace = $document->getDocumentElement();
 $namespace->xmi_id(get_uuid);
 
 top_folders($Namespace->Folders,$namespace->Folders);
 
 my $md5 = Digest::MD5->new();
 foreach my $attachment(@attachments) {
   my $path = $attachment->PathName(); 
   my $ferr = 0;
   open FH,'<',$path or $ferr = 1;
   unless ($ferr > 0) {
     binmode(FH);
     $md5->new();
     $md5->addfile(*FH);
     my $fingerprint = $md5->hexdigest();
     close FH;
     $attachment->MD5($fingerprint);
     if(exists($fingerprints{$fingerprint})) {
       $attachment->PathName($fingerprints{$fingerprint});
       unlink $path;
       print "Duplicate file \'$path\' deleted.\n";
     } else {
       $fingerprints{$fingerprint} = $path;
     }
   }
 }
 
 $document->printToFile('C:/mail/personal_folders.xml');
 
 #========================================
 
 use strict;
 use Rinchi::Outlook;
 
 my $source = 'C:/mail/personal_folders.xml';
 
 my $document = Rinchi::Outlook->parsefile($source);
 
 my @attachments = $document->getElementsByTagName('attachment');
 
 open HTML,'>','C:/mail/attachment/index.html';
 print HTML "<html>\n  <head>\n    <title>Index of Attachments</title>\n  </head>\n  <body>\n    <h1>Index of Attachments</h1>\n    <table border=\"1\" cellspacing=\"0\">\n";
 print HTML "      <tr><th>Display Name</th><th>Subject</th><th>Sender</th><th>Path Name</th><th>FileName</th></tr>\n";
 foreach my $attachment (@attachments) {
   my $link = $attachment->PathName;
   my @l = split('\/',$link);
   $link = pop @l;
   printf HTML "      <tr><td><a href=\"%s\">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n",$link,$attachment->DisplayName,$attachment->getParentNode->getParentNode->Subject,$attachment->getParentNode->getParentNode->SenderName,$attachment->PathName,$attachment->FileName;
 }
 print HTML "    </table>\n  </body>\n</html>\n";
 close HTML;

=head1 DESCRIPTION

Microsoft Outlook 11.0 Object Library

=head2 EXPORT

None by default.

=head1 METHODS

=cut

my %sax_handlers = (
  'Init'         => \&handle_init,
  'Final'        => \&handle_final,
  'Start'        => \&handle_start,
  'End'          => \&handle_end,
  'Char'         => \&handle_char,
  'Proc'         => \&handle_proc,
  'Comment'      => \&handle_comment,
  'CdataStart'   => \&handle_cdata_start,
  'CdataEnd'     => \&handle_cdata_end,
  'Default'      => \&handle_default,
  'Unparsed'     => \&handle_unparsed,
  'Notation'     => \&handle_notation,
  'ExternEnt'    => \&handle_extern_ent,
  'ExternEntFin' => \&handle_extern_ent_fin,
  'Entity'       => \&handle_entity,
  'Element'      => \&handle_element,
  'Attlist'      => \&handle_attlist,
  'Doctype'      => \&handle_doctype,
  'DoctypeFin'   => \&handle_doctype_fin,
  'XMLDecl'      => \&handle_xml_decl,
);

my @elem_stack;

my $Document;

#=================================================================

# Init              (Expat)
sub handle_init() {
  my ($expat) = @_;
  $Document = Rinchi::Outlook::Document->new();
  push @elem_stack,$Document;
}

#=================================================================

# Final             (Expat)
sub handle_final() {
  my ($expat) = @_;
}

#=================================================================

# Start             (Expat, Tag [, Attr, Val [,...]])
sub handle_start() {
  my ($expat, $tag, %attrs) = @_;

  my $Element = $Document->createElement($tag);
  foreach my $attr (keys %attrs) {
    $Element->setAttribute($attr,$attrs{$attr});
  }
  $elem_stack[-1]->appendChild($Element) if(@elem_stack);
  push @elem_stack,$Element;
}

#=================================================================

# End               (Expat, Tag)
sub handle_end() {
  my ($expat, $tag) = @_;
  my $Element = pop @elem_stack;
}

#=================================================================

# Char              (Expat, String)
sub handle_char() {
  my ($expat, $string) = @_;
  $elem_stack[-1]->appendChild($Document->createTextNode($string));
}

#=================================================================

# Proc              (Expat, Target, Data)
sub handle_proc() {
  my ($expat, $target, $data) = @_;
}

#=================================================================

# Comment           (Expat, Data)
sub handle_comment() {
  my ($expat, $data) = @_;
}

#=================================================================

# CdataStart        (Expat)
sub handle_cdata_start() {
  my ($expat) = @_;
}

#=================================================================

# CdataEnd          (Expat)
sub handle_cdata_end() {
  my ($expat) = @_;
}

#=================================================================

# Default           (Expat, String)
sub handle_default() {
  my ($expat, $string) = @_;
}

#=================================================================

# Unparsed          (Expat, Entity, Base, Sysid, Pubid, Notation)
sub handle_unparsed() {
  my ($expat, $entity, $base, $sysid, $pubid, $notation) = @_;
}

#=================================================================

# Notation          (Expat, Notation, Base, Sysid, Pubid)
sub handle_notation() {
  my ($expat, $notation, $base, $sysid, $pubid) = @_;
}

#=================================================================

# ExternEnt         (Expat, Base, Sysid, Pubid)
sub handle_extern_ent() {
  my ($expat, $base, $sysid, $pubid) = @_;
}

#=================================================================

# ExternEntFin      (Expat)
sub handle_extern_ent_fin() {
  my ($expat) = @_;
}

#=================================================================

# Entity            (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
sub handle_entity() {
  my ($expat, $name, $val, $sysid, $pubid, $ndata, $isParam) = @_;
}

#=================================================================

# Element           (Expat, Name, Model)
sub handle_element() {
  my ($expat, $name, $model) = @_;
}

#=================================================================

# Attlist           (Expat, Elname, Attname, Type, Default, Fixed)
sub handle_attlist() {
  my ($expat, $elname, $attname, $type, $default, $fixed) = @_;
}

#=================================================================

# Doctype           (Expat, Name, Sysid, Pubid, Internal)
sub handle_doctype() {
  my ($expat, $name, $sysid, $pubid, $internal) = @_;
}

#=================================================================

# DoctypeFin        (Expat)
sub handle_doctype_fin() {
  my ($expat) = @_;
}

#=================================================================

# XMLDecl           (Expat, Version, Encoding, Standalone)
sub handle_xml_decl() {
  my ($expat, $version, $encoding, $standalone) = @_;
}

#=================================================================

=head2 $Document = Rinchi::Outlook->parsefile($path);

Calls XML::Parser->parsefile with the given path and the Rinchi::Outlook 
handlers.  A tree of DOM objects is returned.

Open FILE for reading, then call parse with the open handle. The
file is closed no matter how parse returns. Returns what parse
returns.

=cut

sub parsefile($) {
  my $self = shift @_;
  my $source = shift @_;

  my $Parser = new XML::Parser('Handlers' => \%sax_handlers);
  $Parser->parsefile($source);
  return $Document;
}

#===============================================================================
{
  package XML::DOM::Implementation;

  sub createDocument() {
    my $self = shift;

    my $doc = new XML::DOM::Document();
    my $xmlDecl = $doc->createXMLDecl('1.0','UTF-8','yes');
    $doc->setXMLDecl($xmlDecl);
    my $ns;
    my $qname;
    my $doctype;
    if (@_) {
      $ns = shift;
    }
    if (@_) {
      $qname = shift;
    }
    if (@_) {
      $doctype = shift;
    }
    if (defined($qname)) {
      my $element = $doc->createElement($qname);
      $doc->appendChild($element);
    }
    return $doc;
  }
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 

package Rinchi::Outlook::Document;

use Carp;

our @ISA = qw(XML::DOM::Document);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Document

Rinchi::Outlook::Document subclasses XML::DOM::Document and is used for creating 
Rinchi::Outlook::* objects based on the following tag to class mapping.

  'action'                            => 'Rinchi::Outlook::Action',
  'actions'                           => 'Rinchi::Outlook::Actions',
  'address-entries'                   => 'Rinchi::Outlook::AddressEntries',
  'address-entry'                     => 'Rinchi::Outlook::AddressEntry',
  'address-list'                      => 'Rinchi::Outlook::AddressList',
  'address-lists'                     => 'Rinchi::Outlook::AddressLists',
  'application'                       => 'Rinchi::Outlook::Application',
  'appointment-item'                  => 'Rinchi::Outlook::AppointmentItem',
  'attachment'                        => 'Rinchi::Outlook::Attachment',
  'attachments'                       => 'Rinchi::Outlook::Attachments',
  'Body'                              => 'Rinchi::Outlook::Body',
  'conflict'                          => 'Rinchi::Outlook::Conflict',
  'conflicts'                         => 'Rinchi::Outlook::Conflicts',
  'contact-item'                      => 'Rinchi::Outlook::ContactItem',
  'dist-list-item'                    => 'Rinchi::Outlook::DistListItem',
  'document-item'                     => 'Rinchi::Outlook::DocumentItem',
  'exception'                         => 'Rinchi::Outlook::Exception',
  'exceptions'                        => 'Rinchi::Outlook::Exceptions',
  'explorer'                          => 'Rinchi::Outlook::Explorer',
  'explorers'                         => 'Rinchi::Outlook::Explorers',
  'folders'                           => 'Rinchi::Outlook::Folders',
  'form-description'                  => 'Rinchi::Outlook::FormDescription',
  'inspector'                         => 'Rinchi::Outlook::Inspector',
  'inspectors'                        => 'Rinchi::Outlook::Inspectors',
  'item-properties'                   => 'Rinchi::Outlook::ItemProperties',
  'item-property'                     => 'Rinchi::Outlook::ItemProperty',
  'items'                             => 'Rinchi::Outlook::Items',
  'journal-item'                      => 'Rinchi::Outlook::JournalItem',
  'link'                              => 'Rinchi::Outlook::Link',
  'links'                             => 'Rinchi::Outlook::Links',
  'mail-item'                         => 'Rinchi::Outlook::MailItem',
  'mapi-folder'                       => 'Rinchi::Outlook::MAPIFolder',
  'meeting-item'                      => 'Rinchi::Outlook::MeetingItem',
  'name-space'                        => 'Rinchi::Outlook::NameSpace',
  'note-item'                         => 'Rinchi::Outlook::NoteItem',
  'outlook-bar-group'                 => 'Rinchi::Outlook::OutlookBarGroup',
  'outlook-bar-groups'                => 'Rinchi::Outlook::OutlookBarGroups',
  'outlook-bar-pane'                  => 'Rinchi::Outlook::OutlookBarPane',
  'outlook-bar-shortcut'              => 'Rinchi::Outlook::OutlookBarShortcut',
  'outlook-bar-shortcuts'             => 'Rinchi::Outlook::OutlookBarShortcuts',
  'outlook-bar-storage'               => 'Rinchi::Outlook::OutlookBarStorage',
  'outlook-base-item-object'          => 'Rinchi::Outlook::OutlookBaseItemObject',
  'outlook-collection'                => 'Rinchi::Outlook::OutlookCollection',
  'outlook-entry'                     => 'Rinchi::Outlook::OutlookEntry',
  'outlook-item-object'               => 'Rinchi::Outlook::OutlookItemObject',
  'outlook-named-entry'               => 'Rinchi::Outlook::OutlookNamedEntry',
  'pages'                             => 'Rinchi::Outlook::Pages',
  'panes'                             => 'Rinchi::Outlook::Panes',
  'post-item'                         => 'Rinchi::Outlook::PostItem',
  'property-pages'                    => 'Rinchi::Outlook::PropertyPages',
  'property-page-site'                => 'Rinchi::Outlook::PropertyPageSite',
  'recipient'                         => 'Rinchi::Outlook::Recipient',
  'recipients'                        => 'Rinchi::Outlook::Recipients',
  'recurrence-pattern'                => 'Rinchi::Outlook::RecurrencePattern',
  'reminder'                          => 'Rinchi::Outlook::Reminder',
  'reminders'                         => 'Rinchi::Outlook::Reminders',
  'remote-item'                       => 'Rinchi::Outlook::RemoteItem',
  'report-item'                       => 'Rinchi::Outlook::ReportItem',
  'results'                           => 'Rinchi::Outlook::Results',
  'search'                            => 'Rinchi::Outlook::Search',
  'selection'                         => 'Rinchi::Outlook::Selection',
  'sync-object'                       => 'Rinchi::Outlook::SyncObject',
  'sync-objects'                      => 'Rinchi::Outlook::SyncObjects',
  'task-item'                         => 'Rinchi::Outlook::TaskItem',
  'task-request-accept-item'          => 'Rinchi::Outlook::TaskRequestAcceptItem',
  'task-request-decline-item'         => 'Rinchi::Outlook::TaskRequestDeclineItem',
  'task-request-item'                 => 'Rinchi::Outlook::TaskRequestItem',
  'task-request-update-item'          => 'Rinchi::Outlook::TaskRequestUpdateItem',
  'user-properties'                   => 'Rinchi::Outlook::UserProperties',
  'user-property'                     => 'Rinchi::Outlook::UserProperty',
  'view'                              => 'Rinchi::Outlook::View',
  'views'                             => 'Rinchi::Outlook::Views',

=cut

#===============================================================================

=head1 METHODS for Document objects

=head2 $Object = Rinchi::Outlook::Document->new();

Create a new Rinchi::Outlook::Document object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;

  my $qname;
  if (@_) {
    $qname = shift;
  }

  my $self = XML::DOM::Document::new($class);
  my $xmlDecl = $self->createXMLDecl('1.0','UTF-8','yes');
  $self->setXMLDecl($xmlDecl);
  if (defined($qname)) {
    my $element = $self->createElement($qname);
    $self->appendChild($element);
  }
  return $self;
}

our %tag_map = (
  'action'                            => 'Rinchi::Outlook::Action',
  'actions'                           => 'Rinchi::Outlook::Actions',
  'address-entries'                   => 'Rinchi::Outlook::AddressEntries',
  'address-entry'                     => 'Rinchi::Outlook::AddressEntry',
  'address-list'                      => 'Rinchi::Outlook::AddressList',
  'address-lists'                     => 'Rinchi::Outlook::AddressLists',
  'application'                       => 'Rinchi::Outlook::Application',
  'appointment-item'                  => 'Rinchi::Outlook::AppointmentItem',
  'attachment'                        => 'Rinchi::Outlook::Attachment',
  'attachments'                       => 'Rinchi::Outlook::Attachments',
  'Body'                              => 'Rinchi::Outlook::Body',
  'conflict'                          => 'Rinchi::Outlook::Conflict',
  'conflicts'                         => 'Rinchi::Outlook::Conflicts',
  'contact-item'                      => 'Rinchi::Outlook::ContactItem',
  'dist-list-item'                    => 'Rinchi::Outlook::DistListItem',
  'document-item'                     => 'Rinchi::Outlook::DocumentItem',
  'exception'                         => 'Rinchi::Outlook::Exception',
  'exceptions'                        => 'Rinchi::Outlook::Exceptions',
  'explorer'                          => 'Rinchi::Outlook::Explorer',
  'explorers'                         => 'Rinchi::Outlook::Explorers',
  'folders'                           => 'Rinchi::Outlook::Folders',
  'form-description'                  => 'Rinchi::Outlook::FormDescription',
  'inspector'                         => 'Rinchi::Outlook::Inspector',
  'inspectors'                        => 'Rinchi::Outlook::Inspectors',
  'item-properties'                   => 'Rinchi::Outlook::ItemProperties',
  'item-property'                     => 'Rinchi::Outlook::ItemProperty',
  'items'                             => 'Rinchi::Outlook::Items',
  'journal-item'                      => 'Rinchi::Outlook::JournalItem',
  'link'                              => 'Rinchi::Outlook::Link',
  'links'                             => 'Rinchi::Outlook::Links',
  'mail-item'                         => 'Rinchi::Outlook::MailItem',
  'mapi-folder'                       => 'Rinchi::Outlook::MAPIFolder',
  'meeting-item'                      => 'Rinchi::Outlook::MeetingItem',
  'name-space'                        => 'Rinchi::Outlook::NameSpace',
  'note-item'                         => 'Rinchi::Outlook::NoteItem',
  'outlook-bar-group'                 => 'Rinchi::Outlook::OutlookBarGroup',
  'outlook-bar-groups'                => 'Rinchi::Outlook::OutlookBarGroups',
  'outlook-bar-pane'                  => 'Rinchi::Outlook::OutlookBarPane',
  'outlook-bar-shortcut'              => 'Rinchi::Outlook::OutlookBarShortcut',
  'outlook-bar-shortcuts'             => 'Rinchi::Outlook::OutlookBarShortcuts',
  'outlook-bar-storage'               => 'Rinchi::Outlook::OutlookBarStorage',
  'outlook-base-item-object'          => 'Rinchi::Outlook::OutlookBaseItemObject',
  'outlook-collection'                => 'Rinchi::Outlook::OutlookCollection',
  'outlook-entry'                     => 'Rinchi::Outlook::OutlookEntry',
  'outlook-item-object'               => 'Rinchi::Outlook::OutlookItemObject',
  'outlook-named-entry'               => 'Rinchi::Outlook::OutlookNamedEntry',
  'pages'                             => 'Rinchi::Outlook::Pages',
  'panes'                             => 'Rinchi::Outlook::Panes',
  'post-item'                         => 'Rinchi::Outlook::PostItem',
  'property-pages'                    => 'Rinchi::Outlook::PropertyPages',
  'property-page-site'                => 'Rinchi::Outlook::PropertyPageSite',
  'recipient'                         => 'Rinchi::Outlook::Recipient',
  'recipients'                        => 'Rinchi::Outlook::Recipients',
  'recurrence-pattern'                => 'Rinchi::Outlook::RecurrencePattern',
  'reminder'                          => 'Rinchi::Outlook::Reminder',
  'reminders'                         => 'Rinchi::Outlook::Reminders',
  'remote-item'                       => 'Rinchi::Outlook::RemoteItem',
  'report-item'                       => 'Rinchi::Outlook::ReportItem',
  'results'                           => 'Rinchi::Outlook::Results',
  'search'                            => 'Rinchi::Outlook::Search',
  'selection'                         => 'Rinchi::Outlook::Selection',
  'sync-object'                       => 'Rinchi::Outlook::SyncObject',
  'sync-objects'                      => 'Rinchi::Outlook::SyncObjects',
  'task-item'                         => 'Rinchi::Outlook::TaskItem',
  'task-request-accept-item'          => 'Rinchi::Outlook::TaskRequestAcceptItem',
  'task-request-decline-item'         => 'Rinchi::Outlook::TaskRequestDeclineItem',
  'task-request-item'                 => 'Rinchi::Outlook::TaskRequestItem',
  'task-request-update-item'          => 'Rinchi::Outlook::TaskRequestUpdateItem',
  'user-properties'                   => 'Rinchi::Outlook::UserProperties',
  'user-property'                     => 'Rinchi::Outlook::UserProperty',
  'view'                              => 'Rinchi::Outlook::View',
  'views'                             => 'Rinchi::Outlook::Views',
);

sub createElement() {
  my $self = shift;
  my $qname = shift;
  if(exists($tag_map{$qname})) {
    return XML::DOM::Element::new($tag_map{$qname},$self,$qname);
  } else {
    return XML::DOM::Element->new($self,$qname);
  }
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 

package Rinchi::Outlook::Element;

our @ISA = qw(XML::DOM::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

BEGIN
{
    import XML::DOM::Node qw( :Fields );
}

=head1 METHODS for Rinchi::Outlook::Element objects

=cut

#===============================================================================
# Rinchi::Outlook::Element::xmi_id

=head2 $value = $Object->xmi_id([$new_value]);

Set or get value of the xmi_id attribute. This attribute is used to provide 
unique object identification.
  
 Type: UUID
 Lower: 0
 Upper: 1

=cut

sub xmi_id() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('xmi.id', lc shift);
  }
  return $self->getAttribute('xmi.id');
}

#===============================================================================
# Rinchi::Outlook::Element::xmi_idref

=head2 $value = $Object->xmi_idref([$new_value]);

Set or get value of the xmi_idref attribute.  The UUID used can reference any 
object, including external objects.
  
 Type: UUID
 Lower: 0
 Upper: 1

=cut

sub xmi_idref() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('xmi.idref', lc shift);
  }
  return $self->getAttribute('xmi.idref');
}

#===============================================================================
# Rinchi::Outlook::Element::get_collection()

sub get_collection() {
  my $self = shift;
  my $name = shift;
  my $qname = shift;

  $self->[_UserData] = {} unless (defined($self->[_UserData]));
  $self->[_UserData]{'_collections'} = {} unless (exists($self->[_UserData]{'_collections'}));
  unless(exists($self->[_UserData]{'_collections'}{$name})) {
    my $elem = $self->getOwnerDocument->createElement($qname);
    $self->appendChild($elem);
    $self->[_UserData]{'_collections'}{$name} = $elem;
  }
  return $self->[_UserData]{'_collections'}{$name};
}

#===============================================================================
# Rinchi::Outlook::Element::attribute_as_element()

sub attribute_as_element() {
  my $self = shift;
  my $name = shift;
  my $text = shift;

  $self->[_UserData] = {} unless (defined($self->[_UserData]));
  $self->[_UserData]{'_elements'} = {} unless (exists($self->[_UserData]{'_elements'}));
  if(defined($text)) {
    if(exists($self->[_UserData]{'_elements'}{$name})) {
      $self->removeChildNodes;
    }
    my $doc = $self->getOwnerDocument();
    my $element = $doc->createElement($name);
    $element->appendChild($doc->createTextNode($text));
    $self->appendChild($element);
    $self->[_UserData]{'_elements'}{$name} = $element;
  }
  unless(exists($self->[_UserData]{'_elements'}{$name})) {
    return undef;
  }
  return $self->[_UserData]{'_elements'}{$name};
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 

package Rinchi::Outlook::Body;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element);
our @EXPORT = qw();
our @EXPORT_OK = qw();

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d96ac8-3c43-11dd-a5ba-001c25551abc

package Rinchi::Outlook::Action;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Action class

Rinchi::Outlook::Action is used for representing Action objects. Represents a 
specialized action (for example, the voting options response) that can be 
executed on an item. The Action object is a member of the Actions  object.

=head1 METHODS for Action objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'action'; };
}

#===============================================================================
# Rinchi::Outlook::Action::CopyLike

=head2 $value = $Object->CopyLike([$new_value]);

Set or get value of the CopyLike attribute.
  
 Type: OlActionCopyLike
 Lower: 0
 Upper: 1

=cut

sub CopyLike() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('CopyLike', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlActionCopyLike\' for attribute \'CopyLike\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlActionCopyLike\' for attribute \'CopyLike\'';
      }
    }
  }
  return $self->getAttribute('CopyLike');
}

#===============================================================================
# Rinchi::Outlook::Action::Enabled

=head2 $value = $Object->Enabled([$new_value]);

Set or get value of the Enabled attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Enabled() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Enabled', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Enabled\'';
    }
  }
  return $self->getAttribute('Enabled');
}

#===============================================================================
# Rinchi::Outlook::Action::MessageClass

=head2 $value = $Object->MessageClass([$new_value]);

Set or get value of the MessageClass attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MessageClass() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MessageClass', shift);
  }
  return $self->getAttribute('MessageClass');
}

#===============================================================================
# Rinchi::Outlook::Action::Prefix

=head2 $value = $Object->Prefix([$new_value]);

Set or get value of the Prefix attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Prefix() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Prefix', shift);
  }
  return $self->getAttribute('Prefix');
}

#===============================================================================
# Rinchi::Outlook::Action::ReplyStyle

=head2 $value = $Object->ReplyStyle([$new_value]);

Set or get value of the ReplyStyle attribute.
  
 Type: OlActionReplyStyle
 Lower: 0
 Upper: 1

=cut

sub ReplyStyle() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ReplyStyle', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlActionReplyStyle\' for attribute \'ReplyStyle\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlActionReplyStyle\' for attribute \'ReplyStyle\'';
      }
    }
  }
  return $self->getAttribute('ReplyStyle');
}

#===============================================================================
# Rinchi::Outlook::Action::ResponseStyle

=head2 $value = $Object->ResponseStyle([$new_value]);

Set or get value of the ResponseStyle attribute.
  
 Type: OlActionResponseStyle
 Lower: 0
 Upper: 1

=cut

sub ResponseStyle() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ResponseStyle', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlActionResponseStyle\' for attribute \'ResponseStyle\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlActionResponseStyle\' for attribute \'ResponseStyle\'';
      }
    }
  }
  return $self->getAttribute('ResponseStyle');
}

#===============================================================================
# Rinchi::Outlook::Action::ShowOn

=head2 $value = $Object->ShowOn([$new_value]);

Set or get value of the ShowOn attribute.
  
 Type: OlActionShowOn
 Lower: 0
 Upper: 1

=cut

sub ShowOn() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ShowOn', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlActionShowOn\' for attribute \'ShowOn\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlActionShowOn\' for attribute \'ShowOn\'';
      }
    }
  }
  return $self->getAttribute('ShowOn');
}

##END_PACKAGE Action

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d99bd8-3c43-11dd-a96e-001c25551abc

package Rinchi::Outlook::AddressEntry;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AddressEntry objects

Rinchi::Outlook::AddressEntry is used for representing AddressEntry objects.

=head1 METHODS for AddressEntry objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'address-entry'; };
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::Address

=head2 $value = $Object->Address([$new_value]);

Set or get value of the Address attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Address() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Address', shift);
  }
  return $self->getAttribute('Address');
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::DisplayType

=head2 $value = $Object->DisplayType([$new_value]);

Set or get value of the DisplayType attribute.
  
 Type: OlDisplayType
 Lower: 0
 Upper: 1

=cut

sub DisplayType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DisplayType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlDisplayType\' for attribute \'DisplayType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlDisplayType\' for attribute \'DisplayType\'';
      }
    }
  }
  return $self->getAttribute('DisplayType');
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::ID

=head2 $value = $Object->ID([$new_value]);

Set or get value of the ID attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ID', shift);
  }
  return $self->getAttribute('ID');
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::Manager

=head2 $value = $Object->Manager([$new_value]);

Set or get value of the Manager attribute.
  
 Type: AddressEntry
 Lower: 0
 Upper: 1

=cut

sub Manager() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::AddressEntry' =~ /$regexp/ ) {
      $self->attribute_as_element('Manager', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::AddressEntry\' for attribute \'Manager\'';
    }
  }
  return $self->attribute_as_element('Manager');
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::Members

=head2 $Element = $Object->Members();

Set or get value of the Members attribute.
  
 Type: AddressEntries
 Lower: 0
 Upper: 1

=cut

sub Members() {
  my $self = shift;
  return $self->get_collection('AddressEntries','address-entries');
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Type', shift);
  }
  return $self->getAttribute('Type');
}

##END_PACKAGE AddressEntry

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d9ab96-3c43-11dd-992f-001c25551abc

package Rinchi::Outlook::AddressList;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AddressList objects

Rinchi::Outlook::AddressList is used for representing AddressList objects.

=head1 METHODS for AddressList objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'address-list'; };
}

#===============================================================================
# Rinchi::Outlook::AddressList::AddressEntries

=head2 $Element = $Object->AddressEntries();

Set or get value of the AddressEntries attribute.
 
 Type: AddressEntries
 Lower: 0
 Upper: 1

=cut

sub AddressEntries() {
  my $self = shift;
  return $self->get_collection('AddressEntries','address-entries');
}

#===============================================================================
# Rinchi::Outlook::AddressList::ID

=head2 $value = $Object->ID([$new_value]);

Set or get value of the ID attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ID', shift);
  }
  return $self->getAttribute('ID');
}

#===============================================================================
# Rinchi::Outlook::AddressList::Index

=head2 $value = $Object->Index([$new_value]);

Set or get value of the Index attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Index() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Index', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Index\'';
    }
  }
  return $self->getAttribute('Index');
}

#===============================================================================
# Rinchi::Outlook::AddressList::IsReadOnly

=head2 $value = $Object->IsReadOnly([$new_value]);

Set or get value of the IsReadOnly attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsReadOnly() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsReadOnly', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsReadOnly\'';
    }
  }
  return $self->getAttribute('IsReadOnly');
}

##END_PACKAGE AddressList

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d9dc7e-3c43-11dd-9b20-001c25551abc

package Rinchi::Outlook::Application;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Application objects

Rinchi::Outlook::Application is used for representing Application objects.

=head1 METHODS for Application objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'application'; };
}

#===============================================================================
# Rinchi::Outlook::Application::AnswerWizard

=head2 $value = $Object->AnswerWizard([$new_value]);

Set or get value of the AnswerWizard attribute.

  
 Type: AnswerWizard
 Lower: 0
 Upper: 1

=cut

sub AnswerWizard() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::AnswerWizard' =~ /$regexp/ ) {
      $self->attribute_as_element('AnswerWizard', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::AnswerWizard\' for attribute \'AnswerWizard\'';
    }
  }
  return $self->attribute_as_element('AnswerWizard');
}

#===============================================================================
# Rinchi::Outlook::Application::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::Application::Assistant

=head2 $value = $Object->Assistant([$new_value]);

Set or get value of the Assistant attribute.

  
 Type: Assistant
 Lower: 0
 Upper: 1

=cut

sub Assistant() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Assistant' =~ /$regexp/ ) {
      $self->attribute_as_element('Assistant', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Assistant\' for attribute \'Assistant\'';
    }
  }
  return $self->attribute_as_element('Assistant');
}

#===============================================================================
# Rinchi::Outlook::Application::COMAddIns

=head2 $value = $Object->COMAddIns([$new_value]);

Set or get value of the COMAddIns attribute.

  
 Type: COMAddIns
 Lower: 0
 Upper: 1

=cut

sub COMAddIns() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::COMAddIns' =~ /$regexp/ ) {
      $self->attribute_as_element('COMAddIns', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::COMAddIns\' for attribute \'COMAddIns\'';
    }
  }
  return $self->attribute_as_element('COMAddIns');
}

#===============================================================================
# Rinchi::Outlook::Application::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::Application::Explorers

=head2 $Element = $Object->Explorers();

Set or get value of the Explorers attribute.

  
 Type: Explorers
 Lower: 0
 Upper: 1

=cut

sub Explorers() {
  my $self = shift;
  return $self->get_collection('Explorers','explorers');
}

#===============================================================================
# Rinchi::Outlook::Application::FeatureInstall

=head2 $value = $Object->FeatureInstall([$new_value]);

Set or get value of the FeatureInstall attribute.

  
 Type: MsoFeatureInstall
 Lower: 0
 Upper: 1

=cut

sub FeatureInstall() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::MsoFeatureInstall' =~ /$regexp/ ) {
      $self->attribute_as_element('FeatureInstall', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::MsoFeatureInstall\' for attribute \'FeatureInstall\'';
    }
  }
  return $self->attribute_as_element('FeatureInstall');
}

#===============================================================================
# Rinchi::Outlook::Application::Inspectors

=head2 $Element = $Object->Inspectors();

Set or get value of the Inspectors attribute.

  
 Type: Inspectors
 Lower: 0
 Upper: 1

=cut

sub Inspectors() {
  my $self = shift;
  return $self->get_collection('Inspectors','inspectors');
}

#===============================================================================
# Rinchi::Outlook::Application::LanguageSettings

=head2 $value = $Object->LanguageSettings([$new_value]);

Set or get value of the LanguageSettings attribute.

  
 Type: LanguageSettings
 Lower: 0
 Upper: 1

=cut

sub LanguageSettings() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::LanguageSettings' =~ /$regexp/ ) {
      $self->attribute_as_element('LanguageSettings', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::LanguageSettings\' for attribute \'LanguageSettings\'';
    }
  }
  return $self->attribute_as_element('LanguageSettings');
}

#===============================================================================
# Rinchi::Outlook::Application::Name

=head2 $value = $Object->Name([$new_value]);

Set or get value of the Name attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Name() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Name', shift);
  }
  return $self->getAttribute('Name');
}

#===============================================================================
# Rinchi::Outlook::Application::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::Application::ProductCode

=head2 $value = $Object->ProductCode([$new_value]);

Set or get value of the ProductCode attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ProductCode() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ProductCode', shift);
  }
  return $self->getAttribute('ProductCode');
}

#===============================================================================
# Rinchi::Outlook::Application::Reminders

=head2 $Element = $Object->Reminders();

Set or get value of the Reminders attribute.

  
 Type: Reminders
 Lower: 0
 Upper: 1

=cut

sub Reminders() {
  my $self = shift;
  return $self->get_collection('Reminders','reminders');
}

#===============================================================================
# Rinchi::Outlook::Application::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::Application::Version

=head2 $value = $Object->Version([$new_value]);

Set or get value of the Version attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Version() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Version', shift);
  }
  return $self->getAttribute('Version');
}

##END_PACKAGE Application

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5da3d18-3c43-11dd-b5da-001c25551abc

package Rinchi::Outlook::Attachment;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Attachment

Rinchi::Outlook::Attachment is used for representing Attachment objects. 
An Attachment represents a document or link to a document contained in an Outlook item.

=head1 METHODS for Attachment objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'attachment'; };
}

#===============================================================================
# Rinchi::Outlook::Attachment::DisplayName

=head2 $value = $Object->DisplayName([$new_value]);

Set or get value of the DisplayName attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub DisplayName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DisplayName', shift);
  }
  return $self->getAttribute('DisplayName');
}

#===============================================================================
# Rinchi::Outlook::Attachment::FileName

=head2 $value = $Object->FileName([$new_value]);

Set or get value of the FileName attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FileName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FileName', shift);
  }
  return $self->getAttribute('FileName');
}

#===============================================================================
# Rinchi::Outlook::Attachment::Index

=head2 $value = $Object->Index([$new_value]);

Set or get value of the Index attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Index() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Index', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Index\'';
    }
  }
  return $self->getAttribute('Index');
}

#===============================================================================
# Rinchi::Outlook::Attachment::PathName

=head2 $value = $Object->PathName([$new_value]);

Set or get value of the PathName attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub PathName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('PathName', shift);
  }
  return $self->getAttribute('PathName');
}

#===============================================================================
# Rinchi::Outlook::Attachment::Position

=head2 $value = $Object->Position([$new_value]);

Set or get value of the Position attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Position() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Position', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Position\'';
    }
  }
  return $self->getAttribute('Position');
}

#===============================================================================
# Rinchi::Outlook::Attachment::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.
  
 Type: OlAttachmentType
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Type', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlAttachmentType\' for attribute \'Type\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlAttachmentType\' for attribute \'Type\'';
      }
    }
  }
  return $self->getAttribute('Type');
}

#===============================================================================
# Rinchi::Outlook::Attachment::MD5

=head2 $value = $Object->MD5([$new_value]);

Set or get value of the MD5 attribute.

  Added attribute for saving the MD5 hash of the saved attachement.  This is used for elimination of duplicate files.

 Type: String
 Lower: 1
 Upper: 1

=cut

sub MD5() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MD5', shift);
  }
  return $self->getAttribute('MD5');
}

##END_PACKAGE Attachment

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5da5da2-3c43-11dd-9c43-001c25551abc

package Rinchi::Outlook::Conflict;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Conflict class

Rinchi::Outlook::Conflict is used for representing Conflict objects.

=head1 METHODS for Conflict objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'conflict'; };
}

#===============================================================================
# Rinchi::Outlook::Conflict::Item

=head2 $value = $Object->Item([$new_value]);

Set or get value of the Item attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Item() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Item', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Item\'';
    }
  }
  return $self->attribute_as_element('Item');
}

#===============================================================================
# Rinchi::Outlook::Conflict::Name

=head2 $value = $Object->Name([$new_value]);

Set or get value of the Name attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Name() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Name', shift);
  }
  return $self->getAttribute('Name');
}

#===============================================================================
# Rinchi::Outlook::Conflict::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.
  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Type', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Type\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Type\'';
      }
    }
  }
  return $self->getAttribute('Type');
}

##END_PACKAGE Conflict

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5db2980-3c43-11dd-8119-001c25551abc

package Rinchi::Outlook::Exception;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Exception class

Rinchi::Outlook::Exception is used for representing Exception objects. An 
Exception object holds information about one instance of an AppointmentItem object 
which is an exception to a recurring series. 

=head1 METHODS for Exception objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'exception'; };
}

#===============================================================================
# Rinchi::Outlook::Exception::AppointmentItem

=head2 $value = $Object->AppointmentItem([$new_value]);

Set or get value of the AppointmentItem attribute.
  
 Type: AppointmentItem
 Lower: 0
 Upper: 1

=cut

sub AppointmentItem() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::AppointmentItem' =~ /$regexp/ ) {
      $self->attribute_as_element('AppointmentItem', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::AppointmentItem\' for attribute \'AppointmentItem\'';
    }
  }
  return $self->attribute_as_element('AppointmentItem');
}

#===============================================================================
# Rinchi::Outlook::Exception::Deleted

=head2 $value = $Object->Deleted([$new_value]);

Set or get value of the Deleted attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Deleted() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Deleted', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Deleted\'';
    }
  }
  return $self->getAttribute('Deleted');
}

#===============================================================================
# Rinchi::Outlook::Exception::ItemProperties

=head2 $Element = $Object->ItemProperties();

Set or get value of the ItemProperties attribute.
  
 Type: ItemProperties (Collection)
 Lower: 0
 Upper: 1

=cut

sub ItemProperties() {
  my $self = shift;
  return $self->get_collection('ItemProperties','item-properties');
}

#===============================================================================
# Rinchi::Outlook::Exception::OriginalDate

=head2 $value = $Object->OriginalDate([$new_value]);

Set or get value of the OriginalDate attribute.
  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub OriginalDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OriginalDate', shift);
  }
  return $self->getAttribute('OriginalDate');
}

##END_PACKAGE Exception

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5db58c4-3c43-11dd-88a8-001c25551abc

package Rinchi::Outlook::Explorer;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Explorer class

Rinchi::Outlook::Explorer is used for representing Explorer objects. An Explorer 
represents the window in which the contents of a folder are displayed.

=head1 METHODS for Explorer objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'explorer'; };
}

#===============================================================================
# Rinchi::Outlook::Explorer::Caption

=head2 $value = $Object->Caption([$new_value]);

Set or get value of the Caption attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Caption() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Caption', shift);
  }
  return $self->getAttribute('Caption');
}

#===============================================================================
# Rinchi::Outlook::Explorer::CommandBars

=head2 $value = $Object->CommandBars([$new_value]);

Set or get value of the CommandBars attribute.
  
 Type: CommandBars (Collection)
 Lower: 0
 Upper: 1

=cut

sub CommandBars() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::CommandBars' =~ /$regexp/ ) {
      $self->attribute_as_element('CommandBars', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::CommandBars\' for attribute \'CommandBars\'';
    }
  }
  return $self->attribute_as_element('CommandBars');
}

#===============================================================================
# Rinchi::Outlook::Explorer::CurrentFolder

=head2 $value = $Object->CurrentFolder([$new_value]);

Set or get value of the CurrentFolder attribute.
  
 Type: MAPIFolder
 Lower: 0
 Upper: 1

=cut

sub CurrentFolder() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::MAPIFolder' =~ /$regexp/ ) {
      $self->attribute_as_element('CurrentFolder', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::MAPIFolder\' for attribute \'CurrentFolder\'';
    }
  }
  return $self->attribute_as_element('CurrentFolder');
}

#===============================================================================
# Rinchi::Outlook::Explorer::CurrentView

=head2 $value = $Object->CurrentView([$new_value]);

Set or get value of the CurrentView attribute.

 Type: Variant
 Lower: 0
 Upper: 1

=cut

sub CurrentView() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Variant' =~ /$regexp/ ) {
      $self->attribute_as_element('CurrentView', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Variant\' for attribute \'CurrentView\'';
    }
  }
  return $self->attribute_as_element('CurrentView');
}

#===============================================================================
# Rinchi::Outlook::Explorer::HTMLDocument

=head2 $value = $Object->HTMLDocument([$new_value]);

Set or get value of the HTMLDocument attribute.

 Type: Object
 Lower: 0
 Upper: 1

=cut

sub HTMLDocument() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('HTMLDocument', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'HTMLDocument\'';
    }
  }
  return $self->attribute_as_element('HTMLDocument');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Height

=head2 $value = $Object->Height([$new_value]);

Set or get value of the Height attribute.

 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Height() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Height', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Height\'';
    }
  }
  return $self->getAttribute('Height');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Left

=head2 $value = $Object->Left([$new_value]);

Set or get value of the Left attribute.

 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Left() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Left', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Left\'';
    }
  }
  return $self->getAttribute('Left');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Panes

=head2 $Element = $Object->Panes();

Set or get value of the Panes attribute.
  
 Type: Panes (Collection)
 Lower: 0
 Upper: 1

=cut

sub Panes() {
  my $self = shift;
  return $self->get_collection('Panes','panes');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Selection

=head2 $value = $Object->Selection([$new_value]);

Set or get value of the Selection attribute.
  
 Type: Selection
 Lower: 0
 Upper: 1

=cut

sub Selection() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Selection' =~ /$regexp/ ) {
      $self->attribute_as_element('Selection', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Selection\' for attribute \'Selection\'';
    }
  }
  return $self->attribute_as_element('Selection');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Top

=head2 $value = $Object->Top([$new_value]);

Set or get value of the Top attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Top() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Top', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Top\'';
    }
  }
  return $self->getAttribute('Top');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Views

=head2 $value = $Object->Views([$new_value]);

Set or get value of the Views attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Views() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Views', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Views\'';
    }
  }
  return $self->attribute_as_element('Views');
}

#===============================================================================
# Rinchi::Outlook::Explorer::Width

=head2 $value = $Object->Width([$new_value]);

Set or get value of the Width attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Width() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Width', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Width\'';
    }
  }
  return $self->getAttribute('Width');
}

#===============================================================================
# Rinchi::Outlook::Explorer::WindowState

=head2 $value = $Object->WindowState([$new_value]);

Set or get value of the WindowState attribute.
  
 Type: OlWindowState
 Lower: 0
 Upper: 1

=cut

sub WindowState() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('WindowState', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlWindowState\' for attribute \'WindowState\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlWindowState\' for attribute \'WindowState\'';
      }
    }
  }
  return $self->getAttribute('WindowState');
}

##END_PACKAGE Explorer

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dbe85c-3c43-11dd-9f5c-001c25551abc

package Rinchi::Outlook::FormDescription;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of FormDescription class

Rinchi::Outlook::FormDescription is used for representing FormDescription objects. 
A FormDescription contains the general properties of a Microsoft Outlook form. 

=head1 METHODS for FormDescription objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'form-description'; };
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.
  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Category

=head2 $value = $Object->Category([$new_value]);

Set or get value of the Category attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Category() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Category', shift);
  }
  return $self->getAttribute('Category');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::CategorySub

=head2 $value = $Object->CategorySub([$new_value]);

Set or get value of the CategorySub attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CategorySub() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CategorySub', shift);
  }
  return $self->getAttribute('CategorySub');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.
  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Comment

=head2 $value = $Object->Comment([$new_value]);

Set or get value of the Comment attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Comment() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Comment', shift);
  }
  return $self->getAttribute('Comment');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::ContactName

=head2 $value = $Object->ContactName([$new_value]);

Set or get value of the ContactName attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ContactName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ContactName', shift);
  }
  return $self->getAttribute('ContactName');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::DisplayName

=head2 $value = $Object->DisplayName([$new_value]);

Set or get value of the DisplayName attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub DisplayName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DisplayName', shift);
  }
  return $self->getAttribute('DisplayName');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Hidden

=head2 $value = $Object->Hidden([$new_value]);

Set or get value of the Hidden attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Hidden() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Hidden', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Hidden\'';
    }
  }
  return $self->getAttribute('Hidden');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Icon

=head2 $value = $Object->Icon([$new_value]);

Set or get value of the Icon attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Icon() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Icon', shift);
  }
  return $self->getAttribute('Icon');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Locked

=head2 $value = $Object->Locked([$new_value]);

Set or get value of the Locked attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Locked() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Locked', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Locked\'';
    }
  }
  return $self->getAttribute('Locked');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::MessageClass

=head2 $value = $Object->MessageClass([$new_value]);

Set or get value of the MessageClass attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MessageClass() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MessageClass', shift);
  }
  return $self->getAttribute('MessageClass');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::MiniIcon

=head2 $value = $Object->MiniIcon([$new_value]);

Set or get value of the MiniIcon attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MiniIcon() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MiniIcon', shift);
  }
  return $self->getAttribute('MiniIcon');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Name

=head2 $value = $Object->Name([$new_value]);

Set or get value of the Name attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Name() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Name', shift);
  }
  return $self->getAttribute('Name');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Number

=head2 $value = $Object->Number([$new_value]);

Set or get value of the Number attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Number() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Number', shift);
  }
  return $self->getAttribute('Number');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::OneOff

=head2 $value = $Object->OneOff([$new_value]);

Set or get value of the OneOff attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub OneOff() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('OneOff', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'OneOff\'';
    }
  }
  return $self->getAttribute('OneOff');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Password

=head2 $value = $Object->Password([$new_value]);

Set or get value of the Password attribute.
 
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Password() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Password', shift);
  }
  return $self->getAttribute('Password');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::ScriptText

=head2 $value = $Object->ScriptText([$new_value]);

Set or get value of the ScriptText attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ScriptText() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ScriptText', shift);
  }
  return $self->getAttribute('ScriptText');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.
  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Template

=head2 $value = $Object->Template([$new_value]);

Set or get value of the Template attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Template() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Template', shift);
  }
  return $self->getAttribute('Template');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::UseWordMail

=head2 $value = $Object->UseWordMail([$new_value]);

Set or get value of the UseWordMail attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub UseWordMail() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('UseWordMail', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'UseWordMail\'';
    }
  }
  return $self->getAttribute('UseWordMail');
}

#===============================================================================
# Rinchi::Outlook::FormDescription::Version

=head2 $value = $Object->Version([$new_value]);

Set or get value of the Version attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Version() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Version', shift);
  }
  return $self->getAttribute('Version');
}

##END_PACKAGE FormDescription

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dc083c-3c43-11dd-9e97-001c25551abc

package Rinchi::Outlook::Inspector;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Inspector class

Rinchi::Outlook::Inspector is used for representing Inspector objects. An 
Inspector represents the window in which an Outlook item is displayed.

=head1 METHODS for Inspector objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'inspector'; };
}

#===============================================================================
# Rinchi::Outlook::Inspector::Caption

=head2 $value = $Object->Caption([$new_value]);

Set or get value of the Caption attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Caption() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Caption', shift);
  }
  return $self->getAttribute('Caption');
}

#===============================================================================
# Rinchi::Outlook::Inspector::CommandBars

=head2 $value = $Object->CommandBars([$new_value]);

Set or get value of the CommandBars attribute.

 Type: CommandBars
 Lower: 0
 Upper: 1

=cut

sub CommandBars() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::CommandBars' =~ /$regexp/ ) {
      $self->attribute_as_element('CommandBars', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::CommandBars\' for attribute \'CommandBars\'';
    }
  }
  return $self->attribute_as_element('CommandBars');
}

#===============================================================================
# Rinchi::Outlook::Inspector::CurrentItem

=head2 $value = $Object->CurrentItem([$new_value]);

Set or get value of the CurrentItem attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub CurrentItem() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('CurrentItem', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'CurrentItem\'';
    }
  }
  return $self->attribute_as_element('CurrentItem');
}

#===============================================================================
# Rinchi::Outlook::Inspector::EditorType

=head2 $value = $Object->EditorType([$new_value]);

Set or get value of the EditorType attribute.

 Type: OlEditorType
 Lower: 0
 Upper: 1

=cut

sub EditorType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('EditorType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlEditorType\' for attribute \'EditorType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlEditorType\' for attribute \'EditorType\'';
      }
    }
  }
  return $self->getAttribute('EditorType');
}

#===============================================================================
# Rinchi::Outlook::Inspector::HTMLEditor

=head2 $value = $Object->HTMLEditor([$new_value]);

Set or get value of the HTMLEditor attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub HTMLEditor() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('HTMLEditor', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'HTMLEditor\'';
    }
  }
  return $self->attribute_as_element('HTMLEditor');
}

#===============================================================================
# Rinchi::Outlook::Inspector::Height

=head2 $value = $Object->Height([$new_value]);

Set or get value of the Height attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Height() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Height', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Height\'';
    }
  }
  return $self->getAttribute('Height');
}

#===============================================================================
# Rinchi::Outlook::Inspector::Left

=head2 $value = $Object->Left([$new_value]);

Set or get value of the Left attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Left() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Left', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Left\'';
    }
  }
  return $self->getAttribute('Left');
}

#===============================================================================
# Rinchi::Outlook::Inspector::ModifiedFormPages

=head2 $value = $Object->ModifiedFormPages([$new_value]);

Set or get value of the ModifiedFormPages attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub ModifiedFormPages() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('ModifiedFormPages', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'ModifiedFormPages\'';
    }
  }
  return $self->attribute_as_element('ModifiedFormPages');
}

#===============================================================================
# Rinchi::Outlook::Inspector::Top

=head2 $value = $Object->Top([$new_value]);

Set or get value of the Top attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Top() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Top', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Top\'';
    }
  }
  return $self->getAttribute('Top');
}

#===============================================================================
# Rinchi::Outlook::Inspector::Width

=head2 $value = $Object->Width([$new_value]);

Set or get value of the Width attribute.
  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Width() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Width', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Width\'';
    }
  }
  return $self->getAttribute('Width');
}

#===============================================================================
# Rinchi::Outlook::Inspector::WindowState

=head2 $value = $Object->WindowState([$new_value]);

Set or get value of the WindowState attribute.
  
 Type: OlWindowState
 Lower: 0
 Upper: 1

=cut

sub WindowState() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('WindowState', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlWindowState\' for attribute \'WindowState\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlWindowState\' for attribute \'WindowState\'';
      }
    }
  }
  return $self->getAttribute('WindowState');
}

#===============================================================================
# Rinchi::Outlook::Inspector::WordEditor

=head2 $value = $Object->WordEditor([$new_value]);

Set or get value of the WordEditor attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub WordEditor() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('WordEditor', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'WordEditor\'';
    }
  }
  return $self->attribute_as_element('WordEditor');
}

##END_PACKAGE Inspector

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dc9856-3c43-11dd-8064-001c25551abc

package Rinchi::Outlook::ItemProperty;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ItemProperty class

Rinchi::Outlook::ItemProperty is used for representing ItemProperty objects. An 
ItemProperty object contains information about a given item property. Each item 
property defines a certain attribute of the item, such as the name, type, or 
value of the item. The ItemProperty object is a member of the ItemProperties 
collection.

=head1 METHODS for ItemProperty objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'item-property'; };
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::Formula

=head2 $value = $Object->Formula([$new_value]);

Set or get value of the Formula attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Formula() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Formula', shift);
  }
  return $self->getAttribute('Formula');
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::IsUserProperty

=head2 $value = $Object->IsUserProperty([$new_value]);

Set or get value of the IsUserProperty attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsUserProperty() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsUserProperty', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsUserProperty\'';
    }
  }
  return $self->getAttribute('IsUserProperty');
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.
  
 Type: OlUserPropertyType
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Type', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlUserPropertyType\' for attribute \'Type\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlUserPropertyType\' for attribute \'Type\'';
      }
    }
  }
  return $self->getAttribute('Type');
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::ValidationFormula

=head2 $value = $Object->ValidationFormula([$new_value]);

Set or get value of the ValidationFormula attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ValidationFormula() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ValidationFormula', shift);
  }
  return $self->getAttribute('ValidationFormula');
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::ValidationText

=head2 $value = $Object->ValidationText([$new_value]);

Set or get value of the ValidationText attribute.
  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ValidationText() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ValidationText', shift);
  }
  return $self->getAttribute('ValidationText');
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.
  
 Type: Variant
 Lower: 0
 Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Variant' =~ /$regexp/ ) {
      $self->attribute_as_element('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Variant\' for attribute \'Value\'';
    }
  }
  return $self->attribute_as_element('Value');
}

##END_PACKAGE ItemProperty

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dcf6b6-3c43-11dd-a30d-001c25551abc

package Rinchi::Outlook::Link;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Link class

Rinchi::Outlook::Link is used for representing Link objects. A Link represents 
an item  that is linked to another Microsoft Outlook item. Each item has a Links 
object associated with it that represents all the items that have been linked to 
the item.

=head1 METHODS for Link objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'link'; };
}

#===============================================================================
# Rinchi::Outlook::Link::Item

=head2 $value = $Object->Item([$new_value]);

Set or get value of the Item attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Item() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Item', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Item\'';
    }
  }
  return $self->attribute_as_element('Item');
}

#===============================================================================
# Rinchi::Outlook::Link::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.
  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Type', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Type\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Type\'';
      }
    }
  }
  return $self->getAttribute('Type');
}

##END_PACKAGE Link

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dd1632-3c43-11dd-b339-001c25551abc

package Rinchi::Outlook::MAPIFolder;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MAPIFolder class

Rinchi::Outlook::MAPIFolder is used for representing MAPIFolder objects. A 
MAPIFolder object Represents a Microsoft Outlook folder. A MAPIFolder object can 
contain other MAPIFolder objects, as well as Outlook items.

=head1 METHODS for MAPIFolder objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'mapi-folder'; };
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::AddressBookName

=head2 $value = $Object->AddressBookName([$new_value]);

Set or get value of the AddressBookName attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub AddressBookName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('AddressBookName', shift);
  }
  return $self->getAttribute('AddressBookName');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::CurrentView

=head2 $value = $Object->CurrentView([$new_value]);

Set or get value of the CurrentView attribute.

 Type: View
 Lower: 0
 Upper: 1

=cut

sub CurrentView() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::View' =~ /$regexp/ ) {
      $self->attribute_as_element('CurrentView', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::View\' for attribute \'CurrentView\'';
    }
  }
  return $self->attribute_as_element('CurrentView');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::CustomViewsOnly

=head2 $value = $Object->CustomViewsOnly([$new_value]);

Set or get value of the CustomViewsOnly attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub CustomViewsOnly() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('CustomViewsOnly', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'CustomViewsOnly\'';
    }
  }
  return $self->getAttribute('CustomViewsOnly');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::DefaultItemType

=head2 $value = $Object->DefaultItemType([$new_value]);

Set or get value of the DefaultItemType attribute.

 Type: OlItemType
 Lower: 0
 Upper: 1

=cut

sub DefaultItemType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DefaultItemType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlItemType\' for attribute \'DefaultItemType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlItemType\' for attribute \'DefaultItemType\'';
      }
    }
  }
  return $self->getAttribute('DefaultItemType');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::DefaultMessageClass

=head2 $value = $Object->DefaultMessageClass([$new_value]);

Set or get value of the DefaultMessageClass attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub DefaultMessageClass() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DefaultMessageClass', shift);
  }
  return $self->getAttribute('DefaultMessageClass');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::Description

=head2 $value = $Object->Description([$new_value]);

Set or get value of the Description attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub Description() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Description', shift);
  }
  return $self->getAttribute('Description');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::EntryID

=head2 $value = $Object->EntryID([$new_value]);

Set or get value of the EntryID attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub EntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('EntryID', shift);
  }
  return $self->getAttribute('EntryID');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::FolderPath

=head2 $value = $Object->FolderPath([$new_value]);

Set or get value of the FolderPath attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub FolderPath() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FolderPath', shift);
  }
  return $self->getAttribute('FolderPath');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::Folders

=head2 $Element = $Object->Folders();

Set or get value of the Folders attribute.

 Type: Folders
 Lower: 0
 Upper: 1

=cut

sub Folders() {
  my $self = shift;
  return $self->get_collection('Folders','folders');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::FullFolderPath

=head2 $value = $Object->FullFolderPath([$new_value]);

Set or get value of the FullFolderPath attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub FullFolderPath() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FullFolderPath', shift);
  }
  return $self->getAttribute('FullFolderPath');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::InAppFolderSyncObject

=head2 $value = $Object->InAppFolderSyncObject([$new_value]);

Set or get value of the InAppFolderSyncObject attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub InAppFolderSyncObject() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('InAppFolderSyncObject', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'InAppFolderSyncObject\'';
    }
  }
  return $self->getAttribute('InAppFolderSyncObject');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::IsSharePointFolder

=head2 $value = $Object->IsSharePointFolder([$new_value]);

Set or get value of the IsSharePointFolder attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsSharePointFolder() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsSharePointFolder', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsSharePointFolder\'';
    }
  }
  return $self->getAttribute('IsSharePointFolder');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::Items

=head2 $Element = $Object->Items();

Set or get value of the Items attribute.

 Type: Items
 Lower: 0
 Upper: 1

=cut

sub Items() {
  my $self = shift;
  return $self->get_collection('Items','items');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::ShowAsOutlookAB

=head2 $value = $Object->ShowAsOutlookAB([$new_value]);

Set or get value of the ShowAsOutlookAB attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ShowAsOutlookAB() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ShowAsOutlookAB', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ShowAsOutlookAB\'';
    }
  }
  return $self->getAttribute('ShowAsOutlookAB');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::ShowItemCount

=head2 $value = $Object->ShowItemCount([$new_value]);

Set or get value of the ShowItemCount attribute.

 Type: OlShowItemCount
 Lower: 0
 Upper: 1

=cut

sub ShowItemCount() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ShowItemCount', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlShowItemCount\' for attribute \'ShowItemCount\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlShowItemCount\' for attribute \'ShowItemCount\'';
      }
    }
  }
  return $self->getAttribute('ShowItemCount');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::StoreID

=head2 $value = $Object->StoreID([$new_value]);

Set or get value of the StoreID attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub StoreID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('StoreID', shift);
  }
  return $self->getAttribute('StoreID');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::UnReadItemCount

=head2 $value = $Object->UnReadItemCount([$new_value]);

Set or get value of the UnReadItemCount attribute.

 Type: Long
 Lower: 0
 Upper: 1

=cut

sub UnReadItemCount() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('UnReadItemCount', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'UnReadItemCount\'';
    }
  }
  return $self->getAttribute('UnReadItemCount');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::UserPermissions

=head2 $value = $Object->UserPermissions([$new_value]);

Set or get value of the UserPermissions attribute.

 Type: Object
 Lower: 0
 Upper: 1

=cut

sub UserPermissions() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('UserPermissions', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'UserPermissions\'';
    }
  }
  return $self->attribute_as_element('UserPermissions');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::Views

=head2 $Element = $Object->Views();

Set or get value of the Views attribute.

 Type: Views
 Lower: 0
 Upper: 1

=cut

sub Views() {
  my $self = shift;
  return $self->get_collection('Views','views');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::WebViewAllowNavigation

=head2 $value = $Object->WebViewAllowNavigation([$new_value]);

Set or get value of the WebViewAllowNavigation attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub WebViewAllowNavigation() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('WebViewAllowNavigation', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'WebViewAllowNavigation\'';
    }
  }
  return $self->getAttribute('WebViewAllowNavigation');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::WebViewOn

=head2 $value = $Object->WebViewOn([$new_value]);

Set or get value of the WebViewOn attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub WebViewOn() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('WebViewOn', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'WebViewOn\'';
    }
  }
  return $self->getAttribute('WebViewOn');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::WebViewURL

=head2 $value = $Object->WebViewURL([$new_value]);

Set or get value of the WebViewURL attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub WebViewURL() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('WebViewURL', shift);
  }
  return $self->getAttribute('WebViewURL');
}

##END_PACKAGE MAPIFolder

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dd7456-3c43-11dd-80a4-001c25551abc

package Rinchi::Outlook::NameSpace;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of NameSpace class

Rinchi::Outlook::NameSpace is used for representing NameSpace objects. A 
NameSpace object represents an abstract root object for any data source.

=head1 METHODS for NameSpace objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'name-space'; };
}

#===============================================================================
# Rinchi::Outlook::NameSpace::AddressLists

=head2 $Element = $Object->AddressLists();

Set or get value of the AddressLists attribute.
  
 Type: AddressLists (Collection)
 Lower: 1
 Upper: 1

=cut

sub AddressLists() {
  my $self = shift;
  return $self->get_collection('AddressLists','address-lists');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.
  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.
  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::CurrentUser

=head2 $value = $Object->CurrentUser([$new_value]);

Set or get value of the CurrentUser attribute.
  
 Type: Recipient
 Lower: 0
 Upper: 1

=cut

sub CurrentUser() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Recipient' =~ /$regexp/ ) {
      $self->attribute_as_element('CurrentUser', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Recipient\' for attribute \'CurrentUser\'';
    }
  }
  return $self->attribute_as_element('CurrentUser');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::ExchangeConnectionMode

=head2 $value = $Object->ExchangeConnectionMode([$new_value]);

Set or get value of the ExchangeConnectionMode attribute.
  
 Type: OlExchangeConnectionMode
 Lower: 0
 Upper: 1

=cut

sub ExchangeConnectionMode() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ExchangeConnectionMode', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlExchangeConnectionMode\' for attribute \'ExchangeConnectionMode\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlExchangeConnectionMode\' for attribute \'ExchangeConnectionMode\'';
      }
    }
  }
  return $self->getAttribute('ExchangeConnectionMode');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Folders

=head2 $Element = $Object->Folders();

Set or get value of the Folders attribute.
  
 Type: Folders
 Lower: 0
 Upper: 1

=cut

sub Folders() {
  my $self = shift;
  return $self->get_collection('Folders','folders');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Offline

=head2 $value = $Object->Offline([$new_value]);

Set or get value of the Offline attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Offline() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Offline', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Offline\'';
    }
  }
  return $self->getAttribute('Offline');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.
  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.
  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::SyncObjects

=head2 $Element = $Object->SyncObjects();

Set or get value of the SyncObjects attribute.

 Type: SyncObjects
 Lower: 0
 Upper: 1

=cut

sub SyncObjects() {
  my $self = shift;
  return $self->get_collection('SyncObjects','sync-objects');
}

#===============================================================================
# Rinchi::Outlook::NameSpace::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Type', shift);
  }
  return $self->getAttribute('Type');
}

##END_PACKAGE NameSpace

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5ddb330-3c43-11dd-b4b7-001c25551abc

package Rinchi::Outlook::OutlookBarGroup;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBarGroup class

Rinchi::Outlook::OutlookBarGroup is used for representing OutlookBarGroup objects. 
An OutlookBarGroup object represents a group of shortcuts in the Shortcuts pane 
of an explorer window.

=head1 METHODS for OutlookBarGroup objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-bar-group'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBarGroup::Shortcuts

=head2 $Element = $Object->Shortcuts();

Set or get value of the Shortcuts attribute.

 Type: OutlookBarShortcuts (Collection)
 Lower: 0
 Upper: 1

=cut

sub Shortcuts() {
  my $self = shift;
  return $self->get_collection('OutlookBarShortcuts','outlook-bar-shortcuts');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarGroup::ViewType

=head2 $value = $Object->ViewType([$new_value]);

Set or get value of the ViewType attribute.

 Type: OlOutlookBarViewType
 Lower: 0
 Upper: 1

=cut

sub ViewType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ViewType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlOutlookBarViewType\' for attribute \'ViewType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlOutlookBarViewType\' for attribute \'ViewType\'';
      }
    }
  }
  return $self->getAttribute('ViewType');
}

##END_PACKAGE OutlookBarGroup

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5de0204-3c43-11dd-b533-001c25551abc

package Rinchi::Outlook::OutlookBarPane;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBarPane class

Rinchi::Outlook::OutlookBarPane is used for representing OutlookBarPane objects.
An OutlookBarPane object represents the Shortcuts pane in an explorer window.

=head1 METHODS for OutlookBarPane objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-bar-pane'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Contents

=head2 $value = $Object->Contents([$new_value]);

Set or get value of the Contents attribute.

 Type: OutlookBarStorage
 Lower: 0
 Upper: 1

=cut

sub Contents() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::OutlookBarStorage' =~ /$regexp/ ) {
      $self->attribute_as_element('Contents', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OutlookBarStorage\' for attribute \'Contents\'';
    }
  }
  return $self->attribute_as_element('Contents');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::CurrentGroup

=head2 $value = $Object->CurrentGroup([$new_value]);

Set or get value of the CurrentGroup attribute.

 Type: OutlookBarGroup
 Lower: 0
 Upper: 1

=cut

sub CurrentGroup() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::OutlookBarGroup' =~ /$regexp/ ) {
      $self->attribute_as_element('CurrentGroup', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OutlookBarGroup\' for attribute \'CurrentGroup\'';
    }
  }
  return $self->attribute_as_element('CurrentGroup');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Name

=head2 $value = $Object->Name([$new_value]);

Set or get value of the Name attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub Name() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Name', shift);
  }
  return $self->getAttribute('Name');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarPane::Visible

=head2 $value = $Object->Visible([$new_value]);

Set or get value of the Visible attribute.

 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Visible() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Visible', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Visible\'';
    }
  }
  return $self->getAttribute('Visible');
}

##END_PACKAGE OutlookBarPane

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5de228e-3c43-11dd-9241-001c25551abc

package Rinchi::Outlook::OutlookBarShortcut;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBarShortcut class

Rinchi::Outlook::OutlookBarShortcut is used for representing OutlookBarShortcut objects.

=head1 METHODS for OutlookBarShortcut objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-bar-shortcut'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBarShortcut::Target

=head2 $value = $Object->Target([$new_value]);

Set or get value of the Target attribute.

  
 Type: Variant
 Lower: 0
 Upper: 1

=cut

sub Target() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Variant' =~ /$regexp/ ) {
      $self->attribute_as_element('Target', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Variant\' for attribute \'Target\'';
    }
  }
  return $self->attribute_as_element('Target');
}

##END_PACKAGE OutlookBarShortcut

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5de61f4-3c43-11dd-a7bb-001c25551abc

package Rinchi::Outlook::OutlookBarStorage;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBarStorage class

Rinchi::Outlook::OutlookBarStorage is used for representing OutlookBarStorage objects.

=head1 METHODS for OutlookBarStorage objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-bar-storage'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBarStorage::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarStorage::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarStorage::Groups

=head2 $value = $Object->Groups([$new_value]);

Set or get value of the Groups attribute.

  
 Type: 
 Lower: 0
 Upper: 1

=cut

sub Groups() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::' =~ /$regexp/ ) {
      $self->attribute_as_element('Groups', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::\' for attribute \'Groups\'';
    }
  }
  return $self->attribute_as_element('Groups');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarStorage::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::OutlookBarStorage::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

##END_PACKAGE OutlookBarStorage

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5deb190-3c43-11dd-818d-001c25551abc

package Rinchi::Outlook::PropertyPageSite;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of PropertyPageSite class

Rinchi::Outlook::PropertyPageSite is used for representing PropertyPageSite objects.

=head1 METHODS for PropertyPageSite objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'property-page-site'; };
}

##END_PACKAGE PropertyPageSite

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5ded1de-3c43-11dd-85e5-001c25551abc

package Rinchi::Outlook::Recipient;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Recipient class

Rinchi::Outlook::Recipient is used for representing Recipient objects.

=head1 METHODS for Recipient objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'recipient'; };
}

#===============================================================================
# Rinchi::Outlook::Recipient::Address

=head2 $value = $Object->Address([$new_value]);

Set or get value of the Address attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Address() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Address', shift);
  }
  return $self->getAttribute('Address');
}

#===============================================================================
# Rinchi::Outlook::Recipient::AddressEntry

=head2 $value = $Object->AddressEntry([$new_value]);

Set or get value of the AddressEntry attribute.

  
 Type: AddressEntry
 Lower: 0
 Upper: 1

=cut

sub AddressEntry() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::AddressEntry' =~ /$regexp/ ) {
      $self->attribute_as_element('AddressEntry', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::AddressEntry\' for attribute \'AddressEntry\'';
    }
  }
  return $self->attribute_as_element('AddressEntry');
}

#===============================================================================
# Rinchi::Outlook::Recipient::AutoResponse

=head2 $value = $Object->AutoResponse([$new_value]);

Set or get value of the AutoResponse attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub AutoResponse() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('AutoResponse', shift);
  }
  return $self->getAttribute('AutoResponse');
}

#===============================================================================
# Rinchi::Outlook::Recipient::DisplayType

=head2 $value = $Object->DisplayType([$new_value]);

Set or get value of the DisplayType attribute.

  
 Type: OlDisplayType
 Lower: 0
 Upper: 1

=cut

sub DisplayType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DisplayType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlDisplayType\' for attribute \'DisplayType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlDisplayType\' for attribute \'DisplayType\'';
      }
    }
  }
  return $self->getAttribute('DisplayType');
}

#===============================================================================
# Rinchi::Outlook::Recipient::EntryID

=head2 $value = $Object->EntryID([$new_value]);

Set or get value of the EntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub EntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('EntryID', shift);
  }
  return $self->getAttribute('EntryID');
}

#===============================================================================
# Rinchi::Outlook::Recipient::Index

=head2 $value = $Object->Index([$new_value]);

Set or get value of the Index attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Index() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Index', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Index\'';
    }
  }
  return $self->getAttribute('Index');
}

#===============================================================================
# Rinchi::Outlook::Recipient::MeetingResponseStatus

=head2 $value = $Object->MeetingResponseStatus([$new_value]);

Set or get value of the MeetingResponseStatus attribute.

  
 Type: OlResponseStatus
 Lower: 0
 Upper: 1

=cut

sub MeetingResponseStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MeetingResponseStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlResponseStatus\' for attribute \'MeetingResponseStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlResponseStatus\' for attribute \'MeetingResponseStatus\'';
      }
    }
  }
  return $self->getAttribute('MeetingResponseStatus');
}

#===============================================================================
# Rinchi::Outlook::Recipient::Resolved

=head2 $value = $Object->Resolved([$new_value]);

Set or get value of the Resolved attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Resolved() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Resolved', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Resolved\'';
    }
  }
  return $self->getAttribute('Resolved');
}

#===============================================================================
# Rinchi::Outlook::Recipient::TrackingStatus

=head2 $value = $Object->TrackingStatus([$new_value]);

Set or get value of the TrackingStatus attribute.

  
 Type: OlTrackingStatus
 Lower: 0
 Upper: 1

=cut

sub TrackingStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('TrackingStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlTrackingStatus\' for attribute \'TrackingStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlTrackingStatus\' for attribute \'TrackingStatus\'';
      }
    }
  }
  return $self->getAttribute('TrackingStatus');
}

#===============================================================================
# Rinchi::Outlook::Recipient::TrackingStatusTime

=head2 $value = $Object->TrackingStatusTime([$new_value]);

Set or get value of the TrackingStatusTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub TrackingStatusTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('TrackingStatusTime', shift);
  }
  return $self->getAttribute('TrackingStatusTime');
}

#===============================================================================
# Rinchi::Outlook::Recipient::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Type', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Type\'';
    }
  }
  return $self->getAttribute('Type');
}

##END_PACKAGE Recipient

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5df01d6-3c43-11dd-9a41-001c25551abc

package Rinchi::Outlook::RecurrencePattern;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of RecurrencePattern class

Rinchi::Outlook::RecurrencePattern is used for representing RecurrencePattern objects.

=head1 METHODS for RecurrencePattern objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'recurrence-pattern'; };
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::DayOfMonth

=head2 $value = $Object->DayOfMonth([$new_value]);

Set or get value of the DayOfMonth attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub DayOfMonth() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DayOfMonth', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'DayOfMonth\'';
    }
  }
  return $self->getAttribute('DayOfMonth');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::DayOfWeekMask

=head2 $value = $Object->DayOfWeekMask([$new_value]);

Set or get value of the DayOfWeekMask attribute.

  
 Type: OlDaysOfWeek
 Lower: 0
 Upper: 1

=cut

sub DayOfWeekMask() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DayOfWeekMask', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlDaysOfWeek\' for attribute \'DayOfWeekMask\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlDaysOfWeek\' for attribute \'DayOfWeekMask\'';
      }
    }
  }
  return $self->getAttribute('DayOfWeekMask');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Duration

=head2 $value = $Object->Duration([$new_value]);

Set or get value of the Duration attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Duration() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Duration', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Duration\'';
    }
  }
  return $self->getAttribute('Duration');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::EndTime

=head2 $value = $Object->EndTime([$new_value]);

Set or get value of the EndTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub EndTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('EndTime', shift);
  }
  return $self->getAttribute('EndTime');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Exceptions

=head2 $Element = $Object->Exceptions();

Set or get value of the Exceptions attribute.

  
 Type: Exceptions
 Lower: 0
 Upper: 1

=cut

sub Exceptions() {
  my $self = shift;
  return $self->get_collection('Exceptions','exceptions');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Instance

=head2 $value = $Object->Instance([$new_value]);

Set or get value of the Instance attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Instance() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Instance', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Instance\'';
    }
  }
  return $self->getAttribute('Instance');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Interval

=head2 $value = $Object->Interval([$new_value]);

Set or get value of the Interval attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Interval() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Interval', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Interval\'';
    }
  }
  return $self->getAttribute('Interval');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::MonthOfYear

=head2 $value = $Object->MonthOfYear([$new_value]);

Set or get value of the MonthOfYear attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub MonthOfYear() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MonthOfYear', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'MonthOfYear\'';
    }
  }
  return $self->getAttribute('MonthOfYear');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::NoEndDate

=head2 $value = $Object->NoEndDate([$new_value]);

Set or get value of the NoEndDate attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub NoEndDate() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('NoEndDate', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'NoEndDate\'';
    }
  }
  return $self->getAttribute('NoEndDate');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Occurrences

=head2 $value = $Object->Occurrences([$new_value]);

Set or get value of the Occurrences attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Occurrences() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Occurrences', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Occurrences\'';
    }
  }
  return $self->getAttribute('Occurrences');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::PatternEndDate

=head2 $value = $Object->PatternEndDate([$new_value]);

Set or get value of the PatternEndDate attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub PatternEndDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('PatternEndDate', shift);
  }
  return $self->getAttribute('PatternEndDate');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::PatternStartDate

=head2 $value = $Object->PatternStartDate([$new_value]);

Set or get value of the PatternStartDate attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub PatternStartDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('PatternStartDate', shift);
  }
  return $self->getAttribute('PatternStartDate');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::RecurrenceType

=head2 $value = $Object->RecurrenceType([$new_value]);

Set or get value of the RecurrenceType attribute.

  
 Type: OlRecurrenceType
 Lower: 0
 Upper: 1

=cut

sub RecurrenceType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('RecurrenceType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlRecurrenceType\' for attribute \'RecurrenceType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlRecurrenceType\' for attribute \'RecurrenceType\'';
      }
    }
  }
  return $self->getAttribute('RecurrenceType');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Regenerate

=head2 $value = $Object->Regenerate([$new_value]);

Set or get value of the Regenerate attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Regenerate() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Regenerate', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Regenerate\'';
    }
  }
  return $self->getAttribute('Regenerate');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::RecurrencePattern::StartTime

=head2 $value = $Object->StartTime([$new_value]);

Set or get value of the StartTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub StartTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('StartTime', shift);
  }
  return $self->getAttribute('StartTime');
}

##END_PACKAGE RecurrencePattern

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5df224c-3c43-11dd-934f-001c25551abc

package Rinchi::Outlook::Reminder;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Reminder class

Rinchi::Outlook::Reminder is used for representing Reminder objects.

=head1 METHODS for Reminder objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'reminder'; };
}

#===============================================================================
# Rinchi::Outlook::Reminder::Caption

=head2 $value = $Object->Caption([$new_value]);

Set or get value of the Caption attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Caption() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Caption', shift);
  }
  return $self->getAttribute('Caption');
}

#===============================================================================
# Rinchi::Outlook::Reminder::IsVisible

=head2 $value = $Object->IsVisible([$new_value]);

Set or get value of the IsVisible attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsVisible() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsVisible', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsVisible\'';
    }
  }
  return $self->getAttribute('IsVisible');
}

#===============================================================================
# Rinchi::Outlook::Reminder::Item

=head2 $value = $Object->Item([$new_value]);

Set or get value of the Item attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Item() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Item', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Item\'';
    }
  }
  return $self->attribute_as_element('Item');
}

#===============================================================================
# Rinchi::Outlook::Reminder::NextReminderDate

=head2 $value = $Object->NextReminderDate([$new_value]);

Set or get value of the NextReminderDate attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub NextReminderDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NextReminderDate', shift);
  }
  return $self->getAttribute('NextReminderDate');
}

#===============================================================================
# Rinchi::Outlook::Reminder::OriginalReminderDate

=head2 $value = $Object->OriginalReminderDate([$new_value]);

Set or get value of the OriginalReminderDate attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub OriginalReminderDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OriginalReminderDate', shift);
  }
  return $self->getAttribute('OriginalReminderDate');
}

##END_PACKAGE Reminder

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dfd6c4-3c43-11dd-b122-001c25551abc

package Rinchi::Outlook::Search;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Search class

Rinchi::Outlook::Search is used for representing Search objects.

=head1 METHODS for Search objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'search'; };
}

#===============================================================================
# Rinchi::Outlook::Search::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::Search::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::Search::Filter

=head2 $value = $Object->Filter([$new_value]);

Set or get value of the Filter attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Filter() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Filter', shift);
  }
  return $self->getAttribute('Filter');
}

#===============================================================================
# Rinchi::Outlook::Search::IsSynchronous

=head2 $value = $Object->IsSynchronous([$new_value]);

Set or get value of the IsSynchronous attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsSynchronous() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsSynchronous', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsSynchronous\'';
    }
  }
  return $self->getAttribute('IsSynchronous');
}

#===============================================================================
# Rinchi::Outlook::Search::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::Search::Results

=head2 $value = $Object->Results([$new_value]);

Set or get value of the Results attribute.

  
 Type: 
 Lower: 0
 Upper: 1

=cut

sub Results() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::' =~ /$regexp/ ) {
      $self->attribute_as_element('Results', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::\' for attribute \'Results\'';
    }
  }
  return $self->attribute_as_element('Results');
}

#===============================================================================
# Rinchi::Outlook::Search::Scope

=head2 $value = $Object->Scope([$new_value]);

Set or get value of the Scope attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Scope() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Scope', shift);
  }
  return $self->getAttribute('Scope');
}

#===============================================================================
# Rinchi::Outlook::Search::SearchSubFolders

=head2 $value = $Object->SearchSubFolders([$new_value]);

Set or get value of the SearchSubFolders attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub SearchSubFolders() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('SearchSubFolders', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'SearchSubFolders\'';
    }
  }
  return $self->getAttribute('SearchSubFolders');
}

#===============================================================================
# Rinchi::Outlook::Search::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::Search::Tag

=head2 $value = $Object->Tag([$new_value]);

Set or get value of the Tag attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Tag() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Tag', shift);
  }
  return $self->getAttribute('Tag');
}

##END_PACKAGE Search

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dfe696-3c43-11dd-a55e-001c25551abc

package Rinchi::Outlook::Selection;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Selection class

Rinchi::Outlook::Selection is used for representing Selection objects.

=head1 METHODS for Selection objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'selection'; };
}

#===============================================================================
# Rinchi::Outlook::Selection::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::Selection::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::Selection::Count

=head2 $value = $Object->Count([$new_value]);

Set or get value of the Count attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Count() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Count', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Count\'';
    }
  }
  return $self->getAttribute('Count');
}

#===============================================================================
# Rinchi::Outlook::Selection::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::Selection::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

##END_PACKAGE Selection

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dff6c2-3c43-11dd-af3e-001c25551abc

package Rinchi::Outlook::SyncObject;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SyncObject class

Rinchi::Outlook::SyncObject is used for representing SyncObject objects.

=head1 METHODS for SyncObject objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'sync-object'; };
}

##END_PACKAGE SyncObject

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e0ea5a-3c43-11dd-9e08-001c25551abc

package Rinchi::Outlook::UserProperty;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of UserProperty class

Rinchi::Outlook::UserProperty is used for representing UserProperty objects. A 
UserProperty object represents a custom property of a Microsoft Outlook item.

=head1 METHODS for UserProperty objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'user-property'; };
}

#===============================================================================
# Rinchi::Outlook::UserProperty::Formula

=head2 $value = $Object->Formula([$new_value]);

Set or get value of the Formula attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Formula() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Formula', shift);
  }
  return $self->getAttribute('Formula');
}

#===============================================================================
# Rinchi::Outlook::UserProperty::IsUserProperty

=head2 $value = $Object->IsUserProperty([$new_value]);

Set or get value of the IsUserProperty attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsUserProperty() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsUserProperty', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsUserProperty\'';
    }
  }
  return $self->getAttribute('IsUserProperty');
}

#===============================================================================
# Rinchi::Outlook::UserProperty::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.

  
 Type: OlUserPropertyType
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Type', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlUserPropertyType\' for attribute \'Type\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlUserPropertyType\' for attribute \'Type\'';
      }
    }
  }
  return $self->getAttribute('Type');
}

#===============================================================================
# Rinchi::Outlook::UserProperty::ValidationFormula

=head2 $value = $Object->ValidationFormula([$new_value]);

Set or get value of the ValidationFormula attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ValidationFormula() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ValidationFormula', shift);
  }
  return $self->getAttribute('ValidationFormula');
}

#===============================================================================
# Rinchi::Outlook::UserProperty::ValidationText

=head2 $value = $Object->ValidationText([$new_value]);

Set or get value of the ValidationText attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ValidationText() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ValidationText', shift);
  }
  return $self->getAttribute('ValidationText');
}

#===============================================================================
# Rinchi::Outlook::UserProperty::Value

=head2 $value = $Object->Value([$new_value]);

Set or get value of the Value attribute.

  
 Type: Variant
 Lower: 0
 Upper: 1

=cut

sub Value() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Variant' =~ /$regexp/ ) {
      $self->attribute_as_element('Value', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Variant\' for attribute \'Value\'';
    }
  }
  return $self->attribute_as_element('Value');
}

##END_PACKAGE UserProperty

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e0f9f0-3c43-11dd-8cc6-001c25551abc

package Rinchi::Outlook::View;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookNamedEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of View class

Rinchi::Outlook::View is used for representing View objects.

=head1 METHODS for  View objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'view'; };
}

#===============================================================================
# Rinchi::Outlook::View::Language

=head2 $value = $Object->Language([$new_value]);

Set or get value of the Language attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Language() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Language', shift);
  }
  return $self->getAttribute('Language');
}

#===============================================================================
# Rinchi::Outlook::View::LockUserChanges

=head2 $value = $Object->LockUserChanges([$new_value]);

Set or get value of the LockUserChanges attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub LockUserChanges() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('LockUserChanges', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'LockUserChanges\'';
    }
  }
  return $self->getAttribute('LockUserChanges');
}

#===============================================================================
# Rinchi::Outlook::View::SaveOption

=head2 $value = $Object->SaveOption([$new_value]);

Set or get value of the SaveOption attribute.

  
 Type: OlViewSaveOption
 Lower: 0
 Upper: 1

=cut

sub SaveOption() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('SaveOption', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlViewSaveOption\' for attribute \'SaveOption\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlViewSaveOption\' for attribute \'SaveOption\'';
      }
    }
  }
  return $self->getAttribute('SaveOption');
}

#===============================================================================
# Rinchi::Outlook::View::Standard

=head2 $value = $Object->Standard([$new_value]);

Set or get value of the Standard attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Standard() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Standard', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Standard\'';
    }
  }
  return $self->getAttribute('Standard');
}

#===============================================================================
# Rinchi::Outlook::View::ViewType

=head2 $value = $Object->ViewType([$new_value]);

Set or get value of the ViewType attribute.

  
 Type: OlViewType
 Lower: 0
 Upper: 1

=cut

sub ViewType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ViewType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlViewType\' for attribute \'ViewType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlViewType\' for attribute \'ViewType\'';
      }
    }
  }
  return $self->getAttribute('ViewType');
}

#===============================================================================
# Rinchi::Outlook::View::XML

=head2 $value = $Object->XML([$new_value]);

Set or get value of the XML attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub XML() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('XML', shift);
  }
  return $self->getAttribute('XML');
}

##END_PACKAGE View

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 2d9adb24-3cc5-11dd-9836-00502c05c241

package Rinchi::Outlook::OutlookNamedEntry;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookEntry);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookNamedEntry class

Rinchi::Outlook::OutlookNamedEntry is an abstract class representing 
OutlookNamedEntry objects.

=head1 METHODS for OutlookNamedEntry objects.

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-named-entry'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookNamedEntry::Name

=head2 $value = $Object->Name([$new_value]);

Set or get value of the Name attribute.

 Type: String
 Lower: 0
 Upper: 1

=cut

sub Name() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Name', shift);
  }
  return $self->getAttribute('Name');
}

##END_PACKAGE OutlookNamedEntry

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: b965e11e-3ce2-11dd-9836-00502c05c241

package Rinchi::Outlook::OutlookEntry;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookEntry class

Rinchi::Outlook::OutlookEntry is an abstract class for representing OutlookEntry objects.

=head1 METHODS for OutlookEntry objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-entry'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookEntry::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::OutlookEntry::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::OutlookEntry::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::OutlookEntry::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

##END_PACKAGE OutlookEntry

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 17e7d2fd-3cc7-11dd-9836-00502c05c241

package Rinchi::Outlook::OutlookCollection;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookCollection

Rinchi::Outlook::OutlookCollection is used for representing OutlookCollection objects.

=head1 METHODS for OutlookCollection objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-collection'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookCollection::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::OutlookCollection::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::OutlookCollection::Count

=head2 $value = $Object->Count([$new_value]);

Set or get value of the Count attribute.

 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Count() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Count', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Count\'';
    }
  }
  return $self->getAttribute('Count');
}

#===============================================================================
# Rinchi::Outlook::OutlookCollection::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::OutlookCollection::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

##END_PACKAGE OutlookCollection

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dcb782-3c43-11dd-bd77-001c25551abc

package Rinchi::Outlook::Items;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Items class

Rinchi::Outlook::Items is used for representing Items objects.

=head1 METHODS for Items objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'items'; };
}

#===============================================================================
# Rinchi::Outlook::Items::IncludeRecurrences

=head2 $value = $Object->IncludeRecurrences([$new_value]);

Set or get value of the IncludeRecurrences attribute.
  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IncludeRecurrences() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IncludeRecurrences', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IncludeRecurrences\'';
    }
  }
  return $self->getAttribute('IncludeRecurrences');
}

#===============================================================================
# Rinchi::Outlook::Items::RawTable

=head2 $value = $Object->RawTable([$new_value]);

Set or get value of the RawTable attribute.
  
 Type: Unknown
 Lower: 0
 Upper: 1

=cut

sub RawTable() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Unknown' =~ /$regexp/ ) {
      $self->attribute_as_element('RawTable', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Unknown\' for attribute \'RawTable\'';
    }
  }
  return $self->attribute_as_element('RawTable');
}

##END_PACKAGE Items

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dd05de-3c43-11dd-a072-001c25551abc

package Rinchi::Outlook::Links;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Links class

Rinchi::Outlook::Links is used for representing Links objects.

=head1 METHODS for Links objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'links'; };
}

#===============================================================================
# Rinchi::Outlook::Link::link

=head2 $arrayref = $Object->link();

Returns a reference to an array of the contained Link objects.
  
 Type: 

=cut

sub link() {
  my $self = shift;
  return $self->{'_link'};
}

#===============================================================================
# Rinchi::Outlook::Link::link

=head2 $value = $Object->push_link([$new_value]);

Set or get value of the link attribute.

  
 Type: 

=cut

sub push_link() {
  my $self = shift;
  if (@_) {
    $self->{'_link'} = [] unless(exists($self->{'_link'}));
    push @{$self->{'_link'}}, shift;
  }
  return $self->{'_link'};
}

##END_PACKAGE Links

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5db98a2-3c43-11dd-8a37-001c25551abc

package Rinchi::Outlook::Explorers;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Explorers class

Rinchi::Outlook::Explorers is used for representing Explorers objects.

=head1 METHODS for Explorers objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'explorers'; };
}

#===============================================================================
# Rinchi::Outlook::Explorer::Explorer

=head2 $arrayref = $Object->Explorer();

Returns a reference to an array of the contained Explorer objects.
Get values of the Explorer property.

  
 Type: 

=cut

sub Explorer() {
  my $self = shift;
  return $self->{'_Explorer'};
}

#===============================================================================
# Rinchi::Outlook::Explorer::Explorer

=head2 $value = $Object->push_Explorer([$new_value]);

Set or get value of the Explorer attribute.
  
 Type: 

=cut

sub push_Explorer() {
  my $self = shift;
  if (@_) {
    $self->{'_Explorer'} = [] unless(exists($self->{'_Explorer'}));
    push @{$self->{'_Explorer'}}, shift;
  }
  return $self->{'_Explorer'};
}

##END_PACKAGE Explorers

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d98b8e-3c43-11dd-b3ae-001c25551abc

package Rinchi::Outlook::AddressEntries;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AddressEntries

Rinchi::Outlook::AddressEntries is used for representing AddressEntries objects.

=head1 METHODS for AddressEntries objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'address-entries'; };
}

#===============================================================================
# Rinchi::Outlook::AddressEntries::RawTable

=head2 $value = $Object->RawTable([$new_value]);

Set or get value of the RawTable attribute.

  
 Type: Unknown
 Lower: 0
 Upper: 1

=cut

sub RawTable() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Unknown' =~ /$regexp/ ) {
      $self->attribute_as_element('RawTable', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Unknown\' for attribute \'RawTable\'';
    }
  }
  return $self->attribute_as_element('RawTable');
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::addressEntry

=head2 $arrayref = $Object->addressEntry();

Returns a reference to an array of the contained AddressEntry objects.
Get values of the addressEntry property.

  
 Type: 

=cut

sub addressEntry() {
  my $self = shift;
  return $self->{'_addressEntry'};
}

#===============================================================================
# Rinchi::Outlook::AddressEntry::addressEntry

=head2 $value = $Object->push_addressEntry([$new_value]);

Set or get value of the addressEntry attribute.

  
 Type: 

=cut

sub push_addressEntry() {
  my $self = shift;
  if (@_) {
    $self->{'_addressEntry'} = [] unless(exists($self->{'_addressEntry'}));
    push @{$self->{'_addressEntry'}}, shift;
  }
  return $self->{'_addressEntry'};
}

##END_PACKAGE AddressEntries

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d9bbfe-3c43-11dd-b12c-001c25551abc

package Rinchi::Outlook::AddressLists;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AddressLists class

Rinchi::Outlook::AddressLists is used for representing AddressLists objects.

=head1 METHODS for AddressLists objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'address-lists'; };
}

#===============================================================================
# Rinchi::Outlook::AddressList::addressList

=head2 $arrayref = $Object->addressList();

Returns a reference to an array of the contained AddressList objects.
Get values of the addressList property.

  
 Type: 

=cut

sub addressList() {
  my $self = shift;
  return $self->{'_addressList'};
}

#===============================================================================
# Rinchi::Outlook::AddressList::addressList

=head2 $value = $Object->push_addressList([$new_value]);

Set or get value of the addressList attribute.

  
 Type: 

=cut

sub push_addressList() {
  my $self = shift;
  if (@_) {
    $self->{'_addressList'} = [] unless(exists($self->{'_addressList'}));
    push @{$self->{'_addressList'}}, shift;
  }
  return $self->{'_addressList'};
}

##END_PACKAGE AddressLists

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5d97afe-3c43-11dd-96cc-001c25551abc

package Rinchi::Outlook::Actions;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Actions

Rinchi::Outlook::Actions is used for representing Actions objects.

=head1 METHODS for Actions objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'actions'; };
}

#===============================================================================
# Rinchi::Outlook::Action::action

=head2 $arrayref = $Object->action();

Returns a reference to an array of the contained Action objects.
Get values of the action property.

  
 Type: 

=cut

sub action() {
  my $self = shift;
  return $self->{'_action'};
}

#===============================================================================
# Rinchi::Outlook::Action::action

=head2 $value = $Object->push_action([$new_value]);

Set or get value of the action attribute.

  
 Type: 

=cut

sub push_action() {
  my $self = shift;
  if (@_) {
    $self->{'_action'} = [] unless(exists($self->{'_action'}));
    push @{$self->{'_action'}}, shift;
  }
  return $self->{'_action'};
}

##END_PACKAGE Actions

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5da4d62-3c43-11dd-b486-001c25551abc

package Rinchi::Outlook::Attachments;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Attachments

Rinchi::Outlook::Attachments is used for representing Attachments objects.

=head1 METHODS for Attachments objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'attachments'; };
}

#===============================================================================
# Rinchi::Outlook::Attachment::attachment

=head2 $arrayref = $Object->attachment();

Returns a reference to an array of the contained Attachment objects.
Get values of the attachment property.

  
 Type: 

=cut

sub attachment() {
  my $self = shift;
  return $self->{'_attachment'};
}

#===============================================================================
# Rinchi::Outlook::Attachment::attachment

=head2 $value = $Object->push_attachment([$new_value]);

Set or get value of the attachment attribute.

  
 Type: 

=cut

sub push_attachment() {
  my $self = shift;
  if (@_) {
    $self->{'_attachment'} = [] unless(exists($self->{'_attachment'}));
    push @{$self->{'_attachment'}}, shift;
  }
  return $self->{'_attachment'};
}

##END_PACKAGE Attachments

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5da6d2e-3c43-11dd-8db8-001c25551abc

package Rinchi::Outlook::Conflicts;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Conflicts class

Rinchi::Outlook::Conflicts is used for representing Conflicts objects.

=head1 METHODS for Conflicts objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'conflicts'; };
}

#===============================================================================
# Rinchi::Outlook::Conflict::Conflict

=head2 $arrayref = $Object->Conflict();

Returns a reference to an array of the contained Conflict objects.
Get values of the Conflict property.

  
 Type: 

=cut

sub Conflict() {
  my $self = shift;
  return $self->{'_Conflict'};
}

#===============================================================================
# Rinchi::Outlook::Conflict::Conflict

=head2 $value = $Object->push_Conflict([$new_value]);

Set or get value of the Conflict attribute.

  
 Type: 

=cut

sub push_Conflict() {
  my $self = shift;
  if (@_) {
    $self->{'_Conflict'} = [] unless(exists($self->{'_Conflict'}));
    push @{$self->{'_Conflict'}}, shift;
  }
  return $self->{'_Conflict'};
}

##END_PACKAGE Conflicts

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5db3952-3c43-11dd-b07c-001c25551abc

package Rinchi::Outlook::Exceptions;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Exceptions class

Rinchi::Outlook::Exceptions is used for representing Exceptions objects.

=head1 METHODS for Exceptions objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'exceptions'; };
}

#===============================================================================
# Rinchi::Outlook::Exception::Exception

=head2 $arrayref = $Object->Exception();

Returns a reference to an array of the contained Exception objects.
Get values of the Exception property.

  
 Type: 

=cut

sub Exception() {
  my $self = shift;
  return $self->{'_Exception'};
}

#===============================================================================
# Rinchi::Outlook::Exception::Exception

=head2 $value = $Object->push_Exception([$new_value]);

Set or get value of the Exception attribute.

  
 Type: 

=cut

sub push_Exception() {
  my $self = shift;
  if (@_) {
    $self->{'_Exception'} = [] unless(exists($self->{'_Exception'}));
    push @{$self->{'_Exception'}}, shift;
  }
  return $self->{'_Exception'};
}

##END_PACKAGE Exceptions

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dc4838-3c43-11dd-8fbc-001c25551abc

package Rinchi::Outlook::Inspectors;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Inspectors class

Rinchi::Outlook::Inspectors is used for representing Inspectors objects.

=head1 METHODS for Inspectors objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'inspectors'; };
}

#===============================================================================
# Rinchi::Outlook::Inspector::inspector

=head2 $arrayref = $Object->inspector();

Returns a reference to an array of the contained Inspector objects.
Get values of the inspector property.

  
 Type: 

=cut

sub inspector() {
  my $self = shift;
  return $self->{'_inspector'};
}

#===============================================================================
# Rinchi::Outlook::Inspector::inspector

=head2 $value = $Object->push_inspector([$new_value]);

Set or get value of the inspector attribute.

  
 Type: 

=cut

sub push_inspector() {
  my $self = shift;
  if (@_) {
    $self->{'_inspector'} = [] unless(exists($self->{'_inspector'}));
    push @{$self->{'_inspector'}}, shift;
  }
  return $self->{'_inspector'};
}

##END_PACKAGE Inspectors

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dc878a-3c43-11dd-908f-001c25551abc

package Rinchi::Outlook::ItemProperties;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ItemProperties class

Rinchi::Outlook::ItemProperties is used for representing ItemProperties objects.

=head1 METHODS for ItemProperties objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'item-properties'; };
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::itemProperty

=head2 $arrayref = $Object->itemProperty();

Returns a reference to an array of the contained ItemProperty objects.
Get values of the itemProperty property.

  
 Type: 

=cut

sub itemProperty() {
  my $self = shift;
  return $self->{'_itemProperty'};
}

#===============================================================================
# Rinchi::Outlook::ItemProperty::itemProperty

=head2 $value = $Object->push_itemProperty([$new_value]);

Set or get value of the itemProperty attribute.

  
 Type: 

=cut

sub push_itemProperty() {
  my $self = shift;
  if (@_) {
    $self->{'_itemProperty'} = [] unless(exists($self->{'_itemProperty'}));
    push @{$self->{'_itemProperty'}}, shift;
  }
  return $self->{'_itemProperty'};
}

##END_PACKAGE ItemProperties

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5ddd298-3c43-11dd-aa3f-001c25551abc

package Rinchi::Outlook::OutlookBarGroups;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBarGroups

Rinchi::Outlook::OutlookBarGroups is used for representing OutlookBarGroups objects.

=head1 METHODS for OutlookBarGroups objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-bar-groups'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBarGroup::outlookBarGroup

=head2 $arrayref = $Object->outlookBarGroup();

Returns a reference to an array of the contained OutlookBarGroup objects.
Get values of the outlookBarGroup property.

  
 Type: 

=cut

sub outlookBarGroup() {
  my $self = shift;
  return $self->{'_outlookBarGroup'};
}

#===============================================================================
# Rinchi::Outlook::OutlookBarGroup::outlookBarGroup

=head2 $value = $Object->push_outlookBarGroup([$new_value]);

Set or get value of the outlookBarGroup attribute.

  
 Type: 

=cut

sub push_outlookBarGroup() {
  my $self = shift;
  if (@_) {
    $self->{'_outlookBarGroup'} = [] unless(exists($self->{'_outlookBarGroup'}));
    push @{$self->{'_outlookBarGroup'}}, shift;
  }
  return $self->{'_outlookBarGroup'};
}

##END_PACKAGE OutlookBarGroups

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5de41ba-3c43-11dd-b3d8-001c25551abc

package Rinchi::Outlook::OutlookBarShortcuts;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBarShortcuts class

Rinchi::Outlook::OutlookBarShortcuts is used for representing OutlookBarShortcuts objects.

=head1 METHODS for OutlookBarShortcuts objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-bar-shortcuts'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBarShortcut::outlookBarShortcut

=head2 $arrayref = $Object->outlookBarShortcut();

Returns a reference to an array of the contained OutlookBarShortcut objects.
Get values of the outlookBarShortcut property.

  
 Type: 

=cut

sub outlookBarShortcut() {
  my $self = shift;
  return $self->{'_outlookBarShortcut'};
}

#===============================================================================
# Rinchi::Outlook::OutlookBarShortcut::outlookBarShortcut

=head2 $value = $Object->push_outlookBarShortcut([$new_value]);

Set or get value of the outlookBarShortcut attribute.

  
 Type: 

=cut

sub push_outlookBarShortcut() {
  my $self = shift;
  if (@_) {
    $self->{'_outlookBarShortcut'} = [] unless(exists($self->{'_outlookBarShortcut'}));
    push @{$self->{'_outlookBarShortcut'}}, shift;
  }
  return $self->{'_outlookBarShortcut'};
}

##END_PACKAGE OutlookBarShortcuts

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5de7202-3c43-11dd-aec5-001c25551abc

package Rinchi::Outlook::Pages;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Pages

Rinchi::Outlook::Pages is used for representing Pages objects.

=head1 METHODS for 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'pages'; };
}

##END_PACKAGE Pages

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5de818e-3c43-11dd-91fe-001c25551abc

package Rinchi::Outlook::Panes;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Panes

Rinchi::Outlook::Panes is used for representing Panes objects.

=head1 METHODS for 

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'panes'; };
}

##END_PACKAGE Panes

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dec1bc-3c43-11dd-b11b-001c25551abc

package Rinchi::Outlook::PropertyPages;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of PropertyPages

Rinchi::Outlook::PropertyPages is used for representing PropertyPages objects.

=head1 METHODS for 

cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'property-pages'; };
}

#===============================================================================
# Rinchi::Outlook::PropertyPageSite::propertyPage

=head2 $arrayref = $Object->propertyPage();

Returns a reference to an array of the contained PropertyPageSite objects.
Get values of the propertyPage property.

  
 Type: 

=cut

sub propertyPage() {
  my $self = shift;
  return $self->{'_propertyPage'};
}

#===============================================================================
# Rinchi::Outlook::PropertyPageSite::propertyPage

=head2 $value = $Object->push_propertyPage([$new_value]);

Set or get value of the propertyPage attribute.

  
 Type: 

=cut

sub push_propertyPage() {
  my $self = shift;
  if (@_) {
    $self->{'_propertyPage'} = [] unless(exists($self->{'_propertyPage'}));
    push @{$self->{'_propertyPage'}}, shift;
  }
  return $self->{'_propertyPage'};
}

##END_PACKAGE PropertyPages

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5def222-3c43-11dd-84a4-001c25551abc

package Rinchi::Outlook::Recipients;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Recipients

Rinchi::Outlook::Recipients is used for representing Recipients objects.

=head1 METHODS for Recipients objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'recipients'; };
}

#===============================================================================
# Rinchi::Outlook::Recipient::recipient

=head2 $arrayref = $Object->recipient();

Returns a reference to an array of the contained Recipient objects.
Get values of the recipient property.

  
 Type: 

=cut

sub recipient() {
  my $self = shift;
  return $self->{'_recipient'};
}

#===============================================================================
# Rinchi::Outlook::Recipient::recipient

=head2 $value = $Object->push_recipient([$new_value]);

Set or get value of the recipient attribute.

  
 Type: 

=cut

sub push_recipient() {
  my $self = shift;
  if (@_) {
    $self->{'_recipient'} = [] unless(exists($self->{'_recipient'}));
    push @{$self->{'_recipient'}}, shift;
  }
  return $self->{'_recipient'};
}

##END_PACKAGE Recipients

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5df5208-3c43-11dd-b760-001c25551abc

package Rinchi::Outlook::Reminders;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Reminders class

Rinchi::Outlook::Reminders is used for representing Reminders objects.

=head1 METHODS for Reminders objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'reminders'; };
}

#===============================================================================
# Rinchi::Outlook::Reminder::reminder

=head2 $arrayref = $Object->reminder();

Returns a reference to an array of the contained Reminder objects.
Get values of the reminder property.

  
 Type: 

=cut

sub reminder() {
  my $self = shift;
  return $self->{'_reminder'};
}

#===============================================================================
# Rinchi::Outlook::Reminder::reminder

=head2 $value = $Object->push_reminder([$new_value]);

Set or get value of the reminder attribute.

  
 Type: 

=cut

sub push_reminder() {
  my $self = shift;
  if (@_) {
    $self->{'_reminder'} = [] unless(exists($self->{'_reminder'}));
    push @{$self->{'_reminder'}}, shift;
  }
  return $self->{'_reminder'};
}

##END_PACKAGE Reminders

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dfb22a-3c43-11dd-935c-001c25551abc

package Rinchi::Outlook::Results;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Results class

Rinchi::Outlook::Results is used for representing Results objects.

=head1 METHODS for Results objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'results'; };
}

#===============================================================================
# Rinchi::Outlook::Results::DefaultItemType

=head2 $value = $Object->DefaultItemType([$new_value]);

Set or get value of the DefaultItemType attribute.

  
 Type: OlItemType
 Lower: 0
 Upper: 1

=cut

sub DefaultItemType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DefaultItemType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlItemType\' for attribute \'DefaultItemType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlItemType\' for attribute \'DefaultItemType\'';
      }
    }
  }
  return $self->getAttribute('DefaultItemType');
}

#===============================================================================
# Rinchi::Outlook::Results::RawTable

=head2 $value = $Object->RawTable([$new_value]);

Set or get value of the RawTable attribute.

  
 Type: Unknown
 Lower: 0
 Upper: 1

=cut

sub RawTable() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Unknown' =~ /$regexp/ ) {
      $self->attribute_as_element('RawTable', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Unknown\' for attribute \'RawTable\'';
    }
  }
  return $self->attribute_as_element('RawTable');
}

##END_PACKAGE Results

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e028cc-3c43-11dd-900a-001c25551abc

package Rinchi::Outlook::SyncObjects;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SyncObjects class

Rinchi::Outlook::SyncObjects is used for representing SyncObjects objects.

=head1 METHODS for SyncObjects objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'sync-objects'; };
}

#===============================================================================
# Rinchi::Outlook::SyncObjects::AppFolders

=head2 $value = $Object->AppFolders([$new_value]);

Set or get value of the AppFolders attribute.

  
 Type: SyncObject
 Lower: 0
 Upper: 1

=cut

sub AppFolders() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::SyncObject' =~ /$regexp/ ) {
      $self->attribute_as_element('AppFolders', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::SyncObject\' for attribute \'AppFolders\'';
    }
  }
  return $self->attribute_as_element('AppFolders');
}

#===============================================================================
# Rinchi::Outlook::SyncObject::syncObject

=head2 $arrayref = $Object->syncObject();

Returns a reference to an array of the contained SyncObject objects.
Get values of the syncObject property.

  
 Type: 

=cut

sub syncObject() {
  my $self = shift;
  return $self->{'_syncObject'};
}

#===============================================================================
# Rinchi::Outlook::SyncObject::syncObject

=head2 $value = $Object->push_syncObject([$new_value]);

Set or get value of the syncObject attribute.

  
 Type: 

=cut

sub push_syncObject() {
  my $self = shift;
  if (@_) {
    $self->{'_syncObject'} = [] unless(exists($self->{'_syncObject'}));
    push @{$self->{'_syncObject'}}, shift;
  }
  return $self->{'_syncObject'};
}

##END_PACKAGE SyncObjects

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e0da92-3c43-11dd-9be6-001c25551abc

package Rinchi::Outlook::UserProperties;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of UserProperties class

Rinchi::Outlook::UserProperties is used for representing UserProperties objects.

=head1 METHODS for UserProperties objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'user-properties'; };
}

#===============================================================================
# Rinchi::Outlook::UserProperty::userProperty

=head2 $arrayref = $Object->userProperty();

Returns a reference to an array of the contained UserProperty objects.
Get values of the userProperty property.

  
 Type: 

=cut

sub userProperty() {
  my $self = shift;
  return $self->{'_userProperty'};
}

#===============================================================================
# Rinchi::Outlook::UserProperty::userProperty

=head2 $value = $Object->push_userProperty([$new_value]);

Set or get value of the userProperty attribute.

  
 Type: 

=cut

sub push_userProperty() {
  my $self = shift;
  if (@_) {
    $self->{'_userProperty'} = [] unless(exists($self->{'_userProperty'}));
    push @{$self->{'_userProperty'}}, shift;
  }
  return $self->{'_userProperty'};
}

##END_PACKAGE UserProperties

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e11c78-3c43-11dd-ab9d-001c25551abc

package Rinchi::Outlook::Views;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Views

Rinchi::Outlook::Views is used for representing Views objects.

=head1 METHODS for Views objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'views'; };
}

#===============================================================================
# Rinchi::Outlook::View::view

=head2 $arrayref = $Object->view();

Returns a reference to an array of the contained View objects.
Get values of the view property.

  
 Type: 

=cut

sub view() {
  my $self = shift;
  return $self->{'_view'};
}

#===============================================================================
# Rinchi::Outlook::View::view

=head2 $value = $Object->push_view([$new_value]);

Set or get value of the view attribute.

  
 Type: 

=cut

sub push_view() {
  my $self = shift;
  if (@_) {
    $self->{'_view'} = [] unless(exists($self->{'_view'}));
    push @{$self->{'_view'}}, shift;
  }
  return $self->{'_view'};
}

##END_PACKAGE Views

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dbc840-3c43-11dd-8f3d-001c25551abc

package Rinchi::Outlook::Folders;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookCollection);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Folders class

Rinchi::Outlook::Folders is used for representing Folders objects.

=head1 METHODS for Folders objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'folders'; };
}

#===============================================================================
# Rinchi::Outlook::Folders::RawTable

=head2 $value = $Object->RawTable([$new_value]);

Set or get value of the RawTable attribute.

  
 Type: Unknown
 Lower: 0
 Upper: 1

=cut

sub RawTable() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Unknown' =~ /$regexp/ ) {
      $self->attribute_as_element('RawTable', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Unknown\' for attribute \'RawTable\'';
    }
  }
  return $self->attribute_as_element('RawTable');
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::MAPIFolder

=head2 $arrayref = $Object->MAPIFolder();

Returns a reference to an array of the contained MAPIFolder objects.
Get values of the MAPIFolder property.

  
 Type: 

=cut

sub MAPIFolder() {
  my $self = shift;
  return $self->{'_MAPIFolder'};
}

#===============================================================================
# Rinchi::Outlook::MAPIFolder::MAPIFolder

=head2 $value = $Object->push_MAPIFolder([$new_value]);

Set or get value of the MAPIFolder attribute.

  
 Type: 

=cut

sub push_MAPIFolder() {
  my $self = shift;
  if (@_) {
    $self->{'_MAPIFolder'} = [] unless(exists($self->{'_MAPIFolder'}));
    push @{$self->{'_MAPIFolder'}}, shift;
  }
  return $self->{'_MAPIFolder'};
}

##END_PACKAGE Folders

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5da2d3c-3c43-11dd-b395-001c25551abc

package Rinchi::Outlook::AppointmentItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AppointmentItem class

Rinchi::Outlook::AppointmentItem is used for representing AppointmentItem 
objects. An AppointmentItem object represents an appointment in the Calendar 
folder. An AppointmentItem object can represent a meeting, a one-time 
appointment, or a recurring appointment or meeting.

=head1 METHODS for AppointmentItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'appointment-item'; };
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::AllDayEvent

=head2 $value = $Object->AllDayEvent([$new_value]);

Set or get value of the AllDayEvent attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub AllDayEvent() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('AllDayEvent', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'AllDayEvent\'';
    }
  }
  return $self->getAttribute('AllDayEvent');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::BusyStatus

=head2 $value = $Object->BusyStatus([$new_value]);

Set or get value of the BusyStatus attribute.

  
 Type: OlBusyStatus
 Lower: 0
 Upper: 1

=cut

sub BusyStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('BusyStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlBusyStatus\' for attribute \'BusyStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlBusyStatus\' for attribute \'BusyStatus\'';
      }
    }
  }
  return $self->getAttribute('BusyStatus');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ConferenceServerAllowExternal

=head2 $value = $Object->ConferenceServerAllowExternal([$new_value]);

Set or get value of the ConferenceServerAllowExternal attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ConferenceServerAllowExternal() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ConferenceServerAllowExternal', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ConferenceServerAllowExternal\'';
    }
  }
  return $self->getAttribute('ConferenceServerAllowExternal');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ConferenceServerPassword

=head2 $value = $Object->ConferenceServerPassword([$new_value]);

Set or get value of the ConferenceServerPassword attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ConferenceServerPassword() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ConferenceServerPassword', shift);
  }
  return $self->getAttribute('ConferenceServerPassword');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::Duration

=head2 $value = $Object->Duration([$new_value]);

Set or get value of the Duration attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Duration() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Duration', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Duration\'';
    }
  }
  return $self->getAttribute('Duration');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::End

=head2 $value = $Object->End([$new_value]);

Set or get value of the End attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub End() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('End', shift);
  }
  return $self->getAttribute('End');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::InternetCodepage

=head2 $value = $Object->InternetCodepage([$new_value]);

Set or get value of the InternetCodepage attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub InternetCodepage() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('InternetCodepage', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'InternetCodepage\'';
    }
  }
  return $self->getAttribute('InternetCodepage');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::IsOnlineMeeting

=head2 $value = $Object->IsOnlineMeeting([$new_value]);

Set or get value of the IsOnlineMeeting attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsOnlineMeeting() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsOnlineMeeting', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsOnlineMeeting\'';
    }
  }
  return $self->getAttribute('IsOnlineMeeting');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::IsRecurring

=head2 $value = $Object->IsRecurring([$new_value]);

Set or get value of the IsRecurring attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsRecurring() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsRecurring', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsRecurring\'';
    }
  }
  return $self->getAttribute('IsRecurring');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::Location

=head2 $value = $Object->Location([$new_value]);

Set or get value of the Location attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Location() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Location', shift);
  }
  return $self->getAttribute('Location');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::MeetingStatus

=head2 $value = $Object->MeetingStatus([$new_value]);

Set or get value of the MeetingStatus attribute.

  
 Type: OlMeetingStatus
 Lower: 0
 Upper: 1

=cut

sub MeetingStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MeetingStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlMeetingStatus\' for attribute \'MeetingStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlMeetingStatus\' for attribute \'MeetingStatus\'';
      }
    }
  }
  return $self->getAttribute('MeetingStatus');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::MeetingWorkspaceURL

=head2 $value = $Object->MeetingWorkspaceURL([$new_value]);

Set or get value of the MeetingWorkspaceURL attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MeetingWorkspaceURL() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MeetingWorkspaceURL', shift);
  }
  return $self->getAttribute('MeetingWorkspaceURL');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::NetMeetingAutoStart

=head2 $value = $Object->NetMeetingAutoStart([$new_value]);

Set or get value of the NetMeetingAutoStart attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub NetMeetingAutoStart() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('NetMeetingAutoStart', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'NetMeetingAutoStart\'';
    }
  }
  return $self->getAttribute('NetMeetingAutoStart');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::NetMeetingDocPathName

=head2 $value = $Object->NetMeetingDocPathName([$new_value]);

Set or get value of the NetMeetingDocPathName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NetMeetingDocPathName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NetMeetingDocPathName', shift);
  }
  return $self->getAttribute('NetMeetingDocPathName');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::NetMeetingOrganizerAlias

=head2 $value = $Object->NetMeetingOrganizerAlias([$new_value]);

Set or get value of the NetMeetingOrganizerAlias attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NetMeetingOrganizerAlias() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NetMeetingOrganizerAlias', shift);
  }
  return $self->getAttribute('NetMeetingOrganizerAlias');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::NetMeetingServer

=head2 $value = $Object->NetMeetingServer([$new_value]);

Set or get value of the NetMeetingServer attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NetMeetingServer() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NetMeetingServer', shift);
  }
  return $self->getAttribute('NetMeetingServer');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::NetMeetingType

=head2 $value = $Object->NetMeetingType([$new_value]);

Set or get value of the NetMeetingType attribute.

  
 Type: OlNetMeetingType
 Lower: 0
 Upper: 1

=cut

sub NetMeetingType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('NetMeetingType', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlNetMeetingType\' for attribute \'NetMeetingType\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlNetMeetingType\' for attribute \'NetMeetingType\'';
      }
    }
  }
  return $self->getAttribute('NetMeetingType');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::NetShowURL

=head2 $value = $Object->NetShowURL([$new_value]);

Set or get value of the NetShowURL attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NetShowURL() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NetShowURL', shift);
  }
  return $self->getAttribute('NetShowURL');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::OptionalAttendees

=head2 $value = $Object->OptionalAttendees([$new_value]);

Set or get value of the OptionalAttendees attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OptionalAttendees() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OptionalAttendees', shift);
  }
  return $self->getAttribute('OptionalAttendees');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::Organizer

=head2 $value = $Object->Organizer([$new_value]);

Set or get value of the Organizer attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Organizer() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Organizer', shift);
  }
  return $self->getAttribute('Organizer');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::Recipients

=head2 $Element = $Object->Recipients();

Set or get value of the Recipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub Recipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::RecurrenceState

=head2 $value = $Object->RecurrenceState([$new_value]);

Set or get value of the RecurrenceState attribute.

  
 Type: OlRecurrenceState
 Lower: 0
 Upper: 1

=cut

sub RecurrenceState() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('RecurrenceState', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlRecurrenceState\' for attribute \'RecurrenceState\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlRecurrenceState\' for attribute \'RecurrenceState\'';
      }
    }
  }
  return $self->getAttribute('RecurrenceState');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ReminderMinutesBeforeStart

=head2 $value = $Object->ReminderMinutesBeforeStart([$new_value]);

Set or get value of the ReminderMinutesBeforeStart attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub ReminderMinutesBeforeStart() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ReminderMinutesBeforeStart', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'ReminderMinutesBeforeStart\'';
    }
  }
  return $self->getAttribute('ReminderMinutesBeforeStart');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ReminderOverrideDefault

=head2 $value = $Object->ReminderOverrideDefault([$new_value]);

Set or get value of the ReminderOverrideDefault attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderOverrideDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderOverrideDefault', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderOverrideDefault\'';
    }
  }
  return $self->getAttribute('ReminderOverrideDefault');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ReminderPlaySound

=head2 $value = $Object->ReminderPlaySound([$new_value]);

Set or get value of the ReminderPlaySound attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderPlaySound() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderPlaySound', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderPlaySound\'';
    }
  }
  return $self->getAttribute('ReminderPlaySound');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ReminderSet

=head2 $value = $Object->ReminderSet([$new_value]);

Set or get value of the ReminderSet attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderSet() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderSet', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderSet\'';
    }
  }
  return $self->getAttribute('ReminderSet');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ReminderSoundFile

=head2 $value = $Object->ReminderSoundFile([$new_value]);

Set or get value of the ReminderSoundFile attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReminderSoundFile() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReminderSoundFile', shift);
  }
  return $self->getAttribute('ReminderSoundFile');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ReplyTime

=head2 $value = $Object->ReplyTime([$new_value]);

Set or get value of the ReplyTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReplyTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReplyTime', shift);
  }
  return $self->getAttribute('ReplyTime');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::RequiredAttendees

=head2 $value = $Object->RequiredAttendees([$new_value]);

Set or get value of the RequiredAttendees attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub RequiredAttendees() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('RequiredAttendees', shift);
  }
  return $self->getAttribute('RequiredAttendees');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::Resources

=head2 $value = $Object->Resources([$new_value]);

Set or get value of the Resources attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Resources() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Resources', shift);
  }
  return $self->getAttribute('Resources');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ResponseRequested

=head2 $value = $Object->ResponseRequested([$new_value]);

Set or get value of the ResponseRequested attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ResponseRequested() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ResponseRequested', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ResponseRequested\'';
    }
  }
  return $self->getAttribute('ResponseRequested');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::ResponseStatus

=head2 $value = $Object->ResponseStatus([$new_value]);

Set or get value of the ResponseStatus attribute.

  
 Type: OlResponseStatus
 Lower: 0
 Upper: 1

=cut

sub ResponseStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ResponseStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlResponseStatus\' for attribute \'ResponseStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlResponseStatus\' for attribute \'ResponseStatus\'';
      }
    }
  }
  return $self->getAttribute('ResponseStatus');
}

#===============================================================================
# Rinchi::Outlook::AppointmentItem::Start

=head2 $value = $Object->Start([$new_value]);

Set or get value of the Start attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub Start() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Start', shift);
  }
  return $self->getAttribute('Start');
}

##END_PACKAGE AppointmentItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5da8d36-3c43-11dd-9cbf-001c25551abc

package Rinchi::Outlook::ContactItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ContactItem class

Rinchi::Outlook::ContactItem is used for representing ContactItem objects. A 
ContactItem object represents a contact in a contacts folder. A contact can 
represent any person with whom you have any personal or professional contact.

=head1 METHODS for ContactItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'contact-item'; };
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Account

=head2 $value = $Object->Account([$new_value]);

Set or get value of the Account attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Account() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Account', shift);
  }
  return $self->getAttribute('Account');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Anniversary

=head2 $value = $Object->Anniversary([$new_value]);

Set or get value of the Anniversary attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub Anniversary() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Anniversary', shift);
  }
  return $self->getAttribute('Anniversary');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::AssistantName

=head2 $value = $Object->AssistantName([$new_value]);

Set or get value of the AssistantName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub AssistantName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('AssistantName', shift);
  }
  return $self->getAttribute('AssistantName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::AssistantTelephoneNumber

=head2 $value = $Object->AssistantTelephoneNumber([$new_value]);

Set or get value of the AssistantTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub AssistantTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('AssistantTelephoneNumber', shift);
  }
  return $self->getAttribute('AssistantTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Birthday

=head2 $value = $Object->Birthday([$new_value]);

Set or get value of the Birthday attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub Birthday() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Birthday', shift);
  }
  return $self->getAttribute('Birthday');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Business2TelephoneNumber

=head2 $value = $Object->Business2TelephoneNumber([$new_value]);

Set or get value of the Business2TelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Business2TelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Business2TelephoneNumber', shift);
  }
  return $self->getAttribute('Business2TelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddress

=head2 $value = $Object->BusinessAddress([$new_value]);

Set or get value of the BusinessAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddress', shift);
  }
  return $self->getAttribute('BusinessAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddressCity

=head2 $value = $Object->BusinessAddressCity([$new_value]);

Set or get value of the BusinessAddressCity attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddressCity() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddressCity', shift);
  }
  return $self->getAttribute('BusinessAddressCity');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddressCountry

=head2 $value = $Object->BusinessAddressCountry([$new_value]);

Set or get value of the BusinessAddressCountry attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddressCountry() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddressCountry', shift);
  }
  return $self->getAttribute('BusinessAddressCountry');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddressPostOfficeBox

=head2 $value = $Object->BusinessAddressPostOfficeBox([$new_value]);

Set or get value of the BusinessAddressPostOfficeBox attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddressPostOfficeBox() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddressPostOfficeBox', shift);
  }
  return $self->getAttribute('BusinessAddressPostOfficeBox');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddressPostalCode

=head2 $value = $Object->BusinessAddressPostalCode([$new_value]);

Set or get value of the BusinessAddressPostalCode attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddressPostalCode() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddressPostalCode', shift);
  }
  return $self->getAttribute('BusinessAddressPostalCode');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddressState

=head2 $value = $Object->BusinessAddressState([$new_value]);

Set or get value of the BusinessAddressState attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddressState() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddressState', shift);
  }
  return $self->getAttribute('BusinessAddressState');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessAddressStreet

=head2 $value = $Object->BusinessAddressStreet([$new_value]);

Set or get value of the BusinessAddressStreet attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessAddressStreet() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessAddressStreet', shift);
  }
  return $self->getAttribute('BusinessAddressStreet');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessFaxNumber

=head2 $value = $Object->BusinessFaxNumber([$new_value]);

Set or get value of the BusinessFaxNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessFaxNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessFaxNumber', shift);
  }
  return $self->getAttribute('BusinessFaxNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessHomePage

=head2 $value = $Object->BusinessHomePage([$new_value]);

Set or get value of the BusinessHomePage attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessHomePage() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessHomePage', shift);
  }
  return $self->getAttribute('BusinessHomePage');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::BusinessTelephoneNumber

=head2 $value = $Object->BusinessTelephoneNumber([$new_value]);

Set or get value of the BusinessTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BusinessTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BusinessTelephoneNumber', shift);
  }
  return $self->getAttribute('BusinessTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CallbackTelephoneNumber

=head2 $value = $Object->CallbackTelephoneNumber([$new_value]);

Set or get value of the CallbackTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CallbackTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CallbackTelephoneNumber', shift);
  }
  return $self->getAttribute('CallbackTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CarTelephoneNumber

=head2 $value = $Object->CarTelephoneNumber([$new_value]);

Set or get value of the CarTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CarTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CarTelephoneNumber', shift);
  }
  return $self->getAttribute('CarTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Children

=head2 $value = $Object->Children([$new_value]);

Set or get value of the Children attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Children() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Children', shift);
  }
  return $self->getAttribute('Children');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CompanyAndFullName

=head2 $value = $Object->CompanyAndFullName([$new_value]);

Set or get value of the CompanyAndFullName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CompanyAndFullName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CompanyAndFullName', shift);
  }
  return $self->getAttribute('CompanyAndFullName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CompanyLastFirstNoSpace

=head2 $value = $Object->CompanyLastFirstNoSpace([$new_value]);

Set or get value of the CompanyLastFirstNoSpace attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CompanyLastFirstNoSpace() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CompanyLastFirstNoSpace', shift);
  }
  return $self->getAttribute('CompanyLastFirstNoSpace');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CompanyLastFirstSpaceOnly

=head2 $value = $Object->CompanyLastFirstSpaceOnly([$new_value]);

Set or get value of the CompanyLastFirstSpaceOnly attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CompanyLastFirstSpaceOnly() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CompanyLastFirstSpaceOnly', shift);
  }
  return $self->getAttribute('CompanyLastFirstSpaceOnly');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CompanyMainTelephoneNumber

=head2 $value = $Object->CompanyMainTelephoneNumber([$new_value]);

Set or get value of the CompanyMainTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CompanyMainTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CompanyMainTelephoneNumber', shift);
  }
  return $self->getAttribute('CompanyMainTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CompanyName

=head2 $value = $Object->CompanyName([$new_value]);

Set or get value of the CompanyName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CompanyName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CompanyName', shift);
  }
  return $self->getAttribute('CompanyName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::ComputerNetworkName

=head2 $value = $Object->ComputerNetworkName([$new_value]);

Set or get value of the ComputerNetworkName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ComputerNetworkName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ComputerNetworkName', shift);
  }
  return $self->getAttribute('ComputerNetworkName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::CustomerID

=head2 $value = $Object->CustomerID([$new_value]);

Set or get value of the CustomerID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CustomerID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CustomerID', shift);
  }
  return $self->getAttribute('CustomerID');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Department

=head2 $value = $Object->Department([$new_value]);

Set or get value of the Department attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Department() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Department', shift);
  }
  return $self->getAttribute('Department');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email1Address

=head2 $value = $Object->Email1Address([$new_value]);

Set or get value of the Email1Address attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email1Address() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email1Address', shift);
  }
  return $self->getAttribute('Email1Address');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email1AddressType

=head2 $value = $Object->Email1AddressType([$new_value]);

Set or get value of the Email1AddressType attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email1AddressType() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email1AddressType', shift);
  }
  return $self->getAttribute('Email1AddressType');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email1DisplayName

=head2 $value = $Object->Email1DisplayName([$new_value]);

Set or get value of the Email1DisplayName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email1DisplayName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email1DisplayName', shift);
  }
  return $self->getAttribute('Email1DisplayName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email1EntryID

=head2 $value = $Object->Email1EntryID([$new_value]);

Set or get value of the Email1EntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email1EntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email1EntryID', shift);
  }
  return $self->getAttribute('Email1EntryID');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email2Address

=head2 $value = $Object->Email2Address([$new_value]);

Set or get value of the Email2Address attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email2Address() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email2Address', shift);
  }
  return $self->getAttribute('Email2Address');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email2AddressType

=head2 $value = $Object->Email2AddressType([$new_value]);

Set or get value of the Email2AddressType attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email2AddressType() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email2AddressType', shift);
  }
  return $self->getAttribute('Email2AddressType');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email2DisplayName

=head2 $value = $Object->Email2DisplayName([$new_value]);

Set or get value of the Email2DisplayName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email2DisplayName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email2DisplayName', shift);
  }
  return $self->getAttribute('Email2DisplayName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email2EntryID

=head2 $value = $Object->Email2EntryID([$new_value]);

Set or get value of the Email2EntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email2EntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email2EntryID', shift);
  }
  return $self->getAttribute('Email2EntryID');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email3Address

=head2 $value = $Object->Email3Address([$new_value]);

Set or get value of the Email3Address attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email3Address() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email3Address', shift);
  }
  return $self->getAttribute('Email3Address');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email3AddressType

=head2 $value = $Object->Email3AddressType([$new_value]);

Set or get value of the Email3AddressType attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email3AddressType() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email3AddressType', shift);
  }
  return $self->getAttribute('Email3AddressType');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email3DisplayName

=head2 $value = $Object->Email3DisplayName([$new_value]);

Set or get value of the Email3DisplayName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email3DisplayName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email3DisplayName', shift);
  }
  return $self->getAttribute('Email3DisplayName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Email3EntryID

=head2 $value = $Object->Email3EntryID([$new_value]);

Set or get value of the Email3EntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Email3EntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Email3EntryID', shift);
  }
  return $self->getAttribute('Email3EntryID');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::FTPSite

=head2 $value = $Object->FTPSite([$new_value]);

Set or get value of the FTPSite attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FTPSite() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FTPSite', shift);
  }
  return $self->getAttribute('FTPSite');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::FileAs

=head2 $value = $Object->FileAs([$new_value]);

Set or get value of the FileAs attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FileAs() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FileAs', shift);
  }
  return $self->getAttribute('FileAs');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::FirstName

=head2 $value = $Object->FirstName([$new_value]);

Set or get value of the FirstName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FirstName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FirstName', shift);
  }
  return $self->getAttribute('FirstName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::FullName

=head2 $value = $Object->FullName([$new_value]);

Set or get value of the FullName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FullName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FullName', shift);
  }
  return $self->getAttribute('FullName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::FullNameAndCompany

=head2 $value = $Object->FullNameAndCompany([$new_value]);

Set or get value of the FullNameAndCompany attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FullNameAndCompany() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FullNameAndCompany', shift);
  }
  return $self->getAttribute('FullNameAndCompany');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Gender

=head2 $value = $Object->Gender([$new_value]);

Set or get value of the Gender attribute.

  
 Type: OlGender
 Lower: 0
 Upper: 1

=cut

sub Gender() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Gender', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlGender\' for attribute \'Gender\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlGender\' for attribute \'Gender\'';
      }
    }
  }
  return $self->getAttribute('Gender');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::GovernmentIDNumber

=head2 $value = $Object->GovernmentIDNumber([$new_value]);

Set or get value of the GovernmentIDNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub GovernmentIDNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('GovernmentIDNumber', shift);
  }
  return $self->getAttribute('GovernmentIDNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HasPicture

=head2 $value = $Object->HasPicture([$new_value]);

Set or get value of the HasPicture attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub HasPicture() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('HasPicture', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'HasPicture\'';
    }
  }
  return $self->getAttribute('HasPicture');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Hobby

=head2 $value = $Object->Hobby([$new_value]);

Set or get value of the Hobby attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Hobby() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Hobby', shift);
  }
  return $self->getAttribute('Hobby');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Home2TelephoneNumber

=head2 $value = $Object->Home2TelephoneNumber([$new_value]);

Set or get value of the Home2TelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Home2TelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Home2TelephoneNumber', shift);
  }
  return $self->getAttribute('Home2TelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddress

=head2 $value = $Object->HomeAddress([$new_value]);

Set or get value of the HomeAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddress', shift);
  }
  return $self->getAttribute('HomeAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddressCity

=head2 $value = $Object->HomeAddressCity([$new_value]);

Set or get value of the HomeAddressCity attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddressCity() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddressCity', shift);
  }
  return $self->getAttribute('HomeAddressCity');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddressCountry

=head2 $value = $Object->HomeAddressCountry([$new_value]);

Set or get value of the HomeAddressCountry attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddressCountry() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddressCountry', shift);
  }
  return $self->getAttribute('HomeAddressCountry');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddressPostOfficeBox

=head2 $value = $Object->HomeAddressPostOfficeBox([$new_value]);

Set or get value of the HomeAddressPostOfficeBox attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddressPostOfficeBox() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddressPostOfficeBox', shift);
  }
  return $self->getAttribute('HomeAddressPostOfficeBox');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddressPostalCode

=head2 $value = $Object->HomeAddressPostalCode([$new_value]);

Set or get value of the HomeAddressPostalCode attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddressPostalCode() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddressPostalCode', shift);
  }
  return $self->getAttribute('HomeAddressPostalCode');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddressState

=head2 $value = $Object->HomeAddressState([$new_value]);

Set or get value of the HomeAddressState attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddressState() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddressState', shift);
  }
  return $self->getAttribute('HomeAddressState');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeAddressStreet

=head2 $value = $Object->HomeAddressStreet([$new_value]);

Set or get value of the HomeAddressStreet attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeAddressStreet() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeAddressStreet', shift);
  }
  return $self->getAttribute('HomeAddressStreet');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeFaxNumber

=head2 $value = $Object->HomeFaxNumber([$new_value]);

Set or get value of the HomeFaxNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeFaxNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeFaxNumber', shift);
  }
  return $self->getAttribute('HomeFaxNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::HomeTelephoneNumber

=head2 $value = $Object->HomeTelephoneNumber([$new_value]);

Set or get value of the HomeTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HomeTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HomeTelephoneNumber', shift);
  }
  return $self->getAttribute('HomeTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::IMAddress

=head2 $value = $Object->IMAddress([$new_value]);

Set or get value of the IMAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub IMAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('IMAddress', shift);
  }
  return $self->getAttribute('IMAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::ISDNNumber

=head2 $value = $Object->ISDNNumber([$new_value]);

Set or get value of the ISDNNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ISDNNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ISDNNumber', shift);
  }
  return $self->getAttribute('ISDNNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Initials

=head2 $value = $Object->Initials([$new_value]);

Set or get value of the Initials attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Initials() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Initials', shift);
  }
  return $self->getAttribute('Initials');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::InternetFreeBusyAddress

=head2 $value = $Object->InternetFreeBusyAddress([$new_value]);

Set or get value of the InternetFreeBusyAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub InternetFreeBusyAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('InternetFreeBusyAddress', shift);
  }
  return $self->getAttribute('InternetFreeBusyAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::JobTitle

=head2 $value = $Object->JobTitle([$new_value]);

Set or get value of the JobTitle attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub JobTitle() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('JobTitle', shift);
  }
  return $self->getAttribute('JobTitle');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Journal

=head2 $value = $Object->Journal([$new_value]);

Set or get value of the Journal attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Journal() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Journal', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Journal\'';
    }
  }
  return $self->getAttribute('Journal');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Language

=head2 $value = $Object->Language([$new_value]);

Set or get value of the Language attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Language() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Language', shift);
  }
  return $self->getAttribute('Language');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastFirstAndSuffix

=head2 $value = $Object->LastFirstAndSuffix([$new_value]);

Set or get value of the LastFirstAndSuffix attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastFirstAndSuffix() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastFirstAndSuffix', shift);
  }
  return $self->getAttribute('LastFirstAndSuffix');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastFirstNoSpace

=head2 $value = $Object->LastFirstNoSpace([$new_value]);

Set or get value of the LastFirstNoSpace attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastFirstNoSpace() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastFirstNoSpace', shift);
  }
  return $self->getAttribute('LastFirstNoSpace');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastFirstNoSpaceAndSuffix

=head2 $value = $Object->LastFirstNoSpaceAndSuffix([$new_value]);

Set or get value of the LastFirstNoSpaceAndSuffix attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastFirstNoSpaceAndSuffix() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastFirstNoSpaceAndSuffix', shift);
  }
  return $self->getAttribute('LastFirstNoSpaceAndSuffix');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastFirstNoSpaceCompany

=head2 $value = $Object->LastFirstNoSpaceCompany([$new_value]);

Set or get value of the LastFirstNoSpaceCompany attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastFirstNoSpaceCompany() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastFirstNoSpaceCompany', shift);
  }
  return $self->getAttribute('LastFirstNoSpaceCompany');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastFirstSpaceOnly

=head2 $value = $Object->LastFirstSpaceOnly([$new_value]);

Set or get value of the LastFirstSpaceOnly attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastFirstSpaceOnly() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastFirstSpaceOnly', shift);
  }
  return $self->getAttribute('LastFirstSpaceOnly');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastFirstSpaceOnlyCompany

=head2 $value = $Object->LastFirstSpaceOnlyCompany([$new_value]);

Set or get value of the LastFirstSpaceOnlyCompany attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastFirstSpaceOnlyCompany() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastFirstSpaceOnlyCompany', shift);
  }
  return $self->getAttribute('LastFirstSpaceOnlyCompany');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastName

=head2 $value = $Object->LastName([$new_value]);

Set or get value of the LastName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastName', shift);
  }
  return $self->getAttribute('LastName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::LastNameAndFirstName

=head2 $value = $Object->LastNameAndFirstName([$new_value]);

Set or get value of the LastNameAndFirstName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub LastNameAndFirstName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastNameAndFirstName', shift);
  }
  return $self->getAttribute('LastNameAndFirstName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddress

=head2 $value = $Object->MailingAddress([$new_value]);

Set or get value of the MailingAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddress', shift);
  }
  return $self->getAttribute('MailingAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddressCity

=head2 $value = $Object->MailingAddressCity([$new_value]);

Set or get value of the MailingAddressCity attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddressCity() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddressCity', shift);
  }
  return $self->getAttribute('MailingAddressCity');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddressCountry

=head2 $value = $Object->MailingAddressCountry([$new_value]);

Set or get value of the MailingAddressCountry attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddressCountry() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddressCountry', shift);
  }
  return $self->getAttribute('MailingAddressCountry');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddressPostOfficeBox

=head2 $value = $Object->MailingAddressPostOfficeBox([$new_value]);

Set or get value of the MailingAddressPostOfficeBox attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddressPostOfficeBox() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddressPostOfficeBox', shift);
  }
  return $self->getAttribute('MailingAddressPostOfficeBox');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddressPostalCode

=head2 $value = $Object->MailingAddressPostalCode([$new_value]);

Set or get value of the MailingAddressPostalCode attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddressPostalCode() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddressPostalCode', shift);
  }
  return $self->getAttribute('MailingAddressPostalCode');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddressState

=head2 $value = $Object->MailingAddressState([$new_value]);

Set or get value of the MailingAddressState attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddressState() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddressState', shift);
  }
  return $self->getAttribute('MailingAddressState');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MailingAddressStreet

=head2 $value = $Object->MailingAddressStreet([$new_value]);

Set or get value of the MailingAddressStreet attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MailingAddressStreet() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MailingAddressStreet', shift);
  }
  return $self->getAttribute('MailingAddressStreet');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::ManagerName

=head2 $value = $Object->ManagerName([$new_value]);

Set or get value of the ManagerName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ManagerName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ManagerName', shift);
  }
  return $self->getAttribute('ManagerName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MiddleName

=head2 $value = $Object->MiddleName([$new_value]);

Set or get value of the MiddleName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MiddleName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MiddleName', shift);
  }
  return $self->getAttribute('MiddleName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::MobileTelephoneNumber

=head2 $value = $Object->MobileTelephoneNumber([$new_value]);

Set or get value of the MobileTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MobileTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MobileTelephoneNumber', shift);
  }
  return $self->getAttribute('MobileTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::NetMeetingAlias

=head2 $value = $Object->NetMeetingAlias([$new_value]);

Set or get value of the NetMeetingAlias attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NetMeetingAlias() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NetMeetingAlias', shift);
  }
  return $self->getAttribute('NetMeetingAlias');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::NetMeetingServer

=head2 $value = $Object->NetMeetingServer([$new_value]);

Set or get value of the NetMeetingServer attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NetMeetingServer() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NetMeetingServer', shift);
  }
  return $self->getAttribute('NetMeetingServer');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::NickName

=head2 $value = $Object->NickName([$new_value]);

Set or get value of the NickName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub NickName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('NickName', shift);
  }
  return $self->getAttribute('NickName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OfficeLocation

=head2 $value = $Object->OfficeLocation([$new_value]);

Set or get value of the OfficeLocation attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OfficeLocation() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OfficeLocation', shift);
  }
  return $self->getAttribute('OfficeLocation');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OrganizationalIDNumber

=head2 $value = $Object->OrganizationalIDNumber([$new_value]);

Set or get value of the OrganizationalIDNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OrganizationalIDNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OrganizationalIDNumber', shift);
  }
  return $self->getAttribute('OrganizationalIDNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddress

=head2 $value = $Object->OtherAddress([$new_value]);

Set or get value of the OtherAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddress', shift);
  }
  return $self->getAttribute('OtherAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddressCity

=head2 $value = $Object->OtherAddressCity([$new_value]);

Set or get value of the OtherAddressCity attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddressCity() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddressCity', shift);
  }
  return $self->getAttribute('OtherAddressCity');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddressCountry

=head2 $value = $Object->OtherAddressCountry([$new_value]);

Set or get value of the OtherAddressCountry attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddressCountry() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddressCountry', shift);
  }
  return $self->getAttribute('OtherAddressCountry');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddressPostOfficeBox

=head2 $value = $Object->OtherAddressPostOfficeBox([$new_value]);

Set or get value of the OtherAddressPostOfficeBox attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddressPostOfficeBox() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddressPostOfficeBox', shift);
  }
  return $self->getAttribute('OtherAddressPostOfficeBox');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddressPostalCode

=head2 $value = $Object->OtherAddressPostalCode([$new_value]);

Set or get value of the OtherAddressPostalCode attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddressPostalCode() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddressPostalCode', shift);
  }
  return $self->getAttribute('OtherAddressPostalCode');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddressState

=head2 $value = $Object->OtherAddressState([$new_value]);

Set or get value of the OtherAddressState attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddressState() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddressState', shift);
  }
  return $self->getAttribute('OtherAddressState');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherAddressStreet

=head2 $value = $Object->OtherAddressStreet([$new_value]);

Set or get value of the OtherAddressStreet attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherAddressStreet() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherAddressStreet', shift);
  }
  return $self->getAttribute('OtherAddressStreet');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherFaxNumber

=head2 $value = $Object->OtherFaxNumber([$new_value]);

Set or get value of the OtherFaxNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherFaxNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherFaxNumber', shift);
  }
  return $self->getAttribute('OtherFaxNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::OtherTelephoneNumber

=head2 $value = $Object->OtherTelephoneNumber([$new_value]);

Set or get value of the OtherTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OtherTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OtherTelephoneNumber', shift);
  }
  return $self->getAttribute('OtherTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::PagerNumber

=head2 $value = $Object->PagerNumber([$new_value]);

Set or get value of the PagerNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub PagerNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('PagerNumber', shift);
  }
  return $self->getAttribute('PagerNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::PersonalHomePage

=head2 $value = $Object->PersonalHomePage([$new_value]);

Set or get value of the PersonalHomePage attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub PersonalHomePage() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('PersonalHomePage', shift);
  }
  return $self->getAttribute('PersonalHomePage');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::PrimaryTelephoneNumber

=head2 $value = $Object->PrimaryTelephoneNumber([$new_value]);

Set or get value of the PrimaryTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub PrimaryTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('PrimaryTelephoneNumber', shift);
  }
  return $self->getAttribute('PrimaryTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Profession

=head2 $value = $Object->Profession([$new_value]);

Set or get value of the Profession attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Profession() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Profession', shift);
  }
  return $self->getAttribute('Profession');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::RadioTelephoneNumber

=head2 $value = $Object->RadioTelephoneNumber([$new_value]);

Set or get value of the RadioTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub RadioTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('RadioTelephoneNumber', shift);
  }
  return $self->getAttribute('RadioTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::ReferredBy

=head2 $value = $Object->ReferredBy([$new_value]);

Set or get value of the ReferredBy attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReferredBy() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReferredBy', shift);
  }
  return $self->getAttribute('ReferredBy');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::SelectedMailingAddress

=head2 $value = $Object->SelectedMailingAddress([$new_value]);

Set or get value of the SelectedMailingAddress attribute.

  
 Type: OlMailingAddress
 Lower: 0
 Upper: 1

=cut

sub SelectedMailingAddress() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('SelectedMailingAddress', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlMailingAddress\' for attribute \'SelectedMailingAddress\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlMailingAddress\' for attribute \'SelectedMailingAddress\'';
      }
    }
  }
  return $self->getAttribute('SelectedMailingAddress');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Spouse

=head2 $value = $Object->Spouse([$new_value]);

Set or get value of the Spouse attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Spouse() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Spouse', shift);
  }
  return $self->getAttribute('Spouse');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Suffix

=head2 $value = $Object->Suffix([$new_value]);

Set or get value of the Suffix attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Suffix() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Suffix', shift);
  }
  return $self->getAttribute('Suffix');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::TTYTDDTelephoneNumber

=head2 $value = $Object->TTYTDDTelephoneNumber([$new_value]);

Set or get value of the TTYTDDTelephoneNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub TTYTDDTelephoneNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('TTYTDDTelephoneNumber', shift);
  }
  return $self->getAttribute('TTYTDDTelephoneNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::TelexNumber

=head2 $value = $Object->TelexNumber([$new_value]);

Set or get value of the TelexNumber attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub TelexNumber() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('TelexNumber', shift);
  }
  return $self->getAttribute('TelexNumber');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::Title

=head2 $value = $Object->Title([$new_value]);

Set or get value of the Title attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Title() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Title', shift);
  }
  return $self->getAttribute('Title');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::User1

=head2 $value = $Object->User1([$new_value]);

Set or get value of the User1 attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub User1() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('User1', shift);
  }
  return $self->getAttribute('User1');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::User2

=head2 $value = $Object->User2([$new_value]);

Set or get value of the User2 attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub User2() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('User2', shift);
  }
  return $self->getAttribute('User2');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::User3

=head2 $value = $Object->User3([$new_value]);

Set or get value of the User3 attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub User3() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('User3', shift);
  }
  return $self->getAttribute('User3');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::User4

=head2 $value = $Object->User4([$new_value]);

Set or get value of the User4 attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub User4() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('User4', shift);
  }
  return $self->getAttribute('User4');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::UserCertificate

=head2 $value = $Object->UserCertificate([$new_value]);

Set or get value of the UserCertificate attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub UserCertificate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('UserCertificate', shift);
  }
  return $self->getAttribute('UserCertificate');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::WebPage

=head2 $value = $Object->WebPage([$new_value]);

Set or get value of the WebPage attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub WebPage() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('WebPage', shift);
  }
  return $self->getAttribute('WebPage');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::YomiCompanyName

=head2 $value = $Object->YomiCompanyName([$new_value]);

Set or get value of the YomiCompanyName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub YomiCompanyName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('YomiCompanyName', shift);
  }
  return $self->getAttribute('YomiCompanyName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::YomiFirstName

=head2 $value = $Object->YomiFirstName([$new_value]);

Set or get value of the YomiFirstName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub YomiFirstName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('YomiFirstName', shift);
  }
  return $self->getAttribute('YomiFirstName');
}

#===============================================================================
# Rinchi::Outlook::ContactItem::YomiLastName

=head2 $value = $Object->YomiLastName([$new_value]);

Set or get value of the YomiLastName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub YomiLastName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('YomiLastName', shift);
  }
  return $self->getAttribute('YomiLastName');
}

##END_PACKAGE ContactItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5daeb96-3c43-11dd-aaa8-001c25551abc

package Rinchi::Outlook::DistListItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of DistListItem

Rinchi::Outlook::DistListItem is used for representing DistListItem objects. A 
DistListItem object represents a distribution list in a contacts folder. A 
distribution list can contain multiple recipients and is used to send messages 
to everyone in the list.

=head1 METHODS for DistListItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'dist-list-item'; };
}

#===============================================================================
# Rinchi::Outlook::DistListItem::CheckSum

=head2 $value = $Object->CheckSum([$new_value]);

Set or get value of the CheckSum attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub CheckSum() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('CheckSum', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'CheckSum\'';
    }
  }
  return $self->getAttribute('CheckSum');
}

#===============================================================================
# Rinchi::Outlook::DistListItem::DLName

=head2 $value = $Object->DLName([$new_value]);

Set or get value of the DLName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub DLName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DLName', shift);
  }
  return $self->getAttribute('DLName');
}

#===============================================================================
# Rinchi::Outlook::DistListItem::MemberCount

=head2 $value = $Object->MemberCount([$new_value]);

Set or get value of the MemberCount attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub MemberCount() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MemberCount', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'MemberCount\'';
    }
  }
  return $self->getAttribute('MemberCount');
}

#===============================================================================
# Rinchi::Outlook::DistListItem::Members

=head2 $value = $Object->Members([$new_value]);

Set or get value of the Members attribute.

  
 Type: Variant
 Lower: 0
 Upper: 1

=cut

sub Members() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Variant' =~ /$regexp/ ) {
      $self->attribute_as_element('Members', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Variant\' for attribute \'Members\'';
    }
  }
  return $self->attribute_as_element('Members');
}

#===============================================================================
# Rinchi::Outlook::DistListItem::OneOffMembers

=head2 $value = $Object->OneOffMembers([$new_value]);

Set or get value of the OneOffMembers attribute.

  
 Type: Variant
 Lower: 0
 Upper: 1

=cut

sub OneOffMembers() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Variant' =~ /$regexp/ ) {
      $self->attribute_as_element('OneOffMembers', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Variant\' for attribute \'OneOffMembers\'';
    }
  }
  return $self->attribute_as_element('OneOffMembers');
}

##END_PACKAGE DistListItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5db1a6c-3c43-11dd-9a98-001c25551abc

package Rinchi::Outlook::DocumentItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of DocumentItem

Rinchi::Outlook::DocumentItem is used for representing DocumentItem objects. A DocumentItem object is any document other than a Microsoft Outlook item as an item in an Outlook folder. In common usage, this will be an Office document but may be any type of document or executable file.

Note  When you try to programmatically add a user-defined property to a DocumentItem object, you receive the following error message: "Property is read-only." This is because the Outlook object model does not support this functionality.
Example

The following Visual Basic for Applications (VBA) example shows how to create a DocumentItem.

Sub AddDocItem()
    Dim outApp As New Outlook.Application
    Dim nsp As Outlook.NameSpace
    Dim mpfInbox As Outlook.MAPIFolder
    Dim doci As Outlook.DocumentItem
    
    Set nsp = outApp.GetNamespace("MAPI")
    Set mpfInbox = nsp.GetDefaultFolder(olFolderInbox)
    Set doci = mpfInbox.Items.Add(olWordDocumentItem)
    doci.Subject = "Word Document Item"
    doci.Save
End Sub


=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'document-item'; };
}

##END_PACKAGE DocumentItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dce770-3c43-11dd-bc44-001c25551abc

package Rinchi::Outlook::JournalItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of JournalItem class

Rinchi::Outlook::JournalItem is used for representing JournalItem objects. 
Represents a journal entry in a Journal folder. A journal entry represents a 
record of all Microsoft Outlook-moderated transactions for any given period.

=head1 METHODS for JournalItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'journal-item'; };
}

#===============================================================================
# Rinchi::Outlook::JournalItem::ContactNames

=head2 $value = $Object->ContactNames([$new_value]);

Set or get value of the ContactNames attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ContactNames() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ContactNames', shift);
  }
  return $self->getAttribute('ContactNames');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::DocPosted

=head2 $value = $Object->DocPosted([$new_value]);

Set or get value of the DocPosted attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub DocPosted() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('DocPosted', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'DocPosted\'';
    }
  }
  return $self->getAttribute('DocPosted');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::DocPrinted

=head2 $value = $Object->DocPrinted([$new_value]);

Set or get value of the DocPrinted attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub DocPrinted() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('DocPrinted', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'DocPrinted\'';
    }
  }
  return $self->getAttribute('DocPrinted');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::DocRouted

=head2 $value = $Object->DocRouted([$new_value]);

Set or get value of the DocRouted attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub DocRouted() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('DocRouted', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'DocRouted\'';
    }
  }
  return $self->getAttribute('DocRouted');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::DocSaved

=head2 $value = $Object->DocSaved([$new_value]);

Set or get value of the DocSaved attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub DocSaved() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('DocSaved', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'DocSaved\'';
    }
  }
  return $self->getAttribute('DocSaved');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::Duration

=head2 $value = $Object->Duration([$new_value]);

Set or get value of the Duration attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Duration() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Duration', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Duration\'';
    }
  }
  return $self->getAttribute('Duration');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::End

=head2 $value = $Object->End([$new_value]);

Set or get value of the End attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub End() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('End', shift);
  }
  return $self->getAttribute('End');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::Recipients

=head2 $Element = $Object->Recipients();

Set or get value of the Recipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub Recipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::Start

=head2 $value = $Object->Start([$new_value]);

Set or get value of the Start attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub Start() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Start', shift);
  }
  return $self->getAttribute('Start');
}

#===============================================================================
# Rinchi::Outlook::JournalItem::Type

=head2 $value = $Object->Type([$new_value]);

Set or get value of the Type attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Type() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Type', shift);
  }
  return $self->getAttribute('Type');
}

##END_PACKAGE JournalItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dd253c-3c43-11dd-bbbf-001c25551abc

package Rinchi::Outlook::MailItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MailItem

Rinchi::Outlook::MailItem is used for representing MailItem objects. A MailItem 
object Represents a mail message in an Inbox (mail) folder.

=head1 METHODS for MailItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'mail-item'; };
}

#===============================================================================
# Rinchi::Outlook::MailItem::AlternateRecipientAllowed

=head2 $value = $Object->AlternateRecipientAllowed([$new_value]);

Set or get value of the AlternateRecipientAllowed attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub AlternateRecipientAllowed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('AlternateRecipientAllowed', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'AlternateRecipientAllowed\'';
    }
  }
  return $self->getAttribute('AlternateRecipientAllowed');
}

#===============================================================================
# Rinchi::Outlook::MailItem::AutoForwarded

=head2 $value = $Object->AutoForwarded([$new_value]);

Set or get value of the AutoForwarded attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub AutoForwarded() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('AutoForwarded', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'AutoForwarded\'';
    }
  }
  return $self->getAttribute('AutoForwarded');
}

#===============================================================================
# Rinchi::Outlook::MailItem::BCC

=head2 $value = $Object->BCC([$new_value]);

Set or get value of the BCC attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BCC() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BCC', shift);
  }
  return $self->getAttribute('BCC');
}

#===============================================================================
# Rinchi::Outlook::MailItem::BodyFormat

=head2 $value = $Object->BodyFormat([$new_value]);

Set or get value of the BodyFormat attribute.

  
 Type: OlBodyFormat
 Lower: 0
 Upper: 1

=cut

sub BodyFormat() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('BodyFormat', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlBodyFormat\' for attribute \'BodyFormat\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlBodyFormat\' for attribute \'BodyFormat\'';
      }
    }
  }
  return $self->getAttribute('BodyFormat');
}

#===============================================================================
# Rinchi::Outlook::MailItem::CC

=head2 $value = $Object->CC([$new_value]);

Set or get value of the CC attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CC() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CC', shift);
  }
  return $self->getAttribute('CC');
}

#===============================================================================
# Rinchi::Outlook::MailItem::DeferredDeliveryTime

=head2 $value = $Object->DeferredDeliveryTime([$new_value]);

Set or get value of the DeferredDeliveryTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub DeferredDeliveryTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DeferredDeliveryTime', shift);
  }
  return $self->getAttribute('DeferredDeliveryTime');
}

#===============================================================================
# Rinchi::Outlook::MailItem::DeleteAfterSubmit

=head2 $value = $Object->DeleteAfterSubmit([$new_value]);

Set or get value of the DeleteAfterSubmit attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub DeleteAfterSubmit() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('DeleteAfterSubmit', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'DeleteAfterSubmit\'';
    }
  }
  return $self->getAttribute('DeleteAfterSubmit');
}

#===============================================================================
# Rinchi::Outlook::MailItem::EnableSharedAttachments

=head2 $value = $Object->EnableSharedAttachments([$new_value]);

Set or get value of the EnableSharedAttachments attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub EnableSharedAttachments() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('EnableSharedAttachments', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'EnableSharedAttachments\'';
    }
  }
  return $self->getAttribute('EnableSharedAttachments');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ExpiryTime

=head2 $value = $Object->ExpiryTime([$new_value]);

Set or get value of the ExpiryTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ExpiryTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ExpiryTime', shift);
  }
  return $self->getAttribute('ExpiryTime');
}

#===============================================================================
# Rinchi::Outlook::MailItem::FlagDueBy

=head2 $value = $Object->FlagDueBy([$new_value]);

Set or get value of the FlagDueBy attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub FlagDueBy() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FlagDueBy', shift);
  }
  return $self->getAttribute('FlagDueBy');
}

#===============================================================================
# Rinchi::Outlook::MailItem::FlagIcon

=head2 $value = $Object->FlagIcon([$new_value]);

Set or get value of the FlagIcon attribute.

  
 Type: OlFlagIcon
 Lower: 0
 Upper: 1

=cut

sub FlagIcon() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('FlagIcon', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlFlagIcon\' for attribute \'FlagIcon\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlFlagIcon\' for attribute \'FlagIcon\'';
      }
    }
  }
  return $self->getAttribute('FlagIcon');
}

#===============================================================================
# Rinchi::Outlook::MailItem::FlagRequest

=head2 $value = $Object->FlagRequest([$new_value]);

Set or get value of the FlagRequest attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FlagRequest() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FlagRequest', shift);
  }
  return $self->getAttribute('FlagRequest');
}

#===============================================================================
# Rinchi::Outlook::MailItem::FlagStatus

=head2 $value = $Object->FlagStatus([$new_value]);

Set or get value of the FlagStatus attribute.

  
 Type: OlFlagStatus
 Lower: 0
 Upper: 1

=cut

sub FlagStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('FlagStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlFlagStatus\' for attribute \'FlagStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlFlagStatus\' for attribute \'FlagStatus\'';
      }
    }
  }
  return $self->getAttribute('FlagStatus');
}

#===============================================================================
# Rinchi::Outlook::MailItem::HTMLBody

=head2 $value = $Object->HTMLBody([$new_value]);

Set or get value of the HTMLBody attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HTMLBody() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HTMLBody', shift);
  }
  return $self->getAttribute('HTMLBody');
}

#===============================================================================
# Rinchi::Outlook::MailItem::HasCoverSheet

=head2 $value = $Object->HasCoverSheet([$new_value]);

Set or get value of the HasCoverSheet attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub HasCoverSheet() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('HasCoverSheet', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'HasCoverSheet\'';
    }
  }
  return $self->getAttribute('HasCoverSheet');
}

#===============================================================================
# Rinchi::Outlook::MailItem::InternetCodepage

=head2 $value = $Object->InternetCodepage([$new_value]);

Set or get value of the InternetCodepage attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub InternetCodepage() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('InternetCodepage', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'InternetCodepage\'';
    }
  }
  return $self->getAttribute('InternetCodepage');
}

#===============================================================================
# Rinchi::Outlook::MailItem::IsIPFax

=head2 $value = $Object->IsIPFax([$new_value]);

Set or get value of the IsIPFax attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsIPFax() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsIPFax', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsIPFax\'';
    }
  }
  return $self->getAttribute('IsIPFax');
}

#===============================================================================
# Rinchi::Outlook::MailItem::OriginatorDeliveryReportRequested

=head2 $value = $Object->OriginatorDeliveryReportRequested([$new_value]);

Set or get value of the OriginatorDeliveryReportRequested attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub OriginatorDeliveryReportRequested() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('OriginatorDeliveryReportRequested', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'OriginatorDeliveryReportRequested\'';
    }
  }
  return $self->getAttribute('OriginatorDeliveryReportRequested');
}

#===============================================================================
# Rinchi::Outlook::MailItem::Permission

=head2 $value = $Object->Permission([$new_value]);

Set or get value of the Permission attribute.

  
 Type: OlPermission
 Lower: 0
 Upper: 1

=cut

sub Permission() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Permission', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlPermission\' for attribute \'Permission\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlPermission\' for attribute \'Permission\'';
      }
    }
  }
  return $self->getAttribute('Permission');
}

#===============================================================================
# Rinchi::Outlook::MailItem::PermissionService

=head2 $value = $Object->PermissionService([$new_value]);

Set or get value of the PermissionService attribute.

  
 Type: OlPermissionService
 Lower: 0
 Upper: 1

=cut

sub PermissionService() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('PermissionService', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlPermissionService\' for attribute \'PermissionService\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlPermissionService\' for attribute \'PermissionService\'';
      }
    }
  }
  return $self->getAttribute('PermissionService');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReadReceiptRequested

=head2 $value = $Object->ReadReceiptRequested([$new_value]);

Set or get value of the ReadReceiptRequested attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReadReceiptRequested() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReadReceiptRequested', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReadReceiptRequested\'';
    }
  }
  return $self->getAttribute('ReadReceiptRequested');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReceivedByEntryID

=head2 $value = $Object->ReceivedByEntryID([$new_value]);

Set or get value of the ReceivedByEntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReceivedByEntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedByEntryID', shift);
  }
  return $self->getAttribute('ReceivedByEntryID');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReceivedByName

=head2 $value = $Object->ReceivedByName([$new_value]);

Set or get value of the ReceivedByName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReceivedByName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedByName', shift);
  }
  return $self->getAttribute('ReceivedByName');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReceivedOnBehalfOfEntryID

=head2 $value = $Object->ReceivedOnBehalfOfEntryID([$new_value]);

Set or get value of the ReceivedOnBehalfOfEntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReceivedOnBehalfOfEntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedOnBehalfOfEntryID', shift);
  }
  return $self->getAttribute('ReceivedOnBehalfOfEntryID');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReceivedOnBehalfOfName

=head2 $value = $Object->ReceivedOnBehalfOfName([$new_value]);

Set or get value of the ReceivedOnBehalfOfName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReceivedOnBehalfOfName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedOnBehalfOfName', shift);
  }
  return $self->getAttribute('ReceivedOnBehalfOfName');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReceivedTime

=head2 $value = $Object->ReceivedTime([$new_value]);

Set or get value of the ReceivedTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReceivedTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedTime', shift);
  }
  return $self->getAttribute('ReceivedTime');
}

#===============================================================================
# Rinchi::Outlook::MailItem::RecipientReassignmentProhibited

=head2 $value = $Object->RecipientReassignmentProhibited([$new_value]);

Set or get value of the RecipientReassignmentProhibited attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub RecipientReassignmentProhibited() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('RecipientReassignmentProhibited', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'RecipientReassignmentProhibited\'';
    }
  }
  return $self->getAttribute('RecipientReassignmentProhibited');
}

#===============================================================================
# Rinchi::Outlook::MailItem::Recipients

=head2 $Element = $Object->Recipients();

Set or get value of the Recipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub Recipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReminderOverrideDefault

=head2 $value = $Object->ReminderOverrideDefault([$new_value]);

Set or get value of the ReminderOverrideDefault attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderOverrideDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderOverrideDefault', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderOverrideDefault\'';
    }
  }
  return $self->getAttribute('ReminderOverrideDefault');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReminderPlaySound

=head2 $value = $Object->ReminderPlaySound([$new_value]);

Set or get value of the ReminderPlaySound attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderPlaySound() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderPlaySound', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderPlaySound\'';
    }
  }
  return $self->getAttribute('ReminderPlaySound');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReminderSet

=head2 $value = $Object->ReminderSet([$new_value]);

Set or get value of the ReminderSet attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderSet() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderSet', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderSet\'';
    }
  }
  return $self->getAttribute('ReminderSet');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReminderSoundFile

=head2 $value = $Object->ReminderSoundFile([$new_value]);

Set or get value of the ReminderSoundFile attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReminderSoundFile() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReminderSoundFile', shift);
  }
  return $self->getAttribute('ReminderSoundFile');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReminderTime

=head2 $value = $Object->ReminderTime([$new_value]);

Set or get value of the ReminderTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReminderTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReminderTime', shift);
  }
  return $self->getAttribute('ReminderTime');
}

#===============================================================================
# Rinchi::Outlook::MailItem::RemoteStatus

=head2 $value = $Object->RemoteStatus([$new_value]);

Set or get value of the RemoteStatus attribute.

  
 Type: OlRemoteStatus
 Lower: 0
 Upper: 1

=cut

sub RemoteStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('RemoteStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlRemoteStatus\' for attribute \'RemoteStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlRemoteStatus\' for attribute \'RemoteStatus\'';
      }
    }
  }
  return $self->getAttribute('RemoteStatus');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReplyRecipientNames

=head2 $value = $Object->ReplyRecipientNames([$new_value]);

Set or get value of the ReplyRecipientNames attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReplyRecipientNames() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReplyRecipientNames', shift);
  }
  return $self->getAttribute('ReplyRecipientNames');
}

#===============================================================================
# Rinchi::Outlook::MailItem::ReplyRecipients

=head2 $Element = $Object->ReplyRecipients();

Set or get value of the ReplyRecipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub ReplyRecipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::MailItem::SaveSentMessageFolder

=head2 $value = $Object->SaveSentMessageFolder([$new_value]);

Set or get value of the SaveSentMessageFolder attribute.

  
 Type: MAPIFolder
 Lower: 0
 Upper: 1

=cut

sub SaveSentMessageFolder() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::MAPIFolder' =~ /$regexp/ ) {
      $self->attribute_as_element('SaveSentMessageFolder', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::MAPIFolder\' for attribute \'SaveSentMessageFolder\'';
    }
  }
  return $self->attribute_as_element('SaveSentMessageFolder');
}

#===============================================================================
# Rinchi::Outlook::MailItem::SenderEmailAddress

=head2 $value = $Object->SenderEmailAddress([$new_value]);

Set or get value of the SenderEmailAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderEmailAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderEmailAddress', shift);
  }
  return $self->getAttribute('SenderEmailAddress');
}

#===============================================================================
# Rinchi::Outlook::MailItem::SenderEmailType

=head2 $value = $Object->SenderEmailType([$new_value]);

Set or get value of the SenderEmailType attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderEmailType() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderEmailType', shift);
  }
  return $self->getAttribute('SenderEmailType');
}

#===============================================================================
# Rinchi::Outlook::MailItem::SenderName

=head2 $value = $Object->SenderName([$new_value]);

Set or get value of the SenderName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderName', shift);
  }
  return $self->getAttribute('SenderName');
}

#===============================================================================
# Rinchi::Outlook::MailItem::Sent

=head2 $value = $Object->Sent([$new_value]);

Set or get value of the Sent attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Sent() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Sent', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Sent\'';
    }
  }
  return $self->getAttribute('Sent');
}

#===============================================================================
# Rinchi::Outlook::MailItem::SentOn

=head2 $value = $Object->SentOn([$new_value]);

Set or get value of the SentOn attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub SentOn() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SentOn', shift);
  }
  return $self->getAttribute('SentOn');
}

#===============================================================================
# Rinchi::Outlook::MailItem::SentOnBehalfOfName

=head2 $value = $Object->SentOnBehalfOfName([$new_value]);

Set or get value of the SentOnBehalfOfName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SentOnBehalfOfName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SentOnBehalfOfName', shift);
  }
  return $self->getAttribute('SentOnBehalfOfName');
}

#===============================================================================
# Rinchi::Outlook::MailItem::Submitted

=head2 $value = $Object->Submitted([$new_value]);

Set or get value of the Submitted attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Submitted() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Submitted', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Submitted\'';
    }
  }
  return $self->getAttribute('Submitted');
}

#===============================================================================
# Rinchi::Outlook::MailItem::To

=head2 $value = $Object->To([$new_value]);

Set or get value of the To attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub To() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('To', shift);
  }
  return $self->getAttribute('To');
}

#===============================================================================
# Rinchi::Outlook::MailItem::VotingOptions

=head2 $value = $Object->VotingOptions([$new_value]);

Set or get value of the VotingOptions attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub VotingOptions() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('VotingOptions', shift);
  }
  return $self->getAttribute('VotingOptions');
}

#===============================================================================
# Rinchi::Outlook::MailItem::VotingResponse

=head2 $value = $Object->VotingResponse([$new_value]);

Set or get value of the VotingResponse attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub VotingResponse() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('VotingResponse', shift);
  }
  return $self->getAttribute('VotingResponse');
}

##END_PACKAGE MailItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dd4544-3c43-11dd-9183-001c25551abc

package Rinchi::Outlook::MeetingItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MeetingItem class

Rinchi::Outlook::MeetingItem is used for representing MeetingItem objects. A 
MeetingItem object Represents an item in an Inbox (mail) folder. A MeetingItem 
object represents a change to the recipient's Calendar folder initiated by 
another party or as a result of a group action.

=head1 METHODS for MeetingItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'meeting-item'; };
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::AutoForwarded

=head2 $value = $Object->AutoForwarded([$new_value]);

Set or get value of the AutoForwarded attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub AutoForwarded() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('AutoForwarded', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'AutoForwarded\'';
    }
  }
  return $self->getAttribute('AutoForwarded');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::DeferredDeliveryTime

=head2 $value = $Object->DeferredDeliveryTime([$new_value]);

Set or get value of the DeferredDeliveryTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub DeferredDeliveryTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DeferredDeliveryTime', shift);
  }
  return $self->getAttribute('DeferredDeliveryTime');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::DeleteAfterSubmit

=head2 $value = $Object->DeleteAfterSubmit([$new_value]);

Set or get value of the DeleteAfterSubmit attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub DeleteAfterSubmit() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('DeleteAfterSubmit', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'DeleteAfterSubmit\'';
    }
  }
  return $self->getAttribute('DeleteAfterSubmit');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::ExpiryTime

=head2 $value = $Object->ExpiryTime([$new_value]);

Set or get value of the ExpiryTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ExpiryTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ExpiryTime', shift);
  }
  return $self->getAttribute('ExpiryTime');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::FlagDueBy

=head2 $value = $Object->FlagDueBy([$new_value]);

Set or get value of the FlagDueBy attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub FlagDueBy() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FlagDueBy', shift);
  }
  return $self->getAttribute('FlagDueBy');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::FlagIcon

=head2 $value = $Object->FlagIcon([$new_value]);

Set or get value of the FlagIcon attribute.

  
 Type: OlFlagIcon
 Lower: 0
 Upper: 1

=cut

sub FlagIcon() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('FlagIcon', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlFlagIcon\' for attribute \'FlagIcon\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlFlagIcon\' for attribute \'FlagIcon\'';
      }
    }
  }
  return $self->getAttribute('FlagIcon');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::FlagRequest

=head2 $value = $Object->FlagRequest([$new_value]);

Set or get value of the FlagRequest attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub FlagRequest() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('FlagRequest', shift);
  }
  return $self->getAttribute('FlagRequest');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::FlagStatus

=head2 $value = $Object->FlagStatus([$new_value]);

Set or get value of the FlagStatus attribute.

  
 Type: OlFlagStatus
 Lower: 0
 Upper: 1

=cut

sub FlagStatus() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('FlagStatus', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlFlagStatus\' for attribute \'FlagStatus\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlFlagStatus\' for attribute \'FlagStatus\'';
      }
    }
  }
  return $self->getAttribute('FlagStatus');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::MeetingWorkspaceURL

=head2 $value = $Object->MeetingWorkspaceURL([$new_value]);

Set or get value of the MeetingWorkspaceURL attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MeetingWorkspaceURL() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MeetingWorkspaceURL', shift);
  }
  return $self->getAttribute('MeetingWorkspaceURL');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::OriginatorDeliveryReportRequested

=head2 $value = $Object->OriginatorDeliveryReportRequested([$new_value]);

Set or get value of the OriginatorDeliveryReportRequested attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub OriginatorDeliveryReportRequested() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('OriginatorDeliveryReportRequested', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'OriginatorDeliveryReportRequested\'';
    }
  }
  return $self->getAttribute('OriginatorDeliveryReportRequested');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::ReceivedTime

=head2 $value = $Object->ReceivedTime([$new_value]);

Set or get value of the ReceivedTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReceivedTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedTime', shift);
  }
  return $self->getAttribute('ReceivedTime');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::Recipients

=head2 $Element = $Object->Recipients();

Set or get value of the Recipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub Recipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::ReminderSet

=head2 $value = $Object->ReminderSet([$new_value]);

Set or get value of the ReminderSet attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderSet() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderSet', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderSet\'';
    }
  }
  return $self->getAttribute('ReminderSet');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::ReminderTime

=head2 $value = $Object->ReminderTime([$new_value]);

Set or get value of the ReminderTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReminderTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReminderTime', shift);
  }
  return $self->getAttribute('ReminderTime');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::ReplyRecipients

=head2 $Element = $Object->ReplyRecipients();

Set or get value of the ReplyRecipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub ReplyRecipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::SaveSentMessageFolder

=head2 $value = $Object->SaveSentMessageFolder([$new_value]);

Set or get value of the SaveSentMessageFolder attribute.

  
 Type: MAPIFolder
 Lower: 0
 Upper: 1

=cut

sub SaveSentMessageFolder() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::MAPIFolder' =~ /$regexp/ ) {
      $self->attribute_as_element('SaveSentMessageFolder', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::MAPIFolder\' for attribute \'SaveSentMessageFolder\'';
    }
  }
  return $self->attribute_as_element('SaveSentMessageFolder');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::SenderEmailAddress

=head2 $value = $Object->SenderEmailAddress([$new_value]);

Set or get value of the SenderEmailAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderEmailAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderEmailAddress', shift);
  }
  return $self->getAttribute('SenderEmailAddress');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::SenderEmailType

=head2 $value = $Object->SenderEmailType([$new_value]);

Set or get value of the SenderEmailType attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderEmailType() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderEmailType', shift);
  }
  return $self->getAttribute('SenderEmailType');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::SenderName

=head2 $value = $Object->SenderName([$new_value]);

Set or get value of the SenderName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderName', shift);
  }
  return $self->getAttribute('SenderName');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::Sent

=head2 $value = $Object->Sent([$new_value]);

Set or get value of the Sent attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Sent() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Sent', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Sent\'';
    }
  }
  return $self->getAttribute('Sent');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::SentOn

=head2 $value = $Object->SentOn([$new_value]);

Set or get value of the SentOn attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub SentOn() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SentOn', shift);
  }
  return $self->getAttribute('SentOn');
}

#===============================================================================
# Rinchi::Outlook::MeetingItem::Submitted

=head2 $value = $Object->Submitted([$new_value]);

Set or get value of the Submitted attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Submitted() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Submitted', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Submitted\'';
    }
  }
  return $self->getAttribute('Submitted');
}

##END_PACKAGE MeetingItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dda32c-3c43-11dd-8375-001c25551abc

package Rinchi::Outlook::NoteItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookBaseItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of NoteItem

Rinchi::Outlook::NoteItem is used for representing NoteItem objects. A NoteItem 
object represents a note in a Notes folder.

=head1 METHODS for NoteItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'note-item'; };
}

#===============================================================================
# Rinchi::Outlook::NoteItem::Color

=head2 $value = $Object->Color([$new_value]);

Set or get value of the Color attribute.

  
 Type: OlNoteColor
 Lower: 0
 Upper: 1

=cut

sub Color() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Color', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlNoteColor\' for attribute \'Color\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlNoteColor\' for attribute \'Color\'';
      }
    }
  }
  return $self->getAttribute('Color');
}

#===============================================================================
# Rinchi::Outlook::NoteItem::Height

=head2 $value = $Object->Height([$new_value]);

Set or get value of the Height attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Height() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Height', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Height\'';
    }
  }
  return $self->getAttribute('Height');
}

#===============================================================================
# Rinchi::Outlook::NoteItem::Left

=head2 $value = $Object->Left([$new_value]);

Set or get value of the Left attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Left() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Left', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Left\'';
    }
  }
  return $self->getAttribute('Left');
}

#===============================================================================
# Rinchi::Outlook::NoteItem::Top

=head2 $value = $Object->Top([$new_value]);

Set or get value of the Top attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Top() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Top', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Top\'';
    }
  }
  return $self->getAttribute('Top');
}

#===============================================================================
# Rinchi::Outlook::NoteItem::Width

=head2 $value = $Object->Width([$new_value]);

Set or get value of the Width attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Width() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Width', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Width\'';
    }
  }
  return $self->getAttribute('Width');
}

##END_PACKAGE NoteItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5dea1fa-3c43-11dd-a269-001c25551abc

package Rinchi::Outlook::PostItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of PostItem class

Rinchi::Outlook::PostItem is used for representing PostItem objects. A PostItem 
object represents a post in a public folder that others may browse.

=head1 METHODS for PostItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'post-item'; };
}

#===============================================================================
# Rinchi::Outlook::PostItem::BodyFormat

=head2 $value = $Object->BodyFormat([$new_value]);

Set or get value of the BodyFormat attribute.

  
 Type: OlBodyFormat
 Lower: 0
 Upper: 1

=cut

sub BodyFormat() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('BodyFormat', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlBodyFormat\' for attribute \'BodyFormat\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlBodyFormat\' for attribute \'BodyFormat\'';
      }
    }
  }
  return $self->getAttribute('BodyFormat');
}

#===============================================================================
# Rinchi::Outlook::PostItem::ExpiryTime

=head2 $value = $Object->ExpiryTime([$new_value]);

Set or get value of the ExpiryTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ExpiryTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ExpiryTime', shift);
  }
  return $self->getAttribute('ExpiryTime');
}

#===============================================================================
# Rinchi::Outlook::PostItem::HTMLBody

=head2 $value = $Object->HTMLBody([$new_value]);

Set or get value of the HTMLBody attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub HTMLBody() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('HTMLBody', shift);
  }
  return $self->getAttribute('HTMLBody');
}

#===============================================================================
# Rinchi::Outlook::PostItem::InternetCodepage

=head2 $value = $Object->InternetCodepage([$new_value]);

Set or get value of the InternetCodepage attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub InternetCodepage() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('InternetCodepage', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'InternetCodepage\'';
    }
  }
  return $self->getAttribute('InternetCodepage');
}

#===============================================================================
# Rinchi::Outlook::PostItem::ReceivedTime

=head2 $value = $Object->ReceivedTime([$new_value]);

Set or get value of the ReceivedTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReceivedTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReceivedTime', shift);
  }
  return $self->getAttribute('ReceivedTime');
}

#===============================================================================
# Rinchi::Outlook::PostItem::SenderEmailAddress

=head2 $value = $Object->SenderEmailAddress([$new_value]);

Set or get value of the SenderEmailAddress attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderEmailAddress() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderEmailAddress', shift);
  }
  return $self->getAttribute('SenderEmailAddress');
}

#===============================================================================
# Rinchi::Outlook::PostItem::SenderEmailType

=head2 $value = $Object->SenderEmailType([$new_value]);

Set or get value of the SenderEmailType attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderEmailType() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderEmailType', shift);
  }
  return $self->getAttribute('SenderEmailType');
}

#===============================================================================
# Rinchi::Outlook::PostItem::SenderName

=head2 $value = $Object->SenderName([$new_value]);

Set or get value of the SenderName attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SenderName() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SenderName', shift);
  }
  return $self->getAttribute('SenderName');
}

#===============================================================================
# Rinchi::Outlook::PostItem::SentOn

=head2 $value = $Object->SentOn([$new_value]);

Set or get value of the SentOn attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub SentOn() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SentOn', shift);
  }
  return $self->getAttribute('SentOn');
}

##END_PACKAGE PostItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5df71ca-3c43-11dd-bd00-001c25551abc

package Rinchi::Outlook::RemoteItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of RemoteItem class

Rinchi::Outlook::RemoteItem is used for representing RemoteItem objects. A 
RemoteItem objects represents a remote item in an Inbox (mail) folder. The 
RemoteItem object is similar to the MailItem object, but it contains only 
the Subject, Received Date and Time, Sender, Size, and the first 256 characters 
of the body of the message. It is used to give someone connecting in remote 
mode enough information to decide whether or not to download the corresponding 
mail message. However, the headers in items contained in an Offline Folders file 
(.ost) cannot be accessed using the RemoteItem object.

=head1 METHODS for RemoteItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'remote-item'; };
}

#===============================================================================
# Rinchi::Outlook::RemoteItem::HasAttachment

=head2 $value = $Object->HasAttachment([$new_value]);

Set or get value of the HasAttachment attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub HasAttachment() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('HasAttachment', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'HasAttachment\'';
    }
  }
  return $self->getAttribute('HasAttachment');
}

#===============================================================================
# Rinchi::Outlook::RemoteItem::RemoteMessageClass

=head2 $value = $Object->RemoteMessageClass([$new_value]);

Set or get value of the RemoteMessageClass attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub RemoteMessageClass() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('RemoteMessageClass', shift);
  }
  return $self->getAttribute('RemoteMessageClass');
}

#===============================================================================
# Rinchi::Outlook::RemoteItem::TransferSize

=head2 $value = $Object->TransferSize([$new_value]);

Set or get value of the TransferSize attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub TransferSize() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('TransferSize', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'TransferSize\'';
    }
  }
  return $self->getAttribute('TransferSize');
}

#===============================================================================
# Rinchi::Outlook::RemoteItem::TransferTime

=head2 $value = $Object->TransferTime([$new_value]);

Set or get value of the TransferTime attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub TransferTime() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('TransferTime', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'TransferTime\'';
    }
  }
  return $self->getAttribute('TransferTime');
}

##END_PACKAGE RemoteItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5df927c-3c43-11dd-a136-001c25551abc

package Rinchi::Outlook::ReportItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ReportItem

Rinchi::Outlook::ReportItem is used for representing ReportItem objects. A 
ReportItem objects represents a mail-delivery report in an Inbox (mail) folder. 
The ReportItem object is similar to a MailItem  object, and it contains a report 
(usually the non-delivery report) or error message from the mail transport system.

=head1 METHODS for ReportItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'report-item'; };
}

##END_PACKAGE ReportItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e048a2-3c43-11dd-ae11-001c25551abc

package Rinchi::Outlook::TaskItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TaskItem class

Rinchi::Outlook::TaskItem is used for representing TaskItem objects. A TaskItem 
object represents a task (an assigned, delegated, or self-imposed task to be 
performed within a specified time frame) in a Tasks folder.

=head1 METHODS for TaskItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'task-item'; };
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ActualWork

=head2 $value = $Object->ActualWork([$new_value]);

Set or get value of the ActualWork attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub ActualWork() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ActualWork', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'ActualWork\'';
    }
  }
  return $self->getAttribute('ActualWork');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::CardData

=head2 $value = $Object->CardData([$new_value]);

Set or get value of the CardData attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub CardData() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CardData', shift);
  }
  return $self->getAttribute('CardData');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Complete

=head2 $value = $Object->Complete([$new_value]);

Set or get value of the Complete attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Complete() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Complete', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Complete\'';
    }
  }
  return $self->getAttribute('Complete');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ContactNames

=head2 $value = $Object->ContactNames([$new_value]);

Set or get value of the ContactNames attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ContactNames() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ContactNames', shift);
  }
  return $self->getAttribute('ContactNames');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Contacts

=head2 $value = $Object->Contacts([$new_value]);

Set or get value of the Contacts attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Contacts() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Contacts', shift);
  }
  return $self->getAttribute('Contacts');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::DateCompleted

=head2 $value = $Object->DateCompleted([$new_value]);

Set or get value of the DateCompleted attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub DateCompleted() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DateCompleted', shift);
  }
  return $self->getAttribute('DateCompleted');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::DelegationState

=head2 $value = $Object->DelegationState([$new_value]);

Set or get value of the DelegationState attribute.

  
 Type: OlTaskDelegationState
 Lower: 0
 Upper: 1

=cut

sub DelegationState() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DelegationState', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlTaskDelegationState\' for attribute \'DelegationState\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlTaskDelegationState\' for attribute \'DelegationState\'';
      }
    }
  }
  return $self->getAttribute('DelegationState');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Delegator

=head2 $value = $Object->Delegator([$new_value]);

Set or get value of the Delegator attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Delegator() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Delegator', shift);
  }
  return $self->getAttribute('Delegator');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::DueDate

=head2 $value = $Object->DueDate([$new_value]);

Set or get value of the DueDate attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub DueDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('DueDate', shift);
  }
  return $self->getAttribute('DueDate');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::InternetCodepage

=head2 $value = $Object->InternetCodepage([$new_value]);

Set or get value of the InternetCodepage attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub InternetCodepage() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('InternetCodepage', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'InternetCodepage\'';
    }
  }
  return $self->getAttribute('InternetCodepage');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::IsRecurring

=head2 $value = $Object->IsRecurring([$new_value]);

Set or get value of the IsRecurring attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsRecurring() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsRecurring', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsRecurring\'';
    }
  }
  return $self->getAttribute('IsRecurring');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Ordinal

=head2 $value = $Object->Ordinal([$new_value]);

Set or get value of the Ordinal attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Ordinal() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Ordinal', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Ordinal\'';
    }
  }
  return $self->getAttribute('Ordinal');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Owner

=head2 $value = $Object->Owner([$new_value]);

Set or get value of the Owner attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Owner() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Owner', shift);
  }
  return $self->getAttribute('Owner');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Ownership

=head2 $value = $Object->Ownership([$new_value]);

Set or get value of the Ownership attribute.

  
 Type: OlTaskOwnership
 Lower: 0
 Upper: 1

=cut

sub Ownership() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Ownership', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlTaskOwnership\' for attribute \'Ownership\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlTaskOwnership\' for attribute \'Ownership\'';
      }
    }
  }
  return $self->getAttribute('Ownership');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::PercentComplete

=head2 $value = $Object->PercentComplete([$new_value]);

Set or get value of the PercentComplete attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub PercentComplete() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('PercentComplete', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'PercentComplete\'';
    }
  }
  return $self->getAttribute('PercentComplete');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Recipients

=head2 $Element = $Object->Recipients();

Set or get value of the Recipients attribute.

  
 Type: Recipients
 Lower: 0
 Upper: 1

=cut

sub Recipients() {
  my $self = shift;
  return $self->get_collection('Recipients','recipients');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ReminderOverrideDefault

=head2 $value = $Object->ReminderOverrideDefault([$new_value]);

Set or get value of the ReminderOverrideDefault attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderOverrideDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderOverrideDefault', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderOverrideDefault\'';
    }
  }
  return $self->getAttribute('ReminderOverrideDefault');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ReminderPlaySound

=head2 $value = $Object->ReminderPlaySound([$new_value]);

Set or get value of the ReminderPlaySound attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderPlaySound() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderPlaySound', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderPlaySound\'';
    }
  }
  return $self->getAttribute('ReminderPlaySound');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ReminderSet

=head2 $value = $Object->ReminderSet([$new_value]);

Set or get value of the ReminderSet attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub ReminderSet() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('ReminderSet', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'ReminderSet\'';
    }
  }
  return $self->getAttribute('ReminderSet');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ReminderSoundFile

=head2 $value = $Object->ReminderSoundFile([$new_value]);

Set or get value of the ReminderSoundFile attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ReminderSoundFile() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReminderSoundFile', shift);
  }
  return $self->getAttribute('ReminderSoundFile');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ReminderTime

=head2 $value = $Object->ReminderTime([$new_value]);

Set or get value of the ReminderTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub ReminderTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ReminderTime', shift);
  }
  return $self->getAttribute('ReminderTime');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::ResponseState

=head2 $value = $Object->ResponseState([$new_value]);

Set or get value of the ResponseState attribute.

  
 Type: OlTaskResponse
 Lower: 0
 Upper: 1

=cut

sub ResponseState() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('ResponseState', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlTaskResponse\' for attribute \'ResponseState\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlTaskResponse\' for attribute \'ResponseState\'';
      }
    }
  }
  return $self->getAttribute('ResponseState');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Role

=head2 $value = $Object->Role([$new_value]);

Set or get value of the Role attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Role() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Role', shift);
  }
  return $self->getAttribute('Role');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::SchedulePlusPriority

=head2 $value = $Object->SchedulePlusPriority([$new_value]);

Set or get value of the SchedulePlusPriority attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub SchedulePlusPriority() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('SchedulePlusPriority', shift);
  }
  return $self->getAttribute('SchedulePlusPriority');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::StartDate

=head2 $value = $Object->StartDate([$new_value]);

Set or get value of the StartDate attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub StartDate() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('StartDate', shift);
  }
  return $self->getAttribute('StartDate');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::Status

=head2 $value = $Object->Status([$new_value]);

Set or get value of the Status attribute.

  
 Type: OlTaskStatus
 Lower: 0
 Upper: 1

=cut

sub Status() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Status', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlTaskStatus\' for attribute \'Status\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlTaskStatus\' for attribute \'Status\'';
      }
    }
  }
  return $self->getAttribute('Status');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::StatusOnCompletionRecipients

=head2 $value = $Object->StatusOnCompletionRecipients([$new_value]);

Set or get value of the StatusOnCompletionRecipients attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub StatusOnCompletionRecipients() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('StatusOnCompletionRecipients', shift);
  }
  return $self->getAttribute('StatusOnCompletionRecipients');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::StatusUpdateRecipients

=head2 $value = $Object->StatusUpdateRecipients([$new_value]);

Set or get value of the StatusUpdateRecipients attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub StatusUpdateRecipients() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('StatusUpdateRecipients', shift);
  }
  return $self->getAttribute('StatusUpdateRecipients');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::TeamTask

=head2 $value = $Object->TeamTask([$new_value]);

Set or get value of the TeamTask attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub TeamTask() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('TeamTask', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'TeamTask\'';
    }
  }
  return $self->getAttribute('TeamTask');
}

#===============================================================================
# Rinchi::Outlook::TaskItem::TotalWork

=head2 $value = $Object->TotalWork([$new_value]);

Set or get value of the TotalWork attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub TotalWork() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('TotalWork', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'TotalWork\'';
    }
  }
  return $self->getAttribute('TotalWork');
}

##END_PACKAGE TaskItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e0692c-3c43-11dd-b7e8-001c25551abc

package Rinchi::Outlook::TaskRequestAcceptItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TaskRequestAcceptItem

Rinchi::Outlook::TaskRequestAcceptItem is used for representing 
TaskRequestAcceptItem objects. A TaskRequestAcceptItem object Represents an item 
in an Inbox (mail) folder.

A TaskRequestAcceptItem object represents a response to a TaskRequestItem sent by 
the initiating user. If the delegated user accepts the task, the ResponseState 
property is set to olTaskAccept. The associated TaskItem is received by the 
delegator as a TaskRequestAcceptItem object.

=head1 METHODS for TaskRequestAcceptItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'task-request-accept-item'; };
}

##END_PACKAGE TaskRequestAcceptItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e08880-3c43-11dd-9d56-001c25551abc

package Rinchi::Outlook::TaskRequestDeclineItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TaskRequestDeclineItem class

Rinchi::Outlook::TaskRequestDeclineItem is used for representing 
TaskRequestDeclineItem objects. A TaskRequestDeclineItem object represents an 
item in an Inbox (mail) folder.

A TaskRequestDeclineItem object represents a response to a TaskRequestItem sent 
by the initiating user. If the delegated user declines the task, the 
ResponseState property is set to olTaskDecline. The associated TaskItem is 
received by the delegator as a TaskRequestDeclineItem object.

=head1 METHODS for TaskRequestDeclineItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'task-request-decline-item'; };
}

##END_PACKAGE TaskRequestDeclineItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e0a8d8-3c43-11dd-84f0-001c25551abc

package Rinchi::Outlook::TaskRequestItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TaskRequestItem class

Rinchi::Outlook::TaskRequestItem is used for representing TaskRequestItem 
objects. A TaskRequestItem object represents an item in an Inbox (mail) folder. 
A TaskRequestItem object represents a change to the recipient's Tasks list 
initiated by another party or as a result of a group tasking.
		
=head1 METHODS for TaskRequestItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'task-request-item'; };
}

##END_PACKAGE TaskRequestItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e0ca16-3c43-11dd-bc30-001c25551abc

package Rinchi::Outlook::TaskRequestUpdateItem;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TaskRequestUpdateItem class

Rinchi::Outlook::TaskRequestUpdateItem is used for representing 
TaskRequestUpdateItem objects. A TaskRequestUpdateItem object represents an 
item in an Inbox (mail) folder.

A TaskRequestUpdateItem object represents a response to a TaskRequestItem sent 
by the initiating user. If the delegated user updates the task by changing 
properties such as the DueDate or the Status, and then sends it, the associated 
TaskItem is received by the delegator as a TaskRequestUpdateItem object.

=head1 METHODS for TaskRequestUpdateItem objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'task-request-update-item'; };
}

##END_PACKAGE TaskRequestUpdateItem

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: e0efff78-40a1-11dd-8bf4-00502c05c241

package Rinchi::Outlook::OutlookBaseItemObject;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::BasicElement);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookBaseItemObject class

Rinchi::Outlook::OutlookBaseItemObject is an abstract class used for 
representing OutlookBaseItemObject objects. Classes derived from 
OutlookBaseItemObject include OutlookItemObject and NoteItem.

=head1 METHODS for OutlookBaseItemObject objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-base-item-object'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Application

=head2 $value = $Object->Application([$new_value]);

Set or get value of the Application attribute.

  
 Type: Application
 Lower: 0
 Upper: 1

=cut

sub Application() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Application' =~ /$regexp/ ) {
      $self->attribute_as_element('Application', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Application\' for attribute \'Application\'';
    }
  }
  return $self->attribute_as_element('Application');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::AutoResolvedWinner

=head2 $value = $Object->AutoResolvedWinner([$new_value]);

Set or get value of the AutoResolvedWinner attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub AutoResolvedWinner() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('AutoResolvedWinner', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'AutoResolvedWinner\'';
    }
  }
  return $self->getAttribute('AutoResolvedWinner');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Body

=head2 $value = $Object->Body([$new_value]);

Set or get value of the Body attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Body() {
  my $self = shift;
  if (@_) {
    $self->attribute_as_element('Body', shift);
  }
  return $self->attribute_as_element('Body');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Categories

=head2 $value = $Object->Categories([$new_value]);

Set or get value of the Categories attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Categories() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Categories', shift);
  }
  return $self->getAttribute('Categories');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Class

=head2 $value = $Object->Class([$new_value]);

Set or get value of the Class attribute.

  
 Type: OlObjectClass
 Lower: 0
 Upper: 1

=cut

sub Class() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Class', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlObjectClass\' for attribute \'Class\'';
      }
    }
  }
  return $self->getAttribute('Class');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Conflicts

=head2 $Element = $Object->Conflicts();

Set or get value of the Conflicts attribute.

  
 Type: Conflicts
 Lower: 0
 Upper: 1

=cut

sub Conflicts() {
  my $self = shift;
  return $self->get_collection('Conflicts','conflicts');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::CreationTime

=head2 $value = $Object->CreationTime([$new_value]);

Set or get value of the CreationTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub CreationTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('CreationTime', shift);
  }
  return $self->getAttribute('CreationTime');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::DownloadState

=head2 $value = $Object->DownloadState([$new_value]);

Set or get value of the DownloadState attribute.

  
 Type: OlDownloadState
 Lower: 0
 Upper: 1

=cut

sub DownloadState() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('DownloadState', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlDownloadState\' for attribute \'DownloadState\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlDownloadState\' for attribute \'DownloadState\'';
      }
    }
  }
  return $self->getAttribute('DownloadState');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::EntryID

=head2 $value = $Object->EntryID([$new_value]);

Set or get value of the EntryID attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub EntryID() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('EntryID', shift);
  }
  return $self->getAttribute('EntryID');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::GetInspector

=head2 $value = $Object->GetInspector([$new_value]);

Set or get value of the GetInspector attribute.

  
 Type: Inspector
 Lower: 0
 Upper: 1

=cut

sub GetInspector() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Inspector' =~ /$regexp/ ) {
      $self->attribute_as_element('GetInspector', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Inspector\' for attribute \'GetInspector\'';
    }
  }
  return $self->attribute_as_element('GetInspector');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::IsConflict

=head2 $value = $Object->IsConflict([$new_value]);

Set or get value of the IsConflict attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub IsConflict() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('IsConflict', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'IsConflict\'';
    }
  }
  return $self->getAttribute('IsConflict');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::ItemProperties

=head2 $Element = $Object->ItemProperties();

Set or get value of the ItemProperties attribute.

  
 Type: ItemProperties
 Lower: 0
 Upper: 1

=cut

sub ItemProperties() {
  my $self = shift;
  return $self->get_collection('ItemProperties','item-properties');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::LastModificationTime

=head2 $value = $Object->LastModificationTime([$new_value]);

Set or get value of the LastModificationTime attribute.

  
 Type: VT_DATE
 Lower: 0
 Upper: 1

=cut

sub LastModificationTime() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('LastModificationTime', shift);
  }
  return $self->getAttribute('LastModificationTime');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Links

=head2 $Element = $Object->Links();

Set or get value of the Links attribute.

  
 Type: Links
 Lower: 0
 Upper: 1

=cut

sub Links() {
  my $self = shift;
  return $self->get_collection('Links','links');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::MarkForDownload

=head2 $value = $Object->MarkForDownload([$new_value]);

Set or get value of the MarkForDownload attribute.

  
 Type: OlRemoteStatus
 Lower: 0
 Upper: 1

=cut

sub MarkForDownload() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('MarkForDownload', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlRemoteStatus\' for attribute \'MarkForDownload\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlRemoteStatus\' for attribute \'MarkForDownload\'';
      }
    }
  }
  return $self->getAttribute('MarkForDownload');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::MessageClass

=head2 $value = $Object->MessageClass([$new_value]);

Set or get value of the MessageClass attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub MessageClass() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('MessageClass', shift);
  }
  return $self->getAttribute('MessageClass');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Parent

=head2 $value = $Object->Parent([$new_value]);

Set or get value of the Parent attribute.

  
 Type: Object
 Lower: 0
 Upper: 1

=cut

sub Parent() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::Object' =~ /$regexp/ ) {
      $self->attribute_as_element('Parent', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::Object\' for attribute \'Parent\'';
    }
  }
  return $self->attribute_as_element('Parent');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Saved

=head2 $value = $Object->Saved([$new_value]);

Set or get value of the Saved attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub Saved() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('Saved', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'Saved\'';
    }
  }
  return $self->getAttribute('Saved');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Session

=head2 $value = $Object->Session([$new_value]);

Set or get value of the Session attribute.

  
 Type: NameSpace
 Lower: 0
 Upper: 1

=cut

sub Session() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::NameSpace' =~ /$regexp/ ) {
      $self->attribute_as_element('Session', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::NameSpace\' for attribute \'Session\'';
    }
  }
  return $self->attribute_as_element('Session');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Size

=head2 $value = $Object->Size([$new_value]);

Set or get value of the Size attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub Size() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Size', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'Size\'';
    }
  }
  return $self->getAttribute('Size');
}

#===============================================================================
# Rinchi::Outlook::OutlookBaseItemObject::Subject

=head2 $value = $Object->Subject([$new_value]);

Set or get value of the Subject attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Subject() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Subject', shift);
  }
  return $self->getAttribute('Subject');
}

##END_PACKAGE OutlookBaseItemObject

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: 80ebedaf-40b0-11dd-8bf4-00502c05c241

package Rinchi::Outlook::OutlookItemObject;

use Carp;

our @ISA = qw(Rinchi::Outlook::Element Rinchi::Outlook::OutlookBaseItemObject);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OutlookItemObject class

Rinchi::Outlook::OutlookItemObject is an abstract class used for representing 
OutlookItemObject objects. Classes derived from OutlookItemObject include the
following:

  AppointmentItem
  ContactItem
  DistListItem
  DocumentItem
  JournalItem
  MailItem
  MeetingItem
  PostItem
  RemoteItem
  ReportItem
  TaskItem
  TaskRequestAcceptItem
  TaskRequestDeclineItem
  TaskRequestItem
  TaskRequestUpdateItem

=head1 METHODS for OutlookItemObject objects

=cut

#===============================================================================

{
  no strict "refs";
  *TAG_NAME = sub { return 'outlook-item-object'; };
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::Actions

=head2 $Element = $Object->Actions();

Set or get value of the Actions attribute.

  
 Type: Actions
 Lower: 0
 Upper: 1

=cut

sub Actions() {
  my $self = shift;
  return $self->get_collection('Actions','actions');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::Attachments

=head2 $Element = $Object->Attachments();

Set or get value of the Attachments attribute.

  
 Type: Attachments
 Lower: 0
 Upper: 1

=cut

sub Attachments() {
  my $self = shift;
  return $self->get_collection('Attachments','attachments');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::BillingInformation

=head2 $value = $Object->BillingInformation([$new_value]);

Set or get value of the BillingInformation attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub BillingInformation() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('BillingInformation', shift);
  }
  return $self->getAttribute('BillingInformation');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::Companies

=head2 $value = $Object->Companies([$new_value]);

Set or get value of the Companies attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Companies() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Companies', shift);
  }
  return $self->getAttribute('Companies');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::ConversationIndex

=head2 $value = $Object->ConversationIndex([$new_value]);

Set or get value of the ConversationIndex attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ConversationIndex() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ConversationIndex', shift);
  }
  return $self->getAttribute('ConversationIndex');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::ConversationTopic

=head2 $value = $Object->ConversationTopic([$new_value]);

Set or get value of the ConversationTopic attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub ConversationTopic() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('ConversationTopic', shift);
  }
  return $self->getAttribute('ConversationTopic');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::FormDescription

=head2 $value = $Object->FormDescription([$new_value]);

Set or get value of the FormDescription attribute.

  
 Type: FormDescription
 Lower: 0
 Upper: 1

=cut

sub FormDescription() {
  my $self = shift;
  if (@_) {
    my $regexp = join('|',Class::ISA::self_and_super_path(ref($_[0])));
    if ('Rinchi::Outlook::FormDescription' =~ /$regexp/ ) {
      $self->attribute_as_element('FormDescription', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::FormDescription\' for attribute \'FormDescription\'';
    }
  }
  return $self->attribute_as_element('FormDescription');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::Importance

=head2 $value = $Object->Importance([$new_value]);

Set or get value of the Importance attribute.

  
 Type: OlImportance
 Lower: 0
 Upper: 1

=cut

sub Importance() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Importance', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlImportance\' for attribute \'Importance\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlImportance\' for attribute \'Importance\'';
      }
    }
  }
  return $self->getAttribute('Importance');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::Mileage

=head2 $value = $Object->Mileage([$new_value]);

Set or get value of the Mileage attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub Mileage() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('Mileage', shift);
  }
  return $self->getAttribute('Mileage');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::NoAging

=head2 $value = $Object->NoAging([$new_value]);

Set or get value of the NoAging attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub NoAging() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('NoAging', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'NoAging\'';
    }
  }
  return $self->getAttribute('NoAging');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::OutlookInternalVersion

=head2 $value = $Object->OutlookInternalVersion([$new_value]);

Set or get value of the OutlookInternalVersion attribute.

  
 Type: Long
 Lower: 0
 Upper: 1

=cut

sub OutlookInternalVersion() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('OutlookInternalVersion', shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Long\' for attribute \'OutlookInternalVersion\'';
    }
  }
  return $self->getAttribute('OutlookInternalVersion');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::OutlookVersion

=head2 $value = $Object->OutlookVersion([$new_value]);

Set or get value of the OutlookVersion attribute.

  
 Type: String
 Lower: 0
 Upper: 1

=cut

sub OutlookVersion() {
  my $self = shift;
  if (@_) {
    $self->setAttribute('OutlookVersion', shift);
  }
  return $self->getAttribute('OutlookVersion');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::Sensitivity

=head2 $value = $Object->Sensitivity([$new_value]);

Set or get value of the Sensitivity attribute.

  
 Type: OlSensitivity
 Lower: 0
 Upper: 1

=cut

sub Sensitivity() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-+]?[0-9]+$/ ) {
      $self->setAttribute('Sensitivity', shift);
    } else {
      if(ref($_[0])) {
        carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Rinchi::Outlook::OlSensitivity\' for attribute \'Sensitivity\'';
      } else {
        carp 'Found scalar \'' . $_[0] . '\', expecting type \'Rinchi::Outlook::OlSensitivity\' for attribute \'Sensitivity\'';
      }
    }
  }
  return $self->getAttribute('Sensitivity');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::UnRead

=head2 $value = $Object->UnRead([$new_value]);

Set or get value of the UnRead attribute.

  
 Type: Boolean
 Lower: 0
 Upper: 1

=cut

sub UnRead() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^(true|false)$/i ) {
      $self->setAttribute('UnRead', lc shift);
    } else {
      carp 'Found type \'' . ref($_[0]) . '\', expecting type \'Boolean\' for attribute \'UnRead\'';
    }
  }
  return $self->getAttribute('UnRead');
}

#===============================================================================
# Rinchi::Outlook::OutlookItemObject::UserProperties

=head2 $Element = $Object->UserProperties();

Set or get value of the UserProperties attribute.

  
 Type: UserProperties
 Lower: 0
 Upper: 1

=cut

sub UserProperties() {
  my $self = shift;
  return $self->get_collection('UserProperties','user-properties');
}

##END_PACKAGE OutlookItemObject

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e151f2-3c43-11dd-a2a3-001c25551abc

package Rinchi::Outlook::OlActionCopyLike;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlActionCopyLike enumeration

Rinchi::Outlook::OlActionCopyLike is used for representing the OlActionCopyLike 
enumeration.

=head1 CONSTANTS for the OlActionCopyLike enumeration

 olReply                                   => 0
 olReplyAll                                => 1
 olForward                                 => 2
 olReplyFolder                             => 3
 olRespond                                 => 4

=cut

#===============================================================================
  *olReply                                   = sub { return 0; };
  *olReplyAll                                = sub { return 1; };
  *olForward                                 = sub { return 2; };
  *olReplyFolder                             = sub { return 3; };
  *olRespond                                 = sub { return 4; };

my @_literal_list_OlActionCopyLike = (
  'olReply'                                   => 0,
  'olReplyAll'                                => 1,
  'olForward'                                 => 2,
  'olReplyFolder'                             => 3,
  'olRespond'                                 => 4,
);

#===============================================================================
# Rinchi::Outlook::OlActionCopyLike::Literals

=head1 METHODS for the OlActionCopyLike enumeration

=head2 @Literals = Rinchi::Outlook::OlActionCopyLike::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlActionCopyLike::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlActionCopyLike;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e16430-3c43-11dd-bc9d-001c25551abc

package Rinchi::Outlook::OlActionReplyStyle;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlActionReplyStyle

Rinchi::Outlook::OlActionReplyStyle is used representing the OlActionReplyStyle enumeration.

=head1 CONSTANTS for the OlActionReplyStyle enumeration

 olOmitOriginalText                        => 0
 olEmbedOriginalItem                       => 1
 olIncludeOriginalText                     => 2
 olIndentOriginalText                      => 3
 olLinkOriginalItem                        => 4
 olUserPreference                          => 5
 olReplyTickOriginalText                   => 1000

=cut

#===============================================================================
  *olOmitOriginalText                        = sub { return 0; };
  *olEmbedOriginalItem                       = sub { return 1; };
  *olIncludeOriginalText                     = sub { return 2; };
  *olIndentOriginalText                      = sub { return 3; };
  *olLinkOriginalItem                        = sub { return 4; };
  *olUserPreference                          = sub { return 5; };
  *olReplyTickOriginalText                   = sub { return 1000; };

my @_literal_list_OlActionReplyStyle = (
  'olOmitOriginalText'                        => 0,
  'olEmbedOriginalItem'                       => 1,
  'olIncludeOriginalText'                     => 2,
  'olIndentOriginalText'                      => 3,
  'olLinkOriginalItem'                        => 4,
  'olUserPreference'                          => 5,
  'olReplyTickOriginalText'                   => 1000,
);

#===============================================================================
# Rinchi::Outlook::OlActionReplyStyle::Literals

=head1 METHODS for the OlActionReplyStyle enumeration

=head2 @Literals = Rinchi::Outlook::OlActionReplyStyle::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlActionReplyStyle::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlActionReplyStyle;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e174b6-3c43-11dd-aaaf-001c25551abc

package Rinchi::Outlook::OlActionResponseStyle;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlActionResponseStyle enumeration

Rinchi::Outlook::OlActionResponseStyle - Module representing the OlActionResponseStyle enumeration. 

=head1 CONSTANTS for the OlActionResponseStyle enumeration

 olOpen                                    => 0
 olSend                                    => 1
 olPrompt                                  => 2

=cut

#===============================================================================
  *olOpen                                    = sub { return 0; };
  *olSend                                    = sub { return 1; };
  *olPrompt                                  = sub { return 2; };

my @_literal_list_OlActionResponseStyle = (
  'olOpen'                                    => 0,
  'olSend'                                    => 1,
  'olPrompt'                                  => 2,
);

#===============================================================================
# Rinchi::Outlook::OlActionResponseStyle::Literals

=head1 METHODS for the OlActionResponseStyle enumeration

=head2 @Literals = Rinchi::Outlook::OlActionResponseStyle::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlActionResponseStyle::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlActionResponseStyle;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e184f6-3c43-11dd-b2f6-001c25551abc

package Rinchi::Outlook::OlActionShowOn;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlActionShowOn enumeration

Rinchi::Outlook::OlActionShowOn - Module representing the OlActionShowOn enumeration. 

=head1 CONSTANTS for the OlActionShowOn enumeration

 olDontShow                                => 0
 olMenu                                    => 1
 olMenuAndToolbar                          => 2

=cut

#===============================================================================
  *olDontShow                                = sub { return 0; };
  *olMenu                                    = sub { return 1; };
  *olMenuAndToolbar                          = sub { return 2; };

my @_literal_list_OlActionShowOn = (
  'olDontShow'                                => 0,
  'olMenu'                                    => 1,
  'olMenuAndToolbar'                          => 2,
);

#===============================================================================
# Rinchi::Outlook::OlActionShowOn::Literals

=head1 METHODS for the OlActionShowOn enumeration

=head2 @Literals = Rinchi::Outlook::OlActionShowOn::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlActionShowOn::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlActionShowOn;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e194be-3c43-11dd-a870-001c25551abc

package Rinchi::Outlook::OlAttachmentType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlAttachmentType enumeration

Rinchi::Outlook::OlAttachmentType - Module representing the OlAttachmentType enumeration. 

=head1 CONSTANTS for the OlAttachmentType enumeration

 olByValue                                 => 1
 olByReference                             => 4
 olEmbeddeditem                            => 5
 olOLE                                     => 6

=cut

#===============================================================================
  *olByValue                                 = sub { return 1; };
  *olByReference                             = sub { return 4; };
  *olEmbeddeditem                            = sub { return 5; };
  *olOLE                                     = sub { return 6; };

my @_literal_list_OlAttachmentType = (
  'olByValue'                                 => 1,
  'olByReference'                             => 4,
  'olEmbeddeditem'                            => 5,
  'olOLE'                                     => 6,
);

#===============================================================================
# Rinchi::Outlook::OlAttachmentType::Literals

=head1 METHODS for the OlAttachmentType enumeration

=head2 @Literals = Rinchi::Outlook::OlAttachmentType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlAttachmentType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlAttachmentType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e1a5a8-3c43-11dd-9b8c-001c25551abc

package Rinchi::Outlook::OlBodyFormat;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlBodyFormat enumeration

Rinchi::Outlook::OlBodyFormat - Module representing the OlBodyFormat enumeration. 

=head1 CONSTANTS for the OlBodyFormat enumeration

 olFormatUnspecified                       => 0
 olFormatPlain                             => 1
 olFormatHTML                              => 2
 olFormatRichText                          => 3

=cut

#===============================================================================
  *olFormatUnspecified                       = sub { return 0; };
  *olFormatPlain                             = sub { return 1; };
  *olFormatHTML                              = sub { return 2; };
  *olFormatRichText                          = sub { return 3; };

my @_literal_list_OlBodyFormat = (
  'olFormatUnspecified'                       => 0,
  'olFormatPlain'                             => 1,
  'olFormatHTML'                              => 2,
  'olFormatRichText'                          => 3,
);

#===============================================================================
# Rinchi::Outlook::OlBodyFormat::Literals

=head1 METHODS for the OlBodyFormat enumeration

=head2 @Literals = Rinchi::Outlook::OlBodyFormat::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlBodyFormat::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlBodyFormat;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e1b516-3c43-11dd-b917-001c25551abc

package Rinchi::Outlook::OlBusyStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlBusyStatus enumeration

Rinchi::Outlook::OlBusyStatus - Module representing the OlBusyStatus enumeration. 

=head1 CONSTANTS for the OlBusyStatus enumeration

 olFree                                    => 0
 olTentative                               => 1
 olBusy                                    => 2
 olOutOfOffice                             => 3

=cut

#===============================================================================
  *olFree                                    = sub { return 0; };
  *olTentative                               = sub { return 1; };
  *olBusy                                    = sub { return 2; };
  *olOutOfOffice                             = sub { return 3; };

my @_literal_list_OlBusyStatus = (
  'olFree'                                    => 0,
  'olTentative'                               => 1,
  'olBusy'                                    => 2,
  'olOutOfOffice'                             => 3,
);

#===============================================================================
# Rinchi::Outlook::OlBusyStatus::Literals

=head1 METHODS for the OlBusyStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlBusyStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlBusyStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlBusyStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e1c42a-3c43-11dd-be2c-001c25551abc

package Rinchi::Outlook::OlDaysOfWeek;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlDaysOfWeek enumeration

Rinchi::Outlook::OlDaysOfWeek - Module representing the OlDaysOfWeek enumeration. 

=head1 CONSTANTS for the OlDaysOfWeek enumeration

 olSunday                                  => 1
 olThursday                                => 16
 olMonday                                  => 2
 olFriday                                  => 32
 olTuesday                                 => 4
 olSaturday                                => 64
 olWednesday                               => 8

=cut

#===============================================================================
  *olSunday                                  = sub { return 1; };
  *olThursday                                = sub { return 16; };
  *olMonday                                  = sub { return 2; };
  *olFriday                                  = sub { return 32; };
  *olTuesday                                 = sub { return 4; };
  *olSaturday                                = sub { return 64; };
  *olWednesday                               = sub { return 8; };

my @_literal_list_OlDaysOfWeek = (
  'olSunday'                                  => 1,
  'olThursday'                                => 16,
  'olMonday'                                  => 2,
  'olFriday'                                  => 32,
  'olTuesday'                                 => 4,
  'olSaturday'                                => 64,
  'olWednesday'                               => 8,
);

#===============================================================================
# Rinchi::Outlook::OlDaysOfWeek::Literals

=head1 METHODS for the OlDaysOfWeek enumeration

=head2 @Literals = Rinchi::Outlook::OlDaysOfWeek::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlDaysOfWeek::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlDaysOfWeek;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e1d3c0-3c43-11dd-8606-001c25551abc

package Rinchi::Outlook::OlDefaultFolders;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlDefaultFolders enumeration

Rinchi::Outlook::OlDefaultFolders - Module representing the OlDefaultFolders enumeration. 

=head1 CONSTANTS for the OlDefaultFolders enumeration

 olFolderDeletedItems                      => 3
 olFolderOutbox                            => 4
 olFolderSentMail                          => 5
 olFolderInbox                             => 6
 olFolderCalendar                          => 9
 olFolderContacts                          => 10
 olFolderJournal                           => 11
 olFolderNotes                             => 12
 olFolderTasks                             => 13
 olFolderDrafts                            => 16
 olPublicFoldersAllPublicFolders           => 18
 olFolderConflicts                         => 19
 olFolderSyncIssues                        => 20
 olFolderLocalFailures                     => 21
 olFolderServerFailures                    => 22
 olFolderJunk                              => 23

=cut

#===============================================================================
  *olFolderContacts                          = sub { return 10; };
  *olFolderJournal                           = sub { return 11; };
  *olFolderNotes                             = sub { return 12; };
  *olFolderTasks                             = sub { return 13; };
  *olFolderDrafts                            = sub { return 16; };
  *olPublicFoldersAllPublicFolders           = sub { return 18; };
  *olFolderConflicts                         = sub { return 19; };
  *olFolderSyncIssues                        = sub { return 20; };
  *olFolderLocalFailures                     = sub { return 21; };
  *olFolderServerFailures                    = sub { return 22; };
  *olFolderJunk                              = sub { return 23; };
  *olFolderDeletedItems                      = sub { return 3; };
  *olFolderOutbox                            = sub { return 4; };
  *olFolderSentMail                          = sub { return 5; };
  *olFolderInbox                             = sub { return 6; };
  *olFolderCalendar                          = sub { return 9; };

my @_literal_list_OlDefaultFolders = (
  'olFolderDeletedItems'                      => 3,
  'olFolderOutbox'                            => 4,
  'olFolderSentMail'                          => 5,
  'olFolderInbox'                             => 6,
  'olFolderCalendar'                          => 9,
  'olFolderContacts'                          => 10,
  'olFolderJournal'                           => 11,
  'olFolderNotes'                             => 12,
  'olFolderTasks'                             => 13,
  'olFolderDrafts'                            => 16,
  'olPublicFoldersAllPublicFolders'           => 18,
  'olFolderConflicts'                         => 19,
  'olFolderSyncIssues'                        => 20,
  'olFolderLocalFailures'                     => 21,
  'olFolderServerFailures'                    => 22,
  'olFolderJunk'                              => 23,
);

#===============================================================================
# Rinchi::Outlook::OlDefaultFolders::Literals

=head1 METHODS for the OlDefaultFolders enumeration

=head2 @Literals = Rinchi::Outlook::OlDefaultFolders::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlDefaultFolders::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlDefaultFolders;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e1e360-3c43-11dd-a729-001c25551abc

package Rinchi::Outlook::OlDisplayType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlDisplayType enumeration

Rinchi::Outlook::OlDisplayType - Module representing the OlDisplayType enumeration. 

=head1 CONSTANTS for the OlDisplayType enumeration

 olUser                                    => 0
 olDistList                                => 1
 olForum                                   => 2
 olAgent                                   => 3
 olOrganization                            => 4
 olPrivateDistList                         => 5
 olRemoteUser                              => 6

=cut

#===============================================================================
  *olUser                                    = sub { return 0; };
  *olDistList                                = sub { return 1; };
  *olForum                                   = sub { return 2; };
  *olAgent                                   = sub { return 3; };
  *olOrganization                            = sub { return 4; };
  *olPrivateDistList                         = sub { return 5; };
  *olRemoteUser                              = sub { return 6; };

my @_literal_list_OlDisplayType = (
  'olUser'                                    => 0,
  'olDistList'                                => 1,
  'olForum'                                   => 2,
  'olAgent'                                   => 3,
  'olOrganization'                            => 4,
  'olPrivateDistList'                         => 5,
  'olRemoteUser'                              => 6,
);

#===============================================================================
# Rinchi::Outlook::OlDisplayType::Literals

=head1 METHODS for the OlDisplayType enumeration

=head2 @Literals = Rinchi::Outlook::OlDisplayType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlDisplayType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlDisplayType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e1f328-3c43-11dd-9f9d-001c25551abc

package Rinchi::Outlook::OlDownloadState;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlDownloadState enumeration

Rinchi::Outlook::OlDownloadState - Module representing the OlDownloadState enumeration. 

=head1 CONSTANTS for the OlDownloadState enumeration

 olHeaderOnly                              => 0
 olFullItem                                => 1

=cut

#===============================================================================
  *olHeaderOnly                              = sub { return 0; };
  *olFullItem                                = sub { return 1; };

my @_literal_list_OlDownloadState = (
  'olHeaderOnly'                              => 0,
  'olFullItem'                                => 1,
);

#===============================================================================
# Rinchi::Outlook::OlDownloadState::Literals

=head1 METHODS for the OlDownloadState enumeration

=head2 @Literals = Rinchi::Outlook::OlDownloadState::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlDownloadState::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlDownloadState;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2021e-3c43-11dd-af36-001c25551abc

package Rinchi::Outlook::OlEditorType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlEditorType enumeration

Rinchi::Outlook::OlEditorType - Module representing the OlEditorType enumeration. 

=head1 CONSTANTS for the OlEditorType enumeration

 olEditorText                              => 1
 olEditorHTML                              => 2
 olEditorRTF                               => 3
 olEditorWord                              => 4

=cut

#===============================================================================
  *olEditorText                              = sub { return 1; };
  *olEditorHTML                              = sub { return 2; };
  *olEditorRTF                               = sub { return 3; };
  *olEditorWord                              = sub { return 4; };

my @_literal_list_OlEditorType = (
  'olEditorText'                              => 1,
  'olEditorHTML'                              => 2,
  'olEditorRTF'                               => 3,
  'olEditorWord'                              => 4,
);

#===============================================================================
# Rinchi::Outlook::OlEditorType::Literals

=head1 METHODS for the OlEditorType enumeration

=head2 @Literals = Rinchi::Outlook::OlEditorType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlEditorType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlEditorType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e21128-3c43-11dd-a647-001c25551abc

package Rinchi::Outlook::OlExchangeConnectionMode;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlExchangeConnectionMode enumeration

Rinchi::Outlook::OlExchangeConnectionMode - Module representing the OlExchangeConnectionMode enumeration. 

=head1 CONSTANTS for the OlExchangeConnectionMode enumeration

 olNoExchange                              => 0
 olOffline                                 => 100
 olCachedOffline                           => 200
 olDisconnected                            => 300
 olCachedDisconnected                      => 400
 olCachedConnectedHeaders                  => 500
 olCachedConnectedDrizzle                  => 600
 olCachedConnectedFull                     => 700
 olOnline                                  => 800

=cut

#===============================================================================
  *olNoExchange                              = sub { return 0; };
  *olOffline                                 = sub { return 100; };
  *olCachedOffline                           = sub { return 200; };
  *olDisconnected                            = sub { return 300; };
  *olCachedDisconnected                      = sub { return 400; };
  *olCachedConnectedHeaders                  = sub { return 500; };
  *olCachedConnectedDrizzle                  = sub { return 600; };
  *olCachedConnectedFull                     = sub { return 700; };
  *olOnline                                  = sub { return 800; };

my @_literal_list_OlExchangeConnectionMode = (
  'olNoExchange'                              => 0,
  'olOffline'                                 => 100,
  'olCachedOffline'                           => 200,
  'olDisconnected'                            => 300,
  'olCachedDisconnected'                      => 400,
  'olCachedConnectedHeaders'                  => 500,
  'olCachedConnectedDrizzle'                  => 600,
  'olCachedConnectedFull'                     => 700,
  'olOnline'                                  => 800,
);

#===============================================================================
# Rinchi::Outlook::OlExchangeConnectionMode::Literals

=head1 METHODS for the OlExchangeConnectionMode enumeration

=head2 @Literals = Rinchi::Outlook::OlExchangeConnectionMode::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlExchangeConnectionMode::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlExchangeConnectionMode;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e22140-3c43-11dd-a180-001c25551abc

package Rinchi::Outlook::OlFlagIcon;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlFlagIcon enumeration

Rinchi::Outlook::OlFlagIcon - Module representing the OlFlagIcon enumeration. 

=head1 CONSTANTS for the OlFlagIcon enumeration

 olNoFlagIcon                              => 0
 olPurpleFlagIcon                          => 1
 olOrangeFlagIcon                          => 2
 olGreenFlagIcon                           => 3
 olYellowFlagIcon                          => 4
 olBlueFlagIcon                            => 5
 olRedFlagIcon                             => 6

=cut

#===============================================================================
  *olNoFlagIcon                              = sub { return 0; };
  *olPurpleFlagIcon                          = sub { return 1; };
  *olOrangeFlagIcon                          = sub { return 2; };
  *olGreenFlagIcon                           = sub { return 3; };
  *olYellowFlagIcon                          = sub { return 4; };
  *olBlueFlagIcon                            = sub { return 5; };
  *olRedFlagIcon                             = sub { return 6; };

my @_literal_list_OlFlagIcon = (
  'olNoFlagIcon'                              => 0,
  'olPurpleFlagIcon'                          => 1,
  'olOrangeFlagIcon'                          => 2,
  'olGreenFlagIcon'                           => 3,
  'olYellowFlagIcon'                          => 4,
  'olBlueFlagIcon'                            => 5,
  'olRedFlagIcon'                             => 6,
);

#===============================================================================
# Rinchi::Outlook::OlFlagIcon::Literals

=head1 METHODS for the OlFlagIcon enumeration

=head2 @Literals = Rinchi::Outlook::OlFlagIcon::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlFlagIcon::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlFlagIcon;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2305e-3c43-11dd-9de2-001c25551abc

package Rinchi::Outlook::OlFlagStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlFlagStatus enumeration

Rinchi::Outlook::OlFlagStatus - Module representing the OlFlagStatus enumeration. 

=head1 CONSTANTS for the OlFlagStatus enumeration

 olNoFlag                                  => 0
 olFlagComplete                            => 1
 olFlagMarked                              => 2

=cut

#===============================================================================
  *olNoFlag                                  = sub { return 0; };
  *olFlagComplete                            = sub { return 1; };
  *olFlagMarked                              = sub { return 2; };

my @_literal_list_OlFlagStatus = (
  'olNoFlag'                                  => 0,
  'olFlagComplete'                            => 1,
  'olFlagMarked'                              => 2,
);

#===============================================================================
# Rinchi::Outlook::OlFlagStatus::Literals

=head1 METHODS for the OlFlagStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlFlagStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlFlagStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlFlagStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e240b2-3c43-11dd-84ac-001c25551abc

package Rinchi::Outlook::OlFolderDisplayMode;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlFolderDisplayMode enumeration

Rinchi::Outlook::OlFolderDisplayMode - Module representing the OlFolderDisplayMode enumeration. 

=head1 CONSTANTS for the OlFolderDisplayMode enumeration

 olFolderDisplayNormal                     => 0
 olFolderDisplayFolderOnly                 => 1
 olFolderDisplayNoNavigation               => 2

=cut

#===============================================================================
  *olFolderDisplayNormal                     = sub { return 0; };
  *olFolderDisplayFolderOnly                 = sub { return 1; };
  *olFolderDisplayNoNavigation               = sub { return 2; };

my @_literal_list_OlFolderDisplayMode = (
  'olFolderDisplayNormal'                     => 0,
  'olFolderDisplayFolderOnly'                 => 1,
  'olFolderDisplayNoNavigation'               => 2,
);

#===============================================================================
# Rinchi::Outlook::OlFolderDisplayMode::Literals

=head1 METHODS for the OlFolderDisplayMode enumeration

=head2 @Literals = Rinchi::Outlook::OlFolderDisplayMode::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlFolderDisplayMode::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlFolderDisplayMode;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2503e-3c43-11dd-aae7-001c25551abc

package Rinchi::Outlook::OlFormRegistry;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlFormRegistry enumeration

Rinchi::Outlook::OlFormRegistry - Module representing the OlFormRegistry enumeration. 

=head1 CONSTANTS for the OlFormRegistry enumeration

 olDefaultRegistry                         => 0
 olPersonalRegistry                        => 2
 olFolderRegistry                          => 3
 olOrganizationRegistry                    => 4

=cut

#===============================================================================
  *olDefaultRegistry                         = sub { return 0; };
  *olPersonalRegistry                        = sub { return 2; };
  *olFolderRegistry                          = sub { return 3; };
  *olOrganizationRegistry                    = sub { return 4; };

my @_literal_list_OlFormRegistry = (
  'olDefaultRegistry'                         => 0,
  'olPersonalRegistry'                        => 2,
  'olFolderRegistry'                          => 3,
  'olOrganizationRegistry'                    => 4,
);

#===============================================================================
# Rinchi::Outlook::OlFormRegistry::Literals

=head1 METHODS for the OlFormRegistry enumeration

=head2 @Literals = Rinchi::Outlook::OlFormRegistry::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlFormRegistry::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlFormRegistry;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e26056-3c43-11dd-bd0a-001c25551abc

package Rinchi::Outlook::OlGender;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlGender enumeration

Rinchi::Outlook::OlGender - Module representing the OlGender enumeration. 

=head1 CONSTANTS for the OlGender enumeration

 olUnspecified                             => 0
 olFemale                                  => 1
 olMale                                    => 2

=cut

#===============================================================================
  *olUnspecified                             = sub { return 0; };
  *olFemale                                  = sub { return 1; };
  *olMale                                    = sub { return 2; };

my @_literal_list_OlGender = (
  'olUnspecified'                             => 0,
  'olFemale'                                  => 1,
  'olMale'                                    => 2,
);

#===============================================================================
# Rinchi::Outlook::OlGender::Literals

=head1 METHODS for the OlGender enumeration

=head2 @Literals = Rinchi::Outlook::OlGender::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlGender::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlGender;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e27046-3c43-11dd-aabe-001c25551abc

package Rinchi::Outlook::OlImportance;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlImportance enumeration

Rinchi::Outlook::OlImportance - Module representing the OlImportance enumeration. 

=head1 CONSTANTS for the OlImportance enumeration

 olImportanceLow                           => 0
 olImportanceNormal                        => 1
 olImportanceHigh                          => 2

=cut

#===============================================================================
  *olImportanceLow                           = sub { return 0; };
  *olImportanceNormal                        = sub { return 1; };
  *olImportanceHigh                          = sub { return 2; };

my @_literal_list_OlImportance = (
  'olImportanceLow'                           => 0,
  'olImportanceNormal'                        => 1,
  'olImportanceHigh'                          => 2,
);

#===============================================================================
# Rinchi::Outlook::OlImportance::Literals

=head1 METHODS for the OlImportance enumeration

=head2 @Literals = Rinchi::Outlook::OlImportance::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlImportance::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlImportance;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e27ffa-3c43-11dd-9df2-001c25551abc

package Rinchi::Outlook::OlInspectorClose;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlInspectorClose enumeration

Rinchi::Outlook::OlInspectorClose - Module representing the OlInspectorClose enumeration. 

=head1 CONSTANTS for the OlInspectorClose enumeration

 olSave                                    => 0
 olDiscard                                 => 1
 olPromptForSave                           => 2

=cut

#===============================================================================
  *olSave                                    = sub { return 0; };
  *olDiscard                                 = sub { return 1; };
  *olPromptForSave                           = sub { return 2; };

my @_literal_list_OlInspectorClose = (
  'olSave'                                    => 0,
  'olDiscard'                                 => 1,
  'olPromptForSave'                           => 2,
);

#===============================================================================
# Rinchi::Outlook::OlInspectorClose::Literals

=head1 METHODS for the OlInspectorClose enumeration

=head2 @Literals = Rinchi::Outlook::OlInspectorClose::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlInspectorClose::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlInspectorClose;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e29008-3c43-11dd-863f-001c25551abc

package Rinchi::Outlook::OlItemType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlItemType enumeration

Rinchi::Outlook::OlItemType - Module representing the OlItemType enumeration. 

=head1 CONSTANTS for the OlItemType enumeration

 olMailItem                                => 0
 olAppointmentItem                         => 1
 olContactItem                             => 2
 olTaskItem                                => 3
 olJournalItem                             => 4
 olNoteItem                                => 5
 olPostItem                                => 6
 olDistributionListItem                    => 7

=cut

#===============================================================================
  *olMailItem                                = sub { return 0; };
  *olAppointmentItem                         = sub { return 1; };
  *olContactItem                             = sub { return 2; };
  *olTaskItem                                = sub { return 3; };
  *olJournalItem                             = sub { return 4; };
  *olNoteItem                                = sub { return 5; };
  *olPostItem                                = sub { return 6; };
  *olDistributionListItem                    = sub { return 7; };

my @_literal_list_OlItemType = (
  'olMailItem'                                => 0,
  'olAppointmentItem'                         => 1,
  'olContactItem'                             => 2,
  'olTaskItem'                                => 3,
  'olJournalItem'                             => 4,
  'olNoteItem'                                => 5,
  'olPostItem'                                => 6,
  'olDistributionListItem'                    => 7,
);

#===============================================================================
# Rinchi::Outlook::OlItemType::Literals

=head1 METHODS for the OlItemType enumeration

=head2 @Literals = Rinchi::Outlook::OlItemType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlItemType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlItemType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2a69c-3c43-11dd-97ea-001c25551abc

package Rinchi::Outlook::OlJournalRecipientType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlJournalRecipientType enumeration

Rinchi::Outlook::OlJournalRecipientType - Module representing the OlJournalRecipientType enumeration. 

=head1 CONSTANTS for the OlJournalRecipientType enumeration

 olAssociatedContact                       => 1

=cut

#===============================================================================
  *olAssociatedContact                       = sub { return 1; };

my @_literal_list_OlJournalRecipientType = (
  'olAssociatedContact'                       => 1,
);

#===============================================================================
# Rinchi::Outlook::OlJournalRecipientType::Literals

=head1 METHODS for the OlJournalRecipientType enumeration

=head2 @Literals = Rinchi::Outlook::OlJournalRecipientType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlJournalRecipientType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlJournalRecipientType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2bb46-3c43-11dd-873f-001c25551abc

package Rinchi::Outlook::OlMailRecipientType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlMailRecipientType enumeration

Rinchi::Outlook::OlMailRecipientType - Module representing the OlMailRecipientType enumeration. 

=head1 CONSTANTS for the OlMailRecipientType enumeration

 olOriginator                              => 0
 olTo                                      => 1
 olCC                                      => 2
 olBCC                                     => 3

=cut

#===============================================================================
  *olOriginator                              = sub { return 0; };
  *olTo                                      = sub { return 1; };
  *olCC                                      = sub { return 2; };
  *olBCC                                     = sub { return 3; };

my @_literal_list_OlMailRecipientType = (
  'olOriginator'                              => 0,
  'olTo'                                      => 1,
  'olCC'                                      => 2,
  'olBCC'                                     => 3,
);

#===============================================================================
# Rinchi::Outlook::OlMailRecipientType::Literals

=head1 METHODS for the OlMailRecipientType enumeration

=head2 @Literals = Rinchi::Outlook::OlMailRecipientType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlMailRecipientType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlMailRecipientType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2ce7e-3c43-11dd-b833-001c25551abc

package Rinchi::Outlook::OlMailingAddress;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlMailingAddress enumeration

Rinchi::Outlook::OlMailingAddress - Module representing the OlMailingAddress enumeration. 

=head1 CONSTANTS for the OlMailingAddress enumeration

 olNone                                    => 0
 olHome                                    => 1
 olBusiness                                => 2
 olOther                                   => 3

=cut

#===============================================================================
  *olNone                                    = sub { return 0; };
  *olHome                                    = sub { return 1; };
  *olBusiness                                = sub { return 2; };
  *olOther                                   = sub { return 3; };

my @_literal_list_OlMailingAddress = (
  'olNone'                                    => 0,
  'olHome'                                    => 1,
  'olBusiness'                                => 2,
  'olOther'                                   => 3,
);

#===============================================================================
# Rinchi::Outlook::OlMailingAddress::Literals

=head1 METHODS for the OlMailingAddress enumeration

=head2 @Literals = Rinchi::Outlook::OlMailingAddress::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlMailingAddress::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlMailingAddress;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2e170-3c43-11dd-b75e-001c25551abc

package Rinchi::Outlook::OlMeetingRecipientType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlMeetingRecipientType enumeration

Rinchi::Outlook::OlMeetingRecipientType - Module representing the OlMeetingRecipientType enumeration. 

=head1 CONSTANTS for the OlMeetingRecipientType enumeration

 olOrganizer                               => 0
 olRequired                                => 1
 olOptional                                => 2
 olResource                                => 3

=cut

#===============================================================================
  *olOrganizer                               = sub { return 0; };
  *olRequired                                = sub { return 1; };
  *olOptional                                = sub { return 2; };
  *olResource                                = sub { return 3; };

my @_literal_list_OlMeetingRecipientType = (
  'olOrganizer'                               => 0,
  'olRequired'                                => 1,
  'olOptional'                                => 2,
  'olResource'                                => 3,
);

#===============================================================================
# Rinchi::Outlook::OlMeetingRecipientType::Literals

=head1 METHODS for the OlMeetingRecipientType enumeration

=head2 @Literals = Rinchi::Outlook::OlMeetingRecipientType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlMeetingRecipientType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlMeetingRecipientType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e2f49e-3c43-11dd-bbbb-001c25551abc

package Rinchi::Outlook::OlMeetingResponse;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlMeetingResponse enumeration

Rinchi::Outlook::OlMeetingResponse - Module representing the OlMeetingResponse enumeration. 

=head1 CONSTANTS for the OlMeetingResponse enumeration

 olMeetingTentative                        => 2
 olMeetingAccepted                         => 3
 olMeetingDeclined                         => 4

=cut

#===============================================================================
  *olMeetingTentative                        = sub { return 2; };
  *olMeetingAccepted                         = sub { return 3; };
  *olMeetingDeclined                         = sub { return 4; };

my @_literal_list_OlMeetingResponse = (
  'olMeetingTentative'                        => 2,
  'olMeetingAccepted'                         => 3,
  'olMeetingDeclined'                         => 4,
);

#===============================================================================
# Rinchi::Outlook::OlMeetingResponse::Literals

=head1 METHODS for the OlMeetingResponse enumeration

=head2 @Literals = Rinchi::Outlook::OlMeetingResponse::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlMeetingResponse::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlMeetingResponse;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e307c2-3c43-11dd-9ed8-001c25551abc

package Rinchi::Outlook::OlMeetingStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlMeetingStatus enumeration

Rinchi::Outlook::OlMeetingStatus - Module representing the OlMeetingStatus enumeration. 

=head1 CONSTANTS for the OlMeetingStatus enumeration

 olNonMeeting                              => 0
 olMeeting                                 => 1
 olMeetingReceived                         => 3
 olMeetingCanceled                         => 5

=cut

#===============================================================================
  *olNonMeeting                              = sub { return 0; };
  *olMeeting                                 = sub { return 1; };
  *olMeetingReceived                         = sub { return 3; };
  *olMeetingCanceled                         = sub { return 5; };

my @_literal_list_OlMeetingStatus = (
  'olNonMeeting'                              => 0,
  'olMeeting'                                 => 1,
  'olMeetingReceived'                         => 3,
  'olMeetingCanceled'                         => 5,
);

#===============================================================================
# Rinchi::Outlook::OlMeetingStatus::Literals

=head1 METHODS for the OlMeetingStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlMeetingStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlMeetingStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlMeetingStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e31ba4-3c43-11dd-aa4d-001c25551abc

package Rinchi::Outlook::OlNetMeetingType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlNetMeetingType enumeration

Rinchi::Outlook::OlNetMeetingType - Module representing the OlNetMeetingType enumeration. 

=head1 CONSTANTS for the OlNetMeetingType enumeration

 olNetMeeting                              => 0
 olNetShow                                 => 1
 olExchangeConferencing                    => 2

=cut

#===============================================================================
  *olNetMeeting                              = sub { return 0; };
  *olNetShow                                 = sub { return 1; };
  *olExchangeConferencing                    = sub { return 2; };

my @_literal_list_OlNetMeetingType = (
  'olNetMeeting'                              => 0,
  'olNetShow'                                 => 1,
  'olExchangeConferencing'                    => 2,
);

#===============================================================================
# Rinchi::Outlook::OlNetMeetingType::Literals

=head1 METHODS for the OlNetMeetingType enumeration

=head2 @Literals = Rinchi::Outlook::OlNetMeetingType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlNetMeetingType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlNetMeetingType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e33058-3c43-11dd-930c-001c25551abc

package Rinchi::Outlook::OlNoteColor;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlNoteColor enumeration

Rinchi::Outlook::OlNoteColor - Module representing the OlNoteColor enumeration. 

=head1 CONSTANTS for the OlNoteColor enumeration

 olBlue                                    => 0
 olGreen                                   => 1
 olPink                                    => 2
 olYellow                                  => 3
 olWhite                                   => 4

=cut

#===============================================================================
  *olBlue                                    = sub { return 0; };
  *olGreen                                   = sub { return 1; };
  *olPink                                    = sub { return 2; };
  *olYellow                                  = sub { return 3; };
  *olWhite                                   = sub { return 4; };

my @_literal_list_OlNoteColor = (
  'olBlue'                                    => 0,
  'olGreen'                                   => 1,
  'olPink'                                    => 2,
  'olYellow'                                  => 3,
  'olWhite'                                   => 4,
);

#===============================================================================
# Rinchi::Outlook::OlNoteColor::Literals

=head1 METHODS for the OlNoteColor enumeration

=head2 @Literals = Rinchi::Outlook::OlNoteColor::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlNoteColor::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlNoteColor;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e343cc-3c43-11dd-a415-001c25551abc

package Rinchi::Outlook::OlObjectClass;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlObjectClass enumeration

Rinchi::Outlook::OlObjectClass - Module representing the OlObjectClass enumeration. 

=head1 CONSTANTS for the OlObjectClass enumeration

 olApplication                             => 0
 olNamespace                               => 1
 olFolder                                  => 2
 olRecipient                               => 4
 olAttachment                              => 5
 olAddressList                             => 7
 olAddressEntry                            => 8
 olFolders                                 => 15
 olItems                                   => 16
 olRecipients                              => 17
 olAttachments                             => 18
 olAddressLists                            => 20
 olAddressEntries                          => 21
 olAppointment                             => 26
 olRecurrencePattern                       => 28
 olExceptions                              => 29
 olException                               => 30
 olAction                                  => 32
 olActions                                 => 33
 olExplorer                                => 34
 olInspector                               => 35
 olPages                                   => 36
 olFormDescription                         => 37
 olUserProperties                          => 38
 olUserProperty                            => 39
 olContact                                 => 40
 olDocument                                => 41
 olJournal                                 => 42
 olMail                                    => 43
 olNote                                    => 44
 olPost                                    => 45
 olReport                                  => 46
 olRemote                                  => 47
 olTask                                    => 48
 olTaskRequest                             => 49
 olTaskRequestUpdate                       => 50
 olTaskRequestAccept                       => 51
 olTaskRequestDecline                      => 52
 olMeetingRequest                          => 53
 olMeetingCancellation                     => 54
 olMeetingResponseNegative                 => 55
 olMeetingResponsePositive                 => 56
 olMeetingResponseTentative                => 57
 olExplorers                               => 60
 olInspectors                              => 61
 olPanes                                   => 62
 olOutlookBarPane                          => 63
 olOutlookBarStorage                       => 64
 olOutlookBarGroups                        => 65
 olOutlookBarGroup                         => 66
 olOutlookBarShortcuts                     => 67
 olOutlookBarShortcut                      => 68
 olDistributionList                        => 69
 olPropertyPageSite                        => 70
 olPropertyPages                           => 71
 olSyncObject                              => 72
 olSyncObjects                             => 73
 olSelection                               => 74
 olLink                                    => 75
 olLinks                                   => 76
 olSearch                                  => 77
 olResults                                 => 78
 olViews                                   => 79
 olView                                    => 80
 olItemProperties                          => 98
 olItemProperty                            => 99
 olReminders                               => 100
 olReminder                                => 101
 olConflict                                => 102
 olConflicts                               => 103

=cut

#===============================================================================
  *olApplication                             = sub { return 0; };
  *olNamespace                               = sub { return 1; };
  *olReminders                               = sub { return 100; };
  *olReminder                                = sub { return 101; };
  *olConflict                                = sub { return 102; };
  *olConflicts                               = sub { return 103; };
  *olFolders                                 = sub { return 15; };
  *olItems                                   = sub { return 16; };
  *olRecipients                              = sub { return 17; };
  *olAttachments                             = sub { return 18; };
  *olFolder                                  = sub { return 2; };
  *olAddressLists                            = sub { return 20; };
  *olAddressEntries                          = sub { return 21; };
  *olAppointment                             = sub { return 26; };
  *olRecurrencePattern                       = sub { return 28; };
  *olExceptions                              = sub { return 29; };
  *olException                               = sub { return 30; };
  *olAction                                  = sub { return 32; };
  *olActions                                 = sub { return 33; };
  *olExplorer                                = sub { return 34; };
  *olInspector                               = sub { return 35; };
  *olPages                                   = sub { return 36; };
  *olFormDescription                         = sub { return 37; };
  *olUserProperties                          = sub { return 38; };
  *olUserProperty                            = sub { return 39; };
  *olRecipient                               = sub { return 4; };
  *olContact                                 = sub { return 40; };
  *olDocument                                = sub { return 41; };
  *olJournal                                 = sub { return 42; };
  *olMail                                    = sub { return 43; };
  *olNote                                    = sub { return 44; };
  *olPost                                    = sub { return 45; };
  *olReport                                  = sub { return 46; };
  *olRemote                                  = sub { return 47; };
  *olTask                                    = sub { return 48; };
  *olTaskRequest                             = sub { return 49; };
  *olAttachment                              = sub { return 5; };
  *olTaskRequestUpdate                       = sub { return 50; };
  *olTaskRequestAccept                       = sub { return 51; };
  *olTaskRequestDecline                      = sub { return 52; };
  *olMeetingRequest                          = sub { return 53; };
  *olMeetingCancellation                     = sub { return 54; };
  *olMeetingResponseNegative                 = sub { return 55; };
  *olMeetingResponsePositive                 = sub { return 56; };
  *olMeetingResponseTentative                = sub { return 57; };
  *olExplorers                               = sub { return 60; };
  *olInspectors                              = sub { return 61; };
  *olPanes                                   = sub { return 62; };
  *olOutlookBarPane                          = sub { return 63; };
  *olOutlookBarStorage                       = sub { return 64; };
  *olOutlookBarGroups                        = sub { return 65; };
  *olOutlookBarGroup                         = sub { return 66; };
  *olOutlookBarShortcuts                     = sub { return 67; };
  *olOutlookBarShortcut                      = sub { return 68; };
  *olDistributionList                        = sub { return 69; };
  *olAddressList                             = sub { return 7; };
  *olPropertyPageSite                        = sub { return 70; };
  *olPropertyPages                           = sub { return 71; };
  *olSyncObject                              = sub { return 72; };
  *olSyncObjects                             = sub { return 73; };
  *olSelection                               = sub { return 74; };
  *olLink                                    = sub { return 75; };
  *olLinks                                   = sub { return 76; };
  *olSearch                                  = sub { return 77; };
  *olResults                                 = sub { return 78; };
  *olViews                                   = sub { return 79; };
  *olAddressEntry                            = sub { return 8; };
  *olView                                    = sub { return 80; };
  *olItemProperties                          = sub { return 98; };
  *olItemProperty                            = sub { return 99; };

my @_literal_list_OlObjectClass = (
  'olApplication'                             => 0,
  'olNamespace'                               => 1,
  'olFolder'                                  => 2,
  'olRecipient'                               => 4,
  'olAttachment'                              => 5,
  'olAddressList'                             => 7,
  'olAddressEntry'                            => 8,
  'olFolders'                                 => 15,
  'olItems'                                   => 16,
  'olRecipients'                              => 17,
  'olAttachments'                             => 18,
  'olAddressLists'                            => 20,
  'olAddressEntries'                          => 21,
  'olAppointment'                             => 26,
  'olRecurrencePattern'                       => 28,
  'olExceptions'                              => 29,
  'olException'                               => 30,
  'olAction'                                  => 32,
  'olActions'                                 => 33,
  'olExplorer'                                => 34,
  'olInspector'                               => 35,
  'olPages'                                   => 36,
  'olFormDescription'                         => 37,
  'olUserProperties'                          => 38,
  'olUserProperty'                            => 39,
  'olContact'                                 => 40,
  'olDocument'                                => 41,
  'olJournal'                                 => 42,
  'olMail'                                    => 43,
  'olNote'                                    => 44,
  'olPost'                                    => 45,
  'olReport'                                  => 46,
  'olRemote'                                  => 47,
  'olTask'                                    => 48,
  'olTaskRequest'                             => 49,
  'olTaskRequestUpdate'                       => 50,
  'olTaskRequestAccept'                       => 51,
  'olTaskRequestDecline'                      => 52,
  'olMeetingRequest'                          => 53,
  'olMeetingCancellation'                     => 54,
  'olMeetingResponseNegative'                 => 55,
  'olMeetingResponsePositive'                 => 56,
  'olMeetingResponseTentative'                => 57,
  'olExplorers'                               => 60,
  'olInspectors'                              => 61,
  'olPanes'                                   => 62,
  'olOutlookBarPane'                          => 63,
  'olOutlookBarStorage'                       => 64,
  'olOutlookBarGroups'                        => 65,
  'olOutlookBarGroup'                         => 66,
  'olOutlookBarShortcuts'                     => 67,
  'olOutlookBarShortcut'                      => 68,
  'olDistributionList'                        => 69,
  'olPropertyPageSite'                        => 70,
  'olPropertyPages'                           => 71,
  'olSyncObject'                              => 72,
  'olSyncObjects'                             => 73,
  'olSelection'                               => 74,
  'olLink'                                    => 75,
  'olLinks'                                   => 76,
  'olSearch'                                  => 77,
  'olResults'                                 => 78,
  'olViews'                                   => 79,
  'olView'                                    => 80,
  'olItemProperties'                          => 98,
  'olItemProperty'                            => 99,
  'olReminders'                               => 100,
  'olReminder'                                => 101,
  'olConflict'                                => 102,
  'olConflicts'                               => 103,
);

#===============================================================================
# Rinchi::Outlook::OlObjectClass::Literals

=head1 METHODS for the OlObjectClass enumeration

=head2 @Literals = Rinchi::Outlook::OlObjectClass::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlObjectClass::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlObjectClass;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e35718-3c43-11dd-be44-001c25551abc

package Rinchi::Outlook::OlOfficeDocItemsType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlOfficeDocItemsType enumeration

Rinchi::Outlook::OlOfficeDocItemsType - Module representing the OlOfficeDocItemsType enumeration. 

=head1 CONSTANTS for the OlOfficeDocItemsType enumeration

 olPowerPointShowItem                      => 10
 olExcelWorkSheetItem                      => 8
 olWordDocumentItem                        => 9

=cut

#===============================================================================
  *olPowerPointShowItem                      = sub { return 10; };
  *olExcelWorkSheetItem                      = sub { return 8; };
  *olWordDocumentItem                        = sub { return 9; };

my @_literal_list_OlOfficeDocItemsType = (
  'olPowerPointShowItem'                      => 10,
  'olExcelWorkSheetItem'                      => 8,
  'olWordDocumentItem'                        => 9,
);

#===============================================================================
# Rinchi::Outlook::OlOfficeDocItemsType::Literals

=head1 METHODS for the OlOfficeDocItemsType enumeration

=head2 @Literals = Rinchi::Outlook::OlOfficeDocItemsType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlOfficeDocItemsType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlOfficeDocItemsType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e36960-3c43-11dd-aef7-001c25551abc

package Rinchi::Outlook::OlOutlookBarViewType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlOutlookBarViewType enumeration

Rinchi::Outlook::OlOutlookBarViewType - Module representing the OlOutlookBarViewType enumeration. 

=head1 CONSTANTS for the OlOutlookBarViewType enumeration

 olLargeIcon                               => 0
 olSmallIcon                               => 1

=cut

#===============================================================================
  *olLargeIcon                               = sub { return 0; };
  *olSmallIcon                               = sub { return 1; };

my @_literal_list_OlOutlookBarViewType = (
  'olLargeIcon'                               => 0,
  'olSmallIcon'                               => 1,
);

#===============================================================================
# Rinchi::Outlook::OlOutlookBarViewType::Literals

=head1 METHODS for the OlOutlookBarViewType enumeration

=head2 @Literals = Rinchi::Outlook::OlOutlookBarViewType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlOutlookBarViewType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlOutlookBarViewType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e37c16-3c43-11dd-a4a1-001c25551abc

package Rinchi::Outlook::OlPane;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlPane enumeration

Rinchi::Outlook::OlPane - Module representing the OlPane enumeration. 

=head1 CONSTANTS for the OlPane enumeration

 olOutlookBar                              => 1
 olFolderList                              => 2
 olPreview                                 => 3
 olNavigationPane                          => 4

=cut

#===============================================================================
  *olOutlookBar                              = sub { return 1; };
  *olFolderList                              = sub { return 2; };
  *olPreview                                 = sub { return 3; };
  *olNavigationPane                          = sub { return 4; };

my @_literal_list_OlPane = (
  'olOutlookBar'                              => 1,
  'olFolderList'                              => 2,
  'olPreview'                                 => 3,
  'olNavigationPane'                          => 4,
);

#===============================================================================
# Rinchi::Outlook::OlPane::Literals

=head1 METHODS for the OlPane enumeration

=head2 @Literals = Rinchi::Outlook::OlPane::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlPane::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlPane;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e38efe-3c43-11dd-99f4-001c25551abc

package Rinchi::Outlook::OlPermission;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlPermission enumeration

Rinchi::Outlook::OlPermission - Module representing the OlPermission enumeration. 

=head1 CONSTANTS for the OlPermission enumeration

 olUnrestricted                            => 0
 olDoNotForward                            => 1
 olPermissionTemplate                      => 2

=cut

#===============================================================================
  *olUnrestricted                            = sub { return 0; };
  *olDoNotForward                            = sub { return 1; };
  *olPermissionTemplate                      = sub { return 2; };

my @_literal_list_OlPermission = (
  'olUnrestricted'                            => 0,
  'olDoNotForward'                            => 1,
  'olPermissionTemplate'                      => 2,
);

#===============================================================================
# Rinchi::Outlook::OlPermission::Literals

=head1 METHODS for the OlPermission enumeration

=head2 @Literals = Rinchi::Outlook::OlPermission::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlPermission::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlPermission;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e3a240-3c43-11dd-aae2-001c25551abc

package Rinchi::Outlook::OlPermissionService;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlPermissionService enumeration

Rinchi::Outlook::OlPermissionService - Module representing the OlPermissionService enumeration. 

=head1 CONSTANTS for the OlPermissionService enumeration

 olUnknown                                 => 0
 olWindows                                 => 1
 olPassport                                => 2

=cut

#===============================================================================
  *olUnknown                                 = sub { return 0; };
  *olWindows                                 = sub { return 1; };
  *olPassport                                = sub { return 2; };

my @_literal_list_OlPermissionService = (
  'olUnknown'                                 => 0,
  'olWindows'                                 => 1,
  'olPassport'                                => 2,
);

#===============================================================================
# Rinchi::Outlook::OlPermissionService::Literals

=head1 METHODS for the OlPermissionService enumeration

=head2 @Literals = Rinchi::Outlook::OlPermissionService::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlPermissionService::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlPermissionService;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e3b532-3c43-11dd-8c1f-001c25551abc

package Rinchi::Outlook::OlRecurrenceState;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlRecurrenceState enumeration

Rinchi::Outlook::OlRecurrenceState - Module representing the OlRecurrenceState enumeration. 

=head1 CONSTANTS for the OlRecurrenceState enumeration

 olApptNotRecurring                        => 0
 olApptMaster                              => 1
 olApptOccurrence                          => 2
 olApptException                           => 3

=cut

#===============================================================================
  *olApptNotRecurring                        = sub { return 0; };
  *olApptMaster                              = sub { return 1; };
  *olApptOccurrence                          = sub { return 2; };
  *olApptException                           = sub { return 3; };

my @_literal_list_OlRecurrenceState = (
  'olApptNotRecurring'                        => 0,
  'olApptMaster'                              => 1,
  'olApptOccurrence'                          => 2,
  'olApptException'                           => 3,
);

#===============================================================================
# Rinchi::Outlook::OlRecurrenceState::Literals

=head1 METHODS for the OlRecurrenceState enumeration

=head2 @Literals = Rinchi::Outlook::OlRecurrenceState::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlRecurrenceState::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlRecurrenceState;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e3c89c-3c43-11dd-a97b-001c25551abc

package Rinchi::Outlook::OlRecurrenceType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlRecurrenceType enumeration

Rinchi::Outlook::OlRecurrenceType - Module representing the OlRecurrenceType enumeration. 

=head1 CONSTANTS for the OlRecurrenceType enumeration

 olRecursDaily                             => 0
 olRecursWeekly                            => 1
 olRecursMonthly                           => 2
 olRecursMonthNth                          => 3
 olRecursYearly                            => 5
 olRecursYearNth                           => 6

=cut

#===============================================================================
  *olRecursDaily                             = sub { return 0; };
  *olRecursWeekly                            = sub { return 1; };
  *olRecursMonthly                           = sub { return 2; };
  *olRecursMonthNth                          = sub { return 3; };
  *olRecursYearly                            = sub { return 5; };
  *olRecursYearNth                           = sub { return 6; };

my @_literal_list_OlRecurrenceType = (
  'olRecursDaily'                             => 0,
  'olRecursWeekly'                            => 1,
  'olRecursMonthly'                           => 2,
  'olRecursMonthNth'                          => 3,
  'olRecursYearly'                            => 5,
  'olRecursYearNth'                           => 6,
);

#===============================================================================
# Rinchi::Outlook::OlRecurrenceType::Literals

=head1 METHODS for the OlRecurrenceType enumeration

=head2 @Literals = Rinchi::Outlook::OlRecurrenceType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlRecurrenceType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlRecurrenceType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e3dbf2-3c43-11dd-8db0-001c25551abc

package Rinchi::Outlook::OlRemoteStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlRemoteStatus enumeration

Rinchi::Outlook::OlRemoteStatus - Module representing the OlRemoteStatus enumeration. 

=head1 CONSTANTS for the OlRemoteStatus enumeration

 olRemoteStatusNone                        => 0
 olUnMarked                                => 1
 olMarkedForDownload                       => 2
 olMarkedForCopy                           => 3
 olMarkedForDelete                         => 4

=cut

#===============================================================================
  *olRemoteStatusNone                        = sub { return 0; };
  *olUnMarked                                = sub { return 1; };
  *olMarkedForDownload                       = sub { return 2; };
  *olMarkedForCopy                           = sub { return 3; };
  *olMarkedForDelete                         = sub { return 4; };

my @_literal_list_OlRemoteStatus = (
  'olRemoteStatusNone'                        => 0,
  'olUnMarked'                                => 1,
  'olMarkedForDownload'                       => 2,
  'olMarkedForCopy'                           => 3,
  'olMarkedForDelete'                         => 4,
);

#===============================================================================
# Rinchi::Outlook::OlRemoteStatus::Literals

=head1 METHODS for the OlRemoteStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlRemoteStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlRemoteStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlRemoteStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e3ef52-3c43-11dd-a02e-001c25551abc

package Rinchi::Outlook::OlResponseStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlResponseStatus enumeration

Rinchi::Outlook::OlResponseStatus - Module representing the OlResponseStatus enumeration. 

=head1 CONSTANTS for the OlResponseStatus enumeration

 olResponseNone                            => 0
 olResponseOrganized                       => 1
 olResponseTentative                       => 2
 olResponseAccepted                        => 3
 olResponseDeclined                        => 4
 olResponseNotResponded                    => 5

=cut

#===============================================================================
  *olResponseNone                            = sub { return 0; };
  *olResponseOrganized                       = sub { return 1; };
  *olResponseTentative                       = sub { return 2; };
  *olResponseAccepted                        = sub { return 3; };
  *olResponseDeclined                        = sub { return 4; };
  *olResponseNotResponded                    = sub { return 5; };

my @_literal_list_OlResponseStatus = (
  'olResponseNone'                            => 0,
  'olResponseOrganized'                       => 1,
  'olResponseTentative'                       => 2,
  'olResponseAccepted'                        => 3,
  'olResponseDeclined'                        => 4,
  'olResponseNotResponded'                    => 5,
);

#===============================================================================
# Rinchi::Outlook::OlResponseStatus::Literals

=head1 METHODS for the OlResponseStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlResponseStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlResponseStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlResponseStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e40226-3c43-11dd-84ad-001c25551abc

package Rinchi::Outlook::OlSaveAsType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlSaveAsType enumeration

Rinchi::Outlook::OlSaveAsType - Module representing the OlSaveAsType enumeration. 

=head1 CONSTANTS for the OlSaveAsType enumeration

 olTXT                                     => 0
 olRTF                                     => 1
 olTemplate                                => 2
 olMSG                                     => 3
 olDoc                                     => 4
 olHTML                                    => 5
 olVCard                                   => 6
 olVCal                                    => 7
 olICal                                    => 8
 olMSGUnicode                              => 9

=cut

#===============================================================================
  *olTXT                                     = sub { return 0; };
  *olRTF                                     = sub { return 1; };
  *olTemplate                                = sub { return 2; };
  *olMSG                                     = sub { return 3; };
  *olDoc                                     = sub { return 4; };
  *olHTML                                    = sub { return 5; };
  *olVCard                                   = sub { return 6; };
  *olVCal                                    = sub { return 7; };
  *olICal                                    = sub { return 8; };
  *olMSGUnicode                              = sub { return 9; };

my @_literal_list_OlSaveAsType = (
  'olTXT'                                     => 0,
  'olRTF'                                     => 1,
  'olTemplate'                                => 2,
  'olMSG'                                     => 3,
  'olDoc'                                     => 4,
  'olHTML'                                    => 5,
  'olVCard'                                   => 6,
  'olVCal'                                    => 7,
  'olICal'                                    => 8,
  'olMSGUnicode'                              => 9,
);

#===============================================================================
# Rinchi::Outlook::OlSaveAsType::Literals

=head1 METHODS for the OlSaveAsType enumeration

=head2 @Literals = Rinchi::Outlook::OlSaveAsType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlSaveAsType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlSaveAsType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e4d6ec-3c43-11dd-bbab-001c25551abc

package Rinchi::Outlook::OlSensitivity;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlSensitivity enumeration

Rinchi::Outlook::OlSensitivity - Module representing the OlSensitivity enumeration. 

=head1 CONSTANTS for the OlSensitivity enumeration

 olNormal                                  => 0
 olPersonal                                => 1
 olPrivate                                 => 2
 olConfidential                            => 3

=cut

#===============================================================================
  *olNormal                                  = sub { return 0; };
  *olPersonal                                = sub { return 1; };
  *olPrivate                                 = sub { return 2; };
  *olConfidential                            = sub { return 3; };

my @_literal_list_OlSensitivity = (
  'olNormal'                                  => 0,
  'olPersonal'                                => 1,
  'olPrivate'                                 => 2,
  'olConfidential'                            => 3,
);

#===============================================================================
# Rinchi::Outlook::OlSensitivity::Literals

=head1 METHODS for the OlSensitivity enumeration

=head2 @Literals = Rinchi::Outlook::OlSensitivity::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlSensitivity::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlSensitivity;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e4f65e-3c43-11dd-bd94-001c25551abc

package Rinchi::Outlook::OlShowItemCount;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlShowItemCount enumeration

Rinchi::Outlook::OlShowItemCount - Module representing the OlShowItemCount enumeration. 

=head1 CONSTANTS for the OlShowItemCount enumeration

 olNoItemCount                             => 0
 olShowUnreadItemCount                     => 1
 olShowTotalItemCount                      => 2

=cut

#===============================================================================
  *olNoItemCount                             = sub { return 0; };
  *olShowUnreadItemCount                     = sub { return 1; };
  *olShowTotalItemCount                      = sub { return 2; };

my @_literal_list_OlShowItemCount = (
  'olNoItemCount'                             => 0,
  'olShowUnreadItemCount'                     => 1,
  'olShowTotalItemCount'                      => 2,
);

#===============================================================================
# Rinchi::Outlook::OlShowItemCount::Literals

=head1 METHODS for the OlShowItemCount enumeration

=head2 @Literals = Rinchi::Outlook::OlShowItemCount::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlShowItemCount::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlShowItemCount;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e50ad6-3c43-11dd-b8be-001c25551abc

package Rinchi::Outlook::OlSortOrder;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlSortOrder enumeration

Rinchi::Outlook::OlSortOrder - Module representing the OlSortOrder enumeration. 

=head1 CONSTANTS for the OlSortOrder enumeration

 olSortNone                                => 0
 olAscending                               => 1
 olDescending                              => 2

=cut

#===============================================================================
  *olSortNone                                = sub { return 0; };
  *olAscending                               = sub { return 1; };
  *olDescending                              = sub { return 2; };

my @_literal_list_OlSortOrder = (
  'olSortNone'                                => 0,
  'olAscending'                               => 1,
  'olDescending'                              => 2,
);

#===============================================================================
# Rinchi::Outlook::OlSortOrder::Literals

=head1 METHODS for the OlSortOrder enumeration

=head2 @Literals = Rinchi::Outlook::OlSortOrder::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlSortOrder::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlSortOrder;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e51ab2-3c43-11dd-87ec-001c25551abc

package Rinchi::Outlook::OlStoreType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlStoreType enumeration

Rinchi::Outlook::OlStoreType - Module representing the OlStoreType enumeration. 

=head1 CONSTANTS for the OlStoreType enumeration

 olStoreDefault                            => 1
 olStoreUnicode                            => 2
 olStoreANSI                               => 3

=cut

#===============================================================================
  *olStoreDefault                            = sub { return 1; };
  *olStoreUnicode                            = sub { return 2; };
  *olStoreANSI                               = sub { return 3; };

my @_literal_list_OlStoreType = (
  'olStoreDefault'                            => 1,
  'olStoreUnicode'                            => 2,
  'olStoreANSI'                               => 3,
);

#===============================================================================
# Rinchi::Outlook::OlStoreType::Literals

=head1 METHODS for the OlStoreType enumeration

=head2 @Literals = Rinchi::Outlook::OlStoreType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlStoreType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlStoreType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e52ae8-3c43-11dd-b1f3-001c25551abc

package Rinchi::Outlook::OlSyncState;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlSyncState enumeration

Rinchi::Outlook::OlSyncState - Module representing the OlSyncState enumeration. 

=head1 CONSTANTS for the OlSyncState enumeration

 olSyncStopped                             => 0
 olSyncStarted                             => 1

=cut

#===============================================================================
  *olSyncStopped                             = sub { return 0; };
  *olSyncStarted                             = sub { return 1; };

my @_literal_list_OlSyncState = (
  'olSyncStopped'                             => 0,
  'olSyncStarted'                             => 1,
);

#===============================================================================
# Rinchi::Outlook::OlSyncState::Literals

=head1 METHODS for the OlSyncState enumeration

=head2 @Literals = Rinchi::Outlook::OlSyncState::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlSyncState::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlSyncState;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e53b0a-3c43-11dd-95d0-001c25551abc

package Rinchi::Outlook::OlTaskDelegationState;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlTaskDelegationState enumeration

Rinchi::Outlook::OlTaskDelegationState - Module representing the OlTaskDelegationState enumeration. 

=head1 CONSTANTS for the OlTaskDelegationState enumeration

 olTaskNotDelegated                        => 0
 olTaskDelegationUnknown                   => 1
 olTaskDelegationAccepted                  => 2
 olTaskDelegationDeclined                  => 3

=cut

#===============================================================================
  *olTaskNotDelegated                        = sub { return 0; };
  *olTaskDelegationUnknown                   = sub { return 1; };
  *olTaskDelegationAccepted                  = sub { return 2; };
  *olTaskDelegationDeclined                  = sub { return 3; };

my @_literal_list_OlTaskDelegationState = (
  'olTaskNotDelegated'                        => 0,
  'olTaskDelegationUnknown'                   => 1,
  'olTaskDelegationAccepted'                  => 2,
  'olTaskDelegationDeclined'                  => 3,
);

#===============================================================================
# Rinchi::Outlook::OlTaskDelegationState::Literals

=head1 METHODS for the OlTaskDelegationState enumeration

=head2 @Literals = Rinchi::Outlook::OlTaskDelegationState::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlTaskDelegationState::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlTaskDelegationState;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e54b22-3c43-11dd-bd47-001c25551abc

package Rinchi::Outlook::OlTaskOwnership;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlTaskOwnership enumeration

Rinchi::Outlook::OlTaskOwnership - Module representing the OlTaskOwnership enumeration. 

=head1 CONSTANTS for the OlTaskOwnership enumeration

 olNewTask                                 => 0
 olDelegatedTask                           => 1
 olOwnTask                                 => 2

=cut

#===============================================================================
  *olNewTask                                 = sub { return 0; };
  *olDelegatedTask                           = sub { return 1; };
  *olOwnTask                                 = sub { return 2; };

my @_literal_list_OlTaskOwnership = (
  'olNewTask'                                 => 0,
  'olDelegatedTask'                           => 1,
  'olOwnTask'                                 => 2,
);

#===============================================================================
# Rinchi::Outlook::OlTaskOwnership::Literals

=head1 METHODS for the OlTaskOwnership enumeration

=head2 @Literals = Rinchi::Outlook::OlTaskOwnership::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlTaskOwnership::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlTaskOwnership;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e55ab8-3c43-11dd-881a-001c25551abc

package Rinchi::Outlook::OlTaskRecipientType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlTaskRecipientType enumeration

Rinchi::Outlook::OlTaskRecipientType - Module representing the OlTaskRecipientType enumeration. 

=head1 CONSTANTS for the OlTaskRecipientType enumeration

 olUpdate                                  => 2
 olFinalStatus                             => 3

=cut

#===============================================================================
  *olUpdate                                  = sub { return 2; };
  *olFinalStatus                             = sub { return 3; };

my @_literal_list_OlTaskRecipientType = (
  'olUpdate'                                  => 2,
  'olFinalStatus'                             => 3,
);

#===============================================================================
# Rinchi::Outlook::OlTaskRecipientType::Literals

=head1 METHODS for the OlTaskRecipientType enumeration

=head2 @Literals = Rinchi::Outlook::OlTaskRecipientType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlTaskRecipientType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlTaskRecipientType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e56a58-3c43-11dd-8a73-001c25551abc

package Rinchi::Outlook::OlTaskResponse;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlTaskResponse enumeration

Rinchi::Outlook::OlTaskResponse - Module representing the OlTaskResponse enumeration. 

=head1 CONSTANTS for the OlTaskResponse enumeration

 olTaskSimple                              => 0
 olTaskAssign                              => 1
 olTaskAccept                              => 2
 olTaskDecline                             => 3

=cut

#===============================================================================
  *olTaskSimple                              = sub { return 0; };
  *olTaskAssign                              = sub { return 1; };
  *olTaskAccept                              = sub { return 2; };
  *olTaskDecline                             = sub { return 3; };

my @_literal_list_OlTaskResponse = (
  'olTaskSimple'                              => 0,
  'olTaskAssign'                              => 1,
  'olTaskAccept'                              => 2,
  'olTaskDecline'                             => 3,
);

#===============================================================================
# Rinchi::Outlook::OlTaskResponse::Literals

=head1 METHODS for the OlTaskResponse enumeration

=head2 @Literals = Rinchi::Outlook::OlTaskResponse::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlTaskResponse::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlTaskResponse;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e58d80-3c43-11dd-ba52-001c25551abc

package Rinchi::Outlook::OlTaskStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlTaskStatus enumeration

Rinchi::Outlook::OlTaskStatus - Module representing the OlTaskStatus enumeration. 

=head1 CONSTANTS for the OlTaskStatus enumeration

 olTaskNotStarted                          => 0
 olTaskInProgress                          => 1
 olTaskComplete                            => 2
 olTaskWaiting                             => 3
 olTaskDeferred                            => 4

=cut

#===============================================================================
  *olTaskNotStarted                          = sub { return 0; };
  *olTaskInProgress                          = sub { return 1; };
  *olTaskComplete                            = sub { return 2; };
  *olTaskWaiting                             = sub { return 3; };
  *olTaskDeferred                            = sub { return 4; };

my @_literal_list_OlTaskStatus = (
  'olTaskNotStarted'                          => 0,
  'olTaskInProgress'                          => 1,
  'olTaskComplete'                            => 2,
  'olTaskWaiting'                             => 3,
  'olTaskDeferred'                            => 4,
);

#===============================================================================
# Rinchi::Outlook::OlTaskStatus::Literals

=head1 METHODS for the OlTaskStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlTaskStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlTaskStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlTaskStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e5a13a-3c43-11dd-bfc1-001c25551abc

package Rinchi::Outlook::OlTrackingStatus;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlTrackingStatus enumeration

Rinchi::Outlook::OlTrackingStatus - Module representing the OlTrackingStatus enumeration. 

=head1 CONSTANTS for the OlTrackingStatus enumeration

 olTrackingNone                            => 0
 olTrackingDelivered                       => 1
 olTrackingNotDelivered                    => 2
 olTrackingNotRead                         => 3
 olTrackingRecallFailure                   => 4
 olTrackingRecallSuccess                   => 5
 olTrackingRead                            => 6
 olTrackingReplied                         => 7

=cut

#===============================================================================
  *olTrackingNone                            = sub { return 0; };
  *olTrackingDelivered                       = sub { return 1; };
  *olTrackingNotDelivered                    = sub { return 2; };
  *olTrackingNotRead                         = sub { return 3; };
  *olTrackingRecallFailure                   = sub { return 4; };
  *olTrackingRecallSuccess                   = sub { return 5; };
  *olTrackingRead                            = sub { return 6; };
  *olTrackingReplied                         = sub { return 7; };

my @_literal_list_OlTrackingStatus = (
  'olTrackingNone'                            => 0,
  'olTrackingDelivered'                       => 1,
  'olTrackingNotDelivered'                    => 2,
  'olTrackingNotRead'                         => 3,
  'olTrackingRecallFailure'                   => 4,
  'olTrackingRecallSuccess'                   => 5,
  'olTrackingRead'                            => 6,
  'olTrackingReplied'                         => 7,
);

#===============================================================================
# Rinchi::Outlook::OlTrackingStatus::Literals

=head1 METHODS for the OlTrackingStatus enumeration

=head2 @Literals = Rinchi::Outlook::OlTrackingStatus::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlTrackingStatus::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlTrackingStatus;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e5b148-3c43-11dd-8307-001c25551abc

package Rinchi::Outlook::OlUserPropertyType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlUserPropertyType enumeration

Rinchi::Outlook::OlUserPropertyType - Module representing the OlUserPropertyType enumeration. 

=head1 CONSTANTS for the OlUserPropertyType enumeration

 olOutlookInternal                         => 0
 olText                                    => 1
 olNumber                                  => 3
 olDateTime                                => 5
 olYesNo                                   => 6
 olDuration                                => 7
 olKeywords                                => 11
 olPercent                                 => 12
 olCurrency                                => 14
 olFormula                                 => 18
 olCombination                             => 19

=cut

#===============================================================================
  *olOutlookInternal                         = sub { return 0; };
  *olText                                    = sub { return 1; };
  *olNumber                                  = sub { return 3; };
  *olDateTime                                = sub { return 5; };
  *olYesNo                                   = sub { return 6; };
  *olDuration                                = sub { return 7; };
  *olKeywords                                = sub { return 11; };
  *olPercent                                 = sub { return 12; };
  *olCurrency                                = sub { return 14; };
  *olFormula                                 = sub { return 18; };
  *olCombination                             = sub { return 19; };

my @_literal_list_OlUserPropertyType = (
  'olOutlookInternal'                         => 0,
  'olText'                                    => 1,
  'olNumber'                                  => 3,
  'olDateTime'                                => 5,
  'olYesNo'                                   => 6,
  'olDuration'                                => 7,
  'olKeywords'                                => 11,
  'olPercent'                                 => 12,
  'olCurrency'                                => 14,
  'olFormula'                                 => 18,
  'olCombination'                             => 19,
);

#===============================================================================
# Rinchi::Outlook::OlUserPropertyType::Literals

=head1 METHODS for the OlUserPropertyType enumeration

=head2 @Literals = Rinchi::Outlook::OlUserPropertyType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlUserPropertyType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlUserPropertyType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e5c1b0-3c43-11dd-9047-001c25551abc

package Rinchi::Outlook::OlViewSaveOption;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlViewSaveOption enumeration

Rinchi::Outlook::OlViewSaveOption - Module representing the OlViewSaveOption enumeration. 

=head1 CONSTANTS for the OlViewSaveOption enumeration

 olViewSaveOptionThisFolderEveryone        => 0
 olViewSaveOptionThisFolderOnlyMe          => 1
 olViewSaveOptionAllFoldersOfType          => 2

=cut

#===============================================================================
  *olViewSaveOptionThisFolderEveryone        = sub { return 0; };
  *olViewSaveOptionThisFolderOnlyMe          = sub { return 1; };
  *olViewSaveOptionAllFoldersOfType          = sub { return 2; };

my @_literal_list_OlViewSaveOption = (
  'olViewSaveOptionThisFolderEveryone'        => 0,
  'olViewSaveOptionThisFolderOnlyMe'          => 1,
  'olViewSaveOptionAllFoldersOfType'          => 2,
);

#===============================================================================
# Rinchi::Outlook::OlViewSaveOption::Literals

=head1 METHODS for the OlViewSaveOption enumeration

=head2 @Literals = Rinchi::Outlook::OlViewSaveOption::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlViewSaveOption::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlViewSaveOption;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e5d1f0-3c43-11dd-9f87-001c25551abc

package Rinchi::Outlook::OlViewType;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlViewType enumeration

Rinchi::Outlook::OlViewType - Module representing the OlViewType enumeration. 

=head1 CONSTANTS for the OlViewType enumeration

 olTableView                               => 0
 olCardView                                => 1
 olCalendarView                            => 2
 olIconView                                => 3
 olTimelineView                            => 4

=cut

#===============================================================================
  *olTableView                               = sub { return 0; };
  *olCardView                                = sub { return 1; };
  *olCalendarView                            = sub { return 2; };
  *olIconView                                = sub { return 3; };
  *olTimelineView                            = sub { return 4; };

my @_literal_list_OlViewType = (
  'olTableView'                               => 0,
  'olCardView'                                => 1,
  'olCalendarView'                            => 2,
  'olIconView'                                => 3,
  'olTimelineView'                            => 4,
);

#===============================================================================
# Rinchi::Outlook::OlViewType::Literals

=head1 METHODS for the OlViewType enumeration

=head2 @Literals = Rinchi::Outlook::OlViewType::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlViewType::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlViewType;
}

#===============================================================================
# Generated by Hymnos Perl Code Generator
# UML Model UUID: d5e5e172-3c43-11dd-a5b4-001c25551abc

package Rinchi::Outlook::OlWindowState;

our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of OlWindowState enumeration

Rinchi::Outlook::OlWindowState - Module representing the OlWindowState enumeration. 

=head1 CONSTANTS for the OlWindowState enumeration

 olMaximized                               => 0
 olMinimized                               => 1
 olNormalWindow                            => 2

=cut

#===============================================================================
  *olMaximized                               = sub { return 0; };
  *olMinimized                               = sub { return 1; };
  *olNormalWindow                            = sub { return 2; };

my @_literal_list_OlWindowState = (
  'olMaximized'                               => 0,
  'olMinimized'                               => 1,
  'olNormalWindow'                            => 2,
);

#===============================================================================
# Rinchi::Outlook::OlWindowState::Literals

=head1 METHODS for the OlWindowState enumeration

=head2 @Literals = Rinchi::Outlook::OlWindowState::Literals

Returns an array of literal name-value pairs.

=head2 %Literals = Rinchi::Outlook::OlWindowState::Literals

Returns a hash of literal name-value pairs.

=cut

sub Literals() {
  my $self = shift;
  return @_literal_list_OlWindowState;
}

1

__END__

=head1 AUTHOR

Brian M. Ames, E<lt>bmames@apk.netE<gt>

=head1 SEE ALSO

L<XML::Parser>.
L<XML::DOM>.

=head1 COPYRIGHT and LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
