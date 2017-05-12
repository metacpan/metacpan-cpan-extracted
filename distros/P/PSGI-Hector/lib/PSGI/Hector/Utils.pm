package PSGI::Hector::Utils;
=pod

=head1 NAME

PSGI::Hector::Utils - Helper methods

=head1 SYNOPSIS

=head1 DESCRIPTION

Various methods used by several of the Hector classes.

=head1 METHODS

=cut
use strict;
use warnings;
#########################################################

=pod

=head2 getThisUrl()

DEPRECATED please use getSiteUrl() instead.

=cut

###########################################################
sub getThisUrl{
	shift->getSiteUrl();
}
#########################################################

=pod

=head2 getSiteUrl()

	my $url = $m->getSiteUrl();

Returns the full site URL for the current script.

=cut

###########################################################
sub getSiteUrl{
	my $request = shift->getRequest();
	$request->base->as_string;
}
#############################################################################################################

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address.

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###########################################################
return 1;
