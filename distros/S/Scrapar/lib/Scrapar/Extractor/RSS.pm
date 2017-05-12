package Scrapar::Extractor::RSS;

use strict;
use warnings;
use XML::RSS;
use base qw(Scrapar::Extractor::_base);

sub extract {
    my $self = shift;
    my $content = shift;

    my $rss = XML::RSS->new(version => '1.0');
    $rss->parse($content);

    return $rss->{items};
}

1;

__END__

=pod

=head1 NAME

Scrapar::Extractor::RSS - RSS extractor

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin 

All right reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
