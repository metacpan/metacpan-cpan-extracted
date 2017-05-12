#!/usr/bin/perl
# $Id: Wrap.pm,v 1.3 2004/01/08 03:20:16 nothingmuch Exp $

package Pod::Wrap;

use strict;
use warnings;

use Text::Wrap;
use base 'Pod::Parser';

our $VERSION = 0.01;

sub begin_input {
    my $self = shift;
    
    $self->parseopts(           # we need some special options:
        '-want_nonPODs' => 1,       # want the perl code
        '-process_cut_cmd' => 9,    # want to preserve cuts so pod is properly terminated
    );
    
    return undef;
}

sub preprocess_paragraph { # used to catch
    my $self = shift;
    my $text = shift;
    
    my $fh = $self->output_handle;
    print $fh $text if $self->cutting(); # this is not pod, so we print it.

    return $text;
}

sub textblock {
    my $self = shift;
    my $text = shift;
    
    my $fh = $self->output_handle;
    if ($text =~ /^=/mg){ # when 'command' is not defined, commands are passed as paragraphs to here. Which means we don't have to recreate them.       
        print $fh $text; # we just don't wrap them.
    } else {
        print $fh wrap('','',$text), "\n"; # wrap 'regular' text, without indenting, and end with another newline..
    }
}

# sub new { $_[0]->SUPER::new() } # force no arguments to new?
# sub verbatim { print $_[1] } # will be printed automatically if not defined
# sub command { my $self = shift; print "=", $_[0], " ", $_[1], "\n" } # ce n'est past bien

1; # keep your mother happy

__END__

=pod

=head1 NAME

Pod::Wrap - Wrap pod paragraphs, leaving verbatim text and code alone.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Pod::Wrap;

    my $w = new Pod::Wrap;

    unless (@ARGV) {
        $w->parse_from_filehandle() # STDIN
    } else {
        $w->parse_from_file($_) for @ARGV;
    }

=head1 DESCRIPTION

This is a L<Pod::Parser> subclass, based on L<Pod::Stripper>. It parses
perl files, wrapping pod text, and leaving everything else intact. It
prints it's output to wherever you point it to (like you do with
L<Pod::Parser> (and L<Pod::Stripper>)).

=head1 METHODS

=over 4

=item new

This is actually L<Pod::Parser/new>.

All arguments to it are meaningless, as they are in L<Pod::Parser>.

=item parse_from_filehandle

=item parse_from_file

These are actually L<Pod::Parser/parse_from_filehandle> and
L<Pod::Parser/parse_from_file>.

They will receive input and output as described therein.

They will invoke this parser class, which will filter the pod text,
wrapping the appropriate sections using L<Text::Wrap>.

=back

=head1 MOTIVATION

I prefer editing with tabs and soft wrapping.

Most people like getting documentation hard wrapped and with tabs expanded.

The tabs are easy (L<Text::Tabs>), but wrapping only the correct parts of
the pod is a little tricker. This module attempts to do this correctly, by
wrapping only what isn't a command, a verbatim example (indented text), or
actual Perl code.

PodMaster noted that I should see what perltidy has to offer. Turns out
that

    What perltidy does not parse and format
    ...
    And, of course, it does not modify pod documents.

This drove me to release this tiny module.

=head1 BEHAVIOR MODIFICATION

The wrapping behavior is defined entirely by L<Text::Wrap>.

No re-exporting is made, in order to minimize bugs. If you want to import
the variables L<Text::Wrap> uses, do something like this:

    use Pod::Wrap;
    use Text::Wrap qw/$columns $huge/;

=head1 BUGS

Welcome.

=head1 TODO

You can ask me.

=head1 CREDITS

Podmaster wrote L<Pod::Stripper>. Even though the functionality of this
module is very limited, and is not really derived from L<Pod::Stripper>, I
would have been too lazy to read L<Pod::Parser>'s docs without seeing
L<Pod::Stripper>'s code as an example first.

Bottom line, most of the work (the research) that was actually done is not
mine. Implementation wouldn't have happened if I hadn't known for sure it's
possible to get perl code, verbatim, out of a pod parser. And I wouldn't
have if I hadn't seen a working example.

=head1 COPYRIGHT & LICENSE

You may not wrap pod files in any way without my explicit permission, in
writing.

Just kidding.

    Copyright 2004 Yuval Kogman. All rights reserved.
    This program is free software; you can redistribute it
    and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Text::Wrap>, L<Pod::Parser>, L<Pod::Stripper>, L<Perl::Tidy>

=cut
