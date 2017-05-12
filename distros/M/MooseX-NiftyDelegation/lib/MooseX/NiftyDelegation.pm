use 5.008;
use strict;
use warnings;
use utf8;

{
	package MooseX::NiftyDelegation;
	no thanks;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use constant {
		Nifty => 'MooseX::NiftyDelegation::Trait::Attribute',
	};
	use Sub::Exporter -setup => {
		exports  => [qw/ Nifty value_is value_like /],
		groups   => { default => [qw/ Nifty /] },
	};
	use Scalar::Util qw( looks_like_number );
	sub value_is ($) {
		my $test = shift;
		looks_like_number($test)
			? sub { $_ == $test }
			: sub { $_ eq $test };
	}
	sub value_like ($) {
		my $test = shift;
		sub { $_ =~ $test };
	}
}

{
	package MooseX::NiftyDelegation::Trait::Attribute;
	no thanks;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use Moose::Role;
	around _canonicalize_handles => sub {
		my $orig = shift;
		my $self = shift;
		my %hash = $self->$orig(@_);
		my $attr;
		for my $k (keys %hash) {
			next unless ref(my $body = $hash{$k});
			$attr ||= ($self->get_read_method || $self->get_read_method_ref);
			$hash{$k} = sub {
				local $_ = $_[0]->$attr;
				$body->(@_);
			};
		};
		return %hash;
	};
}

1;
__END__

=head1 NAME

MooseX::NiftyDelegation - extra sugar for method delegation

=head1 SYNOPSIS

   use 5.014;
   use strict;
   use warnings;
   
   package My::Process {
      use Moose;
      use MooseX::NiftyDelegation -all;
      
      has status => (
         is       => 'rw',
         isa      => 'Str',
         traits   => [ Nifty ],
         required => 1,
         handles  => {
            is_in_progress  => value_is 'in progress',
            is_failed       => value_is 'failed',
            is_complete     => value_like qr/^complete/,
            completion_date => sub { /^completed (.+)$/ and $1 },
         },
      );
   }
   
   package main {
      use Test::More;
      
      my $process = My::Process->new(
         status  => 'completed 2012-11-19',
      );
      
      ok( not $process->is_in_progress );
      ok( not $process->is_failed );
      ok(     $process->is_complete );
      
      is( $process->completion_date, '2012-11-19' );
      
      done_testing;
   }

=head1 DESCRIPTION

Moose has an undocumented feature whereby you can delegate methods to
coderefs like this:

   has status => (
      is       => 'rw',
      isa      => 'Str',
      handles  => {
         is_in_progress  => sub {
            my $self = shift;
            $self->status eq 'in progress';
         },
      },
   );

Kinda ugly though. The C<MooseX::NiftyDelegation::Trait::Attribute> trait
pretties it up a little by automatically wrapping the coderef with a little
gubbin that sets C<< $_ >> to C<< $self->$attribute >>. Thus:

   has status => (
      is       => 'rw',
      isa      => 'Str',
      traits   => ['MooseX::NiftyDelegation::Trait::Attribute'],
      handles  => {
         is_in_progress  => sub { $_ eq 'in progress' },
      },
   );

A little prettier. The rest of C<MooseX::NiftyDelegation> gives you some
handy functions to make these coderefs a cuter still...

=over

=item C<< Nifty >>

This is a constant which returns the string
C<< 'MooseX::NiftyDelegation::Trait::Attribute' >> so you don't have to
type that out every time. It is exported by default.

=item C<< value_is $number >>

Returns a coderef that evaluates C<< $_ >> for numeric equality with the
given number. This function is not exported by default.

=item C<< value_is $string >>

Returns a coderef that evaluates C<< $_ >> for string equality with the
given string. This function is not exported by default.

=item C<< value_like $regexp >>

Returns a coderef that evaluates C<< $_ >> for matching the given
regular expression. This function is not exported by default.

=back

Now, why would you want to stuff these "delegted" methods into attributes?
Why not just write them as regular methods?

   sub is_in_progress {
      my $self = shift;
      $self->status eq 'in progress';
   }

A good question. Writing methods which are closely associated with a
single attribute as delegated methods just seems to me to be a nice
way of grouping related methods. You can even use it for builders:

   has user_agent => (
      is         => 'ro',
      isa        => 'Object',
      lazy_build => 1,
      handles    => {
         get               => 'get',
         _build_user_agent => sub { LWP::UserAgent->new },
      },
   );

=head1 EXPORT

This module uses L<Sub::Exporter> so it's possible to rename exported
functions:

   use MooseX::NiftyDelegation
      Nifty       => {},
      value_is    => { -as => 'value_is_exactly' },
      value_like  => { -as => 'value_matches' },
   ;

See L<Sub::Exporter> for further details.

=head1 CAVEATS

=over

=item *

Using a coderef in the delegation hashref is not documented, it's not
tested for, and Jesse Luehrs says he doesn't like it. So the feature
could get removed at any point.

In that case, I'll need to update this module with a bunch of extra
metahackery. I'm 95% sure it would still be doable - just a lot more
code.

=item *

This module doesn't work in conjunction with attribute native traits.
This is native traits insists that the delegated method is either a
string or arrayref.

Patches to get this working with native traits are welcome.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-NiftyDelegation>.

=head1 SEE ALSO

L<Moose::Manual::Delegation>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

