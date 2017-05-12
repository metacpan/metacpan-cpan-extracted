use 5.008008;
use strict;
use warnings;

use Moose ();
use Moose::Exporter ();

package MooseX::WhatTheTrig;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

{
	package MooseX::WhatTheTrig::Trait::Attribute;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	use Scope::Guard qw(guard);
	
	after _process_trigger_option => sub
	{
		my $class = shift;
		my ($name, $opts) = @_;
		return unless exists $opts->{trigger};
		
		my $orig = delete $opts->{trigger};
		$opts->{trigger} = sub
		{
			my $self = shift;
			my $meta = Moose::Util::find_meta($self);
			my $restore = $meta->triggered_attribute;
			my $guard   = guard { $meta->_set_triggered_attribute($restore) };
			$meta->_set_triggered_attribute($name);
			$self->$orig(@_);
		};
	}
}

{
	package MooseX::WhatTheTrig::Trait::Package;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	
	has triggered_attribute => (
		is     => 'ro',
		writer => '_set_triggered_attribute',
	);
}

{
	package MooseX::WhatTheTrig::Trait::Class;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	with qw(MooseX::WhatTheTrig::Trait::Package);
}

{
	package MooseX::WhatTheTrig::Trait::Role;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	with qw(MooseX::WhatTheTrig::Trait::Package);
}

my %class_metaroles = (
	class => ['MooseX::WhatTheTrig::Trait::Class'],
);

my %role_metaroles = (
	role                 => ['MooseX::WhatTheTrig::Trait::Role'],
	application_to_role  => ['MooseX::WhatTheTrig::Trait::ApplicationToRole'],
	application_to_class => ['MooseX::WhatTheTrig::Trait::ApplicationToClass'],
);

'Moose::Exporter'->setup_import_methods(
	trait_aliases   => [ [ 'MooseX::WhatTheTrig::Trait::Attribute' => 'WhatTheTrig' ] ],
	class_metaroles => \%class_metaroles,
	role_metaroles  => \%role_metaroles,
);

{
	package MooseX::WhatTheTrig::Trait::Application;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	
	sub _whatthetrig_metacrap
	{
		my $self = shift;
		my ($next, $opts, $role, $applied_to) = @_;
		$applied_to = Moose::Util::MetaRole::apply_metaroles(for => $applied_to, %$opts);
		$self->$next($role, $applied_to);
	}
}

{
	package MooseX::WhatTheTrig::Trait::ApplicationToClass;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	with qw(MooseX::WhatTheTrig::Trait::Application);
	
	around apply => sub
	{
		my $next = shift;
		my $self = shift;
		$self->_whatthetrig_metacrap($next, { class_metaroles => \%class_metaroles }, @_);
	};
}

{
	package MooseX::WhatTheTrig::Trait::ApplicationToRole;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	use Moose::Role;
	with qw(MooseX::WhatTheTrig::Trait::Application);
	
	around apply => sub
	{
		my $next = shift;
		my $self = shift;
		$self->_whatthetrig_metacrap($next, { role_metaroles => \%role_metaroles }, @_);
	};
}

1;

__END__

=pod

=for stopwords metaobject

=encoding utf-8

=head1 NAME

MooseX::WhatTheTrig - what attribute triggered me?

=head1 SYNOPSIS

   use v5.14;
   
   package Goose {
      use Moose;
      use MooseX::WhatTheTrig;
      
      has foo => (
         traits  => [ WhatTheTrig ],
         is      => 'rw',
         trigger => sub {
            my $self = shift;
            my $attr = Moose::Util::find_meta($self)->triggered_attribute;
            say "Triggered $attr";
         },
      );
   }
   
   my $obj = Goose->new(foo => 42);    # says "Triggered foo"
   $obj->foo(999);                     # says "Triggered foo"

=head1 DESCRIPTION

Moose trigger subs get passed two (sometimes three) parameters:

=over

=item *

The object itself.

=item *

The new attribute value.

=item *

The old attribute value (if any).

=back

The sub doesn't get told which attribute triggered it. This may present
a problem if you wish to have the same coderef triggered from several
different attributes.

This module adds a C<< $meta->triggered_attribute >> method to your
class' metaobject, which allows you to check which attribute has been
triggered.

Yes, it works if you trigger one attribute from another attribute.

Yes, it works in roles.

Yes, it works with inheritance.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-WhatTheTrig>.

=head1 SEE ALSO

L<http://stackoverflow.com/questions/22306330/moose-trigger-caller>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

