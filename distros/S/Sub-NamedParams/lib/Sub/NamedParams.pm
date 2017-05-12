package Sub::NamedParams;

use 5.005;
use strict;
use Carp qw/croak/;

require Exporter;
use vars     qw/ $VERSION @ISA @EXPORT_OK /;
$VERSION   = '1.02';
@ISA       = qw/ Exporter/;
@EXPORT_OK = qw/ wrap /;

# I don't like defining this outside the sub, but I want this lexically
# scoped (so programmers won't futz with it) and persistant.
{
	my %wrapped_sub;
	
	sub wrap {
		my %wrapper = @_;
		my $package = caller(0);
	
		foreach ( qw/ sub names / ) {
			if ( ! exists $wrapper{$_} ) {
				croak "You must supply '$_' in the argument list'";
			}
		}
	
		croak "'sub' value must not be a reference." unless !ref $wrapper{sub};
	
		my $sub = $wrapper{ sub };
		if ( $sub !~ /::/ ) {
			# if it's not fully qualified, append the package
			$sub = "${package}::$sub";
		}
	
		my $target = $sub;
		if ( exists $wrapper{ target } ) {
			$target = $wrapper{ target };
			if ( $target !~ /::/ ) {
				$target = "${package}::$target";
			}
		}
		if (my $error = _bad_target( $target, \%wrapper )) {
			croak $error;
		}
		
		$wrapped_sub{ $target } = 1;
	
		no strict 'refs';
		my $orig_sub = \&$sub;
		
		$wrapper{ hashref } = 1  if ! exists $wrapper{ hashref };
		$wrapper{ default } = {} if ! exists $wrapper{ default };
	
		local $^W; # suppress warnings about redefined sub
		*{$target} = sub {
			my %args = $wrapper{ hashref } ? %{$_[0]} : @_;
			my @orig_args;
			foreach my $arg_name ( @{$wrapper{ names }} ) {
				if ( exists $args{ $arg_name } ) {
					push @orig_args, $args{ $arg_name };
				} elsif ( exists $wrapper{ default }{ $arg_name } ) {
					push @orig_args, $wrapper{ default }{ $arg_name };
				} else {
					croak( "Cannot find value or default for '$arg_name'" );
				}
			}
			return $orig_sub->( @orig_args );
		}
	}
	
	sub _bad_target {
		my ( $target, $wrap ) = @_;
		my $error = '';
		if ( exists $wrapped_sub{ $target } ) {
			$error = "Cannot rewrap '$target'";
		} elsif (exists $wrap->{target} and $wrap->{sub} ne $wrap->{target}) {
			no strict 'refs';
			if ( defined &{$target} ) {
				$error = "Cannot target a pre-existing sub: '$target'";
			}
		}
		return $error;
	}
}
'Ovid';

__END__

=head1 NAME

Sub::NamedParams - Perl extension for using named arguments with any sub

=head1 SYNOPSIS

  use Sub::NamedParams qw/wrap/;
  wrap ( 
    sub   => some_sub_name,
    names => [qw/ names for your arguments /],
    default => {
      your => 1,
      arguments => undef
    }
  );

  some_sub_name( {
    names => [qw/Bill Mary Ovid/],
    for   => '??'
  } );
    

=head1 DESCRIPTION

Sometimes it can be a pain to work with a sub that takes a long list of
arguments.   Trying to remember their order can be annoying, but it gets worse
if some of the arguments are optional.  This module allows you to use named
arguments with any subroutine.  It has only one function,
C<Sub::NamedParams::wrap>, which has two mandatory and three optional
arguments.

=head1 EXPORT

Exports C<wrap> on demand.

=head2 wrap

Call this function to "wrap" a function in a new function which takes names
parameters.

=over 4

=item C<sub>

Required.  This argument is the name of the sub (B<not> a reference to it.  If
just the sub name is provided, the calling package is assumed to be the correct
one.  Otherwise, a fully-qualified sub name may be used.

This will use the calling package.

  wrap(
    sub   => 'process_report',
    names => [qw/ report summary totals /]
  );

This will use C<Some::Package::>.

  wrap(
    sub   => 'Some::Package::process_report',
    names => [qw/ report summary totals /]
  );

=item C<names>

Required.  This should be an array ref with the names of the arguments in the
order in which they are supplied to the sub.  See examples for C<sub>.

=item C<target>

Optional.  If you're working on a collaborative project, Billy Joe Jim Bob is
going to rightfully get medieval on your po' self when all of his subroutine
calls start failing with mysterious error messages.  To get around this, you
can specify a C<target> parameter.  This will leave the original subroutine
unchanged and create a "new" subroutine exactly like the old one, but requiring
the named parameters that you specify.  This is B<strongly> recommended if you
will be working with others. 

=item C<hashref>

Optional.  If you would rather supply a list instead of a hashref, set this to
false.  The default is true.

=item C<default>

Optional.  This is a hashref with default values for any argument that you
don't supply when you call the subroutine.

=back

=head2 Example

  use Data::Dumper;
  use Sub::NamedParams qw/wrap/;
  wrap(
    sub      => foo,
    names    => [qw/ first second third /],
    hashref  => 1,
    default  => {
      second => 'deux'
    }
  );

  foo( {first => 1, third => 3} );

  sub foo {
    print Dumper \@_;
  }

Another example:

 use Sub::NamedParams qw/wrap/;
 
 sub foo { $_[0] + 1 }

 wrap(
  sub    => 'foo',
  names  => [qw/arg/],
  target => 'bar'
 );

 # the following two are identical:
 print foo( 3 );
 print bar( {arg => 3} );

=head2 EXPORT

None by default.  Adding C<wrap> to the import list will import it.

=head1 CAVEATS

Once wrapped, you may not "rewrap" a sub.  Attempting to do so will throw an 
exception.  Further, the C<target> parameter may not specify a wrapped or
pre-existing subroutine.

This module works on functions, B<not> object methods.  It should be relatively
easy to add this, but I have generally found object interfaces to be cleaner,
so I felt there was less of a need for this.

Hash keys passed in that were not listed in the original 'names' list will be
silently discarded.

=head1 BUGS

2002-04-29 Fixed bug with global value sometimes being overwritten in calling
or target namespace.  Thanks to chromatic for pointing that out.

=head1 AUTHOR

Copyright 2002, Curtis "Ovid" Poe E<lt>poec@yahoo.comE<gt>.  All rights
reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut



