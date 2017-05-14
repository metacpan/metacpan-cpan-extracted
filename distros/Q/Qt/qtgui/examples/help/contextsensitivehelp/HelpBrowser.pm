package HelpBrowser;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtHelp4;

use QtCore4::isa qw( Qt::TextBrowser );

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);

    my $collectionFile = Qt::LibraryInfo::location(Qt::LibraryInfo::ExamplesPath())
        . '/help/contextsensitivehelp/doc/wateringmachine.qhc';

    this->{m_helpEngine} = Qt::HelpEngineCore($collectionFile, this);
    if (!this->{m_helpEngine}->setupData()) {
        this->{m_helpEngine} = 0;
    }
}

sub showHelpForKeyword
{
    my ($id) = @_;
    if (this->{m_helpEngine}) {
        my $links = this->{m_helpEngine}->linksForIdentifier($id);
        if ($links && ref $links eq 'HASH') {
            this->setSource((values %{$links})[0]);
        }
    }
}

sub loadResource
{
    my ($type, $name) = @_;
    my $ba = Qt::ByteArray();
    if ($type < 4 && this->{m_helpEngine}) {
        my $url = Qt::Url($name);
        if ($name->isRelative()) {
            $url = this->source()->resolved($url);
        }
        $ba = this->{m_helpEngine}->fileData($url);
    }
    return Qt::Variant($ba);
}

1;
