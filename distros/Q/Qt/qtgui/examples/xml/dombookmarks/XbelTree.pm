package XbelTree;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXml4;
use QtCore4::isa qw( Qt::TreeWidget );
use QtCore4::slots
    updateDomElement => ['QTreeWidgetItem *', 'int'];

sub domDocument() {
    return this->{domDocument};
}

sub domElementForItem() {
    return this->{domElementForItem};
}

sub folderIcon() {
    return this->{folderIcon};
}

sub bookmarkIcon() {
    return this->{bookmarkIcon};
}

sub NEW
{
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW($parent);
    my @labels = ( this->tr('Title'), this->tr('Location') );

    header()->setResizeMode(Qt::HeaderView::Stretch());
    setHeaderLabels(\@labels);

    this->{domDocument} = Qt::DomDocument();
    this->{domElementForItem} = {};
    this->{folderIcon} = Qt::Icon();
    this->{bookmarkIcon} = Qt::Icon();
    folderIcon->addPixmap(style()->standardPixmap(Qt::Style::SP_DirClosedIcon()),
                         Qt::Icon::Normal(), Qt::Icon::Off());
    folderIcon->addPixmap(style()->standardPixmap(Qt::Style::SP_DirOpenIcon()),
                         Qt::Icon::Normal(), Qt::Icon::On());
    bookmarkIcon->addPixmap(style()->standardPixmap(Qt::Style::SP_FileIcon()));
}

sub read
{
    my ($device) = @_;
    my $errorStr;
    my $errorLine;
    my $errorColumn;

    if (!domDocument->setContent($device, 1, \$errorStr, \$errorLine,
                                \$errorColumn)) {
        Qt::MessageBox::information(window(), this->tr('DOM Bookmarks'),
                                 sprintf this->tr('Parse error at line %s, column %s:\n%s'),
                                 $errorLine,
                                 $errorColumn,
                                 $errorStr);
        return 0;
    }

    my $root = domDocument->documentElement();
    if ($root->tagName() ne 'xbel') {
        Qt::MessageBox::information(window(), this->tr('DOM Bookmarks'),
                                 this->tr('The file is not an XBEL file.'));
        return 0;
    } elsif ($root->hasAttribute('version')
               && $root->attribute('version') ne '1.0') {
        Qt::MessageBox::information(window(), this->tr('DOM Bookmarks'),
                                 this->tr('The file is not an XBEL version 1.0 '.
                                    'file.'));
        return 0;
    }

    clear();

    this->disconnect(this, SIGNAL 'itemChanged(QTreeWidgetItem*,int)',
               this, SLOT 'updateDomElement(QTreeWidgetItem*,int)');

    my $child = $root->firstChildElement('folder');
    while (!$child->isNull()) {
        parseFolderElement($child);
        $child = $child->nextSiblingElement('folder');
    }

    this->connect(this, SIGNAL 'itemChanged(QTreeWidgetItem*,int)',
            this, SLOT 'updateDomElement(QTreeWidgetItem*,int)');

    return 1;
}

sub write
{
    my ($device) = @_;
    my $IndentSize = 4;

    my $out = Qt::TextStream($device);
    domDocument->save($out, $IndentSize);
    return 1;
}

sub updateDomElement
{
    my ($item, $column) = @_;
    # We must use some unique identifier that is compatible with perl hashes.
    my $id = indexFromItem($item)->internalId();
    my $element = domElementForItem->{$id};
    if ($element && !$element->isNull()) {
        if ($column == 0) {
            my $oldTitleElement = $element->firstChildElement('title');
            my $newTitleElement = domDocument->createElement('title');

            my $newTitleText = domDocument->createTextNode($item->text(0));
            $newTitleElement->appendChild($newTitleText);

            $element->replaceChild($newTitleElement, $oldTitleElement);
        } else {
            if ($element->tagName() eq 'bookmark') {
                $element->setAttribute('href', $item->text(1));
            }
        }
    }
}

sub parseFolderElement
{
    my ($element, $parentItem) = @_;
    my $item = createItem($element, $parentItem);

    my $title = $element->firstChildElement('title')->text();
    if (!$title) {
        $title = Qt::Object::this->tr('Folder');
    }

    $item->setFlags($item->flags() | Qt::ItemIsEditable());
    $item->setIcon(0, folderIcon);
    $item->setText(0, $title);

    my $folded = $element->attribute('folded') ne 'no';
    setItemExpanded($item, !$folded);

    my $child = $element->firstChildElement();
    while (!$child->isNull()) {
        if ($child->tagName() eq 'folder') {
            parseFolderElement($child, $item);
        } elsif ($child->tagName() eq 'bookmark') {
            my $childItem = createItem($child, $item);

            my $title = $child->firstChildElement('title')->text();
            if (!$title) {
                $title = Qt::Object::this->tr('Folder');
            }

            $childItem->setFlags($item->flags() | Qt::ItemIsEditable());
            $childItem->setIcon(0, bookmarkIcon);
            $childItem->setText(0, $title);
            $childItem->setText(1, $child->attribute('href'));
        } elsif ($child->tagName() eq 'separator') {
            my $childItem = createItem($child, $item);
            $childItem->setFlags($item->flags() & ~(Qt::ItemIsSelectable() | Qt::ItemIsEditable()));
            $childItem->setText(0, chr(0xB7) x 30);
        }
        $child = $child->nextSiblingElement();
    }
}

sub createItem
{
    my ($element, $parentItem) = @_;
    my $item;
    if ($parentItem) {
        $item = Qt::TreeWidgetItem($parentItem);
    } else {
        $item = Qt::TreeWidgetItem(this);
    }
    # We must use some unique identifier that is compatible with perl hashes.
    my $id = indexFromItem($item)->internalId();
    domElementForItem->{$id} = $element;
    return $item;
}

1;
