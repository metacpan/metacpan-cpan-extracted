use 5.010;
use strict;
use warnings;

{
	package Refinements;
	
	use Exporter::Tiny ();
	use Module::Runtime qw( module_notional_filename );
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	our @EXPORT    = qw( refine );
	our @ISA       = qw( Exporter::Tiny );
	
	sub _exporter_validate_opts
	{
		my $class = shift;
		my ($opt) = @_;
		
		defined($opt->{into}) && !ref($opt->{into})
			or Exporter::Tiny::_croak('Cannot set up %s as a Refinements::Package', $opt->{into});
		
		$INC{module_notional_filename($opt->{into})} ||= __FILE__;
		
		require Refinements::Package;
		no strict 'refs';
		push @{ $opt->{into} . '::ISA' }, 'Refinements::Package';
	}
	
	sub _generate_refine
	{
		my $class = shift;
		my ($name, $value, $opt) = @_;
		
		my $collection = $opt->{into};
		
		return sub {
			@_ >= 2
				or Exporter::Tiny::_croak('Expected at least 2 arguments to refine(); got %d', scalar @_);
			my $coderef = pop;
			$collection->add_refinement($_, $coderef) for map { ref($_) ? @$_ : $_ } @_;
		};
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Refinements - safer monkey-patching; Ruby-2.0-style refinements for Perl

=head1 SYNOPSIS

   BEGIN {
      package LwpDebugging;
      use Refinements;
      
      refine 'LWP::UserAgent::request' => sub
      {
         my $next = shift;  # like Moose's "around" modifier
         my $self = shift;
         
         warn sprintf 'REQUEST: %s %s', $_[0]->method, $_[0]->uri;
         
         return $self->$next(@_);
      };
   };
   
   {
      package MyApp;
      
      use LWP::UserAgent;
      
      my $ua  = LWP::UserAgent->new;
      my $req = HTTP::Request->new(GET => 'http://www.example.com/');
      
      {
         use LwpDebugging;
         
         my $res = $ua->request($req);   # issues debugging warning
         
         # $ua->get internally calls $ua->request
         my $res2 = $ua->get('http://www.example.org/');  # no warning
      }
      
      my $res = $ua->request($req);  # no warning
   }

=head1 DESCRIPTION

B<Refinements> allows you to define Ruby-2.0-style refinements.
Refinements are a lexically-scoped monkey-patch. In the SYNOPSIS
example, we're using a refinement that overrides L<LWP::UserAgent>'s
C<request> method. The refinement only gets applied in the small
block of code where C<< use LwpDebugging >> appears. Calling the
C<request> method from outside that block ignores the refinement.
Refinements are lexically-scoped rather than dynamically-scoped.

Refinements can be used to add or override aspects of a class'
behaviour, as an alternative to subclassing.

Credit where it's due: all the hard work is done by L<Method::Lexical>.
The Refinements module just provides an interface to Method::Lexical
that may be more comfortable to many users. Defining a refinement
becomes much like defining method modifiers in L<Moose> or L<Moo>.

In particular, the Refinements module does a two things:

=over

=item 1.

It makes your package inherit from L<Refinements::Package>; and

=item 2.

It exports a convenience function C<< refine >> to your package.

=back

=head2 Functions

The following function is exported:

=over

=item C<< refine(@names, $coderef) >>

This is roughly equivalent to:

   $your_package->add_refinement($_, $coderef) for @names;

See L<Refinements::Package/"Methods"> for further information on the
C<add_refinement> method.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Refinements>.

=head1 SEE ALSO

L<Refinements::Package>, L<Method::Lexical>.

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

