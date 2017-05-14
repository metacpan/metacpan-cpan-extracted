package KALedMeter;

#/*
 #* KDE::Asteroids - Copyright (c) Martin R. Jones 1997
 #*
 #* Part of the KDE::DE project
 #*/


use strict;
use warnings;
use QtCore4;
use QtGui4;
use Qt3Support4;
use QtCore4::isa qw( Qt3::Frame );
use QtCore4::slots
    setValue => ['int'];

#struct ColorRange
#{
    #int mPc;
    #int mValue;
    #Qt::Color mColor;
#};

sub mRange() {
    return this->{mRange};
}

sub mCount() {
    return this->{mCount};
}

sub mCurrentCount() {
    return this->{mCurrentCount};
}

sub mValue() {
    return this->{mValue};
}

sub mCRanges() {
    return this->{mCRanges};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{mRange} = 100;
    this->{mCount} = 20;
    this->{mCurrentCount} = 0;
    this->{mValue} = 0;
    this->{mCRanges} = [];
    setMinimumWidth( mCount * 2 + frameWidth() );
}

sub setRange
{
    my ( $r ) = @_;
    this->{mRange} = $r;
    if ( mRange < 1 ) {
        this->{mRange} = 1;
    }
    setValue( mValue );
    update();
}

sub setCount
{
    my ( $c ) = @_;
    this->{mCount} = $c;
    if ( mCount < 1 ) {
        this->{mCount} = 1;
    }
    setMinimumWidth( mCount * 2 + frameWidth() );
    calcColorRanges();
    setValue( mValue );
    update();
}

sub setValue
{
    my ( $v ) = @_;
    this->{mValue} = $v;
    if ( mValue > mRange ) {
        this->{mValue} = mRange;
    }
    elsif ( mValue < 0 ) {
        this->{mValue} = 0;
    }
    my $c = ( mValue + mRange / mCount - 1 ) * mCount / mRange;
    if ( $c != mCurrentCount )
    {
        this->{mCurrentCount} = $c;
        update();
    }
}

sub addColorRange
{
    my ( $pc, $c ) = @_;
    my $cr = {
        mPc => $pc,
        mValue => undef,
        mColor => $c,
    };
    push @{mCRanges()}, $cr;
    calcColorRanges();
}

sub resizeEvent
{
    my ( $e ) = @_;
    this->SUPER::resizeEvent( $e );
    my $w = ( width() - frameWidth() - 2 ) / mCount * mCount;
    $w += frameWidth() + 2;
    setFrameRect( Qt::Rect( 0, 0, $w, height() ) );
}

sub drawContents
{
    my ( $p ) = @_;
    my $b = contentsRect();

    my $cidx = 0;
    my $ncol = mCount;
    my $col = colorGroup()->foreground();

    if ( scalar @{mCRanges()} )
    {
        $col = mCRanges()->[$cidx]->{mColor};
        $ncol = mCRanges()->[$cidx]->{mValue};
    }
    $p->setBrush( Qt::Brush(Qt::Color($col)) );
    $p->setPen( Qt::Pen(Qt::Color($col)) );

    my $lw = $b->width() / mCount;
    my $lx = $b->left() + 1;
    for ( my $i = 0; $i < mCurrentCount; $i++, $lx += $lw )
    {
        if ( $i > $ncol )
        {
            if ( ++$cidx < scalar @{mCRanges()} )
            {
                $col = mCRanges()->[$cidx]->{mColor};
                $ncol = mCRanges()->[$cidx]->{mValue};
                $p->setBrush( Qt::Brush(Qt::Color($col)) );
                $p->setPen( Qt::Pen(Qt::Color($col)) );
            }
        }

        $p->drawRect( int($lx), int($b->top() + 1), int($lw - 1), int($b->height() - 2) );
    }
}

sub calcColorRanges
{
    my $prev = 0;
    foreach my $cr ( @{mCRanges()} )
    {
        $cr->{mValue} = $prev + $cr->{mPc} * mCount / 100;
        $prev = $cr->{mValue};
    }
}

1;
