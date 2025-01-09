package Syntax::Feature::QwComments;

use strict;
use warnings;

use version; our $VERSION = qv('v1.16.0');

use XSLoader qw( );

XSLoader::load('Syntax::Feature::QwComments', $VERSION);

sub import   { $^H{ hint_key() } = 1; }
sub unimport { $^H{ hint_key() } = 0; }

*install   = \&import;    # For syntax.pm
*uninstall = \&unimport;  # For syntax.pm

1;


__END__

=head1 NAME

Syntax::Feature::QwComments - Pragma to allow comments in qw()


=head1 VERSION

Version 1.16.0


=head1 SYNOPSIS

    use syntax qw( qw_comments );

    my @a = qw(
       foo  # Now with comments!
       bar
    );


=head1 DESCRIPTION

Syntax::Feature::QwComments is a lexically-scoped pragma that
allows comments inside of C<qw()>.

C<qw()> should work identically with and without this pragma
in all other respects except one: In addition to escaping delimiters
and itself, C<\> will escape C<#>.

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

=item * C<hint_key>

=back

=end comment


=head1 SEE ALSO

=over 4

=item * L<syntax>

=item * L<perlapi>

=back


=head1 DOCUMENTATION AND SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Syntax::Feature::QwComments

You can also find it online at this location:

=over

=item * L<https://metacpan.org/dist/Syntax-Feature-QwComments>

=back

If you need help, the following are great resources:

=over

=item * L<https://stackoverflow.com/|StackOverflow>

=item * L<http://www.perlmonks.org/|PerlMonks>

=item * You may also contact the author directly.

=back


=head1 BUGS

Please report any bugs or feature requests using L<https://github.com/ikegami/perl-Syntax-Feature-QwComments/issues>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 REPOSITORY

=over

=item * Web: L<https://github.com/ikegami/perl-Syntax-Feature-QwComments>

=item * git: L<https://github.com/ikegami/perl-Syntax-Feature-QwComments.git>

=back


=head1 AUTHOR

Eric Brine, C<< <ikegami@adaelis.com> >>


=head1 COPYRIGHT AND LICENSE

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.


=cut
