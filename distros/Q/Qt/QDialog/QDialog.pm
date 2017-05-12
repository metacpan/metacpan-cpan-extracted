package QDialog;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QWidget;

@ISA = qw(Exporter DynaLoader QWidget);
@EXPORT = qw(%DialogCode);

$VERSION = '0.01';
bootstrap QDialog $VERSION;

1;
__END__

=head1 NAME

QDialog - Interface to the Qt QDialog class

=head1 SYNOPSIS

C<use QDialog;>

Inherits QWidget.

=head2 Member functions

new,
exec,
result

=head1 DESCRIPTION

What you see is what you get.

=head1 EXPORTED

The C<%DialogCode> hash is exported into the user's namespace. It just
has C<Accepted> and C<Rejected>.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
