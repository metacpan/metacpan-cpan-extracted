package Perl::Metrics::Lite::Analysis::DocumentFactory;
use strict;
use warnings;
use PPI;
use PPI::Document;
use Perl::Metrics::Lite::Analysis::Util;

use Carp qw(confess);

sub create_normalized_document {
    my ( $class, $path ) = @_;

    my $document;
    if ( ref $path ) {
        if ( ref $path eq 'SCALAR' ) {
            $document = PPI::Document->new($path);
        }
        else {
            $document = $path;
        }
    }
    else {
        if ( !-r $path ) {
            Carp::confess "Path '$path' is missing or not readable!";
        }
        $document = _create_ppi_document($path);
    }

    $document;
}

sub _create_ppi_document {
    my $path = shift;
    my $document;
    if ( -s $path ) {
        $document = PPI::Document->new($path);
    }
    else {

        # The file is empty. Create a PPI document with a single whitespace
        # chararacter. This makes sure that the PPI tokens() method
        # returns something, so we avoid a warning from
        # PPI::Document::index_locations() which expects tokens() to return
        # something other than undef.
        my $one_whitespace_character = q{ };
        $document = PPI::Document->new( \$one_whitespace_character );
    }
    return $document;
}

sub _make_pruned_document {
    my $document = shift;
    $document = Perl::Metrics::Lite::Analysis::Util::prune_non_code_lines($document);
    $document->index_locations();
    $document->readonly(1);
    return $document;
}

1;
