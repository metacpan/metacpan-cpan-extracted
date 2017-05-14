package Template::Flute::Filter::LowerDash;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::LowerDash - LowerDashcase filter

=head1 DESCRIPTION

LowerDashcase filter. Replace spaces with dashes and make lowercase.

=head1 METHODS

=head2 filter

LowerDashcase filter.

=cut

sub filter {
    my $self = shift;
    
    (my $value = shift) =~ s/\s+/-/g;

    return lc($value);
}

=head1 AUTHOR

William Carr (Mr. Maloof), <bill@bottlenose-wine.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
