package Tail::Tool::Plugin::GroupLines;

# Created on: 2011-04-04 14:42:01
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use AnyEvent;

extends 'Tail::Tool::PreProcess';
with 'Tail::Tool::RegexList';

our $VERSION = version->new('0.4.8');

has end => (
    is   => 'rw',
    isa  => 'Bool',
);
has allow_empty => (
    is   => 'rw',
    isa  => 'Bool',
    default => 1,
);
has files => (
    is      => 'rw',
    isa     => 'HashRef[HashRef]',
);

sub process {
    my ($self, $line, $file) = @_;

    if ( !$self->files ) {
        $self->files({});
    }

    my $match = grep {my $r = $_->regex; $_->enabled && $line =~ /$r/  } @{ $self->regex };

    if ( $match || $self->files->{$file->name}{show} ) {
        if ( $self->end ) {
            $line = "$self->files->{$file->name}{line}$line";
            $self->files->{$file->name}{line} = '';
        }
        else {
            my $new_line = $self->files->{$file->name}{line};
            $self->files->{$file->name}{line} = $line;
            $line = $new_line;
        }
        undef $self->files->{$file->name}{watcher} if !$self->files->{$file->name}{show};
        undef $self->files->{$file->name}{show};
    }
    else {
        $self->files->{$file->name}{line} .= $line;
        $line = undef;
        if ( !$self->end && !$self->files->{$file->name}{watcher} ) {
            # create a timer that will cause log lines to be written 2s after
            # they are first encounted when the match method is on the start of
            # the line, other wise these lines wont be shown until the next line
            # is found which may be some time.
            my $size = $file->size || 0;
            $self->files->{$file->name}{watcher} = AE::timer 2, 0, sub {
                $self->allow_empty(1);
                $self->files->{$file->name}{show} = 1;
                $file->run() if $file->size >= $size;
            };
        }
    }

    return defined $line ? ($line) : ();
}

1;

__END__

=head1 NAME

Tail::Tool::Plugin::GroupLines - Groups real lines of a log file so that other plugins treat then as one line.

=head1 VERSION

This documentation refers to Tail::Tool::Plugin::GroupLines version 0.4.8.

=head1 SYNOPSIS

   use Tail::Tool::Plugin::GroupLines;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Groups lines together so that they are presented as one line to other plugins.
It does this by checking each real log file line and checking if it matches
regex to indicate the start of a line (or if end is true the regex matches
the end of lines).

An example of why you might want to do this:

A log file with long data dumps that span many lines may be hard to filter out
but if those lines can be grouped together then only part of the line need
match for all lines to be excluded.

=head1 SUBROUTINES/METHODS

=head2 C<process ($line, $file)>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
