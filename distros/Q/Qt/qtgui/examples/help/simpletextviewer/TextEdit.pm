package TextEdit;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::TextEdit );

sub srcUrl() {
    return this->{srcUrl};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    setReadOnly(1);
}

sub setContents
{
    my ($fileName) = @_;
    my $fi = Qt::FileInfo($fileName);
    this->{srcUrl} = Qt::Url::fromLocalFile($fi->absoluteFilePath());
    my $file = Qt::File($fileName);
    if ($file->open(Qt::IODevice::ReadOnly())) {
        my $data = $file->readAll();
        if ($fileName =~ m/\.html$/) {
            setHtml($data->constData());
        }
        else {
            setPlainText($data->constData());
        }
    }
}

sub loadResource
{
    my ($type, $name) = @_;
    if ($type == Qt::TextDocument::ImageResource()) {
        my $file = Qt::File(srcUrl->resolved($name)->toLocalFile());
        if ($file->open(Qt::IODevice::ReadOnly())) {
            return Qt::Variant($file->readAll());
        }
    }
    return this->SUPER::loadResource($type, $name);
}

1;
