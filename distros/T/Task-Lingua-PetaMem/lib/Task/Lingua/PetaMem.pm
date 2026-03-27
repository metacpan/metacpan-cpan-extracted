# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Task::Lingua::PetaMem;

use 5.16.0;
use utf8;
use warnings;

our $VERSION = '0.2603260';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Task::Lingua::PetaMem - Install all PetaMem Lingua number conversion modules

=head1 VERSION

version 0.2603260

=head1 DESCRIPTION

Installing this module will pull in both L<Task::Lingua::Num2Word> and
L<Task::Lingua::Word2Num>, which together provide number-to-word and
word-to-number conversion for 39 languages.

B<European>: Afrikaans, Basque, Bulgarian, Catalan, Croatian, Czech,
Danish, Dutch, English, Estonian, Finnish, French, German, Greek,
Hungarian, Icelandic, Italian, Latvian, Lithuanian, Norwegian, Polish,
Portuguese, Romanian, Russian, Slovak, Spanish, Swedish, Ukrainian.

B<Middle Eastern>: Arabic, Hebrew, Persian.

B<Asian>: Chinese, Indonesian, Japanese, Korean, Thai, Vietnamese.

B<African>: Swahili.

=head1 SYNOPSIS

 # install everything:
 cpanm Task::Lingua::PetaMem

 # or just one direction:
 cpanm Task::Lingua::Num2Word
 cpanm Task::Lingua::Word2Num

 # then use any language:
 use Lingua::Num2Word qw(cardinal);
 print cardinal('de', 42);    # zweiundvierzig

 use Lingua::Word2Num qw(cardinal);
 print cardinal('fr', 'quarante-deux');  # 42

Both ISO 639-1 (C<de>, C<fr>, C<ja>) and ISO 639-3 (C<deu>, C<fra>,
C<jpn>) language codes are accepted.

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut
