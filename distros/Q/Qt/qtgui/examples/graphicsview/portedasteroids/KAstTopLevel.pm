package KAstTopLevel;

=begin

 * KAsteroids - Copyright (c) Martin R. Jones 1997
 *
 * Part of the KDE::DE project

=cut

use strict;
use warnings;

use QtCore4;
use QtGui4;
use Qt3Support4;
use QtCore4::isa qw( Qt3::MainWindow );
use QtCore4::slots
    slotNewGame => [],
    slotShipKilled => [],
    slotRockHit => ['int'],
    slotRocksRemoved => [],
    slotUpdateVitals => [];
use KAsteroidsView;
use KALedMeter;

sub view() {
    return this->{view};
}

sub scoreLCD() {
    return this->{scoreLCD};
}

sub levelLCD() {
    return this->{levelLCD};
}

sub shipsLCD() {
    return this->{shipsLCD};
}

sub teleportsLCD() {
    return this->{teleportsLCD};
}

sub brakesLCD() {
    return this->{brakesLCD};
}

sub shieldLCD() {
    return this->{shieldLCD};
}

sub shootLCD() {
    return this->{shootLCD};
}

sub powerMeter() {
    return this->{powerMeter};
}

sub sound() {
    return this->{sound};
}

sub soundDict() {
    return this->{soundDict};
}

sub waitShip() {
    # waiting for user to press Enter to launch a ship
    return this->{waitShip};
}

sub isPaused() {
    return this->{isPaused};
}

sub shipsRemain() {
    return this->{shipsRemain};
}

sub score() {
    return this->{score};
}

sub level() {
    return this->{level};
}

sub showHiscores() {
    return this->{showHiscores};
}

sub actions() {
    return this->{actions};
}

use constant {
    Launch => 1,
    Thrust => 2,
    RotateLeft => 3,
    RotateRight => 4,
    Shoot => 5,
    Teleport => 6,
    Brake => 7,
    Shield => 8,
    Pause => 9,
    NewGame => 10,
    SB_SCORE => 1,
    SB_LEVEL => 2,
    SB_SHIPS => 3,
    MAX_LEVELS => 16
};

#struct SLevel
#{
    #int    nrocks;
    #double rockSpeed;
#};


my $levels =
[
    {
        nrocks => 1,
        rockSpeed => 0.4,
    },
    {
        nrocks => 1,
        rockSpeed => 0.6,
    },
    {
        nrocks => 2,
        rockSpeed => 0.5,
    },
    {
        nrocks => 2,
        rockSpeed => 0.7,
    },
    {
        nrocks => 2,
        rockSpeed => 0.8,
    },
    {
        nrocks => 3,
        rockSpeed => 0.6,
    },
    {
        nrocks => 3,
        rockSpeed => 0.7,
    },
    {
        nrocks => 3,
        rockSpeed => 0.8,
    },
    {
        nrocks => 4,
        rockSpeed => 0.6,
    },
    {
        nrocks => 4,
        rockSpeed => 0.7,
    },
    {
        nrocks => 4,
        rockSpeed => 0.8,
    },
    {
        nrocks => 5,
        rockSpeed => 0.7,
    },
    {
        nrocks => 5,
        rockSpeed => 0.8,
    },
    {
        nrocks => 5,
        rockSpeed => 0.9,
    },
    {
        nrocks => 5,
        rockSpeed => 1.0,
    },
];

#const char *soundEvents[] =
#{
    #'ShipDestroyed',
    #'RockDestroyed',
    #0
#};

#const char *soundDefaults[] =
#{
    #'Explosion.wav',
    #'ploop.wav',
    #0
#};


sub NEW
{
    my ( $class, $parent, $name ) = @_;
    $class->SUPER::NEW( $parent, $name, 0 );
    this->{actions} = [];
    my $border = Qt::Widget( this );
    $border->setBackgroundColor( Qt::Color(Qt::black()) );
    setCentralWidget( $border );

    my $borderLayout = Qt3::VBoxLayout( $border );
    $borderLayout->addStretch( 1 );

    my $mainWin = Qt::Widget( $border );
    $mainWin->setFixedSize(640, 480);
    $borderLayout->addWidget( $mainWin, 0, Qt::AlignHCenter() );

    $borderLayout->addStretch( 1 );

    this->{view} = KAsteroidsView( $mainWin );
    view->setFocusPolicy( Qt::StrongFocus() );
    this->connect( view, SIGNAL 'shipKilled()', SLOT 'slotShipKilled()' );
    this->connect( view, SIGNAL 'rockHit(int)', SLOT 'slotRockHit(int)' );
    this->connect( view, SIGNAL 'rocksRemoved()', SLOT 'slotRocksRemoved()' );
    this->connect( view, SIGNAL 'updateVitals()', SLOT 'slotUpdateVitals()' );

    my $vb = Qt3::VBoxLayout( $mainWin );
    my $hb = Qt3::HBoxLayout();
    my $hbd = Qt3::HBoxLayout();
    $vb->addLayout( $hb );

    my $labelFont = Qt::Font( 'helvetica', 24 );
    my $grp = Qt::ColorGroup( Qt::Color(Qt::darkGreen()), Qt::Color(Qt::black()), Qt::Color( 128, 128, 128 ),
	    Qt::Color( 64, 64, 64 ), Qt::Color(Qt::black()), Qt::Color(Qt::darkGreen()), Qt::Color(Qt::black()) );
    my $pal = Qt::Palette( $grp, $grp, $grp );

    $mainWin->setPalette( $pal );

    $hb->addSpacing( 10 );

    my $label = Qt::Label( this->tr('Score'), $mainWin );
    $label->setFont( $labelFont );
    $label->setPalette( $pal );
    $label->setFixedWidth( $label->sizeHint()->width() );
    $hb->addWidget( $label );

    this->{scoreLCD} = Qt::LCDNumber( 6, $mainWin );
    scoreLCD->setFrameStyle( Qt3::Frame::NoFrame() );
    scoreLCD->setSegmentStyle( Qt::LCDNumber::Flat() );
    scoreLCD->setFixedWidth( 150 );
    scoreLCD->setPalette( $pal );
    $hb->addWidget( scoreLCD );
    $hb->addStretch( 10 );

    $label = Qt::Label( this->tr('Level'), $mainWin );
    $label->setFont( $labelFont );
    $label->setPalette( $pal );
    $label->setFixedWidth( $label->sizeHint()->width() );
    $hb->addWidget( $label );

    this->{levelLCD} = Qt::LCDNumber( 2, $mainWin );
    levelLCD->setFrameStyle( Qt3::Frame::NoFrame() );
    levelLCD->setSegmentStyle( Qt::LCDNumber::Flat() );
    levelLCD->setFixedWidth( 70 );
    levelLCD->setPalette( $pal );
    $hb->addWidget( levelLCD );
    $hb->addStretch( 10 );

    $label = Qt::Label( this->tr('Ships'), $mainWin );
    $label->setFont( $labelFont );
    $label->setFixedWidth( $label->sizeHint()->width() );
    $label->setPalette( $pal );
    $hb->addWidget( $label );

    this->{shipsLCD} = Qt::LCDNumber( 1, $mainWin );
    shipsLCD->setFrameStyle( Qt3::Frame::NoFrame() );
    shipsLCD->setSegmentStyle( Qt::LCDNumber::Flat() );
    shipsLCD->setFixedWidth( 40 );
    shipsLCD->setPalette( $pal );
    $hb->addWidget( shipsLCD );

    $hb->addStrut( 30 );

    $vb->addWidget( view, 10 );

# -- bottom layout:
    $vb->addLayout( $hbd );

    my $smallFont = Qt::Font( 'helvetica', 14 );
    $hbd->addSpacing( 10 );

    my $sprites_prefix = ':/trolltech/examples/graphicsview/portedasteroids/sprites/';

    #label = new Qt::Label( this->tr( 'T' ), mainWin );
    #label->setFont( smallFont );
    #label->setFixedWidth( label->sizeHint().width() );
    #label->setPalette( pal );
    #hbd->addWidget( label );

    #teleportsLCD = new Qt::LCDNumber( 1, mainWin );
    #teleportsLCD->setFrameStyle( Qt::Frame::NoFrame );
    #teleportsLCD->setSegmentStyle( Qt::LCDNumber::Flat );
    #teleportsLCD->setPalette( pal );
    #teleportsLCD->setFixedHeight( 20 );
    #hbd->addWidget( teleportsLCD );

    #hbd->addSpacing( 10 );

    my $pm = Qt::Pixmap( $sprites_prefix . 'powerups/brake.png' );
    $label = Qt::Label( $mainWin );
    $label->setPixmap( $pm );
    $label->setFixedWidth( $label->sizeHint()->width() );
    $label->setPalette( $pal );
    $hbd->addWidget( $label );

    this->{brakesLCD} = Qt::LCDNumber( 1, $mainWin );
    brakesLCD->setFrameStyle( Qt3::Frame::NoFrame() );
    brakesLCD->setSegmentStyle( Qt::LCDNumber::Flat() );
    brakesLCD->setPalette( $pal );
    brakesLCD->setFixedHeight( 20 );
    $hbd->addWidget( brakesLCD );

    $hbd->addSpacing( 10 );

    $pm->load( $sprites_prefix . 'powerups/shield.png' );
    $label = Qt::Label( $mainWin );
    $label->setPixmap( $pm );
    $label->setFixedWidth( $label->sizeHint()->width() );
    $label->setPalette( $pal );
    $hbd->addWidget( $label );

    this->{shieldLCD} = Qt::LCDNumber( 1, $mainWin );
    shieldLCD->setFrameStyle( Qt3::Frame::NoFrame() );
    shieldLCD->setSegmentStyle( Qt::LCDNumber::Flat() );
    shieldLCD->setPalette( $pal );
    shieldLCD->setFixedHeight( 20 );
    $hbd->addWidget( shieldLCD );

    $hbd->addSpacing( 10 );

    $pm->load( $sprites_prefix . 'powerups/shoot.png' );
    $label = Qt::Label( $mainWin );
    $label->setPixmap( $pm );
    $label->setFixedWidth( $label->sizeHint()->width() );
    $label->setPalette( $pal );
    $hbd->addWidget( $label );

    this->{shootLCD} = Qt::LCDNumber( 1, $mainWin );
    shootLCD->setFrameStyle( Qt3::Frame::NoFrame() );
    shootLCD->setSegmentStyle( Qt::LCDNumber::Flat() );
    shootLCD->setPalette( $pal );
    shootLCD->setFixedHeight( 20 );
    $hbd->addWidget( shootLCD );

    $hbd->addStretch( 1 );

    $label = Qt::Label( this->tr( 'Fuel' ), $mainWin );
    $label->setFont( $smallFont );
    $label->setFixedWidth( $label->sizeHint()->width() + 10 );
    $label->setPalette( $pal );
    $hbd->addWidget( $label );

    this->{powerMeter} = KALedMeter( $mainWin );
    powerMeter->setFrameStyle( Qt3::Frame::Box() | Qt3::Frame::Plain() );
    powerMeter->setRange( KAsteroidsView::MAX_POWER_LEVEL() );
    powerMeter->addColorRange( 10, Qt::darkRed() );
    powerMeter->addColorRange( 20, Qt::Color(160, 96, 0) );
    powerMeter->addColorRange( 70, Qt::darkGreen() );
    powerMeter->setCount( 40 );
    powerMeter->setPalette( $pal );
    powerMeter->setFixedSize( 200, 12 );
    $hbd->addWidget( powerMeter );

    this->{shipsRemain} = 3;
    this->{showHiscores} = 0;

    this->{actions} = {};
    this->{actions}->{${Qt::Key_Up()}} = Thrust;
    this->{actions}->{${Qt::Key_Left()}} = RotateLeft;
    this->{actions}->{${Qt::Key_Right()}} = RotateRight;
    this->{actions}->{${Qt::Key_Space()}} = Shoot;
    this->{actions}->{${Qt::Key_Z()}} = Teleport;
    this->{actions}->{${Qt::Key_X()}} = Brake;
    this->{actions}->{${Qt::Key_S()}} = Shield;
    this->{actions}->{${Qt::Key_P()}} = Pause;
    this->{actions}->{${Qt::Key_L()}} = Launch;
    this->{actions}->{${Qt::Key_N()}} = NewGame;

    view->showText( this->tr( 'Press N to start playing' ), Qt::Color(Qt::yellow()) );
}

sub playSound
{
}

sub keyPressEvent
{
    my ( $event ) = @_; 
    if ( $event->isAutoRepeat() || !defined actions->{$event->key()} )
    {
        $event->ignore();
        return;
    }

    my $a = actions->{ $event->key() };

    if( $a == RotateLeft ) {
        view->rotateLeft( 1 );
    }
    elsif( $a == RotateRight ) {
        view->rotateRight( 1 );
    }
    elsif( $a == Thrust ) {
        view->thrust( 1 );
    }
    elsif( $a == Shoot ) {
        view->shoot( 1 );
    }
    elsif( $a == Shield ) {
        view->setShield( 1 );
    }
    elsif( $a == Teleport ) {
        view->teleport( 1 );
    }
    elsif( $a == Brake ) {
        view->brake( 1 );
    }
    else {
        $event->ignore();
        return;
    }
    $event->accept();
}

sub keyReleaseEvent
{
    my ( $event ) = @_;
    if ( $event->isAutoRepeat() || !defined actions->{$event->key()} )
    {
        $event->ignore();
        return;
    }

    my $a = actions->{ $event->key() };

    if( $a == RotateLeft ) {
        view->rotateLeft( 0 );
    }

    elsif( $a == RotateRight ) {
        view->rotateRight( 0 );
    }

    elsif( $a == Thrust ) {
        view->thrust( 0 );
    }

    elsif( $a == Shoot ) {
        view->shoot( 0 );
    }

    elsif( $a == Brake ) {
        view->brake( 0 );
    }

    elsif( $a == Shield ) {
        view->setShield( 0 );
    }

    elsif( $a == Teleport ) {
        view->teleport( 0 );
    }

    elsif( $a == Launch ) {
        if ( waitShip )
        {
            view->newShip();
            this->{waitShip} = 0;
            view->hideText();
        }
        else
        {
            $event->ignore();
            return;
        }
    }

    elsif( $a == NewGame ) {
        slotNewGame();
    }

    #elsif( $a == Pause ) {
        #{
            #view->pause( 1 );
            #Qt::MessageBox::information( this,
                                      #this->tr('KAsteroids is paused'),
                                      #this->tr('Paused') );
            #view->pause( 0 );
        #}
    #}

    else {
        $event->ignore();
        return;
    }

    $event->accept();
}

sub showEvent
{
    my ( $e ) = @_;
    this->SUPER::showEvent( $e );
    view->pause( 0 );
    view->setFocus();
}

sub hideEvent
{
    my ( $e ) = @_;
    this->SUPER::hideEvent( $e );
    view->pause( 1 );
}

sub slotNewGame
{
    this->{score} = 0;
    this->{shipsRemain} = SB_SHIPS;
    scoreLCD->display( 0 );
    this->{level} = 0;
    levelLCD->display( level+1 );
    shipsLCD->display( shipsRemain-1 );
    view->newGame();
    view->setRockSpeed( $levels->[0]->{rockSpeed} );
    view->addRocks( $levels->[0]->{nrocks} );
#    view->showText( this->tr( 'Press L to launch.' ), yellow );
    view->newShip();
    this->{waitShip} = 0;
    view->hideText();
    this->{isPaused} = 0;
}

sub slotShipKilled
{
    this->{shipsRemain}--;
    shipsLCD->display( shipsRemain-1 );

    playSound( 'ShipDestroyed' );

    if ( shipsRemain )
    {
        this->{waitShip} = 1;
        view->showText( this->tr( 'Ship Destroyed. Press L to launch.'), Qt::Color(Qt::yellow()) );
    }
    else
    {
        view->showText( this->tr('Game Over!'), Qt::Color(Qt::red()) );
        view->endGame();
        doStats();
#        highscore->addEntry( score, level, showHiscores );
    }
}

sub slotRockHit
{
    my ( $size ) = @_;
	if ( $size == 0 ) {
	    this->{score} += 10;
    }
	if ( $size == 1 ) {
	    this->{score} += 20;
    }
	else {
	    this->{score} += 40;
    }

    playSound( 'RockDestroyed' );

    scoreLCD->display( score );
}

sub slotRocksRemoved
{
    this->{level}++;

    if ( level >= MAX_LEVELS ) {
        this->{level} = MAX_LEVELS - 1;
    }

    view->setRockSpeed( $levels->[level-1]->{rockSpeed} );
    view->addRocks( $levels->[level-1]->{nrocks} );

    levelLCD->display( level+1 );
}

sub doStats
{
    my $r = '0.00';
    if ( view->shots() ) {
        $r = sprintf '%.02f', view->hits() / view->shots() * 100.0;
    }

    #multi-line text broken in Qt 3
    #Qt::String s = this->tr( 'Game Over\n\nShots fired:\t%1\n  Hit:\t%2\n  Missed:\t%3\nHit ratio:\t%4 %\n\nPress N for a new game' )
      #.arg(view->shots()).arg(view->hits())
      #.arg(view->shots() - view->hits())
      #.arg(r);

    view->showText( 'Game Over.   Press N for a game.', Qt::Color(Qt::yellow()), 0 );
}

sub slotUpdateVitals
{
    brakesLCD->display( view->brakeCount() );
    shieldLCD->display( view->shieldCount() );
    shootLCD->display( view->shootCount() );
#    teleportsLCD->display( view->teleportCount() );
    powerMeter->setValue( view->power() );
}

1;
