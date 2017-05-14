package XbelGenerator;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Object);

sub treeWidget() {
    return this->{treeWidget};
}

sub out() {
    return this->{out};
}

sub NEW
{
    my ($class, $treeWidget) = @_;
    $class->SUPER::NEW();
    this->{treeWidget} = $treeWidget;
    this->{out} = Qt::TextStream();
}

sub write
{
    my ($device) = @_;
    out->setDevice($device);
    out->setCodec('UTF-8');
    no warnings 'void';
    out << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    out << "<!DOCTYPE xbel>\n";
    out << "<xbel version=\"1.0\">\n";
    use warnings;

    for (my $i = 0; $i < treeWidget->topLevelItemCount(); ++$i) {
        generateItem(treeWidget->topLevelItem($i), 1);
    }

    no warnings 'void';
    out << "</xbel>\n";
    use warnings;
    return 1;
}

sub indent
{
    my ($depth) = @_;
    my $IndentSize = 4;
    return ' ' x ($IndentSize * $depth);
}

sub escapedText
{
    my ($str) = @_;
    my $result = $str;
    $result =~ s/&/&amp;/g;
    $result =~ s/</&lt;/g;
    $result =~ s/>/&gt;/g;
    return $result;
}

sub escapedAttribute
{
    my ($str) = @_;
    my $result = escapedText($str);
    $result =~ s/"/&quot;/g;
    $result = "\"$result\"";
    return $result;
}

sub generateItem
{
    my ($item, $depth) = @_;
    my $tagName = $item->data(0, Qt::UserRole())->toString();
    no warnings 'void';
    if ($tagName eq 'folder') {
        my $folded = !treeWidget->isItemExpanded($item);
        out << indent($depth) . '<folder folded="' . ($folded ? 'yes' : 'no')
                             . "\">\n"
            . indent($depth + 1) . '<title>' . escapedText($item->text(0))
                                 . "</title>\n";

        for (my $i = 0; $i < $item->childCount(); ++$i) {
            generateItem($item->child($i), $depth + 1);
        }

        out << indent($depth) . "</folder>\n";
    } elsif ($tagName eq 'bookmark') {
        out << indent($depth) . '<bookmark';
        if ($item->text(1)) {
            out << ' href=' . escapedAttribute($item->text(1));
        }
        out << ">\n"
            . indent($depth + 1) . '<title>' . escapedText($item->text(0))
                                 . "</title>\n"
            . indent($depth) . "</bookmark>\n";
    } elsif ($tagName eq 'separator') {
        out << indent($depth) . "<separator/>\n";
    }
    use warnings;
}

1;
