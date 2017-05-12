package Syntax::Feature::QwComments;

use strict;
use warnings;

use version; our $VERSION = qv('v1.12.0');

use Devel::CallParser qw( );
use XSLoader          qw( );

XSLoader::load('Syntax::Feature::QwComments', $VERSION);

sub import {
   require Lexical::Sub;
   Lexical::Sub->import( 'qw' => \&replacement_qw );
}

sub unimport {
   require Lexical::Sub;
   Lexical::Sub->unimport( 'qw' => \&replacement_qw );
}

*install   = \&import;    # For syntax.pm
*uninstall = \&unimport;  # For syntax.pm

1;


__END__

=head1 NAME

Syntax::Feature::QwComments - Pragma to allow comments in qw()


=head1 VERSION

Version 1.12.0


=head1 SYNOPSIS

    use syntax qw( qw_comments );
    
    my @a = qw(
       foo  # Now with comments!
       bar
    );


=head1 DESCRIPTION

Syntax::Feature::QwComments is a lexically-scoped pragma that allows comments inside of C<qw()>.

C<qw()> should work identically with and without this pragma in all other respects except one:
In addition to escaping delimiters and itself, C<\> will escape C<#>.

This module was formerly known as feature::qw_comments.


=head2 C<< use syntax qw( qw_comments ); >>

=head2 C<< use Syntax::Feature::QwComments; >>

Allow comments inside of C<qw()> until the end of the current lexical scope.


=head2 C<< no syntax qw( qw_comments ); >>

=head2 C<< no Syntax::Feature::QwComments; >>

The standard C<qw()> syntax is restored until the end of the current lexical scope.


=begin comment

=head1 Interal Subroutines

=over

=item * C<install>

=item * C<uninstall>

=item * C<replacement_qw>

=back

=end comment


=head1 SEE ALSO

=over 4

=item * L<syntax>

=item * L<Devel::CallParser>

=item * L<Devel::CallChecker>

=item * L<Lexical::Sub>

=item * L<perlapi>

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-Syntax-Feature-QwComments at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Feature-QwComments>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Syntax::Feature::QwComments

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Syntax-Feature-QwComments>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Feature-QwComments>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Syntax-Feature-QwComments>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Syntax-Feature-QwComments>

=back


=head1 AUTHOR

Eric Brine, C<< <ikegami@adaelis.com> >>


=head1 COPYRIGHT & LICENSE

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.


=cut
