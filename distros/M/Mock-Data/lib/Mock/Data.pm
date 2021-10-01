package Mock::Data;

# ABSTRACT: Extensible toolkit for generating mock data
our $VERSION = '0.03'; # VERSION


use strict;
use warnings;
BEGIN {
#	require MRO::Compat if "$]" < '5.009005';   # now requiring v5.10 for dist, anyway
	require mro;
	mro::set_mro(__PACKAGE__, 'c3');
}
require Storable;
require Module::Runtime;


sub new {
	my $class= shift;
	my $self= ref $class? $class->clone
		: bless {
			generators => {}, # can't initialize, plugins go first
			generator_state => {},
			_generator_cache => {},
			_loaded_plugins => {},
		}, $class;
	if (@_) {
		my $args
			= (@_ == 1 && ref $_[0] eq 'ARRAY')? { plugins => $_[0] }
			: (@_ == 1 && ref $_[0] eq 'HASH')? $_[0]
			: { @_ };
		if (my $plugins= $args->{plugins}) {
			$self= $self->load_plugin(ref $plugins? @$plugins : ( $plugins ));
		}
		$self->add_generators($args->{generators})
			if $args->{generators};
	}
	return $self;
}


sub clone {
	my $self= shift;
	my $new= {
		%$self,
		# Shallow clone generators and _loaded_plugins
		_loaded_plugins => { %{ $self->{_loaded_plugins} } },
		generators => { %{ $self->{generators} } },
		# deep clone generator_state
		generator_state => Storable::dclone($self->{generator_state}),
		# clear cache
		_generator_cache => {},
	};
	# Allow generators to handle cloned state
	for (values %{ $new->{generators} }) {
		$_= $_->clone if ref->can('clone');
	}
	bless $new, ref $self;
}


sub generators {
	return $_[0]{generators} if @_ == 1;
	# Coerce generators
	my %new= %{ $_[1] };
	$_= Mock::Data::Util::coerce_generator($_) for values %new;
	# clear cache first
	%{$_[0]{_generator_cache}}= ();
	return $_[0]{generators}= \%new;
}

sub generator_state {
	$_[0]{generator_state}= $_[1] if @_ > 1;
	$_[0]{generator_state};
}


sub load_plugin {
	my ($self, @names)= @_;
	for my $name (@names) {
		next if $self->{_loaded_plugins}{$name};
		my $class= "Mock::Data::Plugin::$name";
		unless ($class->can('apply_mockdata_plugin')) {
			Module::Runtime::require_module($class);
			$class->can('apply_mockdata_plugin')
				or Carp::croak("No such method ${class}->apply_mockdata_plugin");
		}
		$self= $class->apply_mockdata_plugin($self);
		ref($self) && ref($self)->isa(__PACKAGE__)
			or Carp::croak("$class->apply_mockdata_plugin did not return a Mock::Data");
		++$self->{_loaded_plugins}{$name};
	}
	return $self;
}


sub add_generators {
	my $self= shift;
	my @args= @_ == 1? %{ $_[0] } : @_;
	while (@args) {
		my ($name, $gen)= splice @args, 0, 2;
		$gen= Mock::Data::Util::coerce_generator($gen);
		$self->generators->{$name}= $gen;
		delete $self->{_generator_cache}{$name};
		$self->generators->{$1} //= $gen
			if $name =~ /::([^:]+)$/
	}
	$self;
}

sub combine_generators {
	my $self= shift;
	my @args= @_ == 1? %{ $_[0] } : @_;
	while (@args) {
		my ($name, $gen)= splice @args, 0, 2;
		$gen= Mock::Data::Util::coerce_generator($gen);
		my $merged= $gen;
		if (defined (my $cur= $self->generators->{$name})) {
			$merged= $cur->combine_generator($gen);
			delete $self->{_generator_cache}{$name};
		}
		$self->generators->{$name}= $merged;
		
		# If given a namespace-qualified name, also install as the 'leaf' of that name
		if ($name =~ /::([^:]+)$/) {
			($name, $merged)= ($1, $gen);
			if (defined (my $cur= $self->generators->{$name})) {
				$merged= $cur->combine_generator($gen);
				delete $self->{_generator_cache}{$name};
			}
			$self->generators->{$name}= $merged;
		}
	}
	$self;
}


sub call {
	my ($self, $name)= (shift, shift);
	defined $self->{generators}{$name}
		or Carp::croak("No such generator '$name'");
	return $self->{generators}{$name}->generate($self, @_) if @_;
	# If no params, call the cached compiled version
	($self->{_generator_cache}{$name} ||= $self->{generators}{$name}->compile)
		->($self, @_);
}


sub wrap {
	my ($self, $name)= (shift, shift);
	my $gen= $self->{generators}{$name};
	defined $gen or Carp::croak("No such generator '$name'");
	my $code= @_? $gen->compile(@_)
		: ($self->{_generator_cache}{$name} ||= $gen->compile);
	return sub { $code->($self) }
}

our $AUTOLOAD;
sub AUTOLOAD {
	my $self= shift;
	Carp::croak("No method $AUTOLOAD in package $self") unless ref $self;
	my $name= substr($AUTOLOAD, rindex($AUTOLOAD,':')+1);
	$self->call($name, @_);
	# don't install, because generators are defined per-instance not per-package
}

sub DESTROY {} # prevent AUTOLOAD from triggering on ->DESTROY


sub import {
	shift;
	Mock::Data::Util->import_into(scalar caller, @_);
}

require Mock::Data::Util;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data - Extensible toolkit for generating mock data

=head1 SYNOPSIS

  my $mock= Mock::Data->new(
    generators => {
      # Select random element of an array
      business_suffix => [qw( Inc. llc. gmbh. )],
      industry        => [qw( Construction Towing Landscaping )],
      
      # Weighted random selection
      surname => {
        Smith => 24, Johnson => 19, Williams => 16, Brown => 14, Jones => 14,
        Nelson => .4, Baker => .4, Hall => .4, Rivera => .4,
      },
      
      # All strings can be templates
      business_name => [
        '{surname} {industry} {business_suffix}',
        '{surname} and {surname} {business_suffix}',
      ],
      
      # Generate strings that match a regex
      email => qr/(\w+)@(\w+)(\.com|\.org|\.net|\.co\.uk)/,
      
      # Or just code your own generators
      real_address => sub($mock) { $db->resultset("Address")->rand->single },
      address_json => sub($mock) { encode_json($mock->real_address) },
    },
    
    # load plugins
    plugins => ['Text'],  # Mock::Data::Plugin::Text
  );

  # Put all your generators into a plugin for easy access
  my $mock= Mock::Data->new(['MyCollection']);
  
  # Call generators
  say $mock->call('email');
  say $mock->email;              # uses AUTOLOAD
  say $mock->wrap('email')->();  # coderef for repeated calling
  
  # Pass parameters to generators
  say $mock->words({ count => 50 });
  say $mock->words(50);
  say $mock->call(words => 50);

=head1 DESCRIPTION

This module is a generator of mock data.  It takes good ideas seen in L<Data::Faker>,
L<Mock::Populate>, and other similar modules, and combines them into a cohesive
extensible design.

Each mock data generator is called as a method on an instance of C<Mock::Data>.  This allows
generators to store persistent state between calls.  It also allows them to be configured
with per-instance settings.

=head1 CONSTRUCTOR

=head2 new

  $mock= Mock::Data->new(\@package_list);
  $mock= Mock::Data->new({
    generators => \%generator_set,
    plugins    => \@package_list,
  });

Construct a new instance of Mock::Data.  If called as a method of an object, this will clone
the existing instance, applying generators on top of the set already present.

Arguments:

=over

=item C<< plugins => \@package_list >>

This lets you specify a list of packages whose generators should be pulled into the new object.
The plugins may also change the class of the object returned.

=item C<< generators => \%set >>

This specifies a set of generators that should be added I<after> any generators that get added
by plugins (or any that were carried over from the old instance if C<new> is being called on
an instance instead of on the class).

=back

=head2 clone

  $mock2= $mock->clone;

Calling C<clone> on a C<Mock::Data> instance returns a new C<Mock::Data> of the same class
with the same plugins and a deep-clone of the L</generator_state> and a shallow clone of the
L</generators> set.  This may not have the desied effect if one of your generators is storing
state outside of the L</generator_state> hashref.

C<clone> does not take any arguments.  If you wish to modify the object at the same time as
cloning a previous one, call L</new> on the previous object instance.

=head1 ATTRIBUTES

This module defines a minimal number of attributes, to leave most of the method namespace
available for the generators themselves.  All subclasses and custom generators should attempt
to use the existing attributes instead of defining new ones.

=head2 generators

  my $generator= $mock->generators->{$name};
  $mock->generators( $new_hashref );  # clears cache, coerces values

This is a hashref of L<Mock::Data::Generator> objects.  Do not modify the contents of this
attribute directly, as compiled versions of each generator are cached, but you may assign a
new hashref to it.

When assigning, the values of the supplied hash will each get coerced into a generator via
L<Mock::Data::Util/coerce_generator>.

=head2 generator_state

  sub my_generator($mock, @params) {
    $mock->generator_state->{__PACKAGE__.'.something'}= $my_state;
  }

This is a hashref where generators store state data.  If the instance of L<Mock::Data>
is cloned, this hashref will be deep-cloned.  Other hashref fields of the L<Mock::Data> object
are not deep-cloned, aside from the C<generators> field which is cloned one level deep.

Keys in this hash should be prefixed with either the name of the generator or name of the
package the generator was implemented from.

=head1 METHODS

Note: All generators may be called as methods, thanks to C<AUTOLOAD>.

=head2 load_plugin

  $mock= $mock->load_plugin($name);

This method loads the plugin C<< Mock::Data::Plugin::${name} >> if it was not loaded already,
and performs whatever initialization that package wants to perform, which may return a
B<completely different> instance of C<Mock::Data>.  Always use the return value and assume
the initial reference is gone.  If you want a clone, call C<< $mock->new >> first to clone it.

=head2 add_generators

  $mock->add_generators( $name => $spec, ... )

Set one or more named generators.  Arguments can be given as a hashref or a list of key/value
pairs.  C<$spec> can be a coderef, an arrayref (of options) or an instance of
L<Mock::Data::Generator>.  If a previous generator existed by the same name, it will be
replaced.

If the C<$name> of the generator is a package-qualified name, the generator is added under
both the long and short name.  For example, C<< combine_generators( 'MyPlugin::gen' => \&gen ) >>
will register \&gen as both C<'MyPlugin::gen'> and an alias of C<'gen'>.  However, C<'gen'>
will only be added if it didn't already exist.  This allows plugins to refer to eachother's
names without collisions.

Returns C<$mock>, for chaining.

Use this method instead of directly modifying the C<generators> hashref so that this module
can perform proper cache management.

=head2 combine_generators

  $mock->combine_generators( $name => $spec, ... )

Same as L</add_generators>, but if a generator of that name already exists, replace it with a
generator that returns both possible sets of results.  If the old generator was a coderef, it
will be replaced with a new generator that calls the old coderef 50% of the time.  If the old
generator and new generator are both L<Sets|Mock::Data::Set>, the merged generator will be a
concatenation of the sets.

Returns C<$mock>, for chaining.

Use this method instead of directly modifying the C<generators> hashref so that this module
can perform proper cache management.

=head2 call

  $mock->call($name, \%named_params, @positional_params);

This is a more direct way to invoke a generator.  The more convenient way of calling the
generator name as a method of the object uses C<AUTOLOAD> to call this method.  The return
value is whatever the generator returns.

=head2 wrap

  my $sub= $mock->wrap($name, \%named_params, @positional_params);
  say $sub->();

This creates an anonymous sub that wraps the complete call to the generator, including the
instance of C<$mock> and any parameters you supply.  This is intended for efficiency if you
plan to make lots of calls to the generator.

=head1 EXPORTS

Mock::Data can export symbols from L<Mock::Data::Util>.  See that module for a complete
reference for each function.

=over

=item uniform_set(@items)

=item weighted_set($item => $weight, ...)

=item charset($regex_set_notation)

=item template($string)

=item inflate_template($string)

=item coerce_generator($specification)

=item mock_data_subclass($class_or_object, @class_list)

=back

=head1 SEE ALSO

=over

=item *

L<Data::Faker>

=item *

L<Mock::Populate>

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
