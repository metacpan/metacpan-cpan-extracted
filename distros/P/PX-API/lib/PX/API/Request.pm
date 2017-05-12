package PX::API::Request;
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use HTTP::Request;
our @ISA = qw(HTTP::Request);

sub new {
	my $class = shift;
	my $args  = shift;

	my $self = HTTP::Request->new();
	$self->{'method'} = $args->{'method'};
	$self->{'args'} = $args->{'args'};
	$self->{'format'} = $args->{'format'} || "rest";
	bless $self, $class;

	$self->method('GET');
	$self->uri('http://services.peekshows.com/rest/' . $self->_method_to_uri);
	return $self;
	}

sub _method_to_uri {
	my $self = shift;
	my $uri = $self->{'method'};
	$uri =~ s/\./\//g;
	return $uri;
	}


1;
__END__

=head1 NAME

PX::API::Request - A Peekshows Web Services API request.


=head1 SYNOPSIS

    use PX::API;
    use PX::API::Request;

    my $px = PX::API->new({
                        api_key => '13243432434',  #Your api key
                        secret  => 's33cr3tttt',   #Your api secret
                        });

    my $req = PX::API::Request->({
			method  => 'px.test.echo',
			args	=> {},
			});

    my $resp = $px->execute_request($req);


=head1 DESCRIPTION

A Peekshows Web Services API request object.  C<PX::API::Request> is
an L<HTTP::Request> subclass, allowing access to any request parameters.

=head1 METHODS/SUBROUTINES

=over 4

=item C<new($args)>

Constructs a new C<PX::API::Request> object.  The C<$args> passed
to this constructor must contain a C<method> to call.  Optionally
the constructor will accept C<args> as a list of arguments to pass 
with the API request.


=back


=head1 DEPENDENCIES

L<HTTP::Request>

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
