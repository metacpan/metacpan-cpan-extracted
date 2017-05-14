package Dialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtSql4;

use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    revert => [],
    submit => [];

our $uniqueAlbumId;
our $uniqueArtistId;

sub NEW
{
    my ($class, $albums, $details, $output, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{model} = $albums;
    this->{albumDetails} = $details;
    this->{outputFile} = $output;

    my $inputWidgetBox = this->createInputWidgets();
    my $buttonBox = this->createButtons();

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($inputWidgetBox);
    $layout->addWidget($buttonBox);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Add Album'));
}

sub submit
{
    my $artist = this->{artistEditor}->text();
    my $title = this->{titleEditor}->text();

    if (!$artist && !$title) {
        my $message = (this->tr('Please provide both the name of the artist ' .
                           'and the title of the album.'));
        Qt::MessageBox::information(this, this->tr('Add Album'), $message);
    } else {
        my $artistId = this->findArtistId($artist);
        my $albumId = this->addNewAlbum($title, $artistId);

        my @tracks = split ',', this->{tracksEditor}->text();
        this->addTracks($albumId, \@tracks);

        this->increaseAlbumCount(this->indexOfArtist($artist));
        this->accept();
    }
}

sub findArtistId
{
    my ($artist) = @_;
    my $artistModel = this->{model}->relationModel(2);
    my $row = 0;

    while ($row < $artistModel->rowCount()) {
        my $record = $artistModel->record($row);
        if ($record->value('artist')->toString() eq $artist) {
            return $record->value('id')->toInt();
        }
        else {
            $row++;
        }
    }
    return this->addNewArtist($artist);
}


sub addNewArtist
{
    my ($name) = @_;
    my $artistModel = this->{model}->relationModel(2);
    my $record = Qt::SqlRecord();

    my $id = this->generateArtistId();

    my $f1 = Qt::SqlField('id', Qt::Variant::Int());
    my $f2 = Qt::SqlField('artist', Qt::Variant::String());
    my $f3 = Qt::SqlField('albumcount', Qt::Variant::Int());

    $f1->setValue(Qt::Variant(Qt::Int($id)));
    $f2->setValue(Qt::Variant(Qt::String($name)));
    $f3->setValue(Qt::Variant(Qt::Int(0)));
    $record->append($f1);
    $record->append($f2);
    $record->append($f3);

    $artistModel->insertRecord(-1, $record);
    return $id;
}

sub addNewAlbum
{
    my ($title, $artistId) = @_;
    my $id = this->generateAlbumId();
    my $record = Qt::SqlRecord();

    my $f1 = Qt::SqlField('albumid', Qt::Variant::Int());
    my $f2 = Qt::SqlField('title', Qt::Variant::String());
    my $f3 = Qt::SqlField('artistid', Qt::Variant::Int());
    my $f4 = Qt::SqlField('year', Qt::Variant::Int());

    $f1->setValue(Qt::Variant(Qt::Int($id)));
    $f2->setValue(Qt::Variant(Qt::String($title)));
    $f3->setValue(Qt::Variant(Qt::Int($artistId)));
    $f4->setValue(Qt::Variant(Qt::Int(this->{yearEditor}->value())));
    $record->append($f1);
    $record->append($f2);
    $record->append($f3);
    $record->append($f4);

    this->{model}->insertRecord(-1, $record);
    return $id;
}

sub addTracks
{
    my ($albumId, $tracks) = @_;
    my $albumNode = this->{albumDetails}->createElement('album');
    $albumNode->setAttribute('id', Qt::Int($albumId));

    foreach my $i (0..$#{$tracks}) {
        my $trackNumber = $i;
        if ($i < 10) {
            $trackNumber = '0' . $i;
        }

        my $textNode = this->{albumDetails}->createTextNode($tracks->[$i]);

        my $trackNode = this->{albumDetails}->createElement('track');
        $trackNode->setAttribute('number', $trackNumber);
        $trackNode->appendChild($textNode);

        $albumNode->appendChild($trackNode);
    }

    my $archive = this->{albumDetails}->elementsByTagName('archive');
    $archive->item(0)->appendChild($albumNode);

    #The following code is commented out since the example uses an in
    #memory database, i.e., altering the XML file will bring the data
    #out of sync.

    #if (!this->{outputFile}->open(Qt::IODevice::WriteOnly)) {
        #return;
    #} else {
        #Qt::TextStream stream(this->{outputFile});
        #archive.item(0).save(stream, 4);
        #this->{outputFile}->close();
    #}
}

sub increaseAlbumCount
{
    my ($artistIndex) = @_;
    my $artistModel = this->{model}->relationModel(2);

    my $albumCountIndex = $artistIndex->sibling($artistIndex->row(), 2);

    my $albumCount = $albumCountIndex->data()->toInt();
    $artistModel->setData($albumCountIndex, Qt::Variant(Qt::Int($albumCount + 1)));
}


sub revert
{
    this->{artistEditor}->clear();
    this->{titleEditor}->clear();
    this->{yearEditor}->setValue(Qt::Date::currentDate()->year());
    this->{tracksEditor}->clear();
}

sub createInputWidgets
{
    my $box = Qt::GroupBox(this->tr('Add Album'));

    my $artistLabel = Qt::Label(this->tr('Artist:'));
    my $titleLabel = Qt::Label(this->tr('Title:'));
    my $yearLabel = Qt::Label(this->tr('Year:'));
    my $tracksLabel = Qt::Label(this->tr('Tracks (separated by comma):'));

    this->{artistEditor} = Qt::LineEdit();
    this->{titleEditor} = Qt::LineEdit();

    this->{yearEditor} = Qt::SpinBox();
    this->{yearEditor}->setMinimum(1900);
    this->{yearEditor}->setMaximum(Qt::Date::currentDate()->year());
    this->{yearEditor}->setValue(this->{yearEditor}->maximum());
    this->{yearEditor}->setReadOnly(0);

    this->{tracksEditor} = Qt::LineEdit();

    my $layout = Qt::GridLayout();
    $layout->addWidget($artistLabel, 0, 0);
    $layout->addWidget(this->{artistEditor}, 0, 1);
    $layout->addWidget($titleLabel, 1, 0);
    $layout->addWidget(this->{titleEditor}, 1, 1);
    $layout->addWidget($yearLabel, 2, 0);
    $layout->addWidget(this->{yearEditor}, 2, 1);
    $layout->addWidget($tracksLabel, 3, 0, 1, 2);
    $layout->addWidget(this->{tracksEditor}, 4, 0, 1, 2);
    $box->setLayout($layout);

    return $box;
}

sub createButtons
{
    my $closeButton = Qt::PushButton(this->tr('&Close'));
    my $revertButton = Qt::PushButton(this->tr('&Revert'));
    my $submitButton = Qt::PushButton(this->tr('&Submit'));

    $closeButton->setDefault(1);

    this->connect($closeButton, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect($revertButton, SIGNAL 'clicked()', this, SLOT 'revert()');
    this->connect($submitButton, SIGNAL 'clicked()', this, SLOT 'submit()');

    my $buttonBox = Qt::DialogButtonBox();
    $buttonBox->addButton($submitButton, Qt::DialogButtonBox::ResetRole());
    $buttonBox->addButton($revertButton, Qt::DialogButtonBox::ResetRole());
    $buttonBox->addButton($closeButton, Qt::DialogButtonBox::RejectRole());

    return $buttonBox;
}

sub indexOfArtist
{
    my ($artist) = @_;
    my $artistModel = this->{model}->relationModel(2);

    foreach my $i (0..$artistModel->rowCount()-1) {
        my $record = $artistModel->record($i);
        if ($record->value('artist') eq $artist) {
            return $artistModel->index($i, 1);
        }
    }

    return Qt::ModelIndex();
}

sub generateArtistId
{
    $uniqueArtistId += 1;
    return $uniqueArtistId;
}

sub generateAlbumId
{
    $uniqueAlbumId += 1;
    return $uniqueAlbumId;
}

1;
