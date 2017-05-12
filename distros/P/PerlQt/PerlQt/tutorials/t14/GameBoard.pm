package GameBoard;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::slots
	fire => [],
	hit => [],
	missed => [],
	newGame => [];
use Qt::attributes qw(
	hits
	shotsLeft
	cannonField
);

use LCDRange;
use CannonField;

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("&Quit", this, "quit");
    $quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    Qt::app->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

    my $angle = LCDRange("ANGLE", this, "angle");
    $angle->setRange(5, 70);

    my $force = LCDRange("FORCE", this, "force");
    $force->setRange(10, 50);

    my $box = Qt::VBox(this, "cannonFrame");
    $box->setFrameStyle($box->WinPanel | $box->Sunken);

    cannonField = CannonField($box, "cannonField");

    cannonField->connect($angle, SIGNAL('valueChanged(int)'), SLOT('setAngle(int)'));
    $angle->connect(cannonField, SIGNAL('angleChanged(int)'), SLOT('setValue(int)'));

    cannonField->connect($force, SIGNAL('valueChanged(int)'), SLOT('setForce(int)'));
    $force->connect(cannonField, SIGNAL('forceChanged(int)'), SLOT('setValue(int)'));

    this->connect(cannonField, SIGNAL('hit()'), SLOT('hit()'));
    this->connect(cannonField, SIGNAL('missed()'), SLOT('missed()'));

    my $shoot = Qt::PushButton('&Shoot', this, "shoot");
    $shoot->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    this->connect($shoot, SIGNAL('clicked()'), SLOT('fire()'));

    $shoot->connect(cannonField, SIGNAL('canShoot(bool)'), SLOT('setEnabled(bool)'));

    my $restart = Qt::PushButton('&New Game', this, "newgame");
    $restart->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    this->connect($restart, SIGNAL('clicked()'), SLOT('newGame()'));

    hits = Qt::LCDNumber(2, this, "hits");
    shotsLeft = Qt::LCDNumber(2, this, "shotsleft");
    my $hitsL = Qt::Label("HITS", this, "hitsLabel");
    my $shotsLeftL = Qt::Label("SHOTS LEFT", this, "shotsLeftLabel");

    my $accel = Qt::Accel(this);
    $accel->connectItem($accel->insertItem(Qt::KeySequence(int &Key_Enter)),
			this, SLOT('fire()'));
    $accel->connectItem($accel->insertItem(Qt::KeySequence(int &Key_Return)),
			this, SLOT('fire()'));
    $accel->connectItem($accel->insertItem(Qt::KeySequence(int &CTRL+&Key_Q)),
			Qt::app, SLOT('quit()'));

    my $grid = Qt::GridLayout(this, 2, 2, 10);
    $grid->addWidget($quit, 0, 0);
    $grid->addWidget($box, 1, 1);
    $grid->setColStretch(1, 10);

    my $leftBox = Qt::VBoxLayout;
    $grid->addLayout($leftBox, 1, 0);
    $leftBox->addWidget($angle);
    $leftBox->addWidget($force);

    my $topBox = Qt::HBoxLayout;
    $grid->addLayout($topBox, 0, 1);
    $topBox->addWidget($shoot);
    $topBox->addWidget(hits);
    $topBox->addWidget($hitsL);
    $topBox->addWidget(shotsLeft);
    $topBox->addWidget($shotsLeftL);
    $topBox->addStretch(1);
    $topBox->addWidget($restart);

    $angle->setValue(60);
    $force->setValue(25);
    $angle->setFocus();

    newGame();
}

sub fire {
    return if cannonField->gameOver or cannonField->isShooting;
    shotsLeft->display(int(shotsLeft->intValue - 1));
    cannonField->shoot;
}

sub hit {
    hits->display(int(hits->intValue + 1));
    if(shotsLeft->intValue == 0) {
	cannonField->setGameOver;
    } else {
	cannonField->newTarget;
    }
}

sub missed {
    cannonField->setGameOver if shotsLeft->intValue == 0;
}

sub newGame {
    shotsLeft->display(int(15));
    hits->display(0);
    cannonField->restartGame;
    cannonField->newTarget;
}

1;
