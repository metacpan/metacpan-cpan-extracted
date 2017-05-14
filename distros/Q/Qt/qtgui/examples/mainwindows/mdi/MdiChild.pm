package MdiChild;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::TextEdit );
use QtCore4::slots
    documentWasModified => [''];

my $sequenceNumber = 1;

sub NEW {
    shift->SUPER::NEW(@_);
    this->setAttribute(Qt::WA_DeleteOnClose());
    this->{isUntitled} = 1;
}

sub newFile {
    this->{isUntitled} = 1;
    this->{curFile} = sprintf "document%d.txt", $sequenceNumber++;
    this->setWindowTitle(this->{curFile} . "[*]");

    this->connect(this->document(), SIGNAL 'contentsChanged()',
                  this, SLOT 'documentWasModified()');
}

sub loadFile {
    my ( $fileName ) = @_;
    if(!(open( FH, "< $fileName"))) {
        Qt::MessageBox::warning(this, "MDI",
                                 sprintf("Cannot read file %s:\n%s.",
                                 $fileName,
                                 $!));
        return 0;
    }

    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    this->setPlainText( join '', <FH> );
    Qt::Application::restoreOverrideCursor();
    close FH;

    setCurrentFile($fileName);

    this->connect(this->document(), SIGNAL 'contentsChanged()',
                  this, SLOT 'documentWasModified()');

    return 1;
}

sub save {
    if (this->{isUntitled}) {
        return saveAs();
    }
    else {
        return saveFile(this->{curFile});
    }
}

sub saveAs {
    my $fileName = Qt::FileDialog::getSaveFileName(this, "Save As",
                                                    this->{curFile});
    if (!$fileName) {
        return 0;
    }

    return saveFile($fileName);
}

sub saveFile {
    my ( $fileName ) = @_;
    if(!(open( FH, "> $fileName"))) {
        Qt::MessageBox::warning(this, "MDI",
                                 sprintf("Cannot write file %s:\n%s.",
                                 $fileName,
                                 $!));
        return 0;
    }

    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    print FH this->toPlainText();
    Qt::Application::restoreOverrideCursor();
    close FH;

    setCurrentFile($fileName);
    return 1;
}

sub userFriendlyCurrentFile {
    return strippedName(this->{curFile});
}

sub closeEvent {
    my ( $event ) = @_;
    if (maybeSave()) {
        $event->accept();
    } else {
        $event->ignore();
    }
}

sub documentWasModified {
    this->setWindowModified(this->document()->isModified());
}

sub maybeSave {
    if (this->document()->isModified()) {
        my $ret = Qt::MessageBox::warning(
                     this,
                     "MDI",
                     sprintf( "'%s' has been modified.\n" .
                         "Do you want to save your changes?",
                         userFriendlyCurrentFile() ),
                     CAST Qt::MessageBox::Save() | Qt::MessageBox::Discard() | Qt::MessageBox::Cancel(), 'QMessageBox::StandardButtons');
        if ($ret == Qt::MessageBox::Save()) {
            return save();
        }
        elsif ($ret == Qt::MessageBox::Cancel()) {
            return 0;
        }
    }
    return 1;
}

sub setCurrentFile {
    my ( $fileName ) = @_;
    this->{curFile} = Qt::FileInfo($fileName)->canonicalFilePath();
    this->{isUntitled} = 0;
    this->document()->setModified(0);
    this->setWindowModified(0);
    this->setWindowTitle(userFriendlyCurrentFile() . "[*]");
}

sub currentFile {
    if( defined this->{curFile} ) {
        return this->{curFile};
    }
    return '';
}

sub strippedName { 
    my ( $fullFileName ) = @_;
    return Qt::FileInfo($fullFileName)->fileName();
}

1;
