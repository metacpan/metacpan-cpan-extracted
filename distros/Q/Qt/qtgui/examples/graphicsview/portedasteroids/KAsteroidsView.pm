package KAsteroidsView;

=begin

 * KAsteroids - Copyright (c) Martin R-> Jones 1997
 *
 * Part of the KDE project

=cut

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::signals
    shipKilled => [],
    rockHit => ['int'],
    rocksRemoved => [],
    updateVitals => [];

use QtCore4::slots
    hideShield => [];

use Qt::GlobalSpace qw(qrand);
use POSIX qw( RAND_MAX );
use List::MoreUtils qw(first_index);

use constant {
    MAX_POWER_LEVEL => 1000,
    IMG_BACKGROUND => ':/trolltech/examples/graphicsview/portedasteroids/bg.png'
};

use AnimatedPixmapItem;
use Sprites;
use KMissile;
use KBit;
use KExhaust;
use KPowerup;
use KRock;
use KShield;

sub setRockSpeed() { my ($rs) = @_; this->{rockSpeed} = $rs; }
sub rotateLeft() { my ($r) = @_; this->{rotateL} = $r; this->{rotateSlow} = 5; }
sub rotateRight() { my ($r) = @_; this->{rotateR} = $r; this->{rotateSlow} = 5; }
sub thrust() { my ($t) = @_; this->{thrustShip} = $t && this->{shipPower} > 0; }
sub shoot() { my ($s) = @_; this->{shootShip} = $s; this->{shootDelay} = 0; }
sub teleport() { my ($te) = @_; this->{teleportShip} = $te && this->{mTeleportCount}; }

sub shots() { return this->{shotsFired}; }
sub hits() { return this->{shotsHit}; }
sub power() { return this->{shipPower}; }

sub teleportCount() { return this->{mTeleportCount}; }
sub brakeCount() { return this->{mBrakeCount}; }
sub shieldCount() { return this->{mShieldCount}; }
sub shootCount() { return this->{mShootCount}; }

sub refreshRate() {
    return this->{refreshRate};
}

sub field() {
    return this->{field};
}

sub view() {
    return this->{view};
}

sub animation() {
    return this->{animation};
}

sub rocks() {
    return this->{rocks};
}

sub missiles() {
    return this->{missiles};
}

sub bits() {
    return this->{bits};
}

sub exhaust() {
    return this->{exhaust};
}

sub powerups() {
    return this->{powerups};
}

sub shield() {
    return this->{shield};
}

sub ship() {
    return this->{ship};
}

sub textSprite() {
    return this->{textSprite};
}


sub rotateL() {
    return this->{rotateL};
}

sub rotateR() {
    return this->{rotateR};
}

sub thrustShip() {
    return this->{thrustShip};
}

sub shootShip() {
    return this->{shootShip};
}

sub teleportShip() {
    return this->{teleportShip};
}

sub brakeShip() {
    return this->{brakeShip};
}

sub pauseShip() {
    return this->{pauseShip};
}

sub shieldOn() {
    return this->{shieldOn};
}


sub vitalsChanged() {
    return this->{vitalsChanged};
}


sub shipAngle() {
    return this->{shipAngle};
}

sub rotateSlow() {
    return this->{rotateSlow};
}

sub rotateRate() {
    return this->{rotateRate};
}

sub shipPower() {
    return this->{shipPower};
}


sub shotsFired() {
    return this->{shotsFired};
}

sub shotsHit() {
    return this->{shotsHit};
}

sub shootDelay() {
    return this->{shootDelay};
}


sub mBrakeCount() {
    return this->{mBrakeCount};
}

sub mShieldCount() {
    return this->{mShieldCount};
}

sub mTeleportCount() {
    return this->{mTeleportCount};
}

sub mShootCount() {
    return this->{mShootCount};
}


sub shipDx() {
    return this->{shipDx};
}

sub shipDy() {
    return this->{shipDy};
}


sub textDy() {
    return this->{textDy};
}

sub mFrameNum() {
    return this->{mFrameNum};
}

sub mPaused() {
    return this->{mPaused};
}

sub mTimerId() {
    return this->{mTimerId};
}


sub rockSpeed() {
    return this->{rockSpeed};
}

sub powerupSpeed() {
    return this->{powerupSpeed};
}


sub can_destroy_powerups() {
    return this->{can_destroy_powerups};
}


sub shieldTimer() {
    return this->{shieldTimer};
}

sub initialized() {
    return this->{initialized};
}


use constant {
    REFRESH_DELAY => 33,
    SHIP_SPEED => 0.3,
    MISSILE_SPEED => 10.0,
    SHIP_STEPS => 64,
    ROTATE_RATE => 2,
    SHIELD_ON_COST => 1,
    SHIELD_HIT_COST => 30,
    BRAKE_ON_COST => 4,

    MAX_ROCK_SPEED => 2.5,
    MAX_POWERUP_SPEED => 1.5,
    MAX_SHIP_SPEED => 12,
    MAX_BRAKES => 5,
    MAX_SHIELDS => 5,
    MAX_FIREPOWER =>	5,

    TEXT_SPEED => 4,

    PI_X_2 => 6.283185307,
    M_PI => 3.141592654,
};

my @kas_animations =
(
    { id => Sprites::ID_ROCK_LARGE,        path => 'rock1/rock1%1.png',       frames => 32 },
    { id => Sprites::ID_ROCK_MEDIUM,       path => 'rock2/rock2%1.png',       frames => 32 },
    { id => Sprites::ID_ROCK_SMALL,        path => 'rock3/rock3%1.png',       frames => 32 },
    { id => Sprites::ID_SHIP,              path => 'ship/ship%1.png',         frames => 32 },
    { id => Sprites::ID_MISSILE,           path => 'missile/missile.png',     frames => 1 },
    { id => Sprites::ID_BIT,               path => 'bits/bits%1.png',         frames => 16 },
    { id => Sprites::ID_EXHAUST,           path => 'exhaust/exhaust.png',     frames => 1 },
    { id => Sprites::ID_ENERGY_POWERUP,    path => 'powerups/energy.png',     frames => 1 },
#    { id => Sprites::ID_TELEPORT_POWERUP, path => 'powerups/teleport%1.png', frames => 12 },
    { id => Sprites::ID_BRAKE_POWERUP,     path => 'powerups/brake.png',      frames => 1 },
    { id => Sprites::ID_SHIELD_POWERUP,    path => 'powerups/shield.png',     frames => 1 },
    { id => Sprites::ID_SHOOT_POWERUP,     path => 'powerups/shoot.png',      frames => 1 },
    { id => Sprites::ID_SHIELD,            path => 'shield/shield%1.png',     frames => 6 },
    { id => 0,                    path => 0,                         frames => 0 }
);

sub NEW {
    my ($class, $parent, $name) = @_;
    if ( $name ) {
        $class->SUPER::NEW($parent, $name);
    }
    else {
        $class->SUPER::NEW($parent);
    }
    this->{mFrameNum} = 0;
    this->{mBrakeCount} = 0;
    this->{mShieldCount} = 0;
    this->{mShootCount} = 0;
    this->{field} = Qt::GraphicsScene( 0, 0, 640, 440 );
    this->{view} = Qt::GraphicsView(field, this);

    view->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff() );
    view->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff() );
    view->setCacheMode(Qt::GraphicsView::CacheBackground());
    view->setViewportUpdateMode(Qt::GraphicsView::BoundingRectViewportUpdate());
    view->setOptimizationFlags(Qt::GraphicsView::DontClipPainter()
                              | Qt::GraphicsView::DontSavePainterState()
                              | Qt::GraphicsView::DontAdjustForAntialiasing());
    view->viewport()->setFocusProxy( this );

    this->{rocks} = [];
    this->{missiles} = [];
    this->{bits} = [];
    this->{powerups} = [];
    this->{exhaust} = [];
    this->{animation} = [];

    my $pm = Qt::Pixmap( IMG_BACKGROUND );
    field->setBackgroundBrush( Qt::Brush( $pm ) );

    this->{textSprite} = Qt::GraphicsTextItem( undef, field );
    my $font = Qt::Font( 'helvetica', 18 );
    textSprite()->setFont( $font );
    textSprite()->setCacheMode(Qt::GraphicsItem::DeviceCoordinateCache());

    this->{shield} = 0;
    this->{shieldOn} = 0;
    this->{refreshRate} = REFRESH_DELAY;

    this->{initialized} = readSprites();

    this->{shieldTimer} = Qt::Timer( this );
    this->connect( shieldTimer, SIGNAL 'timeout()', this, SLOT 'hideShield()' );
    this->{mTimerId} = -1;

    this->{shipPower} = MAX_POWER_LEVEL;
    this->{vitalsChanged} = 1;
    this->{can_destroy_powerups} = 0;

    this->{mPaused} = 1;

    if ( !initialized ) {
        textSprite()->setHtml( this->tr('<font color=red>Error: Cannot read sprite images</font>') );
        textSprite()->setPos( (field->width()-textSprite()->boundingRect()->width()) / 2,
                (field->height()-textSprite()->boundingRect()->height()) / 2 );
    }
}

# - - -

sub reset
{
    if ( !initialized ) {
        return;
    }
    map { $_->scene->removeItem($_) }
    grep { defined }
        @{rocks()},
        @{missiles()},
        @{bits()},
        @{powerups()},
        @{exhaust()};

    @{rocks()} = ();
    @{missiles()} = ();
    @{bits()} = ();
    @{powerups()} = ();
    @{exhaust()} = ();

    this->{shotsFired} = 0;
    this->{shotsHit} = 0;

    this->{rockSpeed} = 1.0;
    this->{powerupSpeed} = 1.0;
    this->{mFrameNum} = 0;
    this->{mPaused} = 0;

    ship->hide();
    shield->hide();
    #if ( mTimerId >= 0 ) {
        #killTimer( mTimerId );
        #mTimerId = -1;
    #}
}

# - --

sub newGame
{
    if ( !initialized ) {
        return;
    }
    if ( shieldOn )
    {
        shield->hide();
        this->{shieldOn} = 0;
    }
    this->reset();
    if ( this->{mTimerId} < 0 ) {
        this->{mTimerId} = startTimer( REFRESH_DELAY );
    }
    emit updateVitals();
}

# - - -

sub endGame
{
}

sub pause
{
    my ( $p ) = @_;
    if ( !initialized ) {
        return;
    }
    if ( !mPaused && $p ) {
        if ( mTimerId >= 0 ) {
            killTimer( mTimerId );
            this->{mTimerId} = -1;
        }
    } elsif ( mPaused && !$p ) {
        this->{mTimerId} = startTimer( REFRESH_DELAY );
    }
    this->{mPaused} = $p;
}

# - - -

sub newShip
{
    if ( !initialized ) {
        return;
    }
    ship->setPos( width()/2, height()/2 );
    ship->setFrame( 0 );
    shield->setPos( width()/2, height()/2 );
    shield->setFrame( 0 );
    ship->setVelocity( 0.0, 0.0 );
    this->{shipDx} = 0;
    this->{shipDy} = 0;
    this->{shipAngle} = 0;
    this->{rotateL} = 0;
    this->{rotateR} = 0;
    this->{thrustShip} = 0;
    this->{shootShip} = 0;
    this->{brakeShip} = 0;
    this->{teleportShip} = 0;
    this->{shieldOn} = 1;
    this->{shootDelay} = 0;
    this->{shipPower} = MAX_POWER_LEVEL;
    this->{rotateRate} = ROTATE_RATE;
    this->{rotateSlow} = 0;

    this->{mBrakeCount} = 0;
    this->{mTeleportCount} = 0;
    this->{mShootCount} = 0;

    ship->show();
    shield->show();
    this->{mShieldCount} = 1;   # just in case the ship appears on a rock.
    shieldTimer->start( 1000, 1 );
}

sub setShield
{
    my ( $s ) = @_;
    if ( !initialized ) {
        return;
    }
    if ( shieldTimer->isActive() && !$s ) {
        shieldTimer->stop();
        hideShield();
    } else {
        this->{shieldOn} = $s && mShieldCount;
    }
}

sub brake
{
    my ( $b ) = @_;
    if ( !initialized ) {
        return;
    }
    if ( mBrakeCount )
    {
        if ( brakeShip && !$b )
        {
            this->{rotateL} = 0;
            this->{rotateR} = 0;
            this->{thrustShip} = 0;
            this->{rotateRate} = ROTATE_RATE;
        }

        this->{brakeShip} = $b;
    }
}

# - - -

sub readSprites
{
    my $sprites_prefix = ':/trolltech/examples/graphicsview/portedasteroids/sprites/';

    my $i = 0;
    while ( $kas_animations[$i]->{id} )
    {
        my @anim;
        my $wildcard = $sprites_prefix . $kas_animations[$i]->{path};
        $wildcard =~ s/%1/*/g;
        my $fi = Qt::FileInfo($wildcard);
        foreach my $entry (@{Qt::Dir($fi->path(), $fi->fileName())->entryList()}) {
            push @anim, Qt::Pixmap($fi->path() . '/' . $entry);
        }
        animation->[$kas_animations[$i]->{id}] = \@anim;
        $i++;
    }

    this->{ship} = AnimatedPixmapItem( animation->[Sprites::ID_SHIP], field );
    ship->hide();

    this->{shield} = KShield( animation->[Sprites::ID_SHIELD], field );
    shield->hide();

    return (!ship->image(0)->isNull() && !shield->image(0)->isNull());
}

# - - -

sub addRocks
{
    my ( $num ) = @_;
    if ( !initialized ) {
        return;
    }
    for ( my $i = 0; $i < $num; $i++ )
    {
        my $rock = KRock( animation->[Sprites::ID_ROCK_LARGE], field,
                     Sprites::ID_ROCK_LARGE, randInt(2), randInt(2) ? -1 : 1 );
        my $dx = (2.0 - randDouble()*4.0) * rockSpeed;
        my $dy = (2.0 - randDouble()*4.0) * rockSpeed;
        $rock->setVelocity( $dx, $dy );
        $rock->setFrame( randInt( $rock->frameCount() ) );
        if ( $dx > 0 )
        {
            if ( $dy > 0 ) {
                $rock->setPos( 5, 5 );
            }
            else {
                $rock->setPos( 5, field->height() - 25 );
                $rock->setFrame( 0 );
            }
        }
        else
        {
            if ( $dy > 0 ) {
                $rock->setPos( field->width() - 25, 5 );
            }
            else {
                $rock->setPos( field->width() - 25, field->height() - 25 );
                $rock->setFrame( 0 );
            }
        }
        $rock->show();
        push @{rocks()}, $rock;
    }
}

# - - -

sub showText
{
    my ( $text, $color, $scroll ) = @_;
    if ( !defined $scroll ) {
        $scroll = 1;
    }
    if ( !initialized ) {
        return;
    }

    textSprite()->setHtml( sprintf '<font color=#%02x%02x%02x>%s</font>',
                         $color->red(),
                         $color->green(),
                         $color->blue(),
                         $text );
    # ### Porting: no such thing textSprite()->setColor( color );

    if ( $scroll ) {
        textSprite()->setPos( (field->width() - textSprite()->boundingRect()->width()) / 2,
                -textSprite()->boundingRect()->height() );
        this->{textDy} = TEXT_SPEED;
    } else {
        textSprite()->setPos( (field->width() - textSprite()->boundingRect()->width()) / 2,
                (field->height() - textSprite()->boundingRect()->height()) / 2 );
        this->{textDy} = 0;
    }
    textSprite()->show();
}

# - - -

sub hideText
{
    this->{textDy} = -TEXT_SPEED();
}

# - - -

sub resizeEvent
{
    my ($event) = @_;
    Qt::Widget::resizeEvent($event);
    field->setSceneRect(0, 0, width()-4, height()-4);
    view->resize(width(),height());
}

# - - -

sub timerEvent
{
    # XXX why is this necessary?
    field->update();

    field->advance();

    # move rocks forward
    foreach my $rock ( @{rocks()} ) {
        $rock->nextFrame();
        wrapSprite( $rock );
    }

    wrapSprite( ship );

    # check for missile collision with rocks.
    processMissiles();

    # these are generated when a ship explodes
    for( my $it = 0; $it < @{bits()};  )
    {
        my $bit = bits()->[$it];
        if ( $bit->expired() )
        {
            $bit->scene()->removeItem($bit);
            splice @{bits()}, $it, 1;
        }
        else
        {
            $bit->growOlder();
            $bit->setFrame( ( $bit->frame()+1 ) % $bit->frameCount() );
            ++$it;
        }
    }

    foreach my $it ( 0..$#{exhaust()} ) {
        my $e = exhaust()->[$it];
        $e->scene()->removeItem($e);
    }
    @{exhaust()} = ();

    # move / rotate ship.
    # check for collision with a rock.
    processShip();

    # move powerups and check for collision with player and missiles
    processPowerups();

    if ( textSprite()->isVisible() )
    {
        if ( textDy < 0 &&
                textSprite()->boundingRect()->y() <= -textSprite()->boundingRect()->height() ) {
            textSprite()->hide();
        } else {
            textSprite()->moveBy( 0, textDy );
        }

        if ( textSprite()->sceneBoundingRect()->y() > (field->height()-textSprite()->boundingRect()->height())/2 ) {
            this->{textDy} = 0;
        }
    }

    if ( vitalsChanged && !(mFrameNum % 10) ) {
        emit updateVitals();
        this->{vitalsChanged} = 0;
    }

    this->{mFrameNum}++;
}

sub wrapSprite
{
    my ( $s ) = @_;
    my $x = sprintf '%d', ($s->x() + $s->boundingRect()->width() / 2);
    my $y = sprintf '%d', ($s->y() + $s->boundingRect()->height() / 2);

    if ( $x > field->width() ) {
        $s->setPos( $s->x() - field->width(), $s->y() );
    }
    elsif ( $x < 0 ) {
        $s->setPos( field->width() + $s->x(), $s->y() );
    }

    if ( $y > field->height() ) {
        $s->setPos( $s->x(), $s->y() - field->height() );
    }
    elsif ( $y < 0 ) {
        $s->setPos( $s->x(), field->height() + $s->y() );
    }
}

# - - -

sub processRockHit
{
    my ( $hit ) = @_;
    my $nPup = undef;
    my $rnd = sprintf '%d', (randDouble()*30.0) % 30;
    if ($rnd == 4 || $rnd == 5) {
        $nPup = KPowerup( animation->[Sprites::ID_ENERGY_POWERUP], field,
                Sprites::ID_ENERGY_POWERUP );
    }
    elsif ($rnd == 10) {
# Commented out in C++
#        $nPup = KPowerup( animation->[Sprites::ID_TELEPORT_POWERUP], &field,
#                             Sprites::ID_TELEPORT_POWERUP );
    }
    elsif ($rnd == 15) {
        $nPup = KPowerup( animation->[Sprites::ID_BRAKE_POWERUP], field,
                Sprites::ID_BRAKE_POWERUP );
    }
    elsif ($rnd == 20) {
        $nPup = KPowerup( animation->[Sprites::ID_SHIELD_POWERUP], field,
                Sprites::ID_SHIELD_POWERUP );
    }
    elsif ($rnd == 24 || $rnd == 25) {
        $nPup = KPowerup( animation->[Sprites::ID_SHOOT_POWERUP], field,
                Sprites::ID_SHOOT_POWERUP );
    }

    if ( $nPup )
    {
        my $r = 0.5 - randDouble();
        $nPup->setPos( $hit->x(), $hit->y() );
        $nPup->setFrame( 0 );
        $nPup->setVelocity( $hit->xVelocity() + $r, $hit->yVelocity() + $r );
        push @{this->{powerups}}, $nPup;
    }

    if ( $hit->type() == Sprites::ID_ROCK_LARGE || $hit->type() == Sprites::ID_ROCK_MEDIUM )
    {
        # break into smaller rocks
        my @addx = ( 1.0, 1.0, -1.0, -1.0 );
        my @addy = ( -1.0, 1.0, -1.0, 1.0 );

        my $dx = $hit->xVelocity();
        my $dy = $hit->yVelocity();

        my $maxRockSpeed = MAX_ROCK_SPEED * rockSpeed();
        if ( $dx > $maxRockSpeed ) {
            $dx = $maxRockSpeed;
        }
        elsif ( $dx < -$maxRockSpeed ) {
            $dx = -$maxRockSpeed;
        }
        if ( $dy > $maxRockSpeed ) {
            $dy = $maxRockSpeed;
        }
        elsif ( $dy < -$maxRockSpeed ) {
            $dy = -$maxRockSpeed;
        }

        my $nrock;

        for ( my $i = 0; $i < 4; $i++ )
        {
            my $r = rockSpeed()/2 - randDouble()*rockSpeed();
            if ( $hit->type() == Sprites::ID_ROCK_LARGE )
            {
                $nrock = KRock( animation->[Sprites::ID_ROCK_MEDIUM], field,
                        Sprites::ID_ROCK_MEDIUM, randInt(2), randInt(2) ? -1 : 1 );
                emit rockHit( 0 );
            }
            else
            {
                $nrock = KRock( animation->[Sprites::ID_ROCK_SMALL], field,
                        Sprites::ID_ROCK_SMALL, randInt(2), randInt(2) ? -1 : 1 );
                emit rockHit( 1 );
            }

            $nrock->setPos( $hit->x(), $hit->y() );
            $nrock->setFrame( 0 );
            $nrock->setVelocity( $dx+$addx[$i]*rockSpeed()+$r, $dy+$addy[$i]*rockSpeed()+$r );
            $nrock->setFrame( randInt( $nrock->frameCount() ) );
            push @{rocks()}, $nrock;
        }
    }
    elsif ( $hit->type() == Sprites::ID_ROCK_SMALL ) {
        emit rockHit( 2 );
    }

    $hit->scene()->removeItem($hit);
    splice @{rocks()}, (first_index{$hit==$_} @{rocks()}), 1;

    if ( scalar @{rocks()} == 0 ) {
        emit rocksRemoved();
    }
}

sub reducePower
{
    my ( $val ) = @_;
    this->{shipPower} -= $val;
    if ( shipPower <= 0 )
    {
        this->{shipPower} = 0;
        this->{thrustShip} = 0;
        if ( shieldOn )
        {
            this->{shieldOn} = 0;
            shield->hide();
        }
    }
    this->{vitalsChanged} = 1;
}

sub addExhaust
{
    my ( $x, $y, $dx, $dy, $count ) = @_;
    for ( my $i = 0; $i < $count; $i++ )
    {
        my $e = KExhaust( animation->[Sprites::ID_EXHAUST], field );
        $e->setPos( $x + 2 - randDouble()*4, $y + 2 - randDouble()*4 );
        $e->setVelocity( $dx, $dy );
        push @{exhaust()}, $e;
    }
}

sub processMissiles
{
    my $missile;

    # if a missile has hit a rock, remove missile and break rock into smaller
    # rocks or remove completely.

    for( my $it = 0; $it < @{missiles()}; )
    {
        $missile = missiles()->[$it];
        $missile->growOlder();

        if ( $missile->expired() )
        {
            $missile->scene()->removeItem($missile);
            splice @{missiles()}, $it, 1;
            next;
        }

        wrapSprite( $missile );

        my $hits = $missile->collidingItems(Qt::IntersectsItemBoundingRect());
        foreach my $hit ( @{$hits} )
        {
            if ( $hit->type() >= Sprites::ID_ROCK_LARGE &&
                    $hit->type() <= Sprites::ID_ROCK_SMALL && $hit->collidesWithItem($missile) )
            {
                this->{shotsHit}++;
                processRockHit( $hit );
                splice @{missiles()}, $it, 1;
                last;
            }
        }
        ++$it;
    }
}

# - - -

my $sf = 0;

sub processShip
{
    if ( ship->isVisible() )
    {
        if ( shieldOn )
        {
            shield->show();
            reducePower( SHIELD_ON_COST );
            $sf++;

            if ( $sf % 2 ) {
                shield->setFrame( (shield->frame()+1) % shield->frameCount() );
            }
            shield->setPos( ship->x() - 9, ship->y() - 9 );

            my $hits = shield->collidingItems(Qt::IntersectsItemBoundingRect());
            #Qt::List<Qt::GraphicsItem *>::Iterator it;
            #for ( it = hits->begin(); it != hits->end(); ++it )
            foreach my $it ( @{$hits} ) 
            {
                if ( $it->type() >= Sprites::ID_ROCK_LARGE &&
                        $it->type() <= Sprites::ID_ROCK_SMALL && $it->collidesWithItem(shield) )
                {
                    my $factor;
                    if ( $it->type() == Sprites::ID_ROCK_LARGE ) {
                        $factor = 3;
                    }
                    elsif ( $it->type() == Sprites::ID_ROCK_MEDIUM ) {
                        $factor = 2;
                    }
                    else {
                        $factor = 1;
                    }

                    if ( $factor > mShieldCount )
                    {
# shield not strong enough
                        this->{shieldOn} = 0;
                        last;
                    }
                    processRockHit( $it );
# the more shields we have the less costly
                    reducePower( $factor * (SHIELD_HIT_COST - mShieldCount*2) );
                }
            }
        }

        if ( !shieldOn )
        {
            shield->hide();
            my $hits = ship->collidingItems(Qt::IntersectsItemBoundingRect());
            #Qt::List<Qt::GraphicsItem *>::Iterator it;
            #for ( it = hits->begin(); it != hits->end(); ++it )
            foreach my $it ( @{$hits} )
            {
                if ( $it->type() >= Sprites::ID_ROCK_LARGE &&
                        $it->type() <= Sprites::ID_ROCK_SMALL && $it->collidesWithItem(ship) )
                {
                    my $bit;
                    for ( my $i = 0; $i < 12; $i++ )
                    {
                        $bit = KBit( animation->[Sprites::ID_BIT], field );
                        $bit->setPos( ship->x() + 5 - randDouble() * 10,
                                ship->y() + 5 - randDouble() * 10 );
                        $bit->setFrame( randInt($bit->frameCount()) );
                        $bit->setVelocity( 1-randDouble()*2,
                                1-randDouble()*2 );
                        $bit->setDeath( 60 + randInt(60) );
                        push @{bits()}, $bit;
                    }
                    ship->hide();
                    shield->hide();
                    emit shipKilled();
                    last;
                }
            }
        }


        if ( rotateSlow ) {
            this->{rotateSlow}--;
        }

        if ( rotateL )
        {
            this->{shipAngle} -= rotateSlow ? 1 : rotateRate;
            if ( shipAngle < 0 ) {
                this->{shipAngle} += SHIP_STEPS;
            }
        }

        if ( rotateR )
        {
            this->{shipAngle} += rotateSlow ? 1 : rotateRate;
            if ( shipAngle >= SHIP_STEPS ) {
                this->{shipAngle} -= SHIP_STEPS;
            }
        }

        my $angle = shipAngle * PI_X_2 / SHIP_STEPS;
        my $cosangle = cos( $angle );
        my $sinangle = sin( $angle );

        if ( brakeShip )
        {
            this->{thrustShip} = 0;
            this->{rotateL} = 0;
            this->{rotateR} = 0;
            this->{rotateRate} = ROTATE_RATE;
            if ( abs(shipDx) < 2.5 && abs(shipDy) < 2.5 )
            {
                this->{shipDx} = 0.0;
                this->{shipDy} = 0.0;
                ship->setVelocity( shipDx, shipDy );
                this->{brakeShip} = 0;
            }
            else
            {
                my $motionAngle = atan2( -shipDy(), -shipDx() );
                if ( $angle > M_PI ) {
                    $angle -= PI_X_2;
                }
                my $angleDiff = $angle - $motionAngle;
                if ( $angleDiff > M_PI ) {
                    $angleDiff = PI_X_2 - $angleDiff;
                }
                elsif ( $angleDiff < -M_PI() ) {
                    $angleDiff = PI_X_2 + $angleDiff;
                }
                my $fdiff = abs( $angleDiff );
                if ( $fdiff > 0.08 )
                {
                    if ( $angleDiff > 0 ) {
                        this->{rotateL} = 1;
                    }
                    elsif ( $angleDiff < 0 ) {
                        this->{rotateR} = 1;
                    }
                    if ( $fdiff > 0.6 ) {
                        this->{rotateRate} = mBrakeCount + 1;
                    }
                    elsif ( $fdiff > 0.4 ) {
                        this->{rotateRate} = 2;
                    }
                    else {
                        this->{rotateRate} = 1;
                    }

                    if ( rotateRate > 5 ) {
                        this->{rotateRate} = 5;
                    }
                }
                elsif ( abs(shipDx) > 1 || abs(shipDy) > 1 )
                {
                    this->{thrustShip} = 1;
# we'll make braking a bit faster
                    this->{shipDx} += $cosangle/6 * (mBrakeCount - 1);
                    this->{shipDy} += $sinangle/6 * (mBrakeCount - 1);
                    reducePower( BRAKE_ON_COST );
                    addExhaust( ship->x() + 20 - $cosangle*22,
                            ship->y() + 20 - $sinangle*22,
                            shipDx-$cosangle, shipDy-$sinangle,
                            mBrakeCount+1 );
                }
            }
        }

        if ( thrustShip )
        {
            # The ship has a terminal velocity, but trying to go faster
            # still uses fuel (can go faster diagonally - don't care).
            my $thrustx = $cosangle/4;
            my $thrusty = $sinangle/4;
            if ( abs(shipDx + $thrustx) < MAX_SHIP_SPEED ) {
                this->{shipDx} += $thrustx;
            }
            if ( abs(shipDy + $thrusty) < MAX_SHIP_SPEED ) {
                this->{shipDy} += $thrusty;
            }
            ship->setVelocity( shipDx, shipDy );
            reducePower( 1 );
            addExhaust( ship->x() + 20 - $cosangle*20,
                    ship->y() + 20 - $sinangle*20,
                    shipDx-$cosangle, shipDy-$sinangle, 3 );
        }

        ship->setFrame( shipAngle >> 1 );

        if ( shootShip )
        {
            if ( !shootDelay && scalar @{missiles()} < mShootCount + 2 )
            {
                my $missile = KMissile( animation->[Sprites::ID_MISSILE], field );
                $missile->setPos( 21+ship->x()+$cosangle*21,
                        21+ship->y()+$sinangle*21 );
                $missile->setFrame( 0 );
                $missile->setVelocity( shipDx + $cosangle*MISSILE_SPEED,
                        shipDy + $sinangle*MISSILE_SPEED );
                push @{missiles()}, $missile;
                this->{shotsFired}++;
                reducePower( 1 );

                this->{shootDelay} = 5;
            }

            if ( shootDelay ) {
                this->{shootDelay}--;
            }
        }

        if ( teleportShip )
        {
            my $ra = qrand() % 10;
            if( $ra == 0 ) {
                $ra += qrand() % 20;
            }
            my $xra = $ra * 60 + ( (qrand() % 20) * (qrand() % 20) );
            my $yra = $ra * 50 - ( (qrand() % 20) * (qrand() % 20) );
            ship->setPos( $xra, $yra );
        }

        this->{vitalsChanged} = 1;
    }
}

# - - -

sub processPowerups
{
    if ( scalar @{powerups()} )
    {
        # if player gets the powerup remove it from the screen, if option
        # 'Can destroy powerups' is enabled and a missile hits the powerup
        # destroy it

        my $pup;
        for( my $it = 0; $it < @{powerups()}; )
        {
            $pup = powerups()->[$it];
            $pup->growOlder();

            if( $pup->expired() )
            {
                $pup->scene()->removeItem($pup);
                splice @{powerups()}, $it, 1;
                next;
            }

            wrapSprite( $pup );

            my $hits = $pup->collidingItems();
            #Qt::List<Qt::GraphicsItem *>::Iterator it;
            #for ( $it2 = hits->begin(); $it2 != hits->end(); ++$it2 )
            foreach my $it2 ( @{$hits} )
            {
                if ( $it2 == ship() )
                {
                    if ( $pup->type() == Sprites::ID_ENERGY_POWERUP ) {
                        this->{shipPower} += 150;
                        if ( shipPower > MAX_POWER_LEVEL ) {
                            this->{shipPower} = MAX_POWER_LEVEL;
                        }
                    }
                    elsif ( $pup->type() == Sprites::ID_TELEPORT_POWERUP ) {
                        this->{mTeleportCount}++;
                    }
                    elsif ( $pup->type() == Sprites::ID_BRAKE_POWERUP ) {
                        if ( mBrakeCount < MAX_BRAKES ) {
                            this->{mBrakeCount}++;
                        }
                    }
                    elsif ( $pup->type() == Sprites::ID_SHIELD_POWERUP ) {
                        if ( mShieldCount < MAX_SHIELDS ) {
                            this->{mShieldCount}++;
                        }
                    }
                    elsif ( $pup->type() == Sprites::ID_SHOOT_POWERUP ) {
                        if ( mShootCount < MAX_FIREPOWER ) {
                            this->{mShootCount}++;
                        }
                    }

                    $pup->scene()->removeItem($pup);
                    splice @{powerups()}, $it, 1;
                    this->{vitalsChanged} = 1;
                    next;
                }
                elsif ( $it2 == shield )
                {
                    $pup->scene()->removeItem($pup);
                    splice @{powerups()}, $it, 1;
                    next;
                }
                elsif ( $it2->type() == Sprites::ID_MISSILE )
                {
                    if ( can_destroy_powerups )
                    {
                        $pup->scene()->removeItem($pup);
                        splice @{powerups()}, $it, 1;
                        next;
                    }
                }
            }
            ++$it;
        }
    }         # -- if( powerups->isEmpty() )
}

# - - -

sub hideShield
{
    shield->hide();
    this->{mShieldCount} = 0;
    this->{shieldOn} = 0;
}

sub randDouble
{
    my $v = qrand();
    return $v / RAND_MAX;
}

sub randInt
{
    my ( $range ) = @_;
    return qrand() % $range;
}

#void KAsteroidsView::showEvent( Qt::ShowEvent *e )
#{
#if defined( Qt::T_LICENSE_PROFESSIONAL )
    #static bool wasThere = 0;

    #if ( !wasThere ) {
        #wasThere = 1;
        #Qt::MessageBox::information( this, this->tr('Qt::GraphicsView demo'),
                                        #this->tr('This game has been implemented using the Qt::GraphicsView class.\n'
                                           #'The Qt::GraphicsView class is not part of the Light Platform Edition. Please \n'
                                           #'contact Nokia if you want to upgrade to the Full Platform Edition.') );
    #}
#endif

    #Qt::Widget::showEvent( e );
#}

1;
