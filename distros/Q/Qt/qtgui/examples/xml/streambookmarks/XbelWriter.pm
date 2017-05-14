package XbelWriter;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Object);

sub xml() {
    return this->{xml};
}

sub treeWidget() {
    return this->{treeWidget};
}

# [0]
sub NEW
{
    my ($class, $treeWidget) = @_;
    $class->SUPER::NEW();
    this->{treeWidget} = $treeWidget;
    this->{xml} = Qt::XmlStreamWriter();
    xml->setAutoFormatting(1);
}
# [0]

# [1]
sub writeFile
{
    my ($device) = @_;
    xml->setDevice($device);

    xml->writeStartDocument();
    xml->writeDTD('<!DOCTYPE xbel>');
    xml->writeStartElement('xbel');
    xml->writeAttribute('version', '1.0');
    for (my $i = 0; $i < treeWidget->topLevelItemCount(); ++$i) {
        writeItem(treeWidget->topLevelItem($i));
    }

    xml->writeEndDocument();
    return 1;
}
# [1]

# [2]
sub writeItem
{
    my ($item) = @_;
    my $tagName = $item->data(0, Qt::UserRole())->toString();
    if ($tagName eq 'folder') {
        my $folded = !treeWidget->isItemExpanded($item);
        xml->writeStartElement($tagName);
        xml->writeAttribute('folded', $folded ? 'yes' : 'no');
        xml->writeTextElement('title', $item->text(0));
        for (my $i = 0; $i < $item->childCount(); ++$i) {
            writeItem($item->child($i));
        }
        xml->writeEndElement();
    } elsif ($tagName eq 'bookmark') {
        xml->writeStartElement($tagName);
        if ($item->text(1)) {
            xml->writeAttribute('href', $item->text(1));
        }
        xml->writeTextElement('title', $item->text(0));
        xml->writeEndElement();
    } elsif ($tagName eq 'separator') {
        xml->writeEmptyElement($tagName);
    }
}
# [2]

1;
