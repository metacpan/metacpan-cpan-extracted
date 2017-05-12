package Scrapar::Extractor::LinkExtor;

use strict;
use warnings;
use HTML::SimpleLinkExtor;
use base qw(Scrapar::Extractor::_base);

sub extract {
    my $self = shift;
    my $content = shift;
    my $params_ref = shift;

    my @links;

    my $e = HTML::SimpleLinkExtor->new($params_ref->{base});
    $e->parse($content);

    my $grep_filter = $params_ref->{grep_filter};
    if (defined $grep_filter && ref $grep_filter eq 'CODE') {
	@links = grep { $grep_filter->("$_") } $e->links;
    }
    else {
	@links = $e->links;
    }

    return \@links;
}

1;

__END__

=pod

=head1 NAME

Scrapar::Extractor::LinkExtor - Link extractor

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
