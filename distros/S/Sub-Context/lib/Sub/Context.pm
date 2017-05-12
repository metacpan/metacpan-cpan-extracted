package Sub::Context;

use strict;
use Scalar::Util 'reftype';

use vars '$VERSION';
$VERSION = '1.00';

sub import
{
	my ($class, %args) = @_;
	my $pkg            = caller();

	while (my ($subname, $args) = each %args)
	{
		my $sub = $class->_qualify_sub( $pkg, $subname );
		$class->_wrap_sub( $sub, $args );
	}
}

sub _qualify_sub
{
	my ($class, $package, $subname) = @_;

	return $subname if index( $subname, '::' ) > 0;
	return $package . '::' . $subname;
}

sub _wrap_sub
{
	my ($class, $subname, $contexts) = @_;

	# may croak()
	$class->_validate_contexts( $contexts );
	$class->_generate_contexts( $subname, $contexts );

	my $glob                         = $class->_fetch_glob( $subname );
	$class->_apply_contexts( $glob, $contexts );
}

sub _generate_contexts
{
	my ($class, $subname, $contexts) = @_;

	for my $context ( $class->_contexts() )
	{
		next if ref      $contexts->{$context}
		     && reftype( $contexts->{$context} ) eq 'CODE';

		my $message = exists $contexts->{$context} ?
			': ' . delete $contexts->{$context} :
			'';

		$contexts->{$context} = $class->_default_sub(
			$subname, $context, $message
		);
	}
}

sub _default_sub
{
	my ($class, $subname, $context, $message) = @_;

	# don't look at this
	my $sub = \&{ $subname };
	return $sub if defined &$sub;

	return sub
	{
		require Carp;
		Carp::croak( "No sub for $context context$message")
	};
}

sub _apply_contexts
{
	my ($class, $glob, $contexts) = @_;

	*$glob = sub
	{
		my $context = wantarray();
		$context    = defined $context ?
			( $context ? 'list' : 'scalar' ) :
			'void';
		goto &{ $contexts->{$context} };
	};
}

sub _contexts
{
	qw( void scalar list );
}

sub _validate_contexts
{
	my ($class, $contexts) = @_;
	my %allowed            = map { $_ => 1 } $class->_contexts();

	for my $provided ( keys %$contexts )
	{
		unless ( exists $allowed{$provided} )
		{
			require Carp;
			Carp::croak( "Context type '$provided' not allowed!" );
		}
	}
}

sub _fetch_glob
{
	my ($class, $globname) = @_;
	my $glob               = $class->_find_glob( $globname );

	return $glob unless defined &$globname;

	local *NEWGLOB;

	no strict 'refs';

	for my $slot (qw ( SCALAR ARRAY FORMAT IO HASH ))
	{
		*NEWGLOB = *{$glob}{$slot} if defined *{$glob}{$slot};
	}

	*{$glob} = *NEWGLOB;
	return $glob;
}

sub _find_glob
{
	my ($class, $name) = @_;
	my $glob           = \%main::;
	my @package        = split( '::', $name );
	my $subroutine     = pop @package;

	for my $package ( @package )
	{
		$glob = $glob->{$package . '::'};
	}

	$glob = \$glob->{$subroutine};
	return $glob;
}

'your message here, contact $AUTHOR for rates';

__END__

=head1 NAME

Sub::Context - Perl extension to dispatch subroutines based on their calling
context

=head1 SYNOPSIS

	use Sub::Context sensitive =>
	{
		void	=> \&whine,
		scalar	=> \&cry,
		list	=> \&weep,
	};

=head1 DESCRIPTION

Sub::Context dispatches subroutine calls based on their calling context.  This
can be handy for converting return values or for throwing warnings or even
fatal errors.  For example, you can prohibit a function from being called in
void context.  Instead of playing around with C<wantarray()> on your own, this
modules does it for you.

=head2 EXPORT

None by default.  C<use> the module and its custom C<import()> function will
handle things nicely for you.

=head1 IMPORTING

By convention, Sub::Context takes a list of arguments in pairs.  The first item
is the name of a subroutine.  The second item in the list is a reference to a
hash of options for that subroutine.  For example, to create a new sub named
C<penguinize()> in the calling package, with three existing subroutines for
each of the three types of context (void, list, and scalar), write:

	use Sub::Context
		penguinize =>
		{
			void	=> \&void_penguinize,
			list	=> \&list_penguinize,
			scalar	=> \&scalar_penguinize,
		};

You can provide your own subroutine references, of course:

	use Sub::Context
		daemonize =>
		{
			list => sub { paint_red( penguinize() ) },
		};

If you are creating a new subroutine and do not provide a subroutine reference
for a context type, Sub::Context will helpfully C<croak()> when you call the
sub with the unsupported context.  You can also provide a scalar instead of a
subref, which will then be part of the error message:

	use Sub::Context 
		daemonize => {
			list => sub { paint_red( penguinize(@_) ) },
			void => 'daemons get snippy in void context',
		};

You don't have to create new subs.  You can wrap existing subs, as well.  that
in this case, if you do not provide a new behavior for a context type, the old
behavior will persist.  For example, if you have an existing sub that returns a
string of words, you can say:

	use Sub::Context
		get_sentence =>
		{
			list => sub { split(' ', get_sentence(@_) },
			void => 'results too good to throw away',
		};

Called in scalar context, C<get_sentence()> will behave like it always has.  In
list context, it will return a list of words (for whatever definition of
'words' the regex provides).  In void context, it will croak with the provided
error message.

=head1 TODO

=over 4

=item Allow unwrapping of wrapped subs (localized?)

=item World domination?

=back

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>

=head1 COPYRIGHT

Copyright (c) 2001, 2005 by chromatic.

This program is free software. You can use, modify, and distribute it under the
same terms as Perl 5.8.x itself.

=head1 SEE ALSO

L<perl>, C<wantarray>, L<Want>.

=cut
