#response base object for plugins
package PSGI::Hector::Response::Base;

=pod

=head1 NAME

Response Base - Base object for view plugins

=head1 SYNOPSIS

	use myResponse;
	my $response = myResponse->new($hector);
	
	package myResponse;
	use parent ("PSGI::Hector::Response::Base");

=head1 DESCRIPTION

This object should not be used directly, a new class should be created which inherits this one instead.

All response plugins should override at least the display() method and they all a sub class of L<HTTP::Response>.

The module L<PSGI::Hector::Response> will load the specified response plugin on script startup.

=head1 METHODS

=cut

use strict;
use warnings;
use parent qw(HTTP::Response PSGI::Hector::Base);
#########################################################
sub new{
	my($class, $hector) = @_;
	if(!defined($hector)){
		die("No hector object given");
	}
	my $self = $class->SUPER::new(200, "OK");	#we dont care about the code or msg as they get removed later
	$self->{'_hector'} = $hector;	#so we can access the hector object FIXME
	$self->{'_displayedHeader'} = 0;	#flag set on first output
	bless $self, $class;
	return $self;
}
#########################################################

=pod

=head2 setCacheable($seconds)

	$response->setCacheable($seconds)

Sets the page to be cached for the specified amount of seconds.

=cut

#########################################################
sub setCacheable{
	my($self, $seconds) = @_;
	$self->header("Cache-Control" => "max-age=$seconds, public");
	return 1;
}
#########################################################
sub getHector{
	my $self = shift;
	return $self->{'_hector'};
}
#########################################################
sub display{
	my $self = shift;
	my @headers;
	foreach my $field ($self->header_field_names){
		push(@headers, $field => $self->header($field));
	}
	return [$self->code(), \@headers, [$self->content()]];
}
#########################################################
# private methods
#########################################################
sub _setDisplayedHeader{
	my $self = shift;
	$self->{'_displayedHeader'} = 1;
	return 1;
}
#########################################################
sub _getDisplayedHeader{
	my $self = shift;
	return $self->{'_displayedHeader'};
}
###########################################################

=pod

=head1 Provided classes

In this package there are some responses already available for use:

=over 4

=item Raw

See L<PSGI::Hector::Response::Raw> for details.

=item TemplateToolkit

See L<PSGI::Hector::Response::TemplateToolkit> for details.

=back

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address.

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

#########################################################
return 1;