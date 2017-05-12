package PostScript::CDCover;
use strict;

# $Id: CDCover.pm,v 1.9 2004/05/28 22:05:20 cbouvi Exp $
#
#  Copyright (C) 2004 Cédric Bouvier
#
#  This library is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the Free
#  Software Foundation; either version 2 of the License, or (at your option)
#  any later version.
#
#  This library is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this library; if not, write to the Free Software Foundation, Inc., 59 Temple
#  Place, Suite 330, Boston, MA  02111-1307  USA

# $Log: CDCover.pm,v $
# Revision 1.9  2004/05/28 22:05:20  cbouvi
# Forced boolean options to 1 and 0. Updated POD
#
# Revision 1.8  2004/05/28 21:32:26  cbouvi
# Updated POD
#
# Revision 1.7  2004/05/26 22:01:13  cbouvi
# Added POD
#
# Revision 1.6  2004/05/26 21:01:37  cbouvi
# Added comments.
# Files appear now one level deeper than their directory.
# Fixed the removal of the root directory.
#
# Revision 1.5  2004/05/22 21:07:47  cbouvi
# Fixed starting depth and difference between files and dirs depth
#
# Revision 1.4  2004/05/21 20:51:45  cbouvi
# Moved all the functionality to PostScript::CDCover
#
# Revision 1.3  2004/05/10 21:26:48  cbouvi
# Added $VERSION
#
# Revision 1.2  2004/05/04 21:21:31  cbouvi
# Added output() method. Remove non strictly Cover related options
#
# Revision 1.1  2004/04/11 19:36:32  cbouvi
# Started conversion of pscdcover to PostScript::CDCover
#

use vars qw/ $VERSION /;
$VERSION = 1.0;

use File::Basename qw/ dirname /;
use File::Path     qw/ mkpath /;

package PostScript::CDCover::Directory;

# Constructor
# Directory name as optional argument
sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;
    $self->{_name} = $_[0] if @_;
    return $self;
}

sub name {

    my $self = shift;
    ($self->{_name}, @_ && ($self->{_name} = $_[0]))[0];
}

# Returns the PostScript::CDCover::Directory object for a given subdirectory.
# If no argument is given, return $self.
# If the directory object does not exist, it is created.
sub directory {

    my ($self, $name) = @_;

    return $self unless $name;
    return $self->{_directories}{$name} ||= new PostScript::CDCover::Directory $name;
}

# Add a directory, somewhere in the subtree, i.e., if the new directory is more
# than one level below the current one, the actual addition is delegated to a
# first level subdirectory.
sub add_directory {

    my ($self, $path) = @_;

    $path =~ s|^[/\\]||;
    my ($head, $rest) = split m|[/\\]|, $path, 2;
    my $dir = $self->directory($head);
    $dir->add_directory($rest) if $rest;
}

# Add a file somewhere in the subtree. If the file does not belong to the
# current directory, the task of adding it is delegated to a subdirectory
# (which, in turn, can delegate to one of its own subdirectories, and so on).
sub add_file {

    my ($self, $path) = @_;

    $path =~ s|^[/\\]||;
    my ($head, $rest) = split m|[/\\]|, $path, 2;
    if ( $rest ) {
        $self->directory($head)->add_file($rest);
    }
    else {
        push @{$self->{_files}}, $head;
    }
}

# Returns a string consisting of all the calls to the Postscript program
# function file_title or folder_title for the current directory.
# A $depth parameter can optionally be specified for indentation.
# as_ps() will recursively call itself on every subdirectories with an
# incremented $depth, thus generating the output for all the subtree.
sub as_ps {

    my $self = shift;
    # The root has an empty name and is not display. All the subdirectories
    # start at level 0. The root is thus as it were at level -1
    my $depth = @_ ? shift : -1;
    my $indent = '  ' x $depth; # indentation in the Postscript source code

    my $name = PostScript::CDCover::_quote_paren($self->name());
    my @output;

    # A line for the directory itself
    @output = (qq{$indent($name) $depth folder_title}) if $name; 

    # Now for its subdirectories
    for ( sort keys %{$self->{_directories}} ) {
        push @output, $self->{_directories}{$_}->as_ps($depth+1);
    }

    ++$depth;
    # And finally, its files
    if ( $self->{_files} ) {
        for ( sort @{$self->{_files}} ) {
            my $n = PostScript::CDCover::_quote_paren($_);
            push @output, qq{$indent  ($n) $depth file_title};
        }
    }

    return join "\n", @output;
}

package PostScript::CDCover;

# returns the directory where CDCover.pm (this very file) resides.
sub dir {
    (my $module = __PACKAGE__ ) =~ s|::|/|g;
    dirname( $INC{"$module.pm"} )
}

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    my %attr = @_;
    while ( my ($attr, $value) = each %attr ) {
        $attr =~ s/^-+//;
        $attr = lc $attr;

        $self->$attr($value);
    }
    return $self;
}

# Insert a backslash before any parenthesis
sub _quote_paren {

    local $_ = $_[0];
    s/\(/\\(/g;
    s/\)/\\)/g;
    return $_;
}

# Change an hexa triplet (like those used for colors in HTML or CSS) into a
# list of three decimal numbers suitable for PostScript setrgbcolor function.
sub _split_color {

    map $_/255, unpack 'xC3', pack 'N', $_[0];
}

# An accessor (read/write) with a default value: the Postscript code is located
# in the same directory as CDCover.pm itself.
sub ps {

    my $self = shift;

    (
        ($self->{_ps} ||= $self->dir() . '/pscdcover.ps'),
        @_ && ($self->{_ps} = $_[0])
    )[0];
}

#
# _output
#
# This function outputs a chunk of text to "somewhere", this being a coderef,
# or file handle, or a reference to a string, or a filename.
# Code borrowed from the Template Toolkit by Andy Wardley.
#
sub _output {

    my ($where, $text, $binmode) = @_;
    my $reftype = ref($where);
    my $error;

    if ( $reftype eq 'CODE' ) {
        $where->($text);
    }
    elsif ( $reftype eq 'GLOB' ) {
        print $where $text;
    }
    elsif ($reftype eq 'SCALAR' ) {
        $$where .= $text;
    }
    elsif ( UNIVERSAL::can($where, 'print') ) {
        $where->print($text);
    }
    else {
        $error = "Cannot determine target type ($where)\n";
    }

    return $error;
}

# Returns (after creating it if need be) the root directory object.
sub root_directory {

    my $self = shift;

    return $self->{_root_directory} ||= new PostScript::CDCover::Directory;
}

# Adds a directory to the tree, after trimming the root directory
sub add_directory {

    my ($self, $dir) = @_;
    my $root = quotemeta $self->root();

    $dir =~ s/^$root//;
    $self->root_directory()->add_directory($dir);
}

# Adds a file to the subtree.
sub add_file {

    my ($self, $file) = @_;
    my $root = quotemeta $self->root();

    $file =~ s/^$root//;
    $self->root_directory()->add_file($file);
}

# Outputs the Postscript source code
sub flush {

    my $self = shift;

    open my $fh, $self->ps() or die "Cannot open @{[$self->ps()]}: $!\n";
    
    while ( <$fh> ) {
        if ( my $in = (/#START_CONTENT#/ .. /#STOP_CONTENT#/) ) {
            # Generate the Postscript code for the directory tree
            next unless $in == 1; # only once
            _output $self->output(), $self->root_directory()->as_ps();
        }
        else {
            # Keyword substitution
            s[#FORCE_ALL_PAGES#][$self->all() ? 1 : 0]e;
            s[#CD_TITLE#]       [_quote_paren($self->title())]e;
            s[#COLUMNS#]        [$self->columns() || 0]e;
            s[#MIN_WIDTH#]      [$self->minwidth()]e;
            s[#SEPARATOR#]      [$self->separator() ? 1 : 0]e;
            s[#COLOR#]          [$self->color() ? 1 : 0]e;
            s[#CD_COLOR#]       [join ' ', _split_color $self->cdcolor()]e;
            s[#FOLDER_COLOR#]   [join ' ', _split_color $self->foldercolor()]e;
            # Remove the box drawing code if we don't want it
            next if !$self->box() && /#START_BOX#/ .. /#STOP_BOX#/;

            _output $self->output(), $_;
        }
    }
}

# Building accessors for configuration parameters.
# Each key in the hash will be turned into a method that returns the value of
# the corresponding attribute or sets it, when called with an argument. If a
# value is provided in the hash, the method will yield a default value.
{
    my %attr = (
        all         => 0,
        box         => 1,
        columns     => 2,
        minwidth    => 25,
        separator   => 0,
        title       => undef,
        color       => 0,
        cdcolor     => 0xccd8e5,
        foldercolor => 0xffff80,
        output      => \*STDOUT,
        root        => '/media/cdrom',
    );

    while (my ($meth, $default) = each %attr ) {
        no strict 'refs';
        *$meth = sub {
            my $self = shift;
            ((defined($self->{"_$meth"}) ? $self->{"_$meth"} : $default),
             @_ && ($self->{"_$meth"} = $_[0]))[0];
        }
    }
}

1;

=head1 NAME

PostScript::CDCover - a simple module that generates CD covers in Postscript

=head1 SYNOPSIS

    use PostScript::CDCover;

    my $cd = new PostScript::CDCover -root => 'root', -title => 'Backup';
    $cd->add_file('root/sub1/file11');
    $cd->add_file('root/sub1/file12');
    $cd->add_file('root/sub2/file21');
    $cd->add_file('root/sub2/file22');

    $cd->flush();

=head1 DESCRIPTION

This class generates a Postscript program that prints a CD cover suitable for a
CD jewel case. A directory tree is printed on the cover in columns, first on
the front page, then on the inner page (the one that is visible when the box is
open), and finally on the back label. All in all, the output consists of two A4
pages, one for the front and inner pages, and one for the back label. People
using exotic paper formats should still be able to print, provided that their
paper size is close enough to A4, as the labels are drawn rather far from the
paper edge. Notably, printing on Letter has been reported to not cause any
trouble.

A title is printed on top of the front page, and on the sides of the back
label. Various attributes alter the behaviour of the module and the layout of
the generated cover.

Typically, a program using this module should:

=over 4

=item *

Instantiate the PostScript::CDCover class, possibly giving values to attributes
by passing arguments to the constructor. Setting these values can also be
achieved by calling the accessor methods directly.

=item *

Feed information about subdirectories and files in the directory tree by means
of the add_directory() and add_file() methods.

=item *

Call the flush() method to actually generate the Postscript program.

=back

Such a program (too usable actually to be called a mere example) is shipped
with this module: pscdcover(1)

=head2 Editing the output

The output generated by the flush() method can be directly printed or converted
to PDF or whatever. However, it has been designed to be easily modified, even
without much knowledge of the Postscript language.

The layout of the file and directory names in the different columns and pages
is done by the PostScript program. This makes it possible and easy to edit the
resulting PostScript program with a text editor and remove some lines.

The editable section looks like this (text within parentheses are the files and
directory names, the figure that follows it is the depth in the directory tree):

    (directory 1) 0 folder_title
      (file 1) 1 file_title
      (file 2) 1 file_title
      (file 3) 1 file_title
      (file 4) 1 file_title
      (file 5) 1 file_title
      (file 6) 1 file_title
      (file 7) 1 file_title
      (file 8) 1 file_title
      (file 9) 1 file_title
      (file 10) 1 file_title
      (file 11) 1 file_title
      (file 12) 1 file_title
    (directory 2) 0 folder_title

In order to shorten the list (so that it fits on the three pages, for
instance), you may simply change the above to:

    (directory 1) 0 folder_title
      (...) 1 file_title
      (lots of files) 1 file_title
      (...) 1 file_title
    (directory 2) 0 folder_title

You need not worry about the final layout, whether a directory has changed
columns or not, all this is taken care of by the PostScript interpreter.

=head2 Constructor

new() creates and returns an instance of PostScript::CDCover. new() accepts as
arguments a list of key/value pairs to initialize attributes. Each value is
simply passed to the method named after the key. The key may optionally be
prefixed with a dash, and of course, the use of double-barrel arrows C<< => >>
is recommended for readability.

These two code snippets are equivalent:

    my $cd = new PostScript::CDCover;
    $cd->all(1);
    $cd->box(1);
    $cd->files(0);

    my $cd = new PostScript::CDCover -all => 1, -box => 1, -files => 0;

=head2 Attributes

Attributes are accessed through accessor methods. These methods, when called
without aN ARGUMENt, will return the attribute's value. With an argument, they
will set the attribute's value to that argument, and return the former value.

When applicable, the default value is given in parentheses.

=over 4

=item B<all> (I<0>)

Forces the printing of all the pages (front and back), even if the whole
directory tree could be printed on only the first page.

=item B<box> (I<1>)

By default, the edges of the cover are drawn in dim gray. Set this to 0 to
prevent this (only the text will be printed out). You probably want to leave
the default if you use cisors to cut the covers.

=item B<color> (I<0>)

Generate color output: the CD and folder icons will be drawn in colors. The
colors can be changed with the C<cdcolor> and C<foldercolor> attributes.

=item B<cdcolor> (I<0xccd8e5>, i.e. light blue)

=item B<foldercolor> (I<0xffff80>, i.e. light yellow)

Colors of the CD icon and folder icon, respectively. They should be the integer
value of an hexadecimal triplet representing the shares of red, green and blue
in the desired color, like those commonly found in HTML or CSS.

=item B<columns> (I<2>)

The number of columns to print on each page. When set to 0, the column widths
will be calculated dynamically, so that the longest filename in each column
fits.

=item B<minwidth> (I<25>)

The minimum allowed width for a column (in millimeters). If the room left on
the right side of the page is lower than this limit, the next column will be
printed on the next page. This option is only relevant with C<columns> set to
0.

=item B<output> (I<\*STDOUT>)

Where the generated PostScript code will be written to. The value can be one
of: a file GLOB opened ready for output (the default is C<\*STDOUT>, meaning
the standard output), a reference to a scalar to which the output is appended,
a reference to a subroutine which is called, passing the output as a parameter,
or any object reference which implements a print() method (e.g. IO::Handle)
which will be called, passing the generated output as a parameter.

=item B<ps>

The path to the Postscript program. This is actually a template as it requires
some processing before being fed to the printer. By default, the template is
located in the same directory as the PostScript::CDCover module itself.

=item B<root> (I</media/cdrom>)

The directory at the root of the CD-ROM, i.e., its mount point. This value will
be removed from entries added with add_directory() or add_file(), so that the
CD-ROM mount point does not show on the CD cover.

=item B<separator> (I<0>)

Set this to 1 to draw a line as column separator.

=item B<title> (I<undef>)

Provides a title for the CD. The title will be printed on top of the first
page, and on the sides of the back label.

=back

=head2 Methods

=over 4

=item B<add_directory>(I<path>)

=item B<add_file>(I<path>)

Adds a directory or a file to the CD content. The I<path> argument should start
with the value of attribute root(). Both add_directory() and add_file() will
call add_directory() for any parent directory along the way. Calling
add_directory() is still useful for empty directories, non empty ones would be
created when adding files within.

=item B<flush>

Generates the Postscript program, taking all the attributes and the contents into account.
flush() can called repeatedly, changing a couple of attributes in between, e.g.:

    $cd->color(1);
    $cd->flush();
    $cd->color(0);
    $cd->flush();

=back

=head1 BUGS

Very likely.

=head1 SEE ALSO

pscdcover(1)

=head1 AUTHOR

Copyright © 2004

Cédric Bouvier <cbouvi@cpan.org>

Thank you to Terry Gliedt, Sean the RIMBoy, Michael M. Tung for their help with
bug fixing and enhancing, and to Andy Wardley (of Template Toolkit fame) whom I
borrowed the versatile output destination code from.

=cut
