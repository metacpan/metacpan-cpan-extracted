package DropArea;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [DropArea header part1]
use QtCore4::isa qw( Qt::Label );
use QtCore4::slots
    clear => [];

use QtCore4::signals
    changed => ['const QMimeData *'];
# [DropArea header part1]
use DropArea;

# [DropArea header part2]
sub label() {
    return this->{label};
}
# [DropArea header part2]

# [DropArea constructor]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->setMinimumSize(200, 200);
    this->setFrameStyle(Qt::Frame::Sunken() | Qt::Frame::StyledPanel());
    this->setAlignment(Qt::AlignCenter());
    this->setAcceptDrops(1);
    this->setAutoFillBackground(1);
    this->clear();
}
# [DropArea constructor]

# [dragEnterEvent() function]
sub dragEnterEvent
{
    my ($event) = @_;
    this->setText(this->tr('<drop content>'));
    this->setBackgroundRole(Qt::Palette::Highlight());

    $event->acceptProposedAction();
    emit this->changed($event->mimeData());
}
# [dragEnterEvent() function]

# [dragMoveEvent() function]
sub dragMoveEvent
{
    my ($event) = @_;
    $event->acceptProposedAction();
}
# [dragMoveEvent() function]

# [dropEvent() function part1]
sub dropEvent
{
    my ($event) = @_;
    my $mimeData = $event->mimeData();
# [dropEvent() function part1]

# [dropEvent() function part2]
    if ($mimeData->hasImage()) {
        this->setPixmap(Qt::Pixmap::fromImage($mimeData->imageData()->value()));
    } elsif ($mimeData->hasHtml()) {
        this->setText($mimeData->html());
        this->setTextFormat(Qt::RichText());
    } elsif ($mimeData->hasText()) {
        this->setText($mimeData->text());    
        this->setTextFormat(Qt::PlainText());
    } elsif ($mimeData->hasUrls()) {
        my $urlList = $mimeData->urls();
        my $text;
        for (my $i = 0; $i < scalar @{$urlList} && $i < 32; ++$i) {
            my $url = $urlList->[$i]->path();
            $text += $url . "\n";
        }
        this->setText($text);
    } else {
        this->setText(this->tr('Cannot display data'));
    }
# [dropEvent() function part2]

# [dropEvent() function part3]    
    this->setBackgroundRole(Qt::Palette::Dark());
    $event->acceptProposedAction();
}
# [dropEvent() function part3]

# [dragLeaveEvent() function]
sub dragLeaveEvent
{
    my ($event) = @_;
    this->clear();
    $event->accept();
}
# [dragLeaveEvent() function]

# [clear() function]
sub clear
{
    this->setText(this->tr('<drop content>'));
    this->setBackgroundRole(Qt::Palette::Dark());

    emit this->changed(Qt::MimeData());
}
# [clear() function]

1;
