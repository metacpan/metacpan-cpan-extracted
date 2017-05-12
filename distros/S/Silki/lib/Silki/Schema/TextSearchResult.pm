package Silki::Schema::TextSearchResult;
{
  $Silki::Schema::TextSearchResult::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use HTML::Entities qw( encode_entities );
use Silki::Schema::Page;
use Silki::Schema::Wiki;
use Silki::Types qw( Str );
use Silki::Util qw( string_is_empty );

use Moose;

has _result => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'result',
);

# The marker needs to be something that is unlikely to ever appear in normal
# text, does not look like wikitext, and will not changed when HTML-escaped.
sub HighlightMarker {
    return '$@$@$@$';
}

sub title_for_display {
    my $self       = shift;
    my $full_title = shift;

    my ( $title, undef ) = split /\n/, $self->_result(), 2;

    my $marker = $self->HighlightMarker();
    return encode_entities($full_title) unless $title =~ /\Q$marker/;

    my ($matched) = $title =~ m{\Q$marker\E(.+?)\Q$marker};

    $full_title = encode_entities($full_title);
    $full_title =~ s{\Q$matched}{<strong>$matched</strong>};

    return $full_title;
}

sub body_for_display {
    my $self = shift;

    my ( undef, $body ) = split /\n/, $self->_result(), 2;

    return q{} if string_is_empty($body);

    my $marker = $self->HighlightMarker();

    $body = encode_entities($body);

    $body =~ s{\Q$marker\E(.+?)\Q$marker}{<strong>$1</strong>}g;

    $body =~ s/\n\n/&nbsp;&nbsp;/g;

    return $body;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a text search result

__END__
=pod

=head1 NAME

Silki::Schema::TextSearchResult - Represents a text search result

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

