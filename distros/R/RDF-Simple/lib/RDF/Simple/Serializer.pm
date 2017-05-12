
# $Id: Serializer.pm,v 1.3 2009/04/11 15:37:59 Martin Exp $

package RDF::Simple::Serializer;

use strict;
use warnings;

use base q(RDF::Simple::Serialiser);

our
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

RDF::Simple::Serializer - a synonym for RDF::Simple::Serialiser

=head1 SYNOPSIS

Same as RDF::Simple::Serialiser

=head1 DESCRIPTION

See RDF::Simple::Serialiser

=cut

1;

__END__
