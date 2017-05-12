package Regexp::ID::NumVerbage;

our $DATE = '2014-09-28'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Lingua::ID::Words2Nums;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw($RE);

our $RE = $Lingua::ID::Words2Nums::Pat;

1;
# ABSTRACT: Regex pattern to match Indonesian number verbage in text

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::ID::NumVerbage - Regex pattern to match Indonesian number verbage in text

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Regexp::ID::NumVerbage ($RE);

 say $1 if "pemasukan tahun ini mencapai tiga koma tujuh triliun" =~ /\b($RE)\b/; # "tiga koma tujuh triliun"

=head1 EXPORTS

=head2 $RE (regex)

A regex for quickly matching/extracting verbage from text; it looks for a string
of words. It's not perfect (the extracted verbage might not be valid, e.g.
"dua ratus tiga ribu"), but it's convenient.

=head1 SEE ALSO

L<Regexp::EN::NumVerbage>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
