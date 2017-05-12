package MooseX::ArrayRef;

use 5.008;

BEGIN {
	$MooseX::ArrayRef::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ArrayRef::VERSION   = '0.005';
}

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::ArrayRef::Meta::Instance ();
use MooseX::ArrayRef::Meta::Class ();

Moose::Exporter->setup_import_methods(
	also => [qw( Moose )],
);

sub init_meta
{
	shift;
	my %p = @_;
	Moose->init_meta(%p);
	Moose::Util::MetaRole::apply_metaroles(
		for             => $p{for_class},
		class_metaroles => {
			instance => [qw( MooseX::ArrayRef::Meta::Instance )],
			class    => [qw( MooseX::ArrayRef::Meta::Class )],
		},
	);
}

[qw( Yeah baby yeah )]

__END__

=head1 NAME

MooseX::ArrayRef - blessed arrayrefs with Moose

=head1 SYNOPSIS

  {
    package Local::Person;
    use Moose;
    has name => (
      is    => 'ro',
      isa   => 'Str',
    );
    __PACKAGE__->meta->make_immutable;
  }
  
  {
    package Local::Marriage;
    use MooseX::ArrayRef;
    has husband => (
      is    => 'ro',
      isa   => 'Local::Person',
    );
    has wife => (
      is    => 'ro',
      isa   => 'Local::Person',
    );
    __PACKAGE__->meta->make_immutable;
  }
  
  my $marriage = Local::Marriage->new(
    wife      => Local::Person->new(name => 'Alex'),
    husband   => Local::Person->new(name => 'Sam'),
  );
  
  use Data::Dumper;
  use Scalar::Util qw(reftype);
  print reftype($marriage), "\n";   # 'ARRAY'
  print Dumper($marriage);


=head1 DESCRIPTION

Objects implemented with arrayrefs rather than hashrefs are often faster than
those implemented with hashrefs. Moose's default object implementation is
hashref based. Can we go faster?

Simply C<< use MooseX::ArrayRef >> instead of C<< use Moose >>, but note the
limitations in the section below.

The current implementation is mostly a proof of concept, but it does mostly
seem to work.

=begin private

=item init_meta

=end private

=head1 BUGS AND LIMITATIONS

=head2 Limitations on Speed

The accessors for mutable classes not significantly faster than Moose's
traditional hashref-based objects. For immutable classes, the speed up
is bigger

               Rate  HashRef_M ArrayRef_M  HashRef_I ArrayRef_I
  HashRef_M  1016/s         --        -1%       -48%       -55%
  ArrayRef_M 1031/s         1%         --       -47%       -54%
  HashRef_I  1953/s        92%        89%         --       -13%
  ArrayRef_I 2257/s       122%       119%        16%         --

=head2 Limitations on Mutability

Things will probably break if you try to modify classes, add roles, etc "on
the fly". Make your classes immutable before instantiating even a single
object.

=head2 Limitations on Inheritance

Inheritance isn't easy to implement with arrayrefs. The current implementation
suffers from the following limitations:

=over

=item * Single inheritance only.

You cannot extend multiple parent classes.

=item * Inherit from other MooseX::ArrayRef classes only.

A MooseX::ArrayRef class cannot extend a non-MooseX::ArrayRef class.
Even non-Moose classes which are implemented using arrayrefs. (Of
course, all Moose classes inherit from L<Moose::Object> too, which
is just fine.)

=back

Note that delegation (via Moose's C<handles>) is often a good alternative
to inheritance.

=head2 Issue Tracker

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ArrayRef>.

=head1 SEE ALSO

L<Moose>,
L<MooseX::GlobRef>,
L<MooseX::InsideOut>.

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

