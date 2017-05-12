package Template::Plugin::StringTree;

=pod

=head1 NAME

Template::Plugin::StringTree - Access tree-like groups of strings naturally in code and Templates

=head1 SYNOPSIS

  use Template::Plugin::StringTree;
  
  # Create a StringTree and set some values
  my $Tree = Template::Plugin::StringTree->new;
  $Tree->set('foo', 'one');
  $Tree->set('foo.bar', 'two');
  $Tree->set('you.get.the.point' => 'right?');
  
  # Get simple hash of these variables for the template
  my $vars = $Tree->variables;
  
  #######################################################
  # Later that night in a Template
  
  After the number [% foo %] comes the number [% foo.bar %], [% you.get.the.point %]
  
  #######################################################
  # Which of course produces
  
  After the number one comes the number two, right?

=head1 DESCRIPTION

For a couple of months, I had found it really annoying that when I wanted
to put a bunch of configuration options into a template, that I couldn't
use a natural [% IF show.pictures %][% IF show.pictures.dropshadow %] ...etc...
type of notation. Simply, to get "dot" formatting in template, you need
hashes. Which means stupid notation like [% show.pictures.at_all %]. ugh...

As the size of the config tree I wanted to use grew and grew, it finally
started getting totally out of control, so I've created
Template::Plugin::StringTree, which lets you build tree structures in which
every node can have a value. And you can get at these naturally in templates.

=head1 METHODS

=cut

use 5.005;
use strict;
use Template::Plugin::StringTree::Node ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.08';
}





#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor simply creates a new ::StringTree object and
returns it.

=cut

sub new {
	bless {}, ref($_[0]) || $_[0];
}

sub clone {
	my $self = ref $_[0] ? shift : return undef;
	ref($self)->thaw( $self->freeze );
}





#####################################################################
# Main Methods

=pod

=head2 get $path

Taking a single "this.is.a.path" argument, the C<get> method returns the
value associated with the path, if there is one.

Returns the value for the path, if one exists. Returns C<undef> if no value
exists at that path.

=cut

sub get {
	my $self = shift;
	my $path = $self->_path($_[0]) or return undef;

	# Walk the tree to find the value
	my $cursor = $self;
	foreach my $branch ( @$path ) {
		return undef unless ref $cursor; # Last branch took us to a normal value
		defined($cursor = $cursor->{$branch}) or return undef;
	}

	# We have arrived at the value we want.
	ref $cursor ? $cursor->__get : $cursor;
}

=pod

=head2 set $path, $value

The C<set> method takes a "this.is.a.path" style path and a value for that
path. C<undef> is valid as a value, erasing a single value at the node for
the path. ( It does not remove children of that node ).

Returns true if the value is set correctly, or C<undef> on error.

=cut

sub set {
	my $self  = shift;
	my $path  = $self->_path(shift) or return undef;
	my $value = shift;

	# Walk the tree to determine the location to set
	my $cursor = $self;
	my $leaf = pop @$path;
	foreach my $branch ( @$path ) {
		if ( ! defined $cursor->{$branch} ) {
			# Create a new node for the branch
			$cursor->{$branch} = Template::Plugin::StringTree::Node->__new;
		} elsif ( ! ref $cursor->{$branch} ) {
			# Convert the existing leaf into a node
			$cursor->{$branch} = Template::Plugin::StringTree::Node->__new( $cursor->{$branch} );
		}

		# Move down into the node
		$cursor = $cursor->{$branch};		
	}

	# Now set the leaf
	if ( exists $cursor->{$leaf} and ref $cursor->{$leaf} ) {
		# Replace the node's value
		$cursor->{$leaf}->__set($value);
	} else {
		# Create or replace a leaf
		$cursor->{$leaf} = $value;
	}

	1;
}

=pod

The C<add> method is nearly identical to the normal C<set> method,
except that the it expects there B<NOT> to be an existing value in place.
Rather than overwrite an existing value, this method will return an error.

Returns true if there is no existing value, and it is successfully set,
or C<undef> if there is an existing value, or an error while setting.

=cut

sub add {
	my $self  = shift;
	my $path  = $self->_path(shift) or return undef;
	my $value = shift;

	# Walk the tree to determine the location to set
	my $cursor = $self;
	my $leaf = pop @$path;
	foreach my $branch ( @$path ) {
		if ( ! defined $cursor->{$branch} ) {
			# Create a new node for the branch
			$cursor->{$branch} = Template::Plugin::StringTree::Node->__new;
		} elsif ( ! ref $cursor->{$branch} ) {
			# Convert the existing leaf into a node
			$cursor->{$branch} = Template::Plugin::StringTree::Node->__new( $cursor->{$branch} );
		}

		# Move down into the node
		$cursor = $cursor->{$branch};		
	}

	# Now set the leaf
	if ( exists $cursor->{$leaf} and ref $cursor->{$leaf} ) {
		# Fail if there is an existing value
		return undef if defined $cursor->{$leaf}->__get($value);

		# Replace the node's value
		$cursor->{$leaf}->__set($value);
	} else {
		# Fail if there is an existing value
		return undef if defined $cursor->{$leaf};

		# Create or replace a leaf
		$cursor->{$leaf} = $value;
	}

	1;
}


=pod

=head2 hash

The C<hash> method produces a flat hash equivalent to the
Template::Plugin::StringTree object, which can be passed to the template
parser. You can manually add additional elements to the hash after it has
been produced, but you should not attempt to add anything to a hash key
the same as the first element in a path already added via the C<set>
method earlier.

Returns a reference to a HASH containing the tree of strings.

=cut

sub hash { my $hash = { %{$_[0]} }; $hash }

=pod

=head2 freeze

Ever good structure can be serialized and deserialized, and this one is
no exception. The C<freeze> method takes a ::StringTree object and converts
it into a string, which just so happens to be highly useful as a config
file format!

  foo: one
  foo.bar: two
  you.get.the.point: right?

So terribly simple. To make life just a LITTLE more complicated though,
Template::Plugin::StringTree does a little bit of escaping if there's a
newline in the string. But since you'll probably never DO that, it won't
be a problem will it? :)

=cut

sub freeze {
	my $self = shift;

	# Handle the special null case
	return 'null' unless keys %$self;

	# Flatten and escape the tree
	my %flat = ();
	my @queue = ( [ '', $self ] );
	while ( my $item = shift @queue ) {
		my $base   = $item->[0];
		my $cursor = $item->[1];

		foreach my $key ( keys %$cursor ) {
			my $path = length $base ? "$base.$key" : $key;
			my $value = (ref $cursor->{$key})
				? $cursor->{$key}->__get
				: $cursor->{$key};
			if ( defined $value ) {
				# Escape and add the value to the output
				$value =~ s/([\\\n])/sprintf('\\%03d', ord($1))/ge;
				$flat{$path} = $value;
			}
			push @queue, [ $path, $cursor->{$key} ] if ref $cursor->{$key};
		}
	}

	# Now convert the flattened tree to a single string
	join '', map { "$_: $flat{$_}\n" } sort keys %flat;
}

=pod

=head2 thaw $string

The C<thaw> method is the reverse of the C<freeze> method, taking the same
format string turning it back into a Template::Plugin::StringTree object.
THIS is where using this module as a config file -> template mechanism
really comes into it's own. Each entry is the config file is available
using the same path in Template Toolkit templates.
Template::Plugin::StringTree takes care of all the details or making it work
across the different models transparently.

If the string is formatted correctly, returns a new
Template::Plugin::StringTree object. Returns C<undef> on error, probably
because the string wasn't formatted correctly.

=cut

sub thaw {
	my $class = ref $_[0] ? ref shift : shift;
	my $string = shift or return undef;
	my $self = $class->new;

	# Handle the special case
	return $self if $string eq 'null';

	foreach ( split /\n/, $string ) {
		return undef unless /^([\w\.]+)\:\s*(.*)$/;
		my $key = $1;
		my $value = $2;

		# Unescape the value
		$value =~ s/\\(\d\d\d)/chr($1)/ge;
		$self->set($key, $value) or return undef;
	}

	$self;
}

=pod

=head2 equal $path, $value

The C<equal> method provides a quick and convenient bit of shorthand to
let you see if a particular path equals a particular value. And the
method is totally undef-safe. You can test for a value of C<undef>,
and test a value against a path which returns C<undef> quite safely.

Returns true if the value matches the path, or false otherwise.

=cut

sub equal {
	my $self = shift;
	my $left = $self->get(shift);
	my $right = shift;
	defined $left ? (defined($right) and $left eq $right) : ! defined $right;
}





#####################################################################
# Support Methods

sub _path {
	# Check the value before we begin processing it
	my $value = (defined $_[1] and ! ref $_[1]) ? $_[1] : return undef;
	$value =~ /^[^\W\d]\w*(?:\.[^\W\d]\w*)*$/ or return undef;

	# Split the path
	my @path = split /\./, $value;
	if ( grep { $_ eq 'DESTROY' } @path ) {
		# Illegal value, clashes with the Node DESTROY method
		warn "The use of 'DESTROY' as a path node is forbidden";
		return undef;
	}

	\@path;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

  http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-StringTree

For other issues, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
