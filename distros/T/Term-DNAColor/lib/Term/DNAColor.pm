use strict;
use warnings;
use utf8;

package Term::DNAColor;
BEGIN {
  $Term::DNAColor::VERSION = '0.110460';
}
# ABSTRACT: Add colors to DNA and RNA sequences in terminal output

use base 'Exporter::Simple';
use Term::ANSIColor::Print;

sub _get_nucl_color {
    my $nucl_colors = {
        A => 'green',
        T => 'red',
        U => 'red',             # Support RNA too!
        C => 'blue',
        G => 'yellow',
    };
    return $nucl_colors->{$_[0]} || 'normal';
}

my $colorizer = Term::ANSIColor::Print->new(
    output => 'return',
    eol    => '',
);

sub _colorize_nucl {
    my $nucl = $_[0];
    my $color = "bold_" . _get_nucl_color($nucl);
    my $colored_nucl = $colorizer->$color($nucl);
    return $colored_nucl;
}

# Optional Memoize support
eval {
    require Memoize;
    Memoize::memoize('_colorize_nucl');
};


sub colordna : Exported {
    my @seq_chars = split //, shift;
    my @colored_seq_chars = map { _colorize_nucl($_) } @seq_chars;
    return join "", @colored_seq_chars;
}


sub colorrna : Exportable {
    return colordna(@_);
}

1; # Magic true value required at end of module


=pod

=head1 NAME

Term::DNAColor - Add colors to DNA and RNA sequences in terminal output

=head1 VERSION

version 0.110460

=head1 SYNOPSIS

    use Term::DNAColor;

    print colordna("ATCGGTCNNNTAGCTGAN"), "\n";

=head1 DESCRIPTION

This module provides a function, C<colordna>, that takes a DNA
sequence and wraps unambiguous nucleotides in ANSI color codes, so
that you can print the sequence to a terminal and have it come out
colored.

=head1 FUNCTIONS

=head2 colordna

Takes a string representing a DNA sequence and adds ANSI color codes
to the following nucleotides:

=over 4

=item *

A: green

=item *

T: red

=item *

C: blue

=item *

G: yellow

=back

U is colorized like T, to accomodate RNA sequences.

In addition, the entire sequence is rendered in bold.

This function is exported by default.

=head2 colorrna

This is simply an alias for C<colordna>. Both C<colordna> and
C<colorrna> will highlight U for uracil. Unlike C<colordna>, it is not
exported by default, but only by request.

=head1 BUGS AND LIMITATIONS

Colors are not configurable.

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=over 4

=item *

L<Term::ANSIColor> - Provides the ANSI color codes for this module

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

