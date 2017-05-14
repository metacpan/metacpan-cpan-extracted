package TableEditor;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtSql4;

# [0]
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    submit => [];
# [0]

# [0]
sub NEW 
{
    my ($class, $tableName, $parent) = @_;
    $class->SUPER::NEW($parent);

    this->{model} = Qt::SqlTableModel(this);
    this->{model}->setTable($tableName);
    this->{model}->setEditStrategy(Qt::SqlTableModel::OnManualSubmit());
    this->{model}->select();

    this->{model}->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String(this->tr('ID'))));
    this->{model}->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String(this->tr('First name'))));
    this->{model}->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::String(this->tr('Last name'))));

# [0] //! [1]
    my $view = Qt::TableView();
    $view->setModel(this->{model});
# [1]

# [2]
    this->{submitButton} = Qt::PushButton(this->tr('Submit'));
    this->{submitButton}->setDefault(1);
    this->{revertButton} = Qt::PushButton(this->tr('&Revert'));
    this->{quitButton} = Qt::PushButton(this->tr('Quit'));

    this->{buttonBox} = Qt::DialogButtonBox(Qt::Vertical());
    this->{buttonBox}->addButton(this->{submitButton}, Qt::DialogButtonBox::ActionRole());
    this->{buttonBox}->addButton(this->{revertButton}, Qt::DialogButtonBox::ActionRole());
    this->{buttonBox}->addButton(this->{quitButton}, Qt::DialogButtonBox::RejectRole());
# [2]

# [3]
    this->connect(this->{submitButton}, SIGNAL 'clicked()', this, SLOT 'submit()');
    this->connect(this->{revertButton}, SIGNAL 'clicked()', this->{model}, SLOT 'revertAll()');
    this->connect(this->{quitButton}, SIGNAL 'clicked()', this, SLOT 'close()');
# [3]

# [4]
    my $mainLayout = Qt::HBoxLayout();
    $mainLayout->addWidget($view);
    $mainLayout->addWidget(this->{buttonBox});
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Cached Table'));
}
# [4]

# [5]
sub submit
{
    this->{model}->database()->transaction();
    if (this->{model}->submitAll()) {
        this->{model}->database()->commit();
    } else {
        this->{model}->database()->rollback();
        Qt::MessageBox::warning(this, this->tr('Cached Table'),
                     sprintf this->tr('The database reported an error: %s'),
                             this->{model}->lastError()->text());
    }
}
# [5]

1;
