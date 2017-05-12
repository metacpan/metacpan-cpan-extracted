package Role::REST::Client::Auth::Basic;
$Role::REST::Client::Auth::Basic::VERSION = '0.05';
use Moo::Role;
use MIME::Base64;
use Types::Standard qw(Str);

requires '_call', 'httpheaders';


has 'user' => (
	isa => Str,
	is  => 'rw',
	trigger => sub {
		my ($self, $user) = @_;
		Carp::croak("Basic authentication user name can't contain ':'") if $user =~ /:/;
	},
);
has 'passwd' => (
	isa => Str,
	is  => 'rw',
);

before '_call' => sub {
	my ($self, $method, $endpoint, $data, $args) = @_;
	return if $args->{authentication} and $args->{authentication} ne 'basic';

	my $user = $self->user;
	if (defined $user) {
		my $passwd = $self->passwd();
		$passwd = '' if !defined $passwd;
		$self->set_header('Authorization', 'Basic ' . MIME::Base64::encode("$user:$passwd", ''));
	}
	return;
};

1;

=pod

=encoding UTF-8

=head1 NAME

Role::REST::Client::Auth::Basic - Basic Authentication for REST Client Role

=head1 VERSION

version 0.05

=head1 SYNOPSIS

	{
		package RESTExample;

		use Moose;
		with 'Role::REST::Client';
		with 'Role::REST::Client::Auth::Basic';

		sub bar {
			my ($self) = @_;
			my $res = $self->post('foo/bar/baz', {foo => 'bar'});
			my $code = $res->code;
			my $data = $res->data;
			return $data if $code == 200;
	   }

	}

	my $foo = RESTExample->new( 
		server =>      'http://localhost:3000',
		type   =>      'application/json',
		user   =>      'mee',
		passwd =>      'sekrit',
	);

	$foo->bar;

	# controller
	sub foo : Local {
		my ($self, $c) = @_;
		# Call w/ basic authentication
		my $res = $c->model('MyData')->post('foo/bar/baz', {foo => 'bar'});
		my $code = $res->code;
		my $data = $res->data;
		...
		# Call w/o basic authentication
		my $res = $c->model('MyData')->post('xyzzy', {foo => 'bar'}, {authentication => undef});
	}

=head1 DESCRIPTION

This role adds basic authentication to Role::REST::Client.

Just add it to your class and all calls will automatically authenticate.

Add an authentication parameter to the arguments if you for some reaon don't want to authenticate

=head1 NAME

Role::REST::Client::Auth::Basic - Basic Authentication for REST Client Role

=head1 AUTHOR

Kaare Rasmussen, <kaare at cpan dot com>

=head1 CONTRIBUTORS

Aran Deltac, (cpan:BLUEFEET) <bluefeet@gmail.com>

=head1 BUGS 

Please report any bugs or feature requests to bug-role-rest-client-auth-basic at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Role-REST-Client-Auth-Basic.

=head1 COPYRIGHT & LICENSE 

Copyright 2014 Kaare Rasmussen, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may 
have available.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Basic Authentication for REST Client Role

