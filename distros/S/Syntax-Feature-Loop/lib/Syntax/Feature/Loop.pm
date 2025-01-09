package Syntax::Feature::Loop;

use strict;
use warnings;

use version; our $VERSION = qv('v1.10.0');

use XSLoader qw( );

XSLoader::load('Syntax::Feature::Loop', $VERSION);

sub import   { $^H{ hint_key() } = 1; }
sub unimport { $^H{ hint_key() } = 0; }

*install   = \&import;    # For syntax.pm
*uninstall = \&unimport;  # For syntax.pm

1;


__END__

=head1 NAME

Syntax::Feature::Loop - Provides the C<loop BLOCK> syntax for unconditional loops.


=head1 VERSION

Version 1.10.0


=head1 SYNOPSIS

    use syntax qw( loop );

    loop {
       ...
       last if ...;
       ...
    }


=head1 DESCRIPTION

Syntax::Feature::Loop is a lexically-scoped pragma that
provides the C<loop BLOCK> syntax for unconditional loops.

This module serves as a demonstration of the ability to
add keywords to the Perl language using
L<C<PL_keyword_plugin>|perlapi/PL_keyword_plugin>.


=head2 C<< use syntax qw( loop ); >>

=head2 C<< use Syntax::Feature::Loop; >>

Enables the use of C<loop BLOCK> until the end of the current lexical scope.


=head2 C<< no syntax qw( loop ); >>

=head2 C<< no Syntax::Feature::Loop; >>

Restores the standard behaviour of C<loop> (a sub call) until the end of the current lexical scope.


=head2 C<< loop BLOCK >>

Repeatedly executes the BLOCK until it is exited using C<last>, C<return>, C<die>, etc.

In other words, it behaves just like all of the following:

=over

=item * C<for (;;) BLOCK>

=item * C<while (1) BLOCK>

=item * C<while () BLOCK>

=back

Like other flow control statements, there is no need to
terminate the statement with a semi-colon (C<;>).


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

    perldoc Syntax::Feature::Loop

You can also find it online at this location:

=over

=item * L<https://metacpan.org/dist/Syntax-Feature-Loop>

=back

If you need help, the following are great resources:

=over

=item * L<https://stackoverflow.com/|StackOverflow>

=item * L<http://www.perlmonks.org/|PerlMonks>

=item * You may also contact the author directly.

=back


=head1 BUGS

Please report any bugs or feature requests using L<https://github.com/ikegami/perl-Syntax-Feature-Loop/issues>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 REPOSITORY

=over

=item * Web: L<https://github.com/ikegami/perl-Syntax-Feature-Loop>

=item * git: L<https://github.com/ikegami/perl-Syntax-Feature-Loop.git>

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
