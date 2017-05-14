package GSuggestCompletion;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtXml4;
use QtCore4::isa qw( Qt::Object );
use QtCore4::slots
    doneCompletion => [],
    preventSuggest => [],
    autoSuggest => [],
    handleNetworkData => ['QNetworkReply *'];
use List::Util qw(min);

sub editor() {
    return this->{editor};
}

sub popup() {
    return this->{popup};
}

sub timer() {
    return this->{timer};
}

sub networkManager() {
    return this->{networkManager};
}

use constant GSUGGEST_URL => 'http://google.com/complete/search?output=toolbar&q=%s';

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{networkManager} = Qt::NetworkAccessManager();
    this->{editor} = $parent;
    this->{popup} = Qt::TreeWidget();
    this->popup->setColumnCount(2);
    this->popup->setUniformRowHeights(1);
    this->popup->setRootIsDecorated(0);
    this->popup->setEditTriggers(Qt::TreeWidget::NoEditTriggers());
    this->popup->setSelectionBehavior(Qt::TreeWidget::SelectRows());
    this->popup->setFrameStyle(Qt::Frame::Box() | Qt::Frame::Plain());
    this->popup->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff());

    this->popup->header()->hide();
    this->popup->installEventFilter(this);
    this->popup->setMouseTracking(1);

    this->connect(this->popup, SIGNAL 'itemClicked(QTreeWidgetItem*, int)',
            SLOT 'doneCompletion()');

    this->popup->setWindowFlags(Qt::Popup());
    this->popup->setFocusPolicy(Qt::NoFocus());
    this->popup->setFocusProxy($parent);

    this->{timer} = Qt::Timer(this);
    this->timer->setSingleShot(1);
    this->timer->setInterval(500);
    this->connect(this->timer, SIGNAL 'timeout()', SLOT 'autoSuggest()');
    this->connect(this->editor, SIGNAL 'textEdited(QString)', timer, SLOT 'start()');

    this->connect(this->networkManager, SIGNAL 'finished(QNetworkReply*)',
            this, SLOT 'handleNetworkData(QNetworkReply*)');

}

sub eventFilter
{
    my ($obj, $ev) = @_;
    if (!($obj eq this->popup)) {
        return 0;
    }

    if ($ev->type() == Qt::Event::MouseButtonPress()) {
        this->popup->hide();
        this->editor->setFocus();
        return 1;
    }

    if ($ev->type() == Qt::Event::KeyPress()) {

        my $consumed = 0;
        my $key = $ev->key();
        if ( $key == Qt::Key_Enter() || $key == Qt::Key_Return() ) {
            this->doneCompletion();
            $consumed = 1;
        }

        if ( $key == Qt::Key_Escape() ) {
            this->editor->setFocus();
            this->popup->hide();
            $consumed = 1;
        }

        if ( $key == Qt::Key_Up() ||
             $key == Qt::Key_Down() ||
             $key == Qt::Key_Home() ||
             $key == Qt::Key_End() ||
             $key == Qt::Key_PageUp() ||
             $key == Qt::Key_PageDown() ) {
        }
        else {
            this->editor->setFocus();
            this->editor->event($ev);
            this->popup->hide();
        }

        return $consumed;
    }

    return 0;
}

sub showCompletion
{
    my ($choices, $hits) = @_;
    #my (const Qt::StringList &choices, const Qt::StringList &hits)

    if (!defined $choices || !(ref $choices eq 'ARRAY') || scalar @{$choices} != scalar @{$hits}) {
        return;
    }

    my $pal = this->editor->palette();
    my $color = $pal->color(Qt::Palette::Disabled(), Qt::Palette::WindowText());

    this->popup->setUpdatesEnabled(0);
    this->popup->clear();
    for (my $i = 0; $i < scalar @{$choices}; ++$i) {
        my $item = Qt::TreeWidgetItem(this->popup);
        $item->setText(0, $choices->[$i]);
        $item->setText(1, $hits->[$i]);
        $item->setTextAlignment(1, Qt::AlignRight());
        $item->setTextColor(1, $color);
    }
    this->popup->setCurrentItem(this->popup->topLevelItem(0));
    this->popup->resizeColumnToContents(0);
    this->popup->resizeColumnToContents(1);
    this->popup->adjustSize();
    this->popup->setUpdatesEnabled(1);

    my $h = this->popup->sizeHintForRow(0) * min(7, scalar @{$choices}) + 3;
    this->popup->resize(this->popup->width(), $h);

    this->popup->move(this->editor->mapToGlobal(Qt::Point(0, this->editor->height())));
    this->popup->setFocus();
    this->popup->show();
}

sub doneCompletion
{
    this->timer->stop();
    this->popup->hide();
    this->editor->setFocus();
    my $item = this->popup->currentItem();
    if ($item) {
        this->editor->setText($item->text(0));
        my $e = Qt::KeyEvent(Qt::Event::KeyPress(), Qt::Key_Enter(), Qt::NoModifier());
        Qt::Application::postEvent(this->editor, $e);
        $e = Qt::KeyEvent(Qt::Event::KeyRelease(), Qt::Key_Enter(), Qt::NoModifier());
        Qt::Application::postEvent(this->editor, $e);
    }
}

sub preventSuggest
{
    this->timer->stop();
}

sub autoSuggest
{
    my $str = this->editor->text();
    my $url = sprintf GSUGGEST_URL, $str;
    this->networkManager->get(Qt::NetworkRequest(Qt::Url($url)));
}

sub handleNetworkData
{
    my ($networkReply) = @_;
    my $url = $networkReply->url();
    if ($networkReply->error() == Qt::NetworkReply::NoError()) {
        my @choices;
        my @hits;

        my $response = $networkReply->readAll();
        my $xml = Qt::XmlStreamReader($response);
        while (!$xml->atEnd()) {
            $xml->readNext();
            if ($xml->tokenType() == Qt::XmlStreamReader::StartElement()) {
                if ($xml->name()->toString() eq 'suggestion') {
                    my $str = $xml->attributes()->value('data');
                    push @choices, $str->toString();
                }
            }
            if ($xml->tokenType() == Qt::XmlStreamReader::StartElement()) {
                if ($xml->name()->toString() eq 'num_queries') {
                    my $str = $xml->attributes()->value('int');
                    push @hits, $str->toString();
                }
            }
        }

        this->showCompletion(\@choices, \@hits);
    }

    $networkReply->deleteLater();
}

1;
