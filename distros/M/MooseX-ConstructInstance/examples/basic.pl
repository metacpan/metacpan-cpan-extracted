=head1 PURPOSE

A simple example of a class using the C<construct_instance> method.

Two roles hook onto it. One of them auto-loads classes at run time:

   before construct_instance => sub {
      my ($self, $class) = @_;
      Module::Runtime::use_package_optimistically($class);
   };

The other uses an C<around> modifier to tweak the constructed instance:

   around construct_instance => sub {
      my $orig = shift;
      my $self = shift;
      my $inst = $self->$orig(@_);
      ...;
      return $inst;
   };

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

{
	package WebGetter;
	
	use Carp;
	
	use Moo;
	with 'MooseX::ConstructInstance';
	has ua       => (is => 'lazy');
	has ua_class => (is => 'lazy');
	
	sub get
	{
		my ($self, $url) = @_;
		
		my $response = $self->ua->get($url);
		$response->is_success or croak "HTTP fail";
		
		return $response->decoded_content;
	}
	
	sub _build_ua
	{
		my $self = shift;
		$self->construct_instance($self->ua_class);
	}
	
	sub _build_ua_class
	{
		'LWP::UserAgent';
	}
}

{
	package AutoLoading;
	use Moo::Role;
	use Module::Runtime;
	before construct_instance => sub {
		my ($self, $class) = @_;
		Module::Runtime::use_package_optimistically($class);
	};
}

{
	package MySecret;
	use Moo::Role;
	
	around construct_instance => sub {
		my $orig = shift;
		my $self = shift;
		my $inst = $self->$orig(@_);
		$inst->DOES('LWP::UserAgent')
			and $inst->credentials('', '', '007', 'T3R3SA');
		return $inst;
	};
}


my $agent = WebGetter->new;
Moo::Role->apply_roles_to_object($agent, 'AutoLoading', 'MySecret');
print $agent->get('http://www.example.com/bond');
