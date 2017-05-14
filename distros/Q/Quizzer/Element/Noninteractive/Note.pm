#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Noninteractive::Note -- noninteractive note Element

=cut

=head1 DESCRIPTION

This is a noninteractive note Element. Notes are generally some important peice
of information that you want the user to see sometime. Since we are running
non-interactively, we can't pause to show them. Instead, they are saved to
root's mailbox.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Noninteractive::Note;
use strict;
use Quizzer::Element::Noninteractive;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Noninteractive);

my $VERSION='0.01';

=head2 show

The show method mails the note to root if the note has not been displayed
before. The external unix mail program is used to do this, if it is present.

=cut

sub show {
	my $this=shift;

	if (-x '/usr/bin/mail' &&
	    $this->question->flag_isdefault ne 'false') {
	    	my $title="Debconf: ".$this->frontend->title." -- ".
		   $this->question->description;
		$title=~s/'/\'/g;                                                                             # This comment here to work around stupid ' highlighting in jed
	    	open (MAIL, "|mail -s '$title' root") or return;
		print MAIL <<eof;
This note was sent to you because debconf was asked to make sure you saw it,
but debconf was running in noninteractive mode, or you have told it to not
pause and show you unimportant notes. Here is the text of the note:

eof
		print MAIL $this->question->extended_description || $this->question->description;
		print MAIL "\n";
		close MAIL;
	}
	
	# Mark this note as shown. The frontend doesn't do this for us,
	# since we are marked as not visible.
	$this->question->flag_isdefault('false');

	return '';
}

1
