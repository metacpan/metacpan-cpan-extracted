use strict;
package WWW::Scraper::Response::ScraperDiscovery::OPTION;

#####################################################################

use base qw(WWW::Scraper::Response::ScraperDiscovery);
# This is an appropriate VERSION calculation to use for CVS revision numbering.
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+).(\d+)/);

use strict;

sub asHtml {
    my ($self) = @_;
    my $typeLeaf = $self->typeLeaf;
    
    my $attrList = '';
    my %results = %{$self->GetFieldValues()};
    my $val; map { if ($_ ne 'caption') {$val = $self->$_; $attrList .= " $_=$$val" if $val} } keys %{$self->GetFieldTitles()};
    
    my $caption = $self->caption;
    return <<EOT;
<$typeLeaf $attrList>$$caption</$typeLeaf>
EOT
}

1;

__END__
=pod

=head1 NAME

WWW::Scraper::ScraperDiscovery - discovers forms and inputs on a HTML page.


=head1 SYNOPSIS


=head1 DESCRIPTION

This class is an experimental exploration of "Scraper Discovery".

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::ScraperDiscovery> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2002 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

