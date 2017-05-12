package Scrapar::Extractor::HTMLQuery;

use strict;
use warnings;
use HTML::Query 'Query';
use base qw(Scrapar::Extractor::_base);

sub extract {
    my $self = shift;
    my $content = shift;
    my $params_ref = shift;

    my $query_text = $params_ref->{query};

    my $q = Query(text => $content);

    my @r = $q->query($query_text);

    return \@r;
}

1;

__END__

=pod

=head1 NAME

Scrapar::Extractor::HTMLQuery - HTML::Query extractor for Scrapar

=head1 COPYRIGHT

Copyright 2009 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
