package TextEdit;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::TextEdit );
use QtCore4::slots
    insertCompletion => ['const QString &'];

sub c() {
    return this->{c};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    setPlainText(this->tr('This TextEdit provides autocompletions for words that have more than' .
                    ' 3 characters. You can trigger autocompletion using ') .
                    Qt::KeySequence('Ctrl+E')->toString(Qt::KeySequence::NativeText()));
}
# [0]

# [2]
sub setCompleter
{
    my ($completer) = @_;
    if (this->{c}) {
        Qt::Object::disconnect(c, 0, this, 0);
    }

    this->{c} = $completer;

    if (!c) {
        return;
    }

    c->setWidget(this);
    c->setCompletionMode(Qt::Completer::PopupCompletion());
    c->setCaseSensitivity(Qt::CaseInsensitive());
    Qt::Object::connect(c, SIGNAL 'activated(QString)',
                     this, SLOT 'insertCompletion(QString)');
}
# [2]

# [3]
sub completer
{
    return c();
}
# [3]

# [4]
sub insertCompletion
{
    my ($completion) = @_;
    if (c->widget() != this) {
        return;
    }
    my $tc = textCursor();
    $DB::single=1;
    my $extra = length($completion) - length(c->completionPrefix());
    $tc->movePosition(Qt::TextCursor::Left());
    $tc->movePosition(Qt::TextCursor::EndOfWord());
    $tc->insertText(substr $completion, -$extra);
    setTextCursor($tc);
}
# [4]

# [5]
sub textUnderCursor
{
    my $tc = textCursor();
    $tc->select(Qt::TextCursor::WordUnderCursor());
    return $tc->selectedText();
}
# [5]

# [6]
sub focusInEvent
{
    my ($e) = @_;
    if (c()) {
        c->setWidget(this);
    }
    this->SUPER::focusInEvent($e);
}
# [6]

# [7]
sub keyPressEvent
{
    my ($e) = @_;
    if (c && c->popup()->isVisible()) {
        # The following keys are forwarded by the completer to the widget
        my $key = $e->key();
        if ( $key == Qt::Key_Enter() ||
            $key == Qt::Key_Return() ||
            $key == Qt::Key_Escape() ||
            $key == Qt::Key_Tab() ||
            $key == Qt::Key_Backtab() ) {
                $e->ignore(); 
                return; # let the completer do default behavior
        }
    }

    my $isShortcut = ((($e->modifiers() & Qt::ControlModifier()) == Qt::ControlModifier()) && $e->key() == Qt::Key_E()); # CTRL+E
    if (!c || !$isShortcut) { # dont process the shortcut when we have a completer
        this->SUPER::keyPressEvent($e);
    }
# [7]

# [8]
    my $ctrlOrShift = $e->modifiers() & (Qt::ControlModifier() | Qt::ShiftModifier());
    if (!c || ($ctrlOrShift && !defined $e->text())) {
        return;
    }

    my $eow = '~!@#$%^&*()_+{}|:"<>?,./;\'[]\\-='; # end of word
    my $hasModifier = ($e->modifiers() != Qt::NoModifier()) && !$ctrlOrShift;
    my $completionPrefix = textUnderCursor();
    $completionPrefix = $completionPrefix ? $completionPrefix : '';

    my $lastChar = substr $e->text(), -1;
    if (!$isShortcut && ($hasModifier || !defined( $e->text() ) || length( $completionPrefix) < 3 
                      || $eow =~ m/$lastChar/)) {
        c()->popup()->hide();
        return;
    }

    my $ccompletionPrefix = c->completionPrefix;
    $ccompletionPrefix = $ccompletionPrefix ? $ccompletionPrefix : '';
    if ($completionPrefix ne $ccompletionPrefix) {
        c->setCompletionPrefix($completionPrefix);
        c->popup()->setCurrentIndex(c->completionModel()->index(0, 0));
    }
    my $cr = cursorRect();
    $cr->setWidth(c->popup()->sizeHintForColumn(0)
                + c->popup()->verticalScrollBar()->sizeHint()->width());
    c->complete($cr); # popup it up!
}
# [8]

1;
