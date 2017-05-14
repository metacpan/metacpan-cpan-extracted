package SettingsTree;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::TreeWidget );
use QtCore4::slots
    setAutoRefresh => ['bool'],
    setFallbacksEnabled => ['bool'],
    maybeRefresh => [],
    refresh => [],
    updateSetting => ['QTreeWidgetItem *'];
use VariantDelegate;

sub settings() {
    return this->{settings};
}

sub refreshTimer() {
    return this->{refreshTimer};
}

sub autoRefresh() {
    return this->{autoRefresh};
}

sub groupIcon() {
    return this->{groupIcon};
}

sub keyIcon() {
    return this->{keyIcon};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    setItemDelegate(VariantDelegate(this));

    my @labels = (this->tr('Setting'), this->tr('Type'), this->tr('Value'));
    setHeaderLabels(\@labels);
    header()->setResizeMode(0, Qt::HeaderView::Stretch());
    header()->setResizeMode(2, Qt::HeaderView::Stretch());

    this->{settings} = undef;
    this->{refreshTimer} = Qt::Timer(this);
    refreshTimer->setInterval(2000);
    this->{autoRefresh} = 0;

    this->{groupIcon} = Qt::Icon();
    this->{keyIcon} = Qt::Icon();
    groupIcon->addPixmap(style()->standardPixmap(Qt::Style::SP_DirClosedIcon()),
                        Qt::Icon::Normal(), Qt::Icon::Off());
    groupIcon->addPixmap(style()->standardPixmap(Qt::Style::SP_DirOpenIcon()),
                        Qt::Icon::Normal(), Qt::Icon::On());
    keyIcon->addPixmap(style()->standardPixmap(Qt::Style::SP_FileIcon()));

    this->connect(refreshTimer(), SIGNAL 'timeout()', this, SLOT 'maybeRefresh()');
}

sub setSettingsObject
{
    my ($settings) = @_;
    if ( defined this->settings() ) {
        this->settings->setParent(undef);
    }
    this->{settings} = $settings;
    clear();

    if ($settings) {
        $settings->setParent(this);
        refresh();
        if (autoRefresh) {
            refreshTimer->start();
        }
    } else {
        refreshTimer->stop();
    }
}

sub sizeHint
{
    return Qt::Size(800, 600);
}

sub setAutoRefresh
{
    my ($autoRefresh) = @_;
    this->{autoRefresh} = $autoRefresh;
    if (settings()) {
        if (autoRefresh()) {
            maybeRefresh();
            refreshTimer->start();
        } else {
            refreshTimer->stop();
        }
    }
}

sub setFallbacksEnabled
{
    my ($enabled) = @_;
    if (settings()) {
        settings()->setFallbacksEnabled($enabled);
        refresh();
    }
}

sub maybeRefresh
{
    if (state() != Qt::TreeWidget::EditingState()) {
        refresh();
    }
}

sub refresh
{
    if (!settings()) {
        return;
    }

    disconnect(this, SIGNAL 'itemChanged(QTreeWidgetItem*,int)',
               this, SLOT 'updateSetting(QTreeWidgetItem*)');

    settings->sync();
    updateChildItems(undef);

    this->connect(this, SIGNAL 'itemChanged(QTreeWidgetItem*,int)',
            this, SLOT 'updateSetting(QTreeWidgetItem*)');
}

sub event
{
    my ($event) = @_;
    if ($event->type() == Qt::Event::WindowActivate()) {
        if (isActiveWindow() && autoRefresh) {
            maybeRefresh();
        }
    }
    return this->SUPER::event($event);
}

sub updateSetting
{
    my ($item) = @_;
    my $key = $item->text(0);
    my $ancestor = $item->parent();
    while ($ancestor) {
        $key = $ancestor->text(0) . '/' . $key;
        $ancestor = $ancestor->parent();
    }

    settings->setValue($key, $item->data(2, Qt::UserRole()));
    if (autoRefresh) {
        refresh();
    }
}

sub updateChildItems
{
    my ($parent) = @_;
    my $dividerIndex = 0;

    foreach my $group ( @{settings->childGroups()} ) {
        my $child = Qt::TreeWidgetItem();
        my $childIndex = findChild($parent, $group, $dividerIndex);
        if ($childIndex != -1) {
            $child = childAt($parent, $childIndex);
            $child->setText(1, '');
            $child->setText(2, '');
            $child->setData(2, Qt::UserRole(), Qt::Variant());
            moveItemForward($parent, $childIndex, $dividerIndex);
        } else {
            $child = createItem($group, $parent, $dividerIndex);
        }
        $child->setIcon(0, groupIcon);
        ++$dividerIndex;

        settings->beginGroup($group);
        updateChildItems($child);
        settings->endGroup();
    }

    foreach my $key ( @{settings->childKeys()} ) {
        my $child = Qt::TreeWidgetItem();
        my $childIndex = findChild($parent, $key, 0);

        if ($childIndex == -1 || $childIndex >= $dividerIndex) {
            if ($childIndex != -1) {
                $child = childAt($parent, $childIndex);
                for (my $i = 0; $i < $child->childCount(); ++$i) {
                    childAt($child, $i)->DESTROY();
                }
                moveItemForward($parent, $childIndex, $dividerIndex);
            } else {
                $child = createItem($key, $parent, $dividerIndex);
            }
            $child->setIcon(0, keyIcon);
            ++$dividerIndex;
        } else {
            $child = childAt($parent, $childIndex);
        }

        my $value = settings->value($key);
        if ($value->type() == Qt::Variant::Invalid()) {
            $child->setText(1, 'Invalid');
        } else {
            $child->setText(1, $value->typeName());
        }
        $child->setText(2, VariantDelegate::displayText($value));
        $child->setData(2, Qt::UserRole(), $value);
    }

    while ($dividerIndex < childCount($parent)) {
        childAt($parent, $dividerIndex)->DESTROY();
    }
}

sub createItem
{
    my ($text, $parent, $index) = @_;
    my $after = 0;
    if ($index != 0) {
        $after = childAt($parent, $index - 1);
    }

    my $item = Qt::TreeWidgetItem();
    if ($parent) {
        $item = Qt::TreeWidgetItem($parent, $after);
    }
    else {
        $item = Qt::TreeWidgetItem(this, $after);
    }

    $item->setText(0, $text);
    $item->setFlags($item->flags() | Qt::ItemIsEditable());
    return $item;
}

sub childAt
{
    my ($parent, $index) = @_;
    if ($parent) {
        return $parent->child($index);
    }
    else {
        return topLevelItem($index);
    }
}

sub childCount
{
    my ($parent) = @_;
    if ($parent) {
        return $parent->childCount();
    }
    else {
        return topLevelItemCount();
    }
}

sub findChild
{
    my ($parent, $text, $startIndex) = @_;
    for (my $i = $startIndex; $i < childCount($parent); ++$i) {
        if (childAt($parent, $i)->text(0) eq $text) {
            return $i;
        }
    }
    return -1;
}

sub moveItemForward
{
    my ($parent, $oldIndex, $newIndex) = @_;
    for (my $i = 0; $i < $oldIndex - $newIndex; ++$i) {
        # XXX delete childAt($parent, $newIndex);
    }
}

1;
