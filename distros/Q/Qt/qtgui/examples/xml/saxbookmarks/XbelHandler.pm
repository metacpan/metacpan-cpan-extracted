package XbelHandler;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXml4;
use QtCore4::isa qw( Qt::XmlDefaultHandler );

sub treeWidget() {
    return this->{treeWidget};
}

sub item() {
    return this->{item};
}

sub currentText() {
    return this->{currentText};
}

sub errorStr() {
    return this->{errorStr};
}

sub metXbelTag() {
    return this->{metXbelTag};
}

sub folderIcon() {
    return this->{folderIcon};
}

sub bookmarkIcon() {
    return this->{bookmarkIcon};
}

sub NEW {
    my ($class, $treeWidget) = @_;
    $class->SUPER::NEW();
    this->{treeWidget} = $treeWidget;
    this->{folderIcon} = Qt::Icon();
    this->{bookmarkIcon} = Qt::Icon();
    this->{item} = 0;
    this->{metXbelTag} = 0;

    my $style = treeWidget->style();

    folderIcon->addPixmap($style->standardPixmap(Qt::Style::SP_DirClosedIcon()),
                         Qt::Icon::Normal(), Qt::Icon::Off());
    folderIcon->addPixmap($style->standardPixmap(Qt::Style::SP_DirOpenIcon()),
                         Qt::Icon::Normal(), Qt::Icon::On());
    bookmarkIcon->addPixmap($style->standardPixmap(Qt::Style::SP_FileIcon()));
}

sub startElement
{
    my ($namespaceURI, $localName, $qName, $attributes) = @_;
    if (!metXbelTag && $qName ne 'xbel') {
        this->{errorStr} = Qt::Object::tr('The file is not an XBEL file.');
        return 0;
    }

    if ($qName eq 'xbel') {
        my $version = $attributes->value('version');
        if ($version && $version ne '1.0') {
            this->{errorStr} = Qt::Object::tr('The file is not an XBEL version 1.0 file.');
            return 0;
        }
        this->{metXbelTag} = 1;
    } elsif ($qName eq 'folder') {
        this->{item} = createChildItem($qName);
        item->setFlags(item->flags() | Qt::ItemIsEditable());
        item->setIcon(0, folderIcon);
        item->setText(0, Qt::Object::tr('Folder'));
        my $folded = ($attributes->value('folded') ne 'no');
        treeWidget->setItemExpanded(item, !$folded);
    } elsif ($qName eq 'bookmark') {
        this->{item} = createChildItem($qName);
        item->setFlags(item->flags() | Qt::ItemIsEditable());
        item->setIcon(0, bookmarkIcon);
        item->setText(0, Qt::Object::tr('Unknown title'));
        item->setText(1, $attributes->value('href'));
    } elsif ($qName eq 'separator') {
        this->{item} = createChildItem($qName);
        item->setFlags(item->flags() & ~Qt::ItemIsSelectable());
        item->setText(0, chr(0xB7) x 30);
    }

    this->{currentText} = '';
    return 1;
}

sub endElement
{
    my ($namespaceURI, $localName, $qName) = @_;
    if ($qName eq 'title') {
        if (item) {
            item->setText(0, currentText);
        }
    } elsif ($qName eq 'folder' || $qName eq 'bookmark'
               || $qName eq 'separator') {
        this->{item} = item->parent();
    }
    return 1;
}

sub characters
{
    my ($str) = @_;
    this->{currentText} .= $str;
    return 1;
}

sub fatalError
{
    my ($exception) = @_;
    Qt::MessageBox::information(treeWidget->window(), Qt::Object::tr('SAX Bookmarks'),
                             sprintf Qt::Object::tr("Parse error at line %d, column %d:\n%s"),
                             $exception->lineNumber(),
                             $exception->columnNumber(),
                             $exception->message());
    return 0;
}

sub errorString
{
    return errorStr;
}

sub createChildItem
{
    my ($tagName) = @_;
    my $childItem;
    if (item) {
        $childItem = Qt::TreeWidgetItem(item);
    } else {
        $childItem = Qt::TreeWidgetItem(treeWidget);
    }
    $childItem->setData(0, Qt::UserRole(), Qt::Variant($tagName));
    return $childItem;
}

1;
