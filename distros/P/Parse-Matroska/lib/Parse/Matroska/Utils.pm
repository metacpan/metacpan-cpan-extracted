use strict;
use warnings;

# ABSTRACT: internally-used helper functions
package Parse::Matroska::Utils;
{
  $Parse::Matroska::Utils::VERSION = '0.003';
}

use Exporter;
our @ISA       = qw{Exporter};
our @EXPORT_OK = qw{uniq uncamelize};

sub uniq(@) {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub uncamelize($) {
    local $_ = shift;
    # lc followed by UC: lc_UC
    s/(?<=[a-z])([A-Z])/_\L$1/g;
    # UC followed by two lc: _UClclc
    s/([A-Z])(?=[a-z]{2})/_\L$1/g;
    # strip leading _ that the second regexp might add; lowercase all
    s/^_//; lc
}

__END__

=pod

=head1 NAME

Parse::Matroska::Utils - internally-used helper functions

=head1 VERSION

version 0.003

=head1 METHODS

=head2 uniq(@array)

The same as L<List::MoreUtils/"uniq LIST">.
Included to avoid depending on it since it's
not a core module.

=head2 uncamelize($string)

Converts a "StringLikeTHIS" into a
"string_like_this".

=head1 AUTHOR

Kovensky <diogomfranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Diogo Franco.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
