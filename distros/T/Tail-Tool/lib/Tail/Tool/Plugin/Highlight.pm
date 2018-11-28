package Tail::Tool::Plugin::Highlight;

# Created on: 2010-10-06 14:16:20
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Term::ANSIColor;
use Readonly;

extends 'Tail::Tool::PostProcess';
with 'Tail::Tool::RegexList';

our $VERSION = version->new('0.4.8');

Readonly my @COLOURS => qw/
    red
    green
    yellow
    blue
    magenta
    cyan
    on_red
    on_green
    on_yellow
    on_blue
    on_magenta
    on_cyan
    bold
/;

has colourer => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { \&colored },
    trigger => \&_set_colourer,
);

sub process {
    my ($self, $line) = @_;
    my $matches;
    my @colours = @COLOURS;

    $self->colourer( \&colored ) if !$self->colourer;
    $self->_set_colourer($self->colourer);

    for my $match ( @{ $self->regex } ) {
        next if !$match->enabled;

        $match->colour( [ shift @colours || 'red' ] ) if !$match->colour;

        # count the number of internal matches
        my $count = $match->regex =~ /( [(] (?! [?] ) )/gxms || 0;
        my @parts = split /($match->{regex})/, $line;
        $line = '';

        for my $i ( 0 .. @parts -1 ) {
            if ( $i % ($count + 2) == 0 ) {
                # non matching text
                $line .= $parts[$i];
            }
            elsif ( $i % ($count + 2) == 1 ) {
                $line .= $self->colourer->( $match->colour, $parts[$i] );
            }
        }
    }

    # return empty array if there were enabled matches else return the line
    return ($line);
}

sub _set_regex {
    my ( $self, $regexs, $old_regexs ) = @_;

    my $i = 0;
    for my $regex ( @{ $regexs } ) {
        $regex->colour( [ $COLOURS[$i % @COLOURS] ] ) if !$regex->has_colour;
        $i++;
    }

    return;
}

sub _set_colourer {
    my ( $self, $new, $old ) = @_;

    my $test = $new->( ['red'], 'thing' );

    if ( !$test || $test eq 'DUMMY' ) {
        $self->colourer( \&colored );
    }

    return;
}

1;

__END__

=head1 NAME

Tail::Tool::Plugin::Highlight - Highlights any text that matches the supplied regular expressions.

=head1 VERSION

This documentation refers to Tail::Tool::Plugin::Highlight version 0.4.8.


=head1 SYNOPSIS

   use Tail::Tool::Plugin::Highlight;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new (%params)>

Param: regex - ArrayRef - List of regular expressions that lines must match

Param: colourer - CodeRef - A sub that takes an array ref of colour
specifications as the first argument and the text to be coloured as the second
argument. The default colourer is the colored function from L<Term::ANSIColor>

=head2 C<process ($line)>

Description: Checks if the line matches any of the regular expressions supplied
then colours the matched parts and returns the changed line.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gamil.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gamil.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia, 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
