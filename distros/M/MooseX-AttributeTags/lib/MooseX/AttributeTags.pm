use 5.008;
use strict;
use warnings;

package MooseX::AttributeTags;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Carp;
use Data::OptList qw(mkopt);
use Scalar::Util qw(blessed);

my $subname = eval { require Sub::Name; 'Sub::Name'->can('subname') }
	|| do { require Sub::Util; 'Sub::Util'->can('set_subname') };

my $yah = 1; # avoid exported subs becoming constants

sub import
{
	my $caller = caller;
	my $class  = shift;
	my $opts   = mkopt(\@_);
	my $prole  = $class->_prole;
	
	for (@$opts)
	{
		my ($traitname, $traitdesc) = @$_;
		$traitdesc ||= [];
		ref($traitdesc) eq 'ARRAY'
			or croak("Expected arrayref, not $traitdesc; stopped");
		
		my %attrs;
		my $inner_opts = mkopt($traitdesc);
		for (@$inner_opts)
		{
			my ($attrname, $attrdesc) = @$_;
			$attrs{$attrname} = $class->_canonicalize_attribute_spec($attrdesc);
		}
		
		my $traitqname = sprintf('%s::%s', $caller, $traitname);
		my $trait = $prole->generate_role(
			package    => $traitqname,
			parameters => { attributes => \%attrs },
		);
		
		my $coderef = $subname->($traitqname, sub () { $traitqname if $yah });
		no strict 'refs';
		*$traitqname = $coderef;
	}
}

sub _prole
{
	require MooseX::AttributeTags::PRole;
	Class::MOP::class_of('MooseX::AttributeTags::PRole');
}

sub _canonicalize_attribute_spec
{
	shift;
	my $spec = $_[0];
	
	return [ is => 'ro' ]
		unless defined $spec;
	
	return $spec
		if ref $spec eq 'ARRAY';
	
	return [ %$spec ]
		if ref $spec eq 'HASH';
	
	return [ is => 'ro', lazy => 1, default => $spec ]
		if ref $spec eq 'CODE';
	
	return [ is => 'ro', isa => $spec ]
		if blessed($spec) && $spec->isa('Moose::Meta::TypeConstraint');
	
	croak("Expected coderef/arrayref/hashref/constraint, not $spec; stopped");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::AttributeTags - tag your Moose attributes

=head1 SYNOPSIS

   package User;
   
   use Moose;
   use MooseX::Types::Moose 'Bool';
   use MooseX::AttributeTags (
      SerializationStyle => [
         hidden => Bool,
      ],
   );
   
   has username => (
      traits => [ SerializationStyle ],
      is     => 'ro',
      hidden => 0,
   );
   
   has password => (
      traits => [ SerializationStyle ],
      is     => 'rw',
      hidden => 1,
   );

=head1 DESCRIPTION

MooseX::AttributeTags is a factory for attribute traits. All the work is
done in the import method.

=head2 Methods

=over

=item C<< import(@optlist) >>

The option list is a list of trait names to create (which will be exported
to the caller package as constants).

Each trait name may be optionally followed by an arrayref of attributes to
be created within the trait. (In the SYNOPSIS, the "SerializationStyle" trait
gets an attribute called "hidden".)

Each attribute may be optionally followed by I<one> of:

=over

=item *

A coderef which provides a default value for the attribute.

=item *

A type constraint object (such as those provided by Types::Standard or
MooseX::Types; not a type constraint string) to validate the attribute.

=item *

An arrayref or hashref providing options similar to those given to
Moose's C<has> keyword.

=back

=back

Note that in the SYNOPSIS example, a constant C<< User::SerializationStyle >>
is defined.

   my $attr = User->meta->get_attribute('username');
   $attr->does(User::SerializationStyle);    # true
   $attr->hidden;                            # false

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-AttributeTags>.

=head1 SEE ALSO

L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2017, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

