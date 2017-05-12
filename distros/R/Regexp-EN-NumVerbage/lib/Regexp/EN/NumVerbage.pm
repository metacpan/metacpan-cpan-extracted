package Regexp::EN::NumVerbage;

our $DATE = '2014-09-28'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Parse::Number::EN;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw($RE);

my $sdig_pat = qr/(?:zero|one|two|three|four|five|six|seven|eight|nine)/;
my $teen_pat = qr/(?:ten|eleven|twelve|thirteen|four\s*teen|fifteen|six\s*teen|seven\s*teen|eighteen|nine\s*teen)/;
my $tens_pat = qr/(?:(?:twenty|thirty|fou?rty|fifty|sixty|seventy|eighty|ninety)(?:\s*-?\s*$sdig_pat)?)/;
my $neg_pat  = qr/(?:negative|minus)/;
my $mult_pat = qr/(?:hundreds?|thousands?|millions?|mill?s?\.?|billions?|trillions?)/;

our $RE = join(
    "",
    '(?:(?:', "\n",
    '  (?:', $neg_pat, '\s*)?', " # opt: negative\n",
    '  (?:', $sdig_pat, '|', $teen_pat, '|', $tens_pat , '|', $Parse::Number::EN::Pat, ')', " # num\n",
    '  (?:', '\s*(?:point)\s*', $sdig_pat, '+', ')?', " # opt: decimal\n",
    '  (?:', '\s*(?:', $mult_pat, '){0,3})', " # opt: mult\n",
    '\s*)+)',
);
$RE = qr/$RE/x;

1;
# ABSTRACT: Regex pattern to match English number verbage in text

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::EN::NumVerbage - Regex pattern to match English number verbage in text

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Regexp::EN::NumVerbage ($RE);

 say $1 if "this year's revenue reaches 2.5 million dolars" =~ /\b($RE)\b/; # "2.5 million"

=head1 EXPORTS

None are exported by default, but they are exportable.

=head2 $RE (REGEX)

A regex for quickly matching/extracting verbage from text; it looks for a string
of words. It's not perfect (the extracted verbage might not be valid, e.g.
"thousand three"), but it's convenient.

=head1 SEE ALSO

L<Regexp::ID::NumVerbage>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
