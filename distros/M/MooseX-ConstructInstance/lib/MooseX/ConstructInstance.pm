package MooseX::ConstructInstance;

use 5.008;
use strict;
use warnings;

use Moo::Role;
no warnings qw( void once uninitialized );

# Allow import method to work, yet hide it from role method list.
our @ISA = do {
	package # Hide from CPAN indexer too.
	MooseX::ConstructInstance::__ANON__::0001;
	sub import {
		my $class  = shift;
		my $caller = caller;
		if ($_[0] eq '-with') {
			"Moo::Role"->apply_roles_to_package(
				$caller,
				$class,
			);
		}
	}
	__PACKAGE__;
};

BEGIN {
	$MooseX::ConstructInstance::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ConstructInstance::VERSION   = '0.006';
}

# If push comes to shove, you can locally change the name
# of the constructor.
#
our $CONSTRUCTOR = 'new';

sub construct_instance {
	my (undef, $class, @args) = @_;
	
	if ( my $ref = ref($class) )
	{
		if ($ref ne 'CODE')
		{
			require overload;
			require Scalar::Util;
			require Carp;
			
			Carp::croak("Cannot construct instance from reference $class")
				unless Scalar::Util::blessed($class);
			
			Carp::croak("Cannot construct instance from object $class")
				unless overload::Method($class, '&{}');
		}
		
		return $class->(@args);
	}
	
	$class->$CONSTRUCTOR(@args);
}

1;

__END__

=pod

=encoding utf8

=for stopwords backlinks

=head1 NAME

MooseX::ConstructInstance - small wrapper method for instantiating helper objects

=head1 SYNOPSIS

This role consists of a single method:

   sub construct_instance {
      my (undef, $class, @args) = @_;
      $class->new(@args);
   }

(Actually, since 0.006, it's a little more complex.)

=begin trustme

=item construct_instance

=end trustme

=head1 DESCRIPTION

Normally you would build an LWP::UserAgent something like this:

   sub _build_ua {
      my $self = shift;
      LWP::UserAgent->new(...);
   }

Following the principles of dependency injection, you may prefer not to
hard-code the class name (see also L<MooseX::RelatedClasses>):

   has ua_class => (is => 'ro', default => 'LWP::UserAgent');
   
   sub _build_ua {
      my $self = shift;
      $self->ua_class->new(...);
   }

This module allows you to take it to a further level of abstraction:

   has ua_class => (is => 'ro', default => 'LWP::UserAgent');
   
   sub _build_ua {
      my $self = shift;
      $self->construct_instance($self->ua_class, ...);
   }

Why? What benefit do we accrue from constructing all our helper objects via
a seemingly redundant object method call? How about this:

   {
      package Authentication;
      use Moose::Role;
      around construct_instance => sub {
         my ($orig, $self, $class, @args) = @_;
         my $instance = $self->$orig($class, @args);
         if ($instance->DOES('LWP::UserAgent')) {
            $instance->credentials('', '', 'username', 'password');
         }
         return $instance;
      };
   }
   
   Moose::Util::ensure_all_roles($something, 'Authentication');

Now whenever C<< $something >> constructs an LWP::UserAgent object, it will
automatically have authentication credentials supplied.

MooseX::ConstructInstance can be used to apply policies such as:

=over

=item *

If C<< $foo >> has a C<< dbh >> attribute, and it constructs an object
C<< $bar >>, then C<< $bar >> should inherit C<< $foo >>'s database
handle.

=item *

All node objects must be have "backlinks" to the parent node that created
them.

=back

Despite the name, MooseX::ConstructInstance is actually a L<Moo::Role>.
You can apply MooseX::ConstructInstance to Moose classes using:

   package MyClass;
   use Moose;
   with qw( MooseX::ConstructInstance );

You can apply it to Moo classes using:

   package MyClass;
   use Moo;
   with qw( MooseX::ConstructInstance );

You can apply it to other classes using:

   package MyClass;
   use MooseX::ConstructInstance -with;

As of version 0.006 of MooseX::ConstructInstance, C<< $class >> may be
a coderef or a blessed object overloading C<< &{} >>. The
C<construct_instance> method acts a bit like this:

   sub construct_instance {
      my (undef, $class, @args) = @_;
      if ( is_codelike($class) ) {
         return $class->(@args);
      }
      else {
         $class->new(@args);
      }
   }

=head1 FAQ

=head2 What if I need to use a constructor which is not called C<new>?

Aye; there's the rub.

For now, this works, though it's not an especially elegant solution...

   sub _build_document {
      my $self = shift;
      local $MooseX::ConstructInstance::CONSTRUCTOR = 'new_from_file';
      $self->construct_instance($self->document_class, ...);
   }

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ConstructInstance>.

=head1 SEE ALSO

L<Moose>,
L<MooseX::RelatedClasses>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

