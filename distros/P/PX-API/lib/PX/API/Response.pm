package PX::API::Response;
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use HTTP::Response;
our @ISA = qw(HTTP::Response);

use Module::Pluggable::Fast
	name => 'response_plugins',
	search => [ qw/PX::API::Response/ ];


sub new {
	my $class = shift;
	my $args  = shift;

	my $self = HTTP::Response->new();
	return bless $self, $class;
	}

sub _init {
	my $self = shift;
	my $args = shift;
	my $format = $args->{'format'} || "rest";

	my @classes = $self->response_plugins;
	foreach my $c(@classes) {
		if ($c->format eq $format) {
			$self->{'parser'} = $c;
			last;
			}
		}
	return $self;
	}

sub fault {
	my ($self,$err_code,$err_string) = @_;
	$self->{success} = 0;
	$self->{err_code} = $err_code;
	$self->{err_string} = $err_string;
	}

sub success {
	my ($self,$ref) = @_;
	$self->{success} = 1;
	$self->{response} = $ref;
	}


1;
__END__

=head1 NAME

PX::API::Response - A Peekshows Web Services API response.


=head1 SYNOPSIS

    use PX::API;

    my $px = PX::API->new({
                        api_key => '13243432434',  #Your api key
                        secret  => 's33cr3tttt',   #Your api secret
                        });

    my $response = $px->call('px.test.echo',{
					arg1 => 'val1',
					arg2 => 'val2',
					});


=head1 DESCRIPTION

A response object from the Peekshows Web Services API.  C<PX::API::Response>
is a subclass of L<HTTP::Response> allowing for access to any response
parameters.  C<Module::Pluggable::Object> is used to allow an extensible
'plugin' style method for loading response modules.

=head1 CONFIGURATION AND ENVIRONMENT

Along with the response parameters available from C<HTTP::Response>,
the following parameters are added for API responses.

=over 4

=item C<success>

Set to a 1 or 0 to signify response success or error respectively.

=item C<response>

The actual content of the response returned from the API call.

=item C<err_code>

The error code returned from the API call, if an error occurred.

=item C<err_string>

A description of the error returned from the API call, if an error occurred.


=back


=head1 RESPONSE PLUGINS

A response plugin is simply a module that transforms the API response
format into a usable perl object.  Obviously this is not always necessary
and the original structure is always available via C<$response->{_content}>.

Response plugins are required to have to following methods available via
its public api:

=over 4

=item C<format()>

The C<format()> method is used by C<PX::API::Response> to match a plugin
with the format argument sent to the Peekshows API.  This method simply 
needs to return the name of the plugin format. ie: 'rest', 'json'

=item C<parse($content)>

The C<parse()> method is called upon completion of an API call and is
passed the C<_content> returned from the call.  This method need only
return the perl object which was created from parsing the content.


=back


=head1 DEPENDENCIES

L<HTTP::Response>
L<Module::Pluggable>

=head1 SEE ALSO

L<PX::API>
L<http://www.peekshows.com>
L<http://services.peekshows.com>

=head1 AUTHOR

Anthony Decena  C<< <anthony@1bci.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Anthony Decena C<< <anthony@1bci.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
