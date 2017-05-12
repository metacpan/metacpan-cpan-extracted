#factory response object
package PSGI::Hector::Response;

=pod

=head1 NAME

PSGI::Hector::Response - Page response class

=head1 SYNOPSIS

=head1 DESCRIPTION

Factory class for creating response objects.

=head1 METHODS

=cut

use strict;
use warnings;
#########################################################

=pod

=head2 new($hector, $plugin)

Constructor, a factory method that will return an instance of the requested response plugin.

If the response is not modified from the client's provided Etag header an instance of L<PSGI::Hector::Response::NotModified>
will be returned instead.

=cut

#########################################################
sub new{
	my($class, $hector, $plugin) = @_;
	if($plugin){
		eval "use $plugin;";	#should do this a better way
		if(!$@){	#plugin loaded ok
			my $self = $plugin->new($hector);
			return $self;			
		}
		else{
			die("Plugin load problem: $@");
		}
	}
	else{
		die("No plugin given");
	}
	return undef;
}
#########################################################
=pod

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address.

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

##########################################
return 1;
