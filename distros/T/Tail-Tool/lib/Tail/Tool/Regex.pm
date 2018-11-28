package Tail::Tool::Regex;

# Created on: 2011-03-10 17:42:50
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Moose::Util::TypeConstraints;
use English qw/ -no_match_vars /;
use Term::ANSIColor qw/colored/;

our $VERSION = version->new('0.4.8');

coerce 'RegexpRef'
    => from 'Str'
    => via { qr/$_/ };

has regex => (
    is       => 'rw',
    isa      => 'RegexpRef',
    default  => qw/^/,
    coerce   => 1,
    required => 1,
);
has replace => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_replace',
);
has colour => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_colour',
);
has enabled => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

sub summarise {
    my ($self, $term) = @_;

    my $text = "qr/" . $self->regex . "/";

    if ( $self->has_replace ) {
        $text .= $self->replace . '/';
    }

    if ( $self->has_colour ) {
        $text =
            $term ? colored( $text, join ' ', @{ $self->colour } )
            :       $text . ', colour=[' . ( join ', ', @{ $self->colour } ) . ']';
    }

    if ( !$self->enabled ) {
        $text =
            $term ? colored( "[$text]", 'reverse' )
            :       $text . ', disabled';
    }

    return $text;
}

1;

__END__

=head1 NAME

Tail::Tool::Regex - Base class for regex details

=head1 VERSION

This documentation refers to Tail::Tool::Regex version 0.4.8.

=head1 SYNOPSIS

   use Tail::Tool::Regex;

   # create a new object with a regex reference
   my $regex = Tail::Tool::Regex->new( regex => qr/^find/ );

   # if a string is passed it will be coerced into a regex reference
   $regex = Tail::Tool::Regex->new( regex => '^find' );

   # if replacement is to be done specify a replacement string
   $regex = Tail::Tool::Regex->new(
       regex   => qr/find$/,
       replace => 'found',
   );

   # if the regex is used for colouring specify the colours
   $regex = Tail::Tool::Regex->new(
       regex  => qr/find$/,
       colour => [qw/red on_green/],
   );

   # The regex can be set to being disabled initially
   $regex = Tail::Tool::Regex->new(
       regex   => qr/find/,
       enabled => 0,
   );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<summarise ( [$term] )>

Returns a summary of this modules settings, if C<$term> is true the string is
coloured for terminal displays.

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

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
