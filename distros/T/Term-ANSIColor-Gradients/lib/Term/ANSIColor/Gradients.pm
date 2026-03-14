package Term::ANSIColor::Gradients ;

use strict ;
use warnings ;
use Exporter 'import' ;

our $VERSION = '0.10' ;
our @EXPORT_OK = qw(list_groups) ;

sub list_groups
{
return qw(Classic Extended Scientific Sequential Diverging Accessibility Artistic) ;
}

1 ;

__END__

=head1 NAME

Term::ANSIColor::Gradients - curated ANSI 256-color palette library

=head1 SYNOPSIS

 use Term::ANSIColor::Gradients qw(list_groups) ;

 my @groups = list_groups() ;

 # or load a specific sub-module directly
 use Term::ANSIColor::Gradients::Classic ;

 for my $index (@Term::ANSIColor::Gradients::Classic::GRADIENTS{GREY}) {
     print colored('█', "ansi$index") ;
 }

=head1 DESCRIPTION

This distribution provides curated ANSI 256-color palettes organized into
sub-modules by category.  Each sub-module exports a C<%GRADIENTS> hash that
maps palette names to array-refs of ANSI 256-color indices (integers 0-255).

=head1 MODULES

=over

=item * L<Term::ANSIColor::Gradients::Classic> - basic single-hue ramps

=item * L<Term::ANSIColor::Gradients::Extended> - heatmaps, scientific, artistic

=item * L<Term::ANSIColor::Gradients::Scientific> - perceptual and data-viz palettes

=item * L<Term::ANSIColor::Gradients::Sequential> - single-hue sequential ramps

=item * L<Term::ANSIColor::Gradients::Diverging> - bi-directional diverging palettes

=item * L<Term::ANSIColor::Gradients::Accessibility> - colorblind-safe palettes

=item * L<Term::ANSIColor::Gradients::Artistic> - decorative and creative palettes

=back

=head1 FUNCTIONS

=head2 list_groups

 my @groups = list_groups() ;

Returns the list of sub-module group names.

=head1 AUTHOR

Nadim Khemir <nadim.khemir@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself (Artistic License 2.0 or GPL 3.0).

=cut
