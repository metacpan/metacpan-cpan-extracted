package Regexp::Compare;

require 5.026_000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(is_less_or_equal);
our @EXPORT = qw();

our $VERSION = '0.31';

require XSLoader;
XSLoader::load('Regexp::Compare', $VERSION);

sub is_less_or_equal {
    local ${^RE_TRIE_MAXBUF} = -1;
    return Regexp::Compare::_is_less_or_equal(@_);
}

1;
__END__

=head1 NAME

Regexp::Compare - partial ordering for regular expressions

=head1 SYNOPSIS

  use Regexp::Compare qw(is_less_or_equal);

  if (is_less_or_equal($rx[i], $rx[j])) {
      print "duplicate: $rx[i]\n";
  }

=head1 DESCRIPTION

This module implements a function comparing regular expressions: it
returns true if all strings matched by the first regexp are also
matched by the second. It's meant to be used for optimization of
blacklists implemented by regular expressions (like, for example,
C<http://www.communitywiki.org/cw/BannedContent> ).

Both arguments of C<is_less_or_equal> are strings - IOW the call

  $rv = is_less_or_equal($rx, /hardcoded/i);

probably won't do what you want - use

  $rv = is_less_or_equal($rx, '(?i:hardcoded)');

instead.

False return value does I<not> imply that there's a string matched by
the first regexp which isn't matched by the second - many regular
expressions (i.e. those containing Perl code) are impossible to
compare, and this module doesn't even implement all possible
comparisons.

=head1 BUGS

=over

=item * EBCDIC-based platforms not supported

=item * comparison of character classes is simplified and probably has
some incorrect corner cases

=item * comparison fails for locale-specific constructs

=item * comparison fails for regexps with backreferences

=item * global variables affecting regexp matching are ignored

=item * function may die for unusual (legal but unexpected) regexp
constructs

=back

=head1 AUTHOR

Vaclav Barta, E<lt>vbarta@mangrove.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2019 by Vaclav Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Rx>

=cut
