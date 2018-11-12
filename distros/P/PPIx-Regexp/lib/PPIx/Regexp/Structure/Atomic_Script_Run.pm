# Cargo cult to try to prevent CPAN from indexing
package
PPIx::Regexp::Structure::Atomic_Script_Run;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';


1;

__END__

=head1 NAME

PPIx::Regexp::Structure::Atomic_Script_Run - Represent an atomic script run group

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(*atomic_script_run:\d)}' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Atomic_Script_Run> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure::Script_Run|PPIx::Regexp::Structure|PPIx::Regexp::Structure::Script_Run>
and a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure::Subexpression|PPIx::Regexp::Structure|PPIx::Regexp::Structure::Subexpression>

C<PPIx::Regexp::Structure::Atomic_Script_Run> has no descendants.

=head1 DESCRIPTION

This class represents an atomic script run group. That is, the
constructions C<(*atomic_script_run:...)> and C<(*asr:...)>. These are
new with Perl 5.27.9.

If this construction does not make it into Perl 5.28, this class will be
retracted.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
