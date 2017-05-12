package String::Index;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( cindex ncindex crindex ncrindex );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('String::Index', $VERSION);

1;
__END__

=head1 NAME

String::Index - Perl XS module for strpbrk()/index() hybrids

=head1 SYNOPSIS

  use String::Index qw( cindex ncindex crindex ncrindex );
  
  $first_vowel    =   cindex("broadcast", "aeiouy");  # 2
  $last_vowel     =  crindex("broadcast", "aeiouy");  # 6
  $first_nonvowel =  ncindex("eerily",    "aeiouy");  # 2
  $last_nonvowel  = ncrindex("eerily",    "aeiouy");  # 4

=head1 ABSTRACT

This module provides functions that are a cross between Perl's C<index()>
and C<rindex()> and C's C<strpbrk()>.

=head1 DESCRIPTION

This module provides four functions that are Perl/C hybrids.  They allow you
to scan a string for the first or last occurrence of any of a set of
characters, B<or not> of a set of characters.

=head2 Exported on request

There are four functions, which must be exported explicitly.

=over 4

=item cindex(STR, CHARS, POSITION)

=item cindex(STR, CHARS)

It returns the position of the first occurrence of one of CHARS in STR at
or after POSITION.  If POSITION is omitted, starts searching from the
beginning of the string.  The return value is based at 0.  If none of the
characters you are searching for are found, it returns -1.

=item ncindex(STR, CHARS, POSITION)

=item ncindex(STR, CHARS)

It returns the position of the first occurrence of a character B<other
than> those in the string CHARS in STR at or after POSITION.  If POSITION
is omitted, starts searching from the beginning of the string.  The return
value is based at 0.  If STR is composed entirely of characters in CHARS,
it returns -1.

=item crindex(STR, CHARS, POSITION)

=item crindex(STR, CHARS)

Works just like C<cindex()> except that it returns the position of the LAST
occurrence of any of CHARS in STR.  If POSITION is specified, returns the
last occurrence at or before that position.

=item ncrindex(STR, CHARS, POSITION)

=item ncrindex(STR, CHARS)

Works just like C<ncindex()> except that it returns the position of the LAST
occurrence of any character other than those in CHARS in STR.  If POSITION is
specified, returns the last occurrence at or before that position.

=back

=head1 SEE ALSO

See the man page for C<strpbrk()>.

=head1 AUTHOR

Jeff C<japhy> Pinyan, E<lt>japhy@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by japhy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
