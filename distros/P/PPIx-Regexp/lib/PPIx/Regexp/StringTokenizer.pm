package PPIx::Regexp::StringTokenizer;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Tokenizer };

use Carp;

our $VERSION = '0.072';

confess 'PPIx::Regexp::StringTokenizer has been retracted';	## no critic (RequireEndWithOne)

# 1;	# We never actually get here.

__END__

=head1 NAME

PPIx::Regexp::StringTokenizer - Tokenize a string literal RETRACTED

=head1 SYNOPSIS

 use PPIx::Regexp::StringTokenizer; # THROWS EXCEPTION

C<PPIx::Regexp::StringTokenizer> is a
L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer>.

C<PPIx::Regexp::StringTokenizer> has no descendants.

=head1 DESCRIPTION

This class provided tokenization of string literals. It has been
retracted in favor of the use of L<PPIx::QuoteLike|PPIx::QuoteLike>.

Any use of this module will result in an exception.

=head1 SEE ALSO

L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer>.

L<PPIx::QuoteLike|PPIx::QuoteLike>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
