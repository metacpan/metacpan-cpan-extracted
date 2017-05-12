#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2008-08-13
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package Net::Plazes;
use strict;
use warnings;

our $VERSION = '0.03';

1;
__END__

=head1 NAME

Net::Plazes - Documentation for Perl interface to geo-services from http://plazes.net/

=head1 VERSION

$Revision$

=head1 SYNOPSIS

 my $oUser = Net::Plazes::User->new({id => 266});
 print $oUser->name();
 print map { $_->plaze->name() } @{$oUser->activities()}

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
