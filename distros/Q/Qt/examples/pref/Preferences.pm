package Preferences;

use QButtonGroup;
use QLabel;
use QLayout;
use QMultiLineEdit;
use QRadioButton;
use QSlider;
use QTabDialog;

use slots 'setup()', 'apply()';

@ISA = qw(QLabel);

sub new {
    my $self = shift->SUPER::new(@_);
    print "self = $self\n";
    my $tab = new QTabDialog(undef, 'top-level dialog')->setImmortal;
    $tab->setCaption('Ugly Tab Dialog');

    # set up page one of the tab dialog
    my $w = new QWidget($tab, 'page one')->setImmortal;

    # stuff the labels and lineedits into a grid layout
    my $g = new QGridLayout($w, 2, 2, 5);

    # two multilineedits in column 1
    my $ed1 = new QMultiLineEdit($w)->setImmortal;
    $g->addWidget($ed1, 0, 1);
    $ed1->setText('');
    $ed1->setMinimumSize(new QSize(100, 10));
    my $ed2 = new QMultiLineEdit($w)->setImmortal;
    $g->addWidget($ed2, 1, 1);
    $ed2->setText('');
    $ed2->setMinimumSize(new QSize(100, 10));

    # let the lineedits stretch
    $g->setColStretch(1, 1);

    # two labels in column 0
    my $l = new QLabel($w)->setImmortal;
    $g->addWidget($l, 0, 0);
    $l->setText('&Name');
    $l->setBuddy($ed1);
    $l->setMinimumSize($l->sizeHint());
    $l = new QLabel($w)->setImmortal;
    $g->addWidget($l, 1, 0);
    $l->setText('&Email');
    $l->setBuddy($ed2);
    $l->setMinimumSize($l->sizeHint());

    # no stretch on the labels unless they have to
    $g->setColStretch(0, 0);

    # finally insert page one into the tab dialog and start GM
    $tab->addTab($w, 'Who');
    $g->activate();

    # that was page one, now for page two, where we use a box layout
    $w = new QWidget($tab, 'page two')->setImmortal;
    my $b = new QBoxLayout($w, $Direction{LeftToRight}, 5)->setImmortal;

    # two vertical boxes in the horizontal one
    my $radioBoxes = new QBoxLayout($Direction{Down})->setImmortal;
    $b->addLayout($radioBoxes);

    # fill the leftmost vertical box
    my $b1 = new QRadioButton($w, 'radio button 1')->setImmortal;
    $b1->setText('Male');
    $b1->setMinimumSize($b1->sizeHint());
    $b1->setMaximumSize(500, $b1->minimumSize()->height());
    $radioBoxes->addWidget($b1, $Align{Left}|$Align{Top});
    my $b2 = new QRadioButton($w, 'radio button 2')->setImmortal;
    $b2->setText('Female');
    $b2->setMinimumSize($b2->sizeHint());
    $b2->setMaximumSize(500, $b2->minimumSize()->height());
    $radioBoxes->addWidget($b2, $Align{Left}|$Align{Top});
    my $b3 = new QRadioButton($w, 'radio button 3')->setImmortal;
    $b3->setText('Duo Pack');
    $b3->setMinimumSize($b3->sizeHint());
    $b3->setMaximumSize(500, $b3->minimumSize()->height());
    $radioBoxes->addWidget($b3, $Align{Left}|$Align{Top});

    # since none of those will stretch, add some stretch at the bottom
    $radioBoxes->addStretch(1);

    # insert all of the radio boxes into the button group, so they'll
    # switch each other off
    my $bg = new QButtonGroup->setImmortal;
    $bg->insert($b1);
    $bg->insert($b2);
    $bg->insert($b3);

    # add some optional spacing between the radio buttons and the slider
    $b->addStretch(1);

    # make the central slider
    my $mood =
	new QSlider($Orientation{Vertical}, $w, 'mood slider')->setImmortal;
    $mood->setRange(0, 127);
    $mood->setMinimumSize($mood->sizeHint());
    $mood->setMaximumSize($mood->minimumSize->width(), 500);
    $b->addWidget($mood, $Align{Left}|$Align{Top}|$Align{Bottom});

    # make the top and bottom labels for the slider
    my $labels = new QBoxLayout($Direction{Down})->setImmortal;
    $b->addLayout($labels);
    $b->addLayout($labels);
    $l = new QLabel('Optimistic', $w, 'optimistic')->setImmortal;
    $l->setFixedSize($l->sizeHint());
    $labels->addWidget($l, $Align{Top}|$Align{Left});

    # spacing in the middle, so the labels are located right
    $labels->addStretch(1);

    $l = new QLabel('Pessimistic', $w, 'pessimistic')->setImmortal;
    $l->setFixedSize($l->sizeHint());
    $labels->addWidget($l, $Align{Bottom}|$Align{Left});

    $b->activate();
    $tab->addTab($w, 'How');

    # we want both Apply and Cancel
    $tab->setApplyButton();
    $tab->setCancelButton();

    $self->connect($tab, 'applyButtonPressed()', 'apply()');
    $self->connect($tab, 'cancelButtonPressed()', 'setup()');
    $self->connect($tab, 'aboutToShow()', 'setup()');

    $tab->resize(200, 135);

    $self->setText("This tab dialog is rather ugly:  " .
		   "The code is clear, though:\n" .
		   "There are no hard-to-understand aesthetic tradeoffs\n");

    $self->show();
    $tab->show();
    @$self{'ed1', 'ed2', 'bg', 'b1', 'b2', 'b3', 'mood'} =
	($ed1, $ed2, $bg, $b1, $b2, $b3, $mood);
    return $self;
}

sub setup {
    my $self = shift;
    my($ed1, $ed2, $b1, $mood) = @$self{'ed1', 'ed2', 'b1', 'mood'};

    $ed1->setText('Perl Qt');
    $ed2->setText('perlqt@pqt.org');

    $b1->setChecked(1);

    $mood->setValue(42);
}

sub apply {
    my $self = shift;
    my($ed1, $ed2, $b1, $b2, $b3, $mood) =
	@$self{'ed1', 'ed2', 'b1', 'b2', 'b3', 'mood'};
    my $s = sprintf("What the dialog decided:\n" .
		    "\tLine Edit 1: %s\n\tLineEdit 2: %s\n" .
		    "\tMood: %d (0 == down, 127 == up)\n" .
		    "\tButtons: %s %s %s\n",
		    $ed1->text(), $ed2->text(),
		    $mood->value(),
		    $b1->isChecked() ? 'X' : '-',
		    $b2->isChecked() ? 'X' : '-',
		    $b3->isChecked() ? 'X' : '-');
    $self->setText($s);
    my $sh = $self->sizeHint();
    my $b = 0;

    if($sh->width() > $self->width()) {
	$sh->setWidth($self->width());
	$b = 1;
    }
    if($sh->height() > $self->height()) {
	$sh->setHeight($self->height());
	$b = 1;
    }

    $self->resize($sh) if $b;

    $self->repaint();
}
