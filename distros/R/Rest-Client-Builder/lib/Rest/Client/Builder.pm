package Rest::Client::Builder;

use strict;
use warnings;

our $VERSION = '0.03';
our $AUTOLOAD;

sub new {
	my ($class, $opts, $path) = @_;

	return bless({
		on_request => $opts->{on_request},
		path => defined $path ? $path : '',
		opts => { %$opts },
	}, $class);
}

sub _construct {
	my ($self, $path) = (shift, shift);

	my $id = $path;
	my $class = ref($self) . '::' . $path;

	if (defined $self->{path}) {
		$path = $self->{path} . '/' . $path;
	}

	if (@_) {
		my $tail = '/' . join('/', @_);
		$id .= $tail;
		$path .= $tail;
	}

	unless ($self->{objects}->{$id}) {
		$self->{objects}->{$id} = bless(Rest::Client::Builder->new($self->{opts}, $path), $class);
		no strict 'refs';
		push @{$class . '::ISA'}, 'Rest::Client::Builder';
	}

	return $self->{objects}->{$id};
}

sub AUTOLOAD {
	my $self = shift;

	(my $method = $AUTOLOAD) =~ s{.*::}{};
	return undef if $method eq 'DESTROY';
	no strict 'refs';
	my $ref = ref($self);

	*{$ref . '::' . $method} = sub {
		my $self = shift;
		$self->_construct($method, @_);
	};

	return $self->$method(@_);
}

sub get {
	my $self = shift;
	return $self->{on_request}->('GET', $self->{path}, @_);
}

sub post {
	my $self = shift;
	return $self->{on_request}->('POST', $self->{path}, @_);
}

sub put {
	my $self = shift;
	return $self->{on_request}->('PUT', $self->{path}, @_);
}

sub delete {
	my $self = shift;
	return $self->{on_request}->('DELETE', $self->{path}, @_);
}

sub patch {
	my $self = shift;
	return $self->{on_request}->('PATCH', $self->{path}, @_);
}

sub head {
	my $self = shift;
	return $self->{on_request}->('HEAD', $self->{path}, @_);
}

1;

__END__

=head1 NAME

Rest::Client::Builder - Base class to build simple object-oriented REST clients

=head1 SYNOPSIS

	package Your::API;
	use base qw(Rest::Client::Builder);
	use JSON;

	sub new {
		my ($class) = @_;

		my $self;
		$self = $class->SUPER::new({
			on_request => sub {
				return $self->request(@_);
			},
		}, 'http://hostname/api');
		return bless($self, $class);
	};

	sub request {
		my ($self, $method, $path, $args) = @_;
		return sprintf("%s %s %s\n", $method, $path, encode_json($args));
	}

	my $api = Your::API->new();
	print $api->resource->get({ value => 1 });
	# output: GET http://hostname/api/resource {"value":1}

	print $api->resource(10)->post({ value => 1 });
	# output: POST http://hostname/api/resource/10 {"value":1}

	print $api->resource(10)->subresource('alfa', 'beta')->state->put({ value => 1 });
	# output: PUT http://hostname/api/resource/10/subresource/alfa/beta/state {"value":1}

	print $api->resource(10)->subresource->alfa('beta')->state->put({ value => 1 });
	# output: PUT http://hostname/api/resource/10/subresource/alfa/beta/state {"value":1}

	print $api->resource(10)->subresource->alfa->beta->state->put({ value => 1 });
	# output: PUT http://hostname/api/resource/10/subresource/alfa/beta/state {"value":1}

	print $api->resource(10)->delete();
	# output: DELETE http://hostname/api/resource/10

=head1 METHODS

	get put post delete patch head

=head1 ADDITIONAL ARGUMENTS

You can pass any additionals arguments to the on_request callback:

	sub request {
		my ($self, $method, $path, $args, $opts) = @_;
	}

	my $api = Your::API->new();
	$api->resource->get({ value => 1 }, { timeout => 1 });

=head1 INHERITANCE

You can override any methods of any API object:

	package Your::API;
	use base qw(Rest::Client::Builder);
	use JSON;

	sub new {
		my ($class) = @_;

		my $self;
		$self = $class->SUPER::new({
			on_request => sub {
				return $self->request(@_);
			},
		}, 'http://hostname/api');
		return bless($self, $class);
	};

	sub request {
		my ($self, $method, $path, $args) = @_;
		return encode_json($args);
	}

	package Your::API::resource::state;
	sub post {
		my ($self, $args) = (shift, shift);
		$args->{force} = 1;
		return $self->SUPER::post($args, @_);
	}

	my $api = Your::API->new();
	print $api->resource(1)->state->post();
	# output: {"force":1}

=head1 SEE ALSO

L<WWW::REST> L<REST::Client>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Rest::Client::Builder

You can also look for information at:

=over

=item * Code Repository at GitHub

L<http://github.com/alexey-komarov/Rest-Client-Builder>

=item * GitHub Issue Tracker

L<http://github.com/alexey-komarov/Rest-Client-Builder/issues>

=item * RT, CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rest-Client-Builder>

=back

=head1 AUTHOR

Alexey A. Komarov <alexkom@cpan.org>

=head1 COPYRIGHT

2014 Alexey A. Komarov

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut
