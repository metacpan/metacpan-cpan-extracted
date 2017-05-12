package Plack::App::REST;

use 5.008_005;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.04'; # Set automatically by milla

use parent qw( Plack::Component );
use HTTP::Exception;

sub call {
	my($self, $env) = @_;

	my $method = $env->{REQUEST_METHOD};

	### Throw an exception if method is not defined
	if (!$self->can($method)){
		return [405, ['Content-Type', 'text/plain'], ['Method Not Allowed']];
	}

	### Set params of path
	my $id = _get_params($env);
	$env->{'rest.ids'} = $id;

	### Set ref to env
	$env->{'REST.class'} = ref $self;

	# compatibility with Plack::Middleware::ParseContent
	my $data = $env->{'parsecontent.data'} if exists $env->{'parsecontent.data'};

	### Call method 
	my ($ret, $h) = eval{ $self->$method($env, $data) };

	### Parse output
	if ( my $e = HTTP::Exception->caught ) {

		my @headers = ('Content-Type', 'text/plain');
		my $code = $e->code;

		if ( $code =~ /^3/ && (my $loc = eval{$e->location}) ) {
			push( @headers, Location => $loc );
		}

		$env->{'psgi.errors'}->print( $e );
		return [ $code, \@headers, [$e->message] ];
	}elsif($@){
		$env->{'psgi.errors'}->print( $e );
		return [ 500, ['Content-Type', 'text/plain'], [$@] ];
	}
	
	return [200, ($h||[]), $ret];
}

### Get last requested path
sub _get_params {
	my $env = shift;
	my $p = $env->{PATH_INFO};
	return if !$p or $p eq '/';

	# get param of uri
	(my $r = $p) =~ s/\+/ /g;
	$r =~ s/^\///g;

	my @id = split(/\//, $r);
	return \@id;
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::App::REST - Perl PSGI App that just call http method from object.

=head1 SYNOPSIS

	use Plack::App::REST;
	use Test::Root;

	builder {
		mount "/api" => builder {
			mount "/" => Test::Root->new();
		};
	};

	package Test::Root;
	use parent 'Plack::App::REST';

	sub POST {
		my ($self, $env, $data) = @_;
		return [ 'app/root' ];
	}

=head1 DESCRIPTION

Plack::App::REST is simple plack application that call requested method directly from mounted class.

Method can be GET, PUT, POST, DELETE, HEAD, PATCH. 

Each method is called with three params:

=over 4

=item * Env - Plack Env

=item * Data - Compatibility with Plack::Middleware::ParseContent. Return parsed data as perl structure

Method SHOULD return array with two params (body and header). Body is ref to perl structure, header is an array.
Header is optional.

=back

For complete RestAPI in Perl use: 

=over 4

=item * Plack::Middleware::ParseContent

=item * Plack::Middleware::FormatOutput

=back

=cut

=head1 TUTORIAL

L<http://psgirestapi.dovrtel.cz/>

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to github repository.

=head1 ACKNOWLEDGEMENTS

Inspired by L<https://github.com/towhans/hochschober>

Inspired by L<https://github.com/nichtich/Plack-Middleware-REST>

=head1 COPYRIGHT

Copyright 2015- Václav Dovrtěl

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
