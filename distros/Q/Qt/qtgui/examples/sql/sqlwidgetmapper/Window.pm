package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtSql4;

# [Window definition]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    updateButtons => ['int'];
# [Window definition]

# [Set up widgets]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->setupModel();

    this->{nameLabel} = Qt::Label(this->tr('Na&me:'));
    this->{nameEdit} = Qt::LineEdit();
    this->{addressLabel} = Qt::Label(this->tr('&Address:'));
    this->{addressEdit} = Qt::TextEdit();
    this->{typeLabel} = Qt::Label(this->tr('&Type:'));
    this->{typeComboBox} = Qt::ComboBox();
    this->{nextButton} = Qt::PushButton(this->tr('&Next'));
    this->{previousButton} = Qt::PushButton(this->tr('&Previous'));

    this->{nameLabel}->setBuddy(this->{nameEdit});
    this->{addressLabel}->setBuddy(this->{addressEdit});
    this->{typeLabel}->setBuddy(this->{typeComboBox});
# [Set up widgets]

# [Set up the mapper]
    my $relModel = this->{model}->relationModel(this->{typeIndex});
    this->{typeComboBox}->setModel($relModel);
    this->{typeComboBox}->setModelColumn($relModel->fieldIndex('description'));

    this->{mapper} = Qt::DataWidgetMapper(this);
    this->{mapper}->setModel(this->{model});
    this->{mapper}->setItemDelegate(Qt::SqlRelationalDelegate(this));
    this->{mapper}->addMapping(this->{nameEdit}, this->{model}->fieldIndex('name'));
    this->{mapper}->addMapping(this->{addressEdit}, this->{model}->fieldIndex('address'));
    this->{mapper}->addMapping(this->{typeComboBox}, this->{typeIndex});
# [Set up the mapper]

# [Set up connections and layouts]
    this->connect(this->{previousButton}, SIGNAL 'clicked()',
            this->{mapper}, SLOT 'toPrevious()');
    this->connect(this->{nextButton}, SIGNAL 'clicked()',
            this->{mapper}, SLOT 'toNext()');
    this->connect(this->{mapper}, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'updateButtons(int)');

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->{nameLabel}, 0, 0, 1, 1);
    $layout->addWidget(this->{nameEdit}, 0, 1, 1, 1);
    $layout->addWidget(this->{previousButton}, 0, 2, 1, 1);
    $layout->addWidget(this->{addressLabel}, 1, 0, 1, 1);
    $layout->addWidget(this->{addressEdit}, 1, 1, 2, 1);
    $layout->addWidget(this->{nextButton}, 1, 2, 1, 1);
    $layout->addWidget(this->{typeLabel}, 3, 0, 1, 1);
    $layout->addWidget(this->{typeComboBox}, 3, 1, 1, 1);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('SQL Widget Mapper'));
    this->{mapper}->toFirst();
}
# [Set up connections and layouts]

# [Set up the main table]
sub setupModel
{
    my $db = Qt::SqlDatabase::addDatabase('QSQLITE');
    $db->setDatabaseName(':memory:');
    if (!$db->open()) {
        Qt::MessageBox::critical(undef, this->tr('Cannot open database'),
            this->tr("Unable to establish a database connection.\n" .
               'This example needs SQLite support. Please read ' .
               'the Qt SQL driver documentation for information how ' .
               'to build it.'), Qt::MessageBox::Cancel());
        return;
    }

    my $query = Qt::SqlQuery();
    $query->exec('create table person (id int primary key, ' .
               'name varchar(20), address varchar(200), typeid int)');
    $query->exec('insert into person values(1, \'Alice\', ' .
               '\'<qt>123 Main Street<br/>Market Town</qt>\', 101)');
    $query->exec('insert into person values(2, \'Bob\', ' .
               '\'<qt>PO Box 32<br/>Mail Handling Service' .
               '<br/>Service City</qt>\', 102)');
    $query->exec('insert into person values(3, \'Carol\', ' .
               '\'<qt>The Lighthouse<br/>Remote Island</qt>\', 103)');
    $query->exec('insert into person values(4, \'Donald\', ' .
               '\'<qt>47338 Park Avenue<br/>Big City</qt>\', 101)');
    $query->exec('insert into person values(5, \'Emma\', ' .
               '\'<qt>Research Station<br/>Base Camp<br/>' .
               'Big Mountain</qt>\', 103)');
# [Set up the main table]

# [Set up the address type table]
    $query->exec('create table addresstype (id int, description varchar(20))');
    $query->exec('insert into addresstype values(101, \'Home\')');
    $query->exec('insert into addresstype values(102, \'Work\')');
    $query->exec('insert into addresstype values(103, \'Other\')');

    this->{model} = Qt::SqlRelationalTableModel(this);
    this->{model}->setTable('person');
    this->{model}->setEditStrategy(Qt::SqlTableModel::OnManualSubmit());

    this->{typeIndex} = this->{model}->fieldIndex('typeid');

    this->{model}->setRelation(this->{typeIndex},
           Qt::SqlRelation('addresstype', 'id', 'description'));
    this->{model}->select();
}
# [Set up the address type table]

# [Slot for updating the buttons]
sub updateButtons
{
    my ($row) = @_;
    this->{previousButton}->setEnabled($row > 0);
    this->{nextButton}->setEnabled($row < this->{model}->rowCount() - 1);
}
# [Slot for updating the buttons]

1;
