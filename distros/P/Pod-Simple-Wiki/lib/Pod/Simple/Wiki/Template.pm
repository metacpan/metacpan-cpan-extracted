package Pod::Simple::Wiki::Template;

# Portme: This module is used as a boiler plate or example of how to create a
# new C<Pod::Simple::Wiki::> module.
#
# Read the Portme section of the documentation below for more information.
#
# Portme. Try to maintain the same code style as this module:
#     perltidy with the following options: -mbl=2 -pt=0 -nola


###############################################################################
#
# Pod::Simple::Wiki::Template - A class for creating Pod to Template filters.
#
#
# Copyright 2003-2012, John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#

# perltidy with the following options: -mbl=2 -pt=0 -nola

use Pod::Simple::Wiki;
use strict;
use vars qw(@ISA $VERSION);


@ISA     = qw(Pod::Simple::Wiki);
$VERSION = '0.20';

# Portme. Start with these tags.

###############################################################################
#
# The tag to wiki mappings.
#
my $tags = {
    '<b>'    => '*',
    '</b>'   => '*',
    '<i>'    => '/',
    '</i>'   => '/',
    '<tt>'   => '[=',
    '</tt>'  => ']',
    '<pre>'  => '',
    '</pre>' => "\n\n",

    '<h1>'  => "\n----\n= ",
    '</h1>' => " =\n\n",
    '<h2>'  => "\n== ",
    '</h2>' => " ==\n\n",
    '<h3>'  => "\n=== ",
    '</h3>' => " ===\n\n",
    '<h4>'  => "==== ",
    '</h4>' => "\n\n",
};

# Portme. You can leave new() as it is.

###############################################################################
#
# new()
#
# Simple constructor inheriting from Pod::Simple::Wiki.
#
sub new {

    my $class = shift;
    my $self = Pod::Simple::Wiki->new( 'wiki', @_ );
    $self->{_tags} = $tags;

    bless $self, $class;
    return $self;
}

# Portme. How Pod "=over" blocks are converted to Template wiki lists.

###############################################################################
#
# _indent_item()
#
# Indents an "over-item" to the correct level.
#
sub _indent_item {

    my $self         = shift;
    my $item_type    = $_[0];
    my $item_param   = $_[1];
    my $indent_level = $self->{_item_indent};

    if ( $item_type eq 'bullet' ) {
        $self->_append( '*' x $indent_level . ' ' );
    }
    elsif ( $item_type eq 'number' ) {
        $self->_append( '0' x $indent_level . ' ' );
    }
    elsif ( $item_type eq 'text' ) {
        $self->_append( ';' x $indent_level . ' ' );
    }
}

# Portme: Use this is text tokens need to be escaped, such as CamelCase words.

###############################################################################
#
# _handle_text()
#
# Perform any necessary transforms on the text. This is mainly used to escape
# inadvertent CamelCase words.
#
sub _handle_text {

    my $self = shift;
    my $text = $_[0];

    # Only escape words in paragraphs
    if ( not $self->{_in_Para} ) {
        $self->{_wiki_text} .= $text;
        return;
    }

    # Split the text into tokens but maintain the whitespace
    my @tokens = split /(\s+)/, $text;

    # Portme:
    # Escape any tokens here, if necessary.

    # Rejoin the tokens and whitespace.
    $self->{_wiki_text} .= join '', @tokens;
}


# Portme. How Pod "=over" blocks are converted to Template wiki lists.

###############################################################################
#
# Functions to deal with =over ... =back regions for
#
# Bulleted lists
# Numbered lists
# Text     lists
# Block    lists
#
sub _end_item_text { $_[0]->_output( ' ; ' ) }


# Portme: Probably won't have to change this.

###############################################################################
#
# _start_Para()
#
# Special handling for paragraphs that are part of an "over" block.
#
sub _start_Para {

    my $self         = shift;
    my $indent_level = $self->{_item_indent};

    if ( $self->{_in_over_block} ) {

        # Do something here is necessary
    }
}


1;


__END__


=head1 NAME

Pod::Simple::Wiki::Template - A class for creating Pod to Template wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('template');

    ...


Convert Pod to a Template wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style template file.pod > file.wiki


=head1 DESCRIPTION

This module is used as a boiler plate or example of how to create a new C<Pod::Simple::Wiki::> module. See the Portme section below.

The C<Pod::Simple::Wiki::Template> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Template see: L<http://www.portme.org>.

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.


=head1 PORTME

This module is used as a boiler plate or example of how to create a new C<Pod::Simple::Wiki::> module.

If you are thinking of creating a new C<Pod::Simple::Wiki::> you should use this module as a basis.

B<Portme>. Any comments in the code or documentation that begin with or contain the word C<portme> are intended for the C<porter>, the person who is creating the new module. You should read all of the C<portme> comments and eventually delete them when the module is finished.

The following are some suggested steps in porting the module. For the sake of example say we wish to convert Pod to a format called C<portmewiki>. Also for the sake of this example we will assume that you know how to install and work on a module or work on it in a local source tree using C<-I./lib> or C<-Mblib>.


=head2 Portme Step 1

Fork, clone or download the latest version of C<Pod::Simple::Wiki> from the github repository: L<http://github.com/jmcnamara/pod-simple-wiki/>

Copy the C</lib/Pod/Simple/Wiki/Template.pm> to a new module C</lib/Pod/Simple/Wiki/Portmewiki.pm>.

The module name should have the first letter capitalised and all others lowercase, i.e, the same as returned by C<ucfirst()>.


=head2 Portme Step 2

Edit the module and replace all instances of C<Template> with C<Portmewiki> (case sensitive).

Then replace all instances of C<template> with C<portmewiki> (case sensitive).


=head2 Portme Step 3

The module should now work and can now be called as follows:

    use Pod::Simple::Wiki;

    my $parser = Pod::Simple::Wiki->new('portmewiki');

The default output format, in this configuration is Kwiki.


=head2 Portme Step 4

Write some tests.

Copy the tests in the C</t> directory for one of formats that is similar to the format that you are porting.


=head2 Portme Step 5

Modify the source of C<Portmewiki.pm> until all the tests pass and you are happy with the output format.

Start by modifying the C<tags> and then move on to the other methods.

If you encounter problems then you can turn on internal debugging:

    my $parser = Pod::Simple::Wiki->new('portmewiki');
    $parser->_debug(1);

    Or for more debug information that you can deal with:

    # At the start of your program and before anything else:
    use Pod::Simple::Debug (5);

    ...

    $parser->_debug(0);

If you find yourself with a difficult porting issue then you may also wish to read L<Pod::Simple::Methody> and L<Pod::Simple::Subclassing>.

Try to maintain the code style of this module. See the source for more information.


=head2 Portme Step 6

Remove or replace all C<portme> comments.


=head2 Portme Step 7

Send me a git pull request on Github with libs and tests and I'll release it to CPAN.


=head1 METHODS

Pod::Simple::Wiki::Template inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.

=head1 Template Specific information

Portme: Add some information specific to the Template format or this module here. If required.


=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 ACKNOWLEDGEMENTS

Thanks to Portme McPortme and Portme O'Portme for patches, documentation or bugfixes.


=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.


=head1 AUTHORS

John McNamara jmcnamara@cpan.org

Portme McPortme portme@portme.org


=head1 COPYRIGHT

MMIII-MMXV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
