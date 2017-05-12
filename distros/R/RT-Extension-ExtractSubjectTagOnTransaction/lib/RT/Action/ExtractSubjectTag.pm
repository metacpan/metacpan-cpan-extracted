
=head1 COPYRIGHT

This extension is Copyright (C) 2005 Best Practical Solutions, LLC.

It is freely redistributable under the terms of version 2 of the GNU GPL.

=cut

package RT::Action::ExtractSubjectTag;
require RT::Action::Generic;

use strict;
use vars qw/@ISA/;
@ISA=qw(RT::Action::Generic);

our $VERSION = "0.01";

our $ExtractSubjectTagMatch = $RT::ExtractSubjectTagMatch || qr/\[.+? #\d+\]/;
our $ExtractSubjectTagNoMatch = $RT::ExtractSubjectTagNoMatch
  || ( ${RT::EmailSubjectTagRegex}
       ? qr/\[(?:${RT::EmailSubjectTagRegex}) #\d+\]/
       : qr/\[\Q$RT::rtname\E #\d+\]/);

sub Describe  {
  my $self = shift;
  return (ref $self);
}

sub Prepare {
  return (1);
}

sub Commit {
  my $self = shift;
  my $Transaction = $self->TransactionObj;
  my $FirstAttachment = $Transaction->Attachments->First;
  return 1 unless ( $FirstAttachment );

  my $Ticket = $self->TicketObj;

  my $TicketSubject = $self->TicketObj->Subject;
  my $origTicketSubject = $TicketSubject;
  my $TransactionSubject = $FirstAttachment->Subject;

  while ( $TransactionSubject =~ /($ExtractSubjectTagMatch)/g ) {
    my $tag = $1;
    next if $tag =~ /$ExtractSubjectTagNoMatch/;
    $TicketSubject .= " $tag" unless ($TicketSubject =~ /\Q$tag\E/);
  }

  $self->TicketObj->SetSubject( $TicketSubject )
    if ($TicketSubject ne $origTicketSubject);

  return(1);
}

1;
