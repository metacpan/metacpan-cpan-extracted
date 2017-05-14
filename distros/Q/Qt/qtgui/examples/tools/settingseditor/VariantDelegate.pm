package VariantDelegate;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::ItemDelegate );
use List::Util qw( min );

sub boolExp() {
    return this->{boolExp};
}

sub byteArrayExp() {
    return this->{byteArrayExp};
}

sub charExp() {
    return this->{charExp};
}

sub colorExp() {
    return this->{colorExp};
}

sub dateExp() {
    return this->{dateExp};
}

sub dateTimeExp() {
    return this->{dateTimeExp};
}

sub doubleExp() {
    return this->{doubleExp};
}

sub pointExp() {
    return this->{pointExp};
}

sub rectExp() {
    return this->{rectExp};
}

sub signedIntegerExp() {
    return this->{signedIntegerExp};
}

sub sizeExp() {
    return this->{sizeExp};
}

sub timeExp() {
    return this->{timeExp};
}

sub unsignedIntegerExp() {
    return this->{unsignedIntegerExp};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);

    this->{boolExp} = Qt::RegExp();
    this->{byteArrayExp} = Qt::RegExp();
    this->{charExp} = Qt::RegExp();
    this->{colorExp} = Qt::RegExp();
    this->{dateExp} = Qt::RegExp();
    this->{dateTimeExp} = Qt::RegExp();
    this->{doubleExp} = Qt::RegExp();
    this->{pointExp} = Qt::RegExp();
    this->{rectExp} = Qt::RegExp();
    this->{signedIntegerExp} = Qt::RegExp();
    this->{timeExp} = Qt::RegExp();
    this->{unsignedIntegerExp} = Qt::RegExp();

    boolExp->setPattern('true|false');
    boolExp->setCaseSensitivity(Qt::CaseInsensitive());

    byteArrayExp->setPattern('[\\x00-\\xff]*');
    charExp->setPattern('.');
    colorExp->setPattern('\\(([0-9]*),([0-9]*),([0-9]*),([0-9]*)\\)');
    doubleExp->setPattern('');
    pointExp->setPattern('\\((-?[0-9]*),(-?[0-9]*)\\)');
    rectExp->setPattern('\\((-?[0-9]*),(-?[0-9]*),(-?[0-9]*),(-?[0-9]*)\\)');
    signedIntegerExp->setPattern('-?[0-9]*');
    this->{sizeExp} = Qt::RegExp(pointExp);
    unsignedIntegerExp->setPattern('[0-9]*');

    dateExp->setPattern('([0-9]{,4})-([0-9]{,2})-([0-9]{,2})');
    timeExp->setPattern('([0-9]{,2}):([0-9]{,2}):([0-9]{,2})');
    dateTimeExp->setPattern(dateExp->pattern() . 'T' . timeExp->pattern());
}

sub paint
{
    my ($painter, $option, $index) = @_;
    if ($index->column() == 2) {
        my $value = $index->model()->data($index, Qt::UserRole());
        if (!isSupportedType($value->type())) {
            my $myOption = $option;
            $myOption->setState( $myOption->state & ~Qt::Style::State_Enabled() );
            this->SUPER::paint($painter, $myOption, $index);
            return;
        }
    }

    this->SUPER::paint($painter, $option, $index);
}

sub createEditor
{
    my ($parent, $option, $index) = @_;
    if ($index->column() != 2) {
        return undef;
    }

    my $originalValue = $index->model()->data($index, Qt::UserRole());
    if (!isSupportedType($originalValue->type())) {
        return undef;
    }

    my $lineEdit = Qt::LineEdit($parent);
    $lineEdit->setFrame(0);

    my $regExp;

    if ( $originalValue->type() == Qt::Variant::Bool() ) {
        $regExp = boolExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::ByteArray() ) {
        $regExp = byteArrayExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Char() ) {
        $regExp = charExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Color() ) {
        $regExp = colorExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Date() ) {
        $regExp = dateExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::DateTime() ) {
        $regExp = dateTimeExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Double() ) {
        $regExp = doubleExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Int() ||
         $originalValue->type() == Qt::Variant::LongLong() ) {
        $regExp = signedIntegerExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Point() ) {
        $regExp = pointExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Rect() ) {
        $regExp = rectExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Size() ) {
        $regExp = sizeExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::Time() ) {
        $regExp = timeExp;
    }
    elsif ( $originalValue->type() == Qt::Variant::UInt()
        || $originalValue->type() == Qt::Variant::ULongLong() ) {
        $regExp = unsignedIntegerExp;
    }

    if ($regExp) {
        my $validator = Qt::RegExpValidator($regExp, $lineEdit);
        $lineEdit->setValidator($validator);
    }

    return $lineEdit;
}

sub setEditorData
{
    my ($editor, $index) = @_;
    my $value = $index->model()->data($index, Qt::UserRole());
    my $lineEdit = $editor;
    if ($lineEdit->isa('Qt::LineEdit')) {
        $lineEdit->setText(displayText($value));
    }
}

sub setModelData
{
    my ($editor, $model, $index) = @_;
    my $lineEdit = $editor;
    if ($lineEdit->isa('Qt::LineEdit') && !$lineEdit->isModified()) {
        return;
    }

    my $text = $lineEdit->text();
    $DB::single=1;
    my $validator = $lineEdit->validator();
    if ($validator) {
        my $pos;
        if ($validator->validate($text, $pos) != Qt::Validator::Acceptable()) {
            return;
        }
    }

    my $originalValue = $index->model()->data($index, Qt::UserRole());
    my $value;

    if ( $originalValue->type() == Qt::Variant::Char() ) {
        $value = Qt::Variant( Qt::Char( substr $text, 0, 1 ) );
    }
    elsif ( $originalValue->type() == Qt::Variant::Color() ) {
        colorExp->exactMatch($text);
        $value = Qt::Variant( Qt::Color(min(colorExp->cap(1), 255),
                       min(colorExp->cap(2), 255),
                       min(colorExp->cap(3), 255),
                       min(colorExp->cap(4), 255)) );
    }
    elsif ( $originalValue->type() == Qt::Variant::Date() ) {
        my $date = Qt::Date::fromString($text, Qt::ISODate());
        if (!$date->isValid()) {
            return;
        }
        $value = Qt::Variant( $date );
    }
    elsif ( $originalValue->type() == Qt::Variant::DateTime() ) {
        my $dateTime = Qt::DateTime::fromString($text, Qt::ISODate());
        if (!$dateTime->isValid()) {
            return;
        }
        $value = Qt::Variant( $dateTime );
    }
    elsif ( $originalValue->type() == Qt::Variant::Point() ) {
        pointExp->exactMatch($text);
        $value = Qt::Variant( Qt::Point(pointExp->cap(1), pointExp->cap(2)) );
    }
    elsif ( $originalValue->type() == Qt::Variant::Rect() ) {
        rectExp->exactMatch($text);
        $value = Qt::Variant( Qt::Rect(rectExp->cap(1), rectExp->cap(2),
                      rectExp->cap(3), rectExp->cap(4)) );
    }
    elsif ( $originalValue->type() == Qt::Variant::Size() ) {
        sizeExp->exactMatch($text);
        $value = Qt::Variant( Qt::Size(sizeExp->cap(1), sizeExp->cap(2)) );
    }
    elsif ( $originalValue->type() == Qt::Variant::StringList() ) {
        $value = Qt::Variant( [split m/,/, $text] );
    }
    elsif ( $originalValue->type() == Qt::Variant::Time() ) {
        my $time = Qt::Time::fromString($text, Qt::ISODate());
        if (!$time->isValid()) {
            return;
        }
        $value = Qt::Variant( $time );
    }
    else {
        $value = Qt::Variant( Qt::String( $text ) );
        $value->convert($originalValue->type());
    }

    $model->setData($index, Qt::Variant(Qt::String(displayText($value))), Qt::DisplayRole());
    $model->setData($index, $value, Qt::UserRole());
}

sub isSupportedType
{
    my ($type) = @_;
    if ( $type == Qt::Variant::Bool() ||
        $type == Qt::Variant::ByteArray() ||
        $type == Qt::Variant::Char() ||
        $type == Qt::Variant::Color() ||
        $type == Qt::Variant::Date() ||
        $type == Qt::Variant::DateTime() ||
        $type == Qt::Variant::Double() ||
        $type == Qt::Variant::Int() ||
        $type == Qt::Variant::LongLong() ||
        $type == Qt::Variant::Point() ||
        $type == Qt::Variant::Rect() ||
        $type == Qt::Variant::Size() ||
        $type == Qt::Variant::String() ||
        $type == Qt::Variant::StringList() ||
        $type == Qt::Variant::Time() ||
        $type == Qt::Variant::UInt() ||
        $type == Qt::Variant::ULongLong() ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub displayText
{
    my ($value) = @_;
    if ( $value->type() == Qt::Variant::Bool() ||
        $value->type() == Qt::Variant::ByteArray() ||
        $value->type() == Qt::Variant::Char() ||
        $value->type() == Qt::Variant::Double() ||
        $value->type() == Qt::Variant::Int() ||
        $value->type() == Qt::Variant::LongLong() ||
        $value->type() == Qt::Variant::String() ||
        $value->type() == Qt::Variant::UInt() ||
        $value->type() == Qt::Variant::ULongLong() ) {
        return $value->toString();
    }
    elsif( $value->type() == Qt::Variant::Color() ) {
        my $color = $value->value();
        return Qt::String('(%1,%2,%3,%4)')
               ->arg($color->red())->arg($color->green())
               ->arg($color->blue())->arg($color->alpha());
    }
    elsif( $value->type() == Qt::Variant::Date() ) {
        return $value->toDate()->toString(Qt::ISODate());
    }
    elsif( $value->type() == Qt::Variant::DateTime() ) {
        return $value->toDateTime()->toString(Qt::ISODate());
    }
    elsif( $value->type() == Qt::Variant::Invalid() ) {
        return '<Invalid>';
    }
    elsif( $value->type() == Qt::Variant::Point() ) {
        my $point = $value->toPoint();
        return Qt::String('(%1,%2)')->arg($point->x())->arg($point->y());
    }
    elsif( $value->type() == Qt::Variant::Rect() ) {
        my $rect = $value->toRect();
        return Qt::String('(%1,%2,%3,%4)')
               ->arg($rect->x())->arg($rect->y())
               ->arg($rect->width())->arg($rect->height());
    }
    elsif( $value->type() == Qt::Variant::Size() ) {
        my $size = $value->toSize();
        return Qt::String('(%1,%2)')->arg($size->width())->arg($size->height());
    }
    elsif( $value->type() == Qt::Variant::StringList() ) {
        return join ',', @{$value->toStringList()};
    }
    elsif( $value->type() == Qt::Variant::Time() ) {
        return $value->toTime()->toString(Qt::ISODate());
    }
    else {
    }
    return Qt::String('<%1>')->arg($value->typeName());
}

1;
