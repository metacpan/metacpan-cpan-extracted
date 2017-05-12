package Biff;

use QPainter;
use QWidget;

require "bmp.pl";

@ISA = qw(QWidget);

sub new {
    my $self = shift->SUPER::new(undef, 0, $WFlags{Type}{Modal});
    my $mailbox = $ENV{MAIL} || "/var/spool/mail/" . getlogin();

    $self->startTimer(1000) if -e $mailbox;

    $self->setMinimumSize(48, 48);
    $self->setMaximumSize(48, 48);
    $self->resize(48, 48);

    my $hasNewMail = new QPixmap;
    $hasNewMail->loadFromData($hasmail_bmp_data);
    my $noNewMail = new QPixmap;
    $noNewMail->loadFromData($nomail_bmp_data);

    my $gotMail = 0;
    my $lastModified = (stat $mailbox)[9];

    @$self{'lastModified', 'hasNewMail', 'noNewMail', 'mailbox', 'gotMail'} =
	($lastModified, $hasNewMail, $noNewMail, $mailbox, $gotMail);
    return $self;
}

sub timerEvent {
    my $self = shift;
    my($lastModified, $gotMail, $mailbox) =
	@$self{'lastModified', 'gotMail', 'mailbox'};

    my($atime, $mtime) = (stat $mailbox)[8, 9];
    my $newState = ($mtime != $lastModified &&
		    $mtime > $atime) ? 1 : 0;
    if($newState != $gotMail) {
	$$self{'lastModified'} = $mtime if $gotMail;
	$$self{'gotMail'} = $newState;
	$self->repaint(0);
    }
}

sub paintEvent {
    my $self = shift;
    my($gotMail, $hasNewMail, $noNewMail) =
	@$self{'gotMail', 'hasNewMail', 'noNewMail'};

    $self->bitBlt(0, 0, $gotMail ? $hasNewMail : $noNewMail);
}

sub mousePressEvent {
    my $self = shift;
    my $mtime = (stat $$self{'mailbox'})[9];

    $$self{'lastModified'} = $mtime;
}
