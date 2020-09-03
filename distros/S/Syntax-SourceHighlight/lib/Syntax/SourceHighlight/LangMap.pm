package Syntax::SourceHighlight::LangMap;

use 5.010;
use strict;
use warnings;
use parent 'Syntax::SourceHighlight';

our $VERSION = '2.1.2';

sub langNames {
    my $self = shift;
    return $self->getLangNames();
}

sub mappedFileNames {
    my $self = shift;
    return $self->getMappedFileNames();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::SourceHighlight::LangMap - Perl class for libsource-highlight's
C<srchilite::LangMap>

=head1 SYNOPSIS

    use Syntax::SourceHighlight;
    my $lm = Syntax::SourceHighlight::LangMap->new();
    print( $lm->getMappedFileName('bash'), "\n" );

=head1 DESCRIPTION

This is the counterpart to the libsource-highlight's
C<< L<srchilite::LangMap|https://www.gnu.org/software/src-highlite/api/classsrchilite_1_1LangMap.html> >> class.

The following public methods are implemented in this package:

=over

=item

C<< L<getMappedFileName()|Syntax::SourceHighlight/getMappedFileName()> >>

=item

C<< L<getMappedFileNameFromFileName()|Syntax::SourceHighlight/getMappedFileNameFromFileName()> >>

=item

C<< L<getLangNames()|Syntax::SourceHighlight/getLangNames()> >>

=item

C<< L<getMappedFileNames()|Syntax::SourceHighlight/getMappedFileNames()> >>

=back

These are missing:

=over

=item

C<getFileName()>

=item

C<reload()>

=back

The following methods exist due to backwards compatibility with earlier
versions of this package:

=over

=item

C<langNames()> is the same as
C<< L<getLangNames()|Syntax::SourceHighlight/getLangNames()> >>

=item

C<mappedFileNames()> is the same as
C<< L<getMappedFileNames()|Syntax::SourceHighlight/getMappedFileNames()> >>

=back

=head1 SEE ALSO

The main documentation with examples is in the L<Syntax::SourceHighlight> POD.

=cut
