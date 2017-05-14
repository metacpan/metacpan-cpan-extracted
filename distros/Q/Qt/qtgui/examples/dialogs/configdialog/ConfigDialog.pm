package ConfigDialog;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    changePage => ['QListWidgetItem *', 'QListWidgetItem *'];

use Pages;
use ConfigurationPage;
use UpdatePage;
use QueryPage;

sub NEW {
    shift->SUPER::NEW();
    my $contentsWidget = Qt::ListWidget();
    this->{contentsWidget} = $contentsWidget;
    $contentsWidget->setViewMode(Qt::ListView::IconMode());
    $contentsWidget->setIconSize(Qt::Size(96, 84));
    $contentsWidget->setMovement(Qt::ListView::Static());
    $contentsWidget->setMaximumWidth(128);
    $contentsWidget->setSpacing(12);

    my $pagesWidget = Qt::StackedWidget();
    this->{pagesWidget} = $pagesWidget;
    $pagesWidget->addWidget(ConfigurationPage());
    $pagesWidget->addWidget(UpdatePage());
    $pagesWidget->addWidget(QueryPage());

    my $closeButton = Qt::PushButton(this->tr('Close'));

    createIcons();
    $contentsWidget->setCurrentRow(0);

    this->connect($closeButton, SIGNAL 'clicked()', this, SLOT 'close()');

    my $horizontalLayout = Qt::HBoxLayout();
    $horizontalLayout->addWidget($contentsWidget);
    $horizontalLayout->addWidget($pagesWidget, 1);

    my $buttonsLayout = Qt::HBoxLayout();
    $buttonsLayout->addStretch(1);
    $buttonsLayout->addWidget($closeButton);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addLayout($horizontalLayout);
    $mainLayout->addStretch(1);
    $mainLayout->addSpacing(12);
    $mainLayout->addLayout($buttonsLayout);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Config Dialog'));
}

sub createIcons {
    my $contentsWidget = this->{contentsWidget};

    my $configButton = Qt::ListWidgetItem($contentsWidget);
    $configButton->setIcon(Qt::Icon('images/config.png'));
    $configButton->setText(this->tr('Configuration'));
    $configButton->setTextAlignment(Qt::AlignHCenter());
    $configButton->setFlags(Qt::ItemIsSelectable() | Qt::ItemIsEnabled());

    my $updateButton = Qt::ListWidgetItem($contentsWidget);
    $updateButton->setIcon(Qt::Icon('images/update.png'));
    $updateButton->setText(this->tr('Update'));
    $updateButton->setTextAlignment(Qt::AlignHCenter());
    $updateButton->setFlags(Qt::ItemIsSelectable() | Qt::ItemIsEnabled());

    my $queryButton = Qt::ListWidgetItem($contentsWidget);
    $queryButton->setIcon(Qt::Icon('images/query.png'));
    $queryButton->setText(this->tr('Query'));
    $queryButton->setTextAlignment(Qt::AlignHCenter());
    $queryButton->setFlags(Qt::ItemIsSelectable() | Qt::ItemIsEnabled());

    this->connect($contentsWidget,
            SIGNAL 'currentItemChanged(QListWidgetItem *, QListWidgetItem *)',
            this, SLOT 'changePage(QListWidgetItem *, QListWidgetItem*)');
}

sub changePage {
    my ($current, $previous) = @_;
    if (!$current) {
        $current = $previous;
    }

    this->{pagesWidget}->setCurrentIndex(this->{contentsWidget}->row($current));
}

1;
