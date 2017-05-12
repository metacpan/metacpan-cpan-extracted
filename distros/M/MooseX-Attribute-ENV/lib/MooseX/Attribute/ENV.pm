package MooseX::Attribute::ENV;

use Moose::Role;

our $VERSION = "0.02";
our $AUTHORITY = 'cpan:JJNAPIORK';

=head1 NAME

MooseX::Attribute::ENV - Set default of an attribute to a value from %ENV

=head1 SYNOPSIS

The following is example usage for this attribute trait.

	package MyApp::MyClass;

	use Moose;
	use MooseX::Attribute::ENV;

	## Checks $ENV{username} and $ENV{USERNAME}
	has 'username' => (
		traits => ['ENV'],
	);

	## Checks $ENV{GLOBAL_PASSWORD}
	has 'password' => (
		traits => ['ENV'],
		env_key => 'GLOBAL_PASSWORD',
	);

	## Checks $ENV{last_login}, $ENV{LAST_LOGIN} and then uses the default
	has 'last_login' => (
		traits => ['ENV'],
		default => sub {localtime},
	);

	## Checks $ENV{XXX_config_name} and $ENV{XXX_CONFIG_NAME}
	has 'config_name' => (
		traits => ['ENV'],
		env_prefix => 'XXX',
	);

	## Checks $ENV{MyApp_MyClass_extra} and $ENV{MYAPP_MYCLASS_EXTRA}
	has 'extra' => (
		traits => ['ENV'],
		env_package_prefix => 1,
	);

Please see the test cases for more detailed examples.

=head1 DESCRIPTION

This is a L<Moose> attribute trait that you use when you want the default value
for an attribute to be populated from the %ENV hash.  So, for example if you
have set the environment variable USERNAME = 'John' you can do:

	package MyApp::MyClass;

	use Moose;
	use MooseX::Attribute::ENV;

	has 'username' => (is=>'ro', traits=>['ENV']);

	package main;

	my $myclass = MyApp::MyClass->new();

	print $myclass->username; # STDOUT => 'John';

This is basically similar functionality to something like:

	has 'attr' => (
		is=>'ro',
		default=> sub {
			$ENV{uc 'attr'};
		},
	);

but this module has a few other features that offer merit, as well as being a
simple enough attribute trait that I hope it can serve as a learning tool.

If the named key isn't found in %ENV, then defaults will execute as normal.

=head1 ATTRIBUTES

This role defines the following attributes.

=head2 env_key ($Str)

By default we look for a key in %ENV based on the actual attribute name.  If
want or need to override this behavior, you can use this modifier.

=cut

has 'env_key' => (
	is=>'ro',
	isa=>'Str',
	predicate=>'has_env_key',
);

=head2 env_prefix ($Str)

A prefix to attach to the generated filename.  The prefix is prepended with a
trailing underscore. For example, if you attribute was 'attr' and your set a
prefix of 'xxx' then we'd check for $ENV{xxx_attr} and $ENV{XXX_ATTR}.

=cut

has 'env_prefix' => (
	is=>'ro',
	isa=>'Str',
	predicate=>'has_env_prefix',
);

=head2 env_package_prefix ($Bool)

Similar to env_prefix, but automatically sets the prefix based on the consuming
classes package name.  So if your attribute is 'attr' and it's in a package
called: 'Myapp::Myclass' the follow keys in %ENV will be examined:

* Myapp_Myclass_attr
* MYAPP_MYCLASS_ATTR

Please be aware that if you use this feature, your attribute will automatically
be converted to lazy, which might effect any default subrefs you also assign to
this attribute.

Please note that you can't currently use this option along with the option
'lazy_build'.  That might change in a future release, however since these
attributes are likely to hold simple strings the lazy_build option probably
won't be missed.

=cut

has 'env_package_prefix' => (
	is=>'ro',
	isa=>'Str',
	predicate=>'has_env_package_prefix',
);

=head1 METHODS

This module defines the following methods.

=head2 _process_options

Overload method so that we can assign the default to be what's in %ENV

=cut

around '_process_options' => sub
{
    my ($_process_options, $self, $name, $options) = (shift, @_);

    ## get some stuff we need.
	my $key = $options->{env_key} || $name;
	my $default = $options->{default};
	my $use_pp = $options->{env_package_prefix};

	## Make it lazy if we are using the package prefix option
	if( defined $use_pp && $use_pp )
	{
		$options->{lazy} = 1;
	}

	## Prepend any custom prefixes.
	if($options->{env_prefix})
	{
		$key = join('_', ($options->{env_prefix}, $key));
	}

	## override/update the default method for this attribute.
	CHECK_ENV: {

		$options->{default} = sub {

			if(defined $use_pp && $use_pp)
			{
				my $class = blessed $_[0];
				$class =~s/::/_/g;

				$key = join ('_', ($class, $key));
			}

			## Wish we could use perl 5.10 given instead :)
			if(defined $ENV{$key})
			{
				return $ENV{$key};
			}
			elsif(defined $ENV{uc $key})
			{
				return $ENV{uc $key};
			}
			elsif(defined $default)
			{
				return ref $default eq 'CODE' ? $default->(@_) : $default;
			}
		};
	}

    $_process_options->($self, $name, $options);
};

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to:

	C<MooseX-Attribute-ENV at rt.cpan.org>

or through the web interface at:

	L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Attribute-ENV>

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Attribute::ENV

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Attribute-ENV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Attribute-ENV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Attribute-ENV>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-PopulateMore>

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

## Register the trait so this can be used without verbose invocation.
package Moose::Meta::Attribute::Custom::Trait::ENV;
sub register_implementation { 'MooseX::Attribute::ENV' }

1;
