use 5.008;
use strict;
use warnings;

package Sub::HandlesVia;

use Exporter::Shiny qw( delegations );

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.044';

sub _generate_delegations {
	my ($me, $name, $args, $globals) = (shift, @_);
	
	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;

	my $toolkit = $me->detect_toolkit($target);
	return sub { $toolkit->install_delegations(target => $target, @_) };
}

sub _exporter_validate_opts {
	my ($me, $globals) = (shift, @_);

	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;

	my $toolkit = $me->detect_toolkit($target);
	$toolkit->setup_for($target) if $toolkit->can('setup_for');
}

sub detect_toolkit {
	my $toolkit = sprintf(
		'%s::Toolkit::%s',
		__PACKAGE__,
		shift->_detect_framework(@_),
	);
	eval "require $toolkit" or Exporter::Tiny::_croak($@);
	return $toolkit;
}

sub _detect_framework {
	my ($me, $target) = (shift, @_);
	
	# Need to ask Role::Tiny too because Moo::Role will pretend
	# that Moose::Role and Mouse::Role roles are Moo::Role roles!
	#
	if ($INC{'Moo/Role.pm'}
	and Role::Tiny->is_role($target)
	and Moo::Role->is_role($target)) {
		return 'Moo';
	}
	
	if ($INC{'Moo.pm'}
	and $Moo::MAKERS{$target}
	and $Moo::MAKERS{$target}{is_class}) {
		return 'Moo';
	}
	
	if ($INC{'Moose/Role.pm'}
	and $target->can('meta')
	and $target->meta->isa('Moose::Meta::Role')) {
		return 'Moose';
	}
	
	if ($INC{'Moose.pm'}
	and $target->can('meta')
	and $target->meta->isa('Moose::Meta::Class')) {
		return 'Moose';
	}

	if ($INC{'Mouse/Role.pm'}
	and $target->can('meta')
	and $target->meta->isa('Mouse::Meta::Role')) {
		return 'Mouse';
	}
	
	if ($INC{'Mouse.pm'}
	and $target->can('meta')
	and $target->meta->isa('Mouse::Meta::Class')) {
		return 'Mouse';
	}
	
	{
		no warnings;
		if ($INC{'Object/Pad.pm'}
		and 'Object::Pad'->VERSION ge 0.67
		and do { require Object::Pad::MOP::Class; 1 }
		and eval { Object::Pad::MOP::Class->for_class($target) } ) {
			require Scalar::Util;
			my $META = Object::Pad::MOP::Class->for_class($target);
			return 'ObjectPad'
				if Scalar::Util::blessed($META) && $META->isa('Object::Pad::MOP::Class');
		}
	}
	
	{
		no strict 'refs';
		no warnings 'once';
		if ( ${"$target\::USES_MITE"} ) {
			return 'Mite';
		}
	}
	
	return 'Plain';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia - alternative handles_via implementation

=head1 SYNOPSIS

 package Kitchen {
   use Moo;
   use Sub::HandlesVia;
   use Types::Standard qw( ArrayRef Str );
   
   has food => (
     is          => 'ro',
     isa         => ArrayRef[Str],
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

 my $kitchen = Kitchen->new;
 $kitchen->add_food('Bacon');
 $kitchen->add_food('Eggs');
 $kitchen->add_food('Sausages');
 $kitchen->add_food('Beans');
 
 my @foods = $kitchen->find_food(sub { /^B/i });

=head1 DESCRIPTION

If you've used L<Moose>'s native attribute traits, or L<MooX::HandlesVia>
before, you should have a fairly good idea what this does.

Why re-invent the wheel? Well, this is an implementation that should work
okay with Moo, Moose, Mouse, and any other OO toolkit you throw at it.
One ring to rule them all, so to speak.

For details of how to use it, see the manual.

=over

=item L<Sub::HandlesVia::Manual::WithMoo>

How to use Sub::HandlesVia with L<Moo> and L<Moo::Role>.

=item L<Sub::HandlesVia::Manual::WithMoose>

How to use Sub::HandlesVia with L<Moose> and L<Moose::Role>.

=item L<Sub::HandlesVia::Manual::WithMouse>

How to use Sub::HandlesVia with L<Mouse> and L<Mouse::Role>.

=item L<Sub::HandlesVia::Manual::WithMite>

How to use Sub::HandlesVia with L<Mite>.

=item L<Sub::HandlesVia::Manual::WithClassTiny>

How to use Sub::HandlesVia with L<Class::Tiny>.

=item L<Sub::HandlesVia::Manual::WithObjectPad>

How to use Sub::HandlesVia with L<Object::Pad> classes.

=item L<Sub::HandlesVia::Manual::WithGeneric>

How to use Sub::HandlesVia with other OO toolkits, and hand-written
Perl classes.

=back

Note: as Sub::HandlesVia needs to detect which toolkit you are using, and
often needs to detect whether your package is a class or a role, it needs
to be loaded I<after> Moo/Moose/Mouse/etc. Your C<< use Moo >> or
C<< use Moose::Role >> or whatever needs to be I<before> your
C<< use Sub::HandlesVia >>.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

(There are known bugs for Moose native types that do coercion.)

=head1 SEE ALSO

Guides for use with different OO toolkits:
L<Sub::HandlesVia::Manual::WithMoo>,
L<Sub::HandlesVia::Manual::WithMoose>,
L<Sub::HandlesVia::Manual::WithMouse>,
L<Sub::HandlesVia::Manual::WithMite>,
L<Sub::HandlesVia::Manual::WithClassTiny>,
L<Sub::HandlesVia::Manual::WithObjectPad>,
L<Sub::HandlesVia::Manual::WithGeneric>.

Documentation for delegatable methods:
L<Sub::HandlesVia::HandlerLibrary::Array>,
L<Sub::HandlesVia::HandlerLibrary::Blessed>,
L<Sub::HandlesVia::HandlerLibrary::Bool>,
L<Sub::HandlesVia::HandlerLibrary::Code>,
L<Sub::HandlesVia::HandlerLibrary::Counter>,
L<Sub::HandlesVia::HandlerLibrary::Hash>,
L<Sub::HandlesVia::HandlerLibrary::Number>,
L<Sub::HandlesVia::HandlerLibrary::Scalar>, and
L<Sub::HandlesVia::HandlerLibrary::String>.

Other implementations of the same concept:
L<Moose::Meta::Attribute::Native>, L<MouseX::NativeTraits>, and
L<MooX::HandlesVia> with L<Data::Perl>.

Comparison of those: L<Sub::HandlesVia::Manual::Comparison>

L<Sub::HandlesVia::Declare> is a helper for declaring Sub::HandlesVia
delegations at compile-time, useful for L<Object::Pad> and (to a lesser
extent) L<Class::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

