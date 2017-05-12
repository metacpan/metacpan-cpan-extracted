use 5.008;
use strict;
use warnings;

BEGIN { if ($] < 5.010000) { require UNIVERSAL::DOES } };

package MooX::ObjectBuilder;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use B::Hooks::EndOfScope;
use Exporter::Shiny our(@EXPORT) = qw(make_builder);
use Lexical::Accessor;
use MooseX::ConstructInstance -with;
use Sub::Name qw(subname);

sub _generate_make_builder
{
	my $me = shift;
	my ($name, $args, $globals) = @_;
	
	lexical_has(accessor => \(my $storage));
	my @need_to_store;
	
	my $caller = $globals->{into};
	# around BUILD
	on_scope_end {
		no strict 'refs';
		my $next = exists(&{"$caller\::BUILD"}) ? \&{"$caller\::BUILD"} : undef;
		*{"$caller\::BUILD"} = sub {
			my $self = shift;
			my ($params) = @_;
			$self->$storage({ map exists($params->{$_})?($_=>$params->{$_}):(), @need_to_store });
			$self->$next(@_) if $next;
		};
		subname("$caller\::BUILD", \&{"$caller\::BUILD"});
	};
	
	return sub { # make_builder
		my $klass = shift;
		my %attrs =
			@_==1 && ref($_[0]) eq 'HASH'  ? %{$_[0]} :
			@_==1 && ref($_[0]) eq 'ARRAY' ? map(+($_=>$_), @{$_[0]}) :
			@_;
		push @need_to_store, keys(%attrs);
		my $code = sub {
			my $self    = shift;
			my $storage = $self->$storage;
			my %args    = map exists($storage->{$_})?($attrs{$_}=>$storage->{$_}):(), keys(%attrs);
			my $bless   = exists($args{'__CLASS__'}) ? delete($args{'__CLASS__'}) : $klass;
			
			$self->DOES('MooseX::ConstructInstance')
				? $self->construct_instance($bless, \%args)
				: MooX::ObjectBuilder->construct_instance($bless, \%args);
		};
		wantarray ? ('lazy', builder => $code) : $code;
	}
}

1;

__END__

=pod

=encoding utf-8

=for stopwords Torbjørn

=head1 NAME

MooX::ObjectBuilder - lazy construction of objects from extra init args

=head1 SYNOPSIS

   package Person {
      use Moo;
      
      has name  => (is => "ro");
      has title => (is => "ro");
   }
   
   package Organization {
      use Moo;
      use MooX::ObjectBuilder;
      
      has name => (is => "ro");
      has boss => (
         is => make_builder(
            "Person" => (
               boss_name   => "name",
               boss_title  => "title",
            ),
         ),
      );
   }
   
   my $org = Organization->new(
      name       => "Catholic Church",
      boss_name  => "Francis",
      boss_title => "Pope",
   );
   
   use Data::Dumper;
   print Dumper( $org->boss );

=head1 DESCRIPTION

This module exports a function C<make_builder> which can be used to
generate lazy builders suitable for L<Moo> attributes. The import
procedure also performs some setup operations on the caller class
necessary for C<make_builder> to work correctly.

=head2 Functions

=over

=item C<< make_builder( $class|$coderef, \%args|\@args|%args ) >>

The C<make_builder> function conceptually takes two arguments, though
the second one (which is normally a hashref or arrayref) may be passed
as a flattened hash.

The C<< %args >> hash is a mapping of argument names where keys are
names in the "aggregating" or "container" class (i.e. "Organization"
in the L</SYNOPSIS>) and values are names in the "aggregated" or
"contained" class (i.e. "Person" in the L</SYNOPSIS>).

If C<< \@args >> is provided instead, this is expanded into a hash as
follows:

   my %args = map { $_ => $_ } @args;

The builder returned by this function will accept arguments from the
aggregating class and map them into arguments for the aggregated class.
The builder will then construct an instance of C<< $class >> passing
it a hashref of arguments. If C<< $coderef >> has been provided instead
of a class name, this will be called with the hashref of arguments
instead.

The C<make_builder> function behaves differently in scalar and list
context. In list context, it returns a three item list. The first two
items are the strings C<< "lazy" >> and C<< "builder" >>; the third
item is the builder coderef described above. In scalar context, only
the coderef is returned. Thus the following two examples work
equivalently:

   # Scalar context
   my $builder = make_builder($class, {...});
   has attr => (
      is      => "lazy",
      builder => $builder,
   );

   # List context
   has attr => (
      is => make_builder($class, {...}),
   );

=back

=head2 Class Setup

On import, this module installs a sub called C<BUILD> into your class.
If your class already has a sub with this name, it will be wrapped.

The point of this sub is to capture argument passed to the aggregating
class' constructor, to enable them to be later forwarded to the
aggregated class.

See also: L<Moo/"BUILD">.

=head2 Using MooX::ObjectBuilder with Moose and Mouse

It is possible to use C<make_builder> in scalar context with L<Moose>
and L<Mouse> classes:

   has attr => (
      is      => "ro",
      lazy    => 1,
      default => scalar make_builder($class, {...}),
   );

=head2 MooseX::ConstructInstance

If your object does the L<MooseX::ConstructInstance> role, then this
module will automatically do the right thing and delegate to that for
the actual object construction.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-ObjectBuilder>.

=head1 SEE ALSO

L<Moo>, L<Moose>, L<Mouse>.

L<MooseX::ConstructInstance>.

L<MooX::LazyRequire>,
L<MooseX::LazyRequire>,
L<MooseX::LazyCoercion>,
etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 CREDITS

Most of the test suite was written by Torbjørn Lindahl (cpan:TORBJORN).

Various advice was given by Graham Knop (cpan:HAARG) and Matt S Trout
(cpan:MSTROUT).

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
