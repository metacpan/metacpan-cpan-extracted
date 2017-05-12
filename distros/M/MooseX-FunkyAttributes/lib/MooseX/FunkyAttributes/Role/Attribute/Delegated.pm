package MooseX::FunkyAttributes::Role::Attribute::Delegated;

use 5.008;
use strict;
use warnings;

BEGIN {
	$MooseX::FunkyAttributes::Role::Attribute::Delegated::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::FunkyAttributes::Role::Attribute::Delegated::VERSION   = '0.003';
}

use Moose::Role;
use namespace::autoclean;

with qw(MooseX::FunkyAttributes::Role::Attribute);

has delegated_to        => (is => 'ro', isa => 'Str', required => 1);
has delegated_accessor  => (is => 'ro', isa => 'Str');
has delegated_predicate => (is => 'ro', isa => 'Str');
has delegated_clearer   => (is => 'ro', isa => 'Str');

before _process_options => sub
{
	my ($class, $name, $options) = @_;
	
	my $to = $options->{delegated_to}
		or confess "Required option 'delegated_to' missing";
	
	# Meh... we should use Moose's introspection to get the name of accessors, clearers, etc.
	# ... actually we can't do that. We don't know at attribute creation time, what sort of
	# object $self->$to will be!!
	#
	
	$options->{custom_weaken}        ||= sub { 0   };  # :-(
	$options->{custom_inline_weaken} ||= sub { q() };  # :-(
	
	$options->{delegated_accessor} = (
		my $accessor  = exists $options->{delegated_accessor} ? $options->{delegated_accessor} : $name
	);
	my $private   = !!($accessor =~ /^_/);
		
	if ($accessor and not exists $options->{custom_get})
	{
		$options->{custom_get} = sub { $_[1]->$to->$accessor };
		$options->{custom_inline_get} ||= sub {
			my ($self, $inst, $val) = @_;
			qq( $inst->$to->$accessor() )
		};
	}
	
	if ($accessor and not exists $options->{custom_set})
	{
		$options->{custom_set} = sub { $_[1]->$to->$accessor($_[2]) };
		$options->{custom_inline_set} ||= sub {
			my ($self, $inst, $val) = @_;
			qq( $inst->$to->$accessor($val) )
		};
	}
	
	$options->{delegated_predicate} = (
		my $predicate = exists $options->{delegated_predicate} ? $options->{delegated_predicate} : ($private ? "_has$accessor"   : "has_$accessor")
	);
	
	if ($predicate and not exists $options->{custom_has})
	{
		$options->{custom_has} = sub { $_[1]->$to->$predicate };
		$options->{custom_inline_has} ||= sub {
			my ($self, $inst) = @_;
			qq( $inst->$to->$predicate() )
		};
	}
	
	$options->{delegated_clearer} = (
		my $clearer   = exists $options->{delegated_clearer}   ? $options->{delegated_clearer}   : ($private ? "_clear$accessor" : "clear_$accessor")
	);
	
	if ($clearer and not exists $options->{custom_clear})
	{
		$options->{custom_clear} = sub { $_[1]->$to->$clearer };
		$options->{custom_inline_clear} ||= sub {
			my ($self, $inst) = @_;
			qq( $inst->$to->$clearer() )
		};
	}
	
	delete $options->{$_} for
		grep { not defined $options->{$_} }
		grep { /^delegated_/ }
		keys %$options;
};

1;


__END__

=head1 NAME

MooseX::FunkyAttributes::Role::Attribute::Delegated - delegate an attribute to another object

=head1 SYNOPSIS

   package Head;
   
   use Moose;
   
   has mouth => (
      is           => 'ro',
      isa          => 'Mouth',
   );
   
   package Person;
   
   use Moose;
   use MooseX::FunkyAttributes;
   
   has head => (
      is           => 'ro',
      isa          => 'Head',
   );
   
   has mouth => (
      is           => 'ro',
      isa          => 'Mouth::Human',
      traits       => [ DelegatedAttribute ],
      delegated_to => 'head',
   );

=head1 DESCRIPTION

This trait delegates the storage of one attribute's value to the object stored
in another attribute. The example in the SYNOPSIS might have been written using
Moose's native delegation as:

   package Head;
   
   use Moose;
   
   has mouth => (
      is           => 'ro',
      isa          => 'Mouth',
   );
   
   package Person;
   
   use Moose;
   
   has head => (
      is           => 'ro',
      isa          => 'Head',
      handles      => [qw( mouth )],
   );

However, there are some differences. Using native delegation, C<mouth>
will be treated as a method using Moose's introspection API
(C<< Person->meta->get_all_methods >>) and not as an attribute
(C<< Person->meta->get_all_attributes >>). Using this API, C<mouth> is
a proper attribute of C<Person>; it just relies on the C<Head> object for
storage.

Because C<mouth> is a proper attribute of C<Person>, it can perform
delegations of its own; can have its own type constraints, etc.

   has mouth => (
      is           => 'ro',
      isa          => 'Mouth::Human',
      traits       => [ DelegatedAttribute ],
      delegated_to => 'head',
      handles      => [qw/ speak kiss vomit eat /], # but not necessarily
   );                                               # in that order

=head2 Options

=over

=item C<< delegated_to => STR >>

The name of the other attribute to delegate this attribute to. This is the
only required option.

=item C<< delegated_accessor => STR >>

This option may be used if you wish to rename the delegated attribute. For
example:

   package Person;
   
   has pie_hole => (
      is           => 'ro',
      isa          => 'Mouth::Human',
      traits       => [ DelegatedAttribute ],
      delegated_to => 'head',
      delegated_accessor => 'mouth',
   );

Now C<< $person->pie_hole >> is equivalent to C<< $person->head->mouth >>.

If omitted, then it is assumed that the attribute has the same name in both
classes. If explicitly set to C<undef>, then this assumption is not made, and
the accessor is unknown. If the accessor is unknown, then this trait gets
somewhat stuck, so you'd need to provide C<custom_get> and C<custom_set>
options (see L<MooseX::FunkyAttributes::Role::Attribute>).

=item C<< delegated_predicate => STR >>

Like C<delegated_accessor>, but for the attribute's predicate. If omitted,
assumes the convention of C<< has_$accessor >>. An explicit undef can
avoid this assumption, but then you'll need to provide C<custom_has>.

=item C<< delegated_clearer => STR >>

Like C<delegated_accessor>, but for the attribute's clearer. If omitted,
assumes the convention of C<< clear_$accessor >>. An explicit undef can
avoid this assumption, but then you'll need to provide C<custom_has> if
you want to define a clearer.

=back

All the C<custom_blah> and C<custom_inline_blah> options from
L<MooseX::FunkyAttributes::Role::Attribute> are also available. The
C<delegated_blah> options above are essentially just shortcuts
for defining them.

Your attribute metaobject has the following methods (in addition to the
standard L<MooseX::FunkyAttributes::Role::Attribute> and
L<Moose::Meta::Attribute> stuff):

=over

=item C<delegated_to>

=item C<delegated_accessor>

=item C<delegated_clearer>

=item C<delegated_predicate>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-FunkyAttributes>.

=head1 SEE ALSO

L<MooseX::FunkyAttributes>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

