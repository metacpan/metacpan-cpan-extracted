package POE::Declare::Meta;

=pod

=head1 NAME

POE::Declare::Meta - Metadata object that describes a POE::Declare class

=head1 DESCRIPTION

B<POE::Declare::Meta> objects are constructed and used internally by
L<POE::Declare> during class construction. B<POE::Declare::Meta> objects
are not created directly.

Access to the meta object for a L<POE::Declare> class is via the exported
C<meta> function.

=head1 METHODS

=cut

use 5.008007;
use strict;
use warnings;
use Carp                  ();
use File::Temp            ();
use Scalar::Util     1.19 ();
use Params::Util     1.00 ();
use Class::ISA       0.33 ();
use Class::Inspector 1.22 ();

use vars qw{$VERSION $DEBUG};
BEGIN {
	$VERSION = '0.59';
	$DEBUG   = !! $DEBUG;
}

use constant DEBUG => $DEBUG;

use POE::Declare::Meta::Slot      ();
use POE::Declare::Meta::Message   ();
use POE::Declare::Meta::Event     ();
use POE::Declare::Meta::Timeout   ();
use POE::Declare::Meta::Attribute ();
use POE::Declare::Meta::Internal  ();
use POE::Declare::Meta::Param     ();

use Class::XSAccessor 1.10 {
	getters => {
		name     => 'name',
		alias    => 'alias',
		sequence => 'sequence',
		compiled => 'compiled',
	},
};





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# The name of the class
	my $name = shift;
	unless ( Params::Util::_CLASS($name) ) {
		Carp::croak("Invalid class name '$name'");
	}
	unless ( Class::Inspector->loaded($name) ) {
		Carp::croak("Class $name is not loaded");
	}
	unless ( $name->isa('POE::Declare::Object') ) {
		Carp::croak("Class $name is not a POE::Declare::Object subclass");
	}

	# Create the object
	my $self = bless {
		name     => $name,
		alias    => $name,
		sequence => 0,
		attr     => { },
	}, $class;

	$self;
}





#####################################################################
# Accessors

=pod

=head2 name

The C<name> accessor returns the name of the class for this meta instance.

=cut

# sub name {
#     $_[0]->{name};
# }

=pod

=head2 alias

The C<alias> accessor returns the alias root string that will be used for
objects that are created of this type.

Normally this will be identical to the class C<name> but may be changed
at constructor time.

=cut

# sub alias {
#     $_[0]->{alias};
# }

=pod

=head2 sequence

Because each object has its own L<POE::Session>, each session also needs
its own session alias, and the session alias is derived from a combination
of the C<alias> method an an incrementing C<sequence> value.

The C<sequence> accessor returns the most recently requested value from the
sequence. As with sequence in SQL, not all values pulled from the sequence
will necesarily be used in an object, and objects will not necesarily have
incrementing sequence values.

=cut

# sub sequence {
#     $_[0]->{sequence};
# }





#####################################################################
# Methods

=pod

=head2 next_alias

The C<next_alias> method generates and returns a new session alias,
by taking the C<alias> base string and appending an incremented
C<sequence> value.

The typical alias string returned will look something like
C<'My::Class.123'>.

=cut

sub next_alias {
	$_[0]->{alias} . '.' . ++$_[0]->{sequence};
}

=pod

=head2 super_path

The C<super_path> method is provided as a convenience, and returns a list
of the inheritance path for the class.

It is equivalent to C<Class::ISA::self_and_super_path('My::Class')>.

=cut

sub super_path {
	Class::ISA::self_and_super_path( $_[0]->name );
}

=pod

=head2 attr

  my $attribute = My::Class->meta->attr('foo');

The C<attr> method is used to get a single named attribute meta object
within the class meta object.

Returns a L<POE::Declare::Meta::Attribute> object or C<undef> if no such
named attribute exists.

=cut

sub attr {
	my $self = shift;
	my $name = shift;
	foreach my $c ( $self->super_path ) {
		my $meta = $POE::Declare::META{$c} or next;
		my $attr = $meta->{attr}->{$name}  or next;
		return $attr;
	}
	return undef;
}

# Fetch all named attributes (from this or parents)
sub attrs {
	my $self = shift;
	my %hash = ();
	foreach my $c ( $self->super_path ) {
		my $meta = $POE::Declare::META{$c} or next;
		my $attr = $meta->{attr};
		foreach ( keys %$attr ) {
			$hash{$_} = $attr->{$_};
		}
	}
	return values %hash;
}





#####################################################################
# Compilation

sub as_perl {
	my $self = shift;
	my $name = $self->name;
	my $attr = $self->{attr};

	# Go over all our methods, and add any required events
	my $methods = Class::Inspector->methods($name, 'expanded');
	foreach my $method ( @$methods ) {
		my $mname  = $method->[2];
		my $mcode  = $method->[3];
		my $maddr  = Scalar::Util::refaddr($mcode);
		my $mevent = $POE::Declare::EVENT{$maddr} or next;
		my $mattr  = $self->attr($mname);
		if ( $mattr ) {
			# Make sure the existing attribute is an event
			next if $mattr->isa('POE::Declare::Meta::Event');
			Carp::croak("Event '$mname' in $name clashes with non-event in parent class");
			next;
		}

		# Add an attribute for the event
		my $class = $mevent->[0];
		my @param = @$mevent[1..$#$mevent];
		$self->{attr}->{$mname} = $class->new(
			name => $mname,
			@param,
		);
	}

	# Get all the package fragments
	my $code = join "\n", (
		"package $name;",
		"",
		"BEGIN {",
		"    no strict 'refs';",
		"    delete \${\"\${name}::\"}{'meta'};",
		"    use strict;",
		"}",
		"",
		"sub meta () { \$POE::Declare::META{'$name'} }",
		map {
			$attr->{$_}->as_perl
		} sort keys %$attr
	);

	# Load the code
	if ( DEBUG ) {
		# Compile the combined code via a temp file
		my ($fh, $filename) = File::Temp::tempfile();
		$fh->print("$code\n\n1;\n");
		close $fh;
		require $filename;
		unlink $filename;

		# Print the debugging output
		my @trace = map {
			s/\s*[{;]$//;
			s/^s/  s/;
			s/^p/\np/;
			"$_\n"
		} grep {
			/^(?:package|sub)\b/
		} split /\n/, $code;
		print STDERR @trace, "\n$name code saved as $filename\n\n";
	} else {
		eval("$code\n\n1;\n");
		die $@ if $@;
		Carp::croak("Failed to compile code for $name") if $@;
	}

	return (
		$self->{compiled} = 1
	);
}

# sub compiled {
#     $_[0]->{compiled};
# }





#####################################################################
# Run-Time Support Methods

# Resolve the inline states for a class
sub _package_states {
	my $self = shift;
	unless ( exists $self->{_package_states} ) {
		# Cache for speed reasons
		$self->{_package_states} = [
			sort map {
				$_->name
			} grep {
				$_->isa('POE::Declare::Meta::Event')
			} $self->attrs
		];
	}
	if ( wantarray ) {
		return @{$self->{_package_states}};
	} else {
		return $self->{_package_states};
	}
}

# Resolve the parameter list
sub _params {
	my $self = shift;
	unless ( exists $self->{_params} ) {
		# Cache for speed reasons
		$self->{_params} = [
			sort map {
				$_->name
			} grep {
				$_->isa('POE::Declare::Meta::Param')
			} $self->attrs
		];
	}
	if ( wantarray ) {
		return @{$self->{_params}};
	} else {
		return $self->{_params};
	}
}

# Resolve the message list
sub _messages {
	my $self = shift;
	unless ( exists $self->{_messages} ) {
		# Cache for speed reasons
		$self->{_messages} = [
			sort map {
				$_->name
			} grep {
				$_->isa('POE::Declare::Meta::Message')
			} $self->attrs
		];
	}
	if ( wantarray ) {
		return @{$self->{_messages}};
	} else {
		return $self->{_messages};
	}
}

# Resolve the timeout list
sub _timeouts {
	my $self = shift;
	unless ( exists $self->{_timeouts} ) {
		# Cache for speed reasons
		$self->{_timeouts} = [
			sort map {
				$_->name
			} grep {
				$_->isa('POE::Declare::Meta::Timeout')
			} $self->attrs
		];
	}
	if ( wantarray ) {
		return @{$self->{_timeouts}};
	} else {
		return $self->{_timeouts};
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
