package Acme::MooseX::JSON;

use 5.008;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose 2.00 ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use Scalar::Accessors::LikeHash::JSON ();

my $ACCESSORS = "Scalar::Accessors::LikeHash::JSON";

BEGIN {
	package Acme::MooseX::JSON::Trait::Class;
	use Moose::Role;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.002';
};

BEGIN {
	package Acme::MooseX::JSON::Trait::Instance;
	use Moose::Role;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.002';
	
	override create_instance => sub {
		my $meta  = shift;
		my $class = $meta->associated_metaclass;
		my $str   = "{}";
		bless \$str, $class->name;
	};
	
	override clone_instance => sub {
		my ($meta, $instance) = @_;
		my $class = $meta->associated_metaclass;
		my $str   = $$instance;
		bless \$str, $class->name;
	};
	
	override get_slot_value => sub {
		my ($meta, $instance, $slot_name) = @_;
		return $ACCESSORS->fetch($instance, $slot_name);
	};
	
	override set_slot_value => sub {
		my ($meta, $instance, $slot_name, $value) = @_;
		return $ACCESSORS->store($instance, $slot_name, $value);
	};
	
	override initialize_slot => sub { 1 };
	
	override deinitialize_slot => sub {
		my ($meta, $instance, $slot_name) = @_;
		return $ACCESSORS->delete($instance, $slot_name);
	};
	
	override deinitialize_all_slots => sub {
		my ($meta, $instance) = @_;
		return $ACCESSORS->clear($instance);
	};
	
	override is_slot_initialized => sub {
		my ($meta, $instance, $slot_name) = @_;
		return $ACCESSORS->exists($instance, $slot_name);
	};
	
	override weaken_slot_value => sub {
		my ($meta, $instance, $slot_name) = @_;
		my $class = $meta->associated_metaclass;
		confess "$class is implemented using Acme::MooseX::JSON, so cannot store weakened references.";
	};
	
	override slot_value_is_weak => sub { 0 };
	
	override inline_create_instance => sub {
		my ($meta, $klass) = @_;
		qq{ bless \\(my \$json = '{}'), $klass }
	};
	
	override inline_slot_access => sub {
		my ($meta, $instance, $slot_name) = @_;
		qq{ '$ACCESSORS'->fetch($instance, '$slot_name') }
	};
	
	override inline_get_slot_value => sub {
		my ($meta, $instance, $slot_name) = @_;
		$meta->inline_slot_access($instance, $slot_name);
	};
	
	override inline_set_slot_value => sub {
		my ($meta, $instance, $slot_name, $value) = @_;
		qq{ '$ACCESSORS'->store($instance, '$slot_name', $value) }
	};
	
	override inline_deinitialize_slot => sub {
		my ($meta, $instance, $slot_name) = @_;
		qq{ '$ACCESSORS'->delete($instance, '$slot_name') }
	};
	
	override inline_is_slot_initialized => sub {
		my ($meta, $instance, $slot_name) = @_;
		qq{ '$ACCESSORS'->exists($instance, '$slot_name') }
	};
	
	override inline_weaken_slot_value => sub {
		my ($meta, $instance, $slot_name) = @_;
		my $class = $meta->associated_metaclass;
		confess "$class is implemented using Acme::MooseX::JSON, so cannot store weakened references.";
	};
};

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
			instance => [qw( Acme::MooseX::JSON::Trait::Instance )],
			class    => [qw( Acme::MooseX::JSON::Trait::Class )],
		},
	);
}

1;

__END__

=head1 NAME

Acme::MooseX::JSON - Moose objects that are internally blessed scalar refs containing JSON

=head1 SYNOPSIS

   {
      package Local::Person;
      use Acme::MooseX::JSON;
      has name => (is => 'rw', isa => 'Str');
   }
   
   my $object = Local::Person->new(name => "Bob");
   print $$object;  # JSON

=head1 DESCRIPTION

This L<Moose> extension is akin to L<MooseX::InsideOut>, L<MooseX::GlobRef>
and L<MooseX::ArrayRef> in that it allows you to create Moose classes where
the instances aren't blessed hashes.

However, unlike those fine modules, Acme::MooseX::JSON chooses just about
the most insane way of implementing an instance's internals possible: they're
serialized as a JSON string, which is then used as a blessed scalar reference.

The use of JSON to serialize the object's internals places fairly strong
restrictions on what kind of data can be held in the object's attributes.
Strings, numbers and undef are all OK; arrayrefs and hashrefs are OK
provided you don't create cyclical data structures, and provided they
don't contain any non-OK data as values.

This module requires L<JSON> 2.00+ and L<Moose> 2.00+ to be installed.

=begin private

=item init_meta

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Scalar-Accessors-LikeHash>.

=head1 SEE ALSO

L<Scalar::Accessors::LikeHash>, L<JSON>, L<Moose>.

L<MooseX::InsideOut>, L<MooseX::GlobRef>, L<MooseX::ArrayRef>.

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

