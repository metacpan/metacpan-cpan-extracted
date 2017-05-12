#
# This file is part of SDLx-GUI
#
# This software is copyright (c) 2013 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use warnings;

package SDLx::GUI;
# ABSTRACT: Create GUI easily with SDL
$SDLx::GUI::VERSION = '0.002';
use Exporter::Lite;

use SDLx::GUI::Widget::Toplevel;

our @EXPORT = qw{ toplevel };


# -- public functions


sub toplevel {
    return SDLx::GUI::Widget::Toplevel->new( @_ );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SDLx::GUI - Create GUI easily with SDL

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use SDLx::App;
    use SDLx::GUI;
    my $app = SDLx::App->new( ... );
    my $top = toplevel( app=>$app );
    $top->Label( text=>"hello, world!" )->pack;

=head1 DESCRIPTION

L<SDL> is great to create nifty games, except it's cumbersome to write
a usable GUI with it... Unfortunately, almost all games do have some
part that needs buttons and checkboxes and stuff (think configuration
screens).

This module eases the pain, by providing a L<Tk>-like way of building a
GUI.

=head1 METHODS

=head2 toplevel

    my $top = toplevel( %options );

Return a new toplevel widget (a L<SDLx::GUI::Widget::Toplevel> object).
Refer to this class for more information on accepted C<%options>.

=head1 SEE ALSO

You can find more information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/SDLx-GUI>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SDLx-GUI>

=item * Git repository

L<http://github.com/jquelin/sdlx-gui>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SDLx-GUI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SDLx-GUI>

=back

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
