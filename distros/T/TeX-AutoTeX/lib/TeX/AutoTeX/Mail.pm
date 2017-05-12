package TeX::AutoTeX::Mail;

#
# $Id: Mail.pm,v 1.5.2.4 2011/01/27 18:42:28 thorstens Exp $
# $Revision: 1.5.2.4 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/Mail.pm,v $
#
# $Date: 2011/01/27 18:42:28 $
# $Author: thorstens $
#

use strict;
### use warnings;

our ($VERSION) = '$Revision: 1.5.2.4 $' =~ m{ \$Revision: \s+ (\S+) }x;

use TeX::AutoTeX::Config qw($TEX_ADMIN_ADDRESS $MAIL_FAILURES_ADDRESS $SENDMAIL);

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = {id => shift};
  bless $self, $class;
}

sub send_notification {
  my ($self, $to, $subject, $message, $reply_to) = @_;

  if (!defined $to) {
    return 'send_notification called but no message sent as destination address undefined.';
  }

  my $PIPEMAIL;
  if (!open $PIPEMAIL, q{|-}, $SENDMAIL) {
    return 'send_notification failed to open pipe to sendmail for writing.';
  }

  $message ||= '[NO MESSAGE SPECIFIED IN ' . __PACKAGE__ . "]\n";
  $message =~ s/\n\./\n \./g;

  my $id = $self->{id} || 'NO_IDENTIFIER';
  print {$PIPEMAIL} <<"EOM";
To: $to
Subject: AutoTeX[$id]: $subject
EOM
  if ($reply_to) {
    print {$PIPEMAIL} "Reply-To: $reply_to\n";
  }
  print {$PIPEMAIL} "\n\n",
    $message;
  close $PIPEMAIL;
  return;
}

sub send_failure {
  my $self = shift;
  my $subject = shift;
  $subject = "$subject (mail_failure)";
  return $self->send_notification($MAIL_FAILURES_ADDRESS, $subject, @_);
}

sub send_tex_admin {
  my $self = shift;
  my $subject = shift;
  $subject = "$subject (mail_tex_admin)";
  return $self->send_notification($TEX_ADMIN_ADDRESS, $subject, @_);
}

1;

__END__

=for stopwords undef AutoTeX sendmail arxiv.org perlartistic MTAs www-admin Schwander

=head1 NAME

TeX::AutoTeX::Mail - email handling for TeX::AutoTeX process messages

=head1 DESCRIPTION

Mail routines for TeX::AutoTeX. TeX::AutoTeX can be instructed to mail
notification of various failure conditions to specific email addresses.

=head1 HISTORY

 AutoTeX automatic TeX processing system
 Copyright (c) 1994-2006 arXiv.org and contributors

 AutoTeX is supplied under the GNU Public License and comes
 with ABSOLUTELY NO WARRANTY; see COPYING for more details.

 AutoTeX is an automatic TeX processing system designed to
 process TeX/LaTeX/AMSTeX/etc source code of papers submitted
 to the arXiv.org (nee xxx.lanl.gov) e-print archive. The
 portable part of this code has been extracted and is made
 available in the hope that it will be useful to other projects
 and that the input of others will benefit arXiv.org.

 Code developed and contributed to by Tanmoy Bhattacharya, Rob
 Hartill, Mark Doyle, Thorsten Schwander, and Simeon Warner.
 Refactored to separate generic code from arXiv.org specific code
 by Stephen Marsh, Michael Fromerth, and Simeon Warner 2005/2006.

 Major cleanups and algorithmic improvements/corrections by
 Thorsten Schwander 2006 - 2011

=head1 METHODS

=head2 new($identifier)

Instantiates a TeX::AutoTeX::Mail object. The optional $identifier will be
used in mail subject lines, which is useful when AutoTeX is deployed for
automated processing in a repository context.

=head2 send_notification($to, $subject, $message, $reply_to)

Send mail message to the address specified. The parameter names should be
self explanatory.

Returns undef on success, error message otherwise.

=head2 send_failure($subject, ...)

Convenience method calling send_notification with the configured address for
failure messages as recipient.

=head2 send_tex_admin($subject, ...)

Convenience method calling send_notification with the configured TeX
installation maintainer as delivery address.

=head1 DIAGNOSTICS

send_notification() returns C<undef> on success and an informative message on various errors

=head1 CONFIGURATION AND ENVIRONMENT

The following configuration variables from TeX::AutoTeX::Config are used

=over 4

=item $TEX_ADMIN_ADDRESS

Recipient for specific TeX issues.

=item $MAIL_FAILURES_ADDRESS

Recipient for processing failures or other error conditions.

=item $SENDMAIL

Full PATH to the sendmail executable.

=back

=head1 DEPENDENCIES

The mail commands opens a pipe into C<sendmail>, and the command syntax used
here is tailored with sendmail in mind. Other MTAs may require a different
setup.

=head1 BUGS AND LIMITATIONS

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

See history above. Current maintainer: Thorsten Schwander for
L<arXiv.org|http://arxiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
