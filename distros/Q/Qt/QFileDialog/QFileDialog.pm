package QFileDialog;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QDialog;

@ISA = qw(DynaLoader QDialog);

$VERSION = '0.01';
bootstrap QFileDialog $VERSION;

1;
__END__

=head1 NAME

QFileDialog - Interface to the Qt QFileDialog class

=head1 SYNOPSIS

C<use QFileDialog;>

Inherits QDialog.

=head2 Member functions

new,
dirPath,
getOpenFileName,
getSaveFileName,
rereadDir,
selectedFile,
setDir

=head1 DESCRIPTION

What you see is what you get.

=head1 CAVEATS

Implementing QDir is not on my todo list. I may provide a dir-name stub,
but nothing good is likely before PerlQt-1.00. Get used to it.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
