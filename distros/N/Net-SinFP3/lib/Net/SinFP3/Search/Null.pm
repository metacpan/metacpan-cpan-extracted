#
# $Id: Null.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Search::Null;
use strict;
use warnings;

use base qw(Net::SinFP3::Search);
__PACKAGE__->cgBuildIndices;

1;

__END__

=head1 NAME

Net::SinFP3::Search::Null - turn off Search plugin

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
