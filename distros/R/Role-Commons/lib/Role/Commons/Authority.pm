use 5.008;
use strict;
use warnings;

package Role::Commons::Authority;

use Carp qw[croak];
use match::simple qw[match];
use Scalar::Util qw[blessed];

BEGIN {
	use Moo::Role;
	$Role::Commons::Authority::AUTHORITY = 'cpan:TOBYINK';
	$Role::Commons::Authority::VERSION   = '0.104';
}

our %ENABLE_SHARED;
our %SHARED_AUTHORITIES;

our $setup_for_class = sub {
	my ($role, $package, %args) = @_;
	
	if ( exists $args{-authorities} )
	{
		$ENABLE_SHARED{ $package } = 1;
		
		ref($args{-authorities}) eq 'ARRAY' and
			$SHARED_AUTHORITIES{ $package } = $args{-authorities};
	}
};

sub AUTHORITY
{
	my ($invocant, $test) = @_;
	$invocant = ref $invocant if blessed($invocant);
	
	my @authorities = do {
		no strict 'refs';
		my @a = ${"$invocant\::AUTHORITY"};
		if (exists $ENABLE_SHARED{ $invocant })
		{
			push @a, @{$SHARED_AUTHORITIES{$invocant} || []};
			push @a, @{"$invocant\::AUTHORITIES"};
		}
		@a;
	};
	
	if (scalar @_ > 1)
	{
		my $ok = undef;
		AUTH: for my $A (@authorities)
		{
			if (match($A, $test))
			{
				$ok = $A;
				last AUTH;
			}
		}
		return $ok if defined $ok;
		
		@authorities
			? croak("Invocant ($invocant) has authority '$authorities[0]'")
			: croak("Invocant ($invocant) has no authority defined");
	}
	
	wantarray ? @authorities : $authorities[0];
}

1;

__END__

=head1 NAME

Role::Commons::Authority - a class method indicating who published the package

=head1 SYNOPSIS

   package MyApp;
   use Role::Commons -all;
   BEGIN { our $AUTHORITY = 'cpan:JOEBLOGGS' };
   
   say MyApp->AUTHORITY;   # says "cpan:JOEBLOGGS"
   
   MyApp->AUTHORITY("cpan:JOEBLOGGS");     # does nothing much
   MyApp->AUTHORITY("cpan:JOHNTCITIZEN");  # croaks

=head1 DESCRIPTION

This module adds an C<AUTHORITY> function to your package, which works along
the same lines as the C<VERSION> function.

The authority of a package can be defined like this:

   package MyApp;
   BEGIN { our $AUTHORITY = 'cpan:JOEBLOGGS' };

The authority should be a URI identifying the person, team, organisation or
trained chimp responsible for the release of the package. The pseudo-URI
scheme "cpan:" is the most commonly used identifier.

=head2 Method

=over

=item C<< AUTHORITY >>

Called with no parameters returns the authority of the module.

=item C<< AUTHORITY($test) >>

If passed a test, will croak if the test fails. The authority is tested
against the test using something approximating Perl 5.10's smart match
operator. (Briefly, you can pass a string for eq comparison, a regular
expression, a code reference to use as a callback, or an array reference
that will be grepped.)

=back

=head2 Multiple Authorities

This module allows you to indicate that your module is issued by multiple
authorities. The package variable C<< $AUTHORITY >> should still be used
to indicate the primary authority for the package.

   package MyApp;
   use Role::Commons
      Authority => { -authorities => [qw( cpan:ALICE cpan:BOB )] };
   BEGIN { $MyApp::AUTHORITY = 'cpan:JOE'; }
    
   package main;
   use feature qw(say);
   say scalar MyApp->AUTHORITY;     # says "cpan:JOE"
   MyApp->AUTHORITY('cpan:JOE');    # lives
   MyApp->AUTHORITY('cpan:ALICE');  # lives
   MyApp->AUTHORITY('cpan:BOB');    # lives
   MyApp->AUTHORITY('cpan:CAROL');  # croaks

The main use case for shared authorities is for team projects. The team would
designate a URI to represent the team as a whole. For example, 
C<< http://datetime.perl.org/ >>, C<< http://moose.iinteractive.com/ >> or
C<< http://www.perlrdf.org/ >>. Releases can then be officially stamped with
the authority of the team.

And users can check they have an module released by the official team using:

   RDF::TakeOverTheWorld->AUTHORITY(
      q<http://www.perlrdf.org/>,
   );

which will croak if package RDF::TakeOverTheWorld doesn't have the specified
authority.

=head1 BUGS

An obvious limitation is that this module relies on honesty. Don't release
modules under authorities you have no authority to use.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Role-Commons>.

=head1 SEE ALSO

L<Role::Commons>,
L<authority>.

Background reading:
L<http://feather.perl6.nl/syn/S11.html>,
L<http://www.perlmonks.org/?node_id=694377>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

