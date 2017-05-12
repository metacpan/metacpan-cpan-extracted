package Tail::Tool::Plugin::Spacing;

# Created on: 2010-10-06 14:17:00
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use List::MoreUtils qw/pairwise/;
use English qw/ -no_match_vars /;

extends 'Tail::Tool::PreProcess';

our $VERSION = version->new('0.4.7');

has last_time => (
    is       => 'rw',
    isa      => 'Int',
    init_arg => undef,
);
has times => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub {[]},
);
has lines => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub {[]},
);
has '+many' => (
    default => 0,
);

around BUILDARGS => sub {
    my ($orig, $class, @params) = @_;
    my %param;

    if ( ref $params[0] eq 'HASH' ) {
        %param = %{ shift @params };
    }
    else {
        %param = @params;
    }

    for my $param ( keys %param) {
        my $value = $param{$param};
        if ( !ref $value ) {
            $value = [ split /,/xms, $value ];
        }
        $param{$param} = $value;
    }

    return $class->$orig(%param);
};

sub process {
    my ( $self, $line ) = @_;
    my @lines = ($line);

    my $last = $self->last_time;
    $self->last_time(time);
    return @lines if !$last;

    my $diff = time - $last;

    for my $time ( pairwise {[$a, $b]} @{ $self->times }, @{ $self->lines } ) {
        unshift @lines, ("\n") x $time->[1] if $diff >= $time->[0];
    }

    return @lines;
}

sub summarise {
    my ($self) = @_;

    return "times = " . ( join ', ', @{ $self->times } ) . ", lines = " . ( join ', ', @{ $self->lines } );
}

1;

__END__

=head1 NAME

Tail::Tool::Plugin::Spacing - Prints spaces when there has been a pause in running.

=head1 VERSION

This documentation refers to Tail::Tool::Plugin::Spacing version 0.4.7.

=head1 SYNOPSIS

   use Tail::Tool::Plugin::Spacing;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

   my $sp = Tail::Tool::Plugin::Spacing(
       times => [ 2, 5 ],
       lines => [ 2, 5 ],
   );

   $sp->process("test\n");
   # returns ("test\n");

   ...

   # 2 seconds later
   $sp->process("test\n");
   # returns ( "\n", "\n", "test\n" );

   ...

   # another 5 seconds later
   $sp->process("test\n");
   # returns ( "\n", "\n", "\n", "\n", "\n", "\n", "\n", "test\n" );
   # ie 7 blank lines ( 2 lines + 5 lines )

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new (%params)>

Param: C<times> - [int] - The minimum time (in seconds) for a pause to be
considered to have occurred, resulting in the corresponding number of lines
(in the C<lines> argument) prepended to the found line.

Param: C<lines> - [int] - The number of lines to print when the corresponding
period in C<times> is reached.

Description: create a new object

=head2 C<process ()>

Description: Prints spaces based on time between last call and this one and
the settings.

=head2 C<summarise ()>

Returns a string that summarise the current settings of the plugin instance

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

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
