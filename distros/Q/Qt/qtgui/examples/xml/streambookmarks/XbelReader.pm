package XbelReader;


use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw(Qt::Object);

sub xml() {
    return this->{xml};
}

sub treeWidget() {
    return this->{treeWidget};
}

sub folderIcon() {
    return this->{folderIcon};
}

sub bookmarkIcon() {
    return this->{bookmarkIcon};
}

# [0]
sub NEW
{
    my ($class, $treeWidget) = @_;
    $class->SUPER::NEW();
    this->{treeWidget} = $treeWidget;
    this->{xml} = Qt::XmlStreamReader();
    this->{folderIcon} = Qt::Icon();
    this->{bookmarkIcon} = Qt::Icon();

    my $style = treeWidget->style();

    folderIcon->addPixmap($style->standardPixmap(Qt::Style::SP_DirClosedIcon()),
                         Qt::Icon::Normal(), Qt::Icon::Off());
    folderIcon->addPixmap($style->standardPixmap(Qt::Style::SP_DirOpenIcon()),
                         Qt::Icon::Normal(), Qt::Icon::On());
    bookmarkIcon->addPixmap($style->standardPixmap(Qt::Style::SP_FileIcon()));
}
# [0]

# [1]
sub read
{
    my ($device) = @_;
    xml->setDevice($device);

    if (xml->readNextStartElement()) {
        if (xml->name()->toString() eq 'xbel' && xml->attributes()->value('version') == '1.0') {
            readXBEL();
        }
        else {
            xml->raiseError(this->tr('The file is not an XBEL version 1.0 file.'));
        }
    }

    return xml->error();
}
# [1]

# [2]
sub errorString
{
    return sprintf this->tr("%s\nLine %d, column %d"),
            xml->errorString(),
            xml->lineNumber(),
            xml->columnNumber();
}
# [2]

# [3]
sub readXBEL
{
    if (!(xml->isStartElement() && xml->name()->toString() eq 'xbel')) {
        die;
    }

    while (xml->readNextStartElement()) {
        if (xml->name()->toString() eq 'folder') {
            readFolder(0);
        }
        elsif (xml->name()->toString() eq 'bookmark') {
            readBookmark(0);
        }
        elsif (xml->name()->toString() eq 'separator') {
            readSeparator(0);
        }
        else {
            xml->skipCurrentElement();
        }
    }
}
# [3]

# [4]
sub readTitle
{
    my ($item) = @_;
    if (!(xml->isStartElement() && xml->name()->toString eq 'title')) {
        die;
    }

    my $title = xml->readElementText();
    $item->setText(0, $title);
}
# [4]

# [5]
sub readSeparator
{
    my ($item) = @_;
    if (!(xml->isStartElement() && xml->name()->toString eq 'separator')) {
        die;
    }

    my $separator = createChildItem($item);
    $separator->setFlags($item->flags() & ~Qt::ItemIsSelectable());
    $separator->setText(0, chr(0xB7) x 30);
    xml->skipCurrentElement();
}
# [5]

sub readFolder
{
    my ($item) = @_;
    if (!(xml->isStartElement() && xml->name()->toString eq 'folder')) {
        die;
    }

    my $folder = createChildItem($item);
    my $folded = xml->attributes()->value('folded')->toString() ne 'no';
    treeWidget->setItemExpanded($folder, !$folded);

    while (xml->readNextStartElement()) {
        if (xml->name()->toString() eq 'title') {
            readTitle($folder);
        }
        elsif (xml->name()->toString() eq 'folder') {
            readFolder($folder);
        }
        elsif (xml->name()->toString() eq 'bookmark') {
            readBookmark($folder);
        }
        elsif (xml->name()->toString() eq 'separator') {
            readSeparator($folder);
        }
        else {
            xml->skipCurrentElement();
        }
    }
}

sub readBookmark
{
    my ($item) = @_;
    if (!(xml->isStartElement() && xml->name()->toString eq 'bookmark')) {
        die;
    }

    my $bookmark = createChildItem($item);
    $bookmark->setFlags($bookmark->flags() | Qt::ItemIsEditable());
    $bookmark->setIcon(0, bookmarkIcon);
    $bookmark->setText(0, this->tr('Unknown title'));
    $bookmark->setText(1, xml->attributes()->value('href')->toString());

    while (xml->readNextStartElement()) {
        if (xml->name()->toString eq 'title') {
            readTitle($bookmark);
        }
        else {
            xml->skipCurrentElement();
        }
    }
}

sub createChildItem
{
    my ($item) = @_;
    my $childItem;
    if ($item) {
        $childItem = Qt::TreeWidgetItem($item);
    } else {
        $childItem = Qt::TreeWidgetItem(treeWidget);
    }
    $childItem->setData(0, Qt::UserRole(), Qt::Variant(xml->name()->toString()));
    return $childItem;
}

1;
