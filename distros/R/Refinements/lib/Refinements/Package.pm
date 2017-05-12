use 5.010;
use strict;
use warnings;

{
	package Refinements::Package;
	
	use Exporter::Tiny ();
	use Method::Lexical ();
	use Module::Runtime qw( use_package_optimistically );
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	our @ISA       = qw( Method::Lexical );
	
	sub add_refinement
	{
		my $class = shift;
		my ($fqname, $coderef) = @_;
		
		my ($package, $subname) = ($fqname =~ /^(.+)::(\w+)$/)
			or Exporter::Tiny::_croak('Could not split "%s" as a fully qualified sub name', $fqname);
		
		$Refinements::REFINEMENTS{$class}{$fqname} = $coderef;
	}
	
	sub get_refinement
	{
		my $class = shift;
		my ($fqname) = @_;
		$Refinements::REFINEMENTS{$class}{$fqname};
	}
	
	sub has_refinement
	{
		my $class = shift;
		my ($fqname) = @_;
		exists($Refinements::REFINEMENTS{$class}{$fqname});
	}
	
	sub get_refinement_names
	{
		my $class = shift;
		keys %{ $Refinements::REFINEMENTS{$class} };
	}
	
	my $wrap = sub
	{
		my $class = shift;
		my ($fqname, $coderef) = @_;
		my ($package, $subname) = ($fqname =~ /^(.+)::(\w+)$/);
		use_package_optimistically($package);
		my $orig = $package->can($subname);
		
		return sub
		{
			my $curr = $_[0]->can($subname);
			if ($curr == $orig)
			{
				unshift @_, $orig;
				goto $coderef;
			}
			goto $curr;
		};
	};
	
	sub import
	{
		my $class = shift;
		
		my @refinements = map {
			my $name = $_;
			my $code = $class->$wrap( $name, $class->get_refinement($name) );
			$name => $code;
		} $class->get_refinement_names;
		
		$class->SUPER::import(@refinements);
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Refinements::Package - a package of refinements

=head1 DESCRIPTION

B<Refinements> will make your package inherit from this package.
This package itself is a subclass of L<Method::Lexical>.

=head2 Methods

The following class methods are defined:

=over

=item C<< add_refinement($fqname, $coderef) >>

Adds a refinement to your package.

C<< $fqname >> should be a fully-qualified sub name; the method which
you wish to override; such as C<< "LWP::UserAgent::request" >> or
C<< "UNIVERSAL::DOES" >>.

C<< $coderef >> is the new implementation for the method. Note that,
like L<Moose> C<around> method modifiers, it gets passed a coderef for
the I<original> method as its first argument. Unlike L<Moose>, this may
sometimes be C<undef> (if your refinement is defining a new method
which does not already exist).

=item C<< has_refinement($fqname) >>

Returns a boolean indicating whether the package has a refinement.

=item C<< get_refinement($fqname) >>

Returns the refinement coderef for the name.

=item C<< get_refinement_names() >>

Returns the fully-qualified names of all refinements in the package,
in no particular order.

=item C<< import() >>

The glue for L<Method::Lexical>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Refinements>.

=head1 SEE ALSO

L<Refinements>, L<Method::Lexical>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
