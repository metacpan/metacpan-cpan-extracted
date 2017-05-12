package Tail::Tool::RegexList;

# Created on: 2011-03-10 16:59:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Moose::Role;
use Moose::Util::TypeConstraints;
use version;
use English qw/ -no_match_vars /;
use Tail::Tool::Regex;

our $VERSION = version->new('0.4.7');

subtype 'ArrayRefRegex'
    => as 'ArrayRef[Tail::Tool::Regex]';

coerce 'ArrayRefRegex'
    => from 'ArrayRef'
    => via {
        my $array = $_;
        for my $item (@$array) {
            my ( $regex, $replace, $enabled ) = ('', '', 1);
            if ( $item =~ m{^/[^/]+?/,} ) {
                my $rest;
                ( $regex, $rest ) = split m{/,}, $item, 2;
                $regex =~ s{^/}{};

                if ( !defined $enabled ) {
                    $enabled = 1;
                }
            }
            elsif ( ( $regex, $replace, $enabled ) = $item =~ m{^/ ([^/]+?) / ([^/]+?) / (.)? $}xms ) {
                $enabled = defined $enabled && $enabled ne '' ? !!$enabled : 1;
            }
            else {
                $regex = $item;
                $enabled = 1,
            }
            $item = Tail::Tool::Regex->new(
                regex   => $regex,
                enabled => $enabled,
                $replace
                ? ( replace => $replace )
                : (),
            );
        }
        return $array;
    };

coerce 'ArrayRefRegex'
    => from 'RegexpRef'
    => via { [ Tail::Tool::Regex->new( regex => $_, enabled => 1 ) ] };

coerce 'ArrayRefRegex'
    => from 'Str'
    => via { [ Tail::Tool::Regex->new( regex => qr/$_/, enabled => 1 ) ] };

coerce 'ArrayRefRegex'
    => from 'Tail::Tool::Regex'
    => via { [ $_ ] };

has regex => (
    is     => 'rw',
    isa    => 'ArrayRefRegex',
    coerce => 1,
    trigger => \&_set_regex,
);

has replace => (
    is     => 'rw',
    isa    => 'Str',
);

sub summarise {
    my ($self, $term) = @_;

    my @out;
    for my $regex ( @{ $self->regex } ) {
        push @out, eval { $regex->summarise($term) };
        warn "regex not a propper Tail::Tool::Regex object: $@" if $@;
    }
    return join ', ', @out;
}

sub _set_regex {
    my ( $self, $regexs, $old_regexs ) = @_;

    for my $regex ( @{ $regexs } ) {
       # $regex->{enabled} ||= 0;
    }

    return;
}

1;

__END__

=head1 NAME

Tail::Tool::RegexList - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to Tail::Tool::RegexList version 0.4.7.


=head1 SYNOPSIS

   use Tail::Tool::RegexList;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<summarise ( [$term] )>

Returns a summary of this modules settings, setting C<$term> true results in
summary being coloured for terminal display

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
