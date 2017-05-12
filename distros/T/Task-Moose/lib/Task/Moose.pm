package Task::Moose;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

1;

__END__

=pod

=head1 NAME

Task::Moose - Moose in a box

=head1 DESCRIPTION

This Task installs Moose and then optionally installs a number of 
Moose extensions listed below. This list is meant to be comprehensive, 
so if I missed something please let me know.

=head1 MODULES

=head2 Make Moose Stricter

=head3 L<MooseX::StrictConstructor>

Making Moose constructors stricter

=head3 L<MooseX::Params::Validate>

Moose-ish method parameter handling

=head2  Traits / Roles

=head3 L<MooseX::Role::TraitConstructor>

Runtime trait application in constructors

=head3 L<MooseX::Traits>

Easy creation of objects with traits

=head3 L<MooseX::Object::Pluggable>

Moose-ish plugin system

=head3 L<MooseX::Role::Parameterized>

Parameterized roles

=head2 Instance Types

=head3 L<MooseX::GlobRef>

Globref instance type for Moose

=head3 L<MooseX::InsideOut>

Inside out instance type for Moose

=head3 L<MooseX::Singleton>

Singleton instance type for Moose

=head3 L<MooseX::NonMoose>

Subclassing of non-Moose classes

=head2 Declarative Syntax

=head3 L<MooseX::Declare>

Declarative syntax with L<Devel::Declare>

=head3 L<MooseX::Method::Signatures>

Declarative method syntax

=head3 L<TryCatch>

Declarative exception handling

=head2 Types

=head3 L<MooseX::Types>

Moose type extensions

=head3 L<MooseX::Types::Structured>

Structured type constraints

=head3 L<MooseX::Types::Path::Class>

L<Path::Class> Moose type extension

=head3 L<MooseX::Types::Set::Object>

L<Set::Object> Moose type extension

=head3 L<MooseX::Types::DateTime>

L<DateTime> Moose type extension

=head2 Command Line Integration

=head3 L<MooseX::Getopt>

Better script writing with Moose

=head3 L<MooseX::ConfigFromFile>

Support for config with L<MooseX::Getopt>

=head3 L<MooseX::SimpleConfig>

Config file support for L<MooseX::Getopt> with L<Config::Any>

=head3 L<MooseX::App::Cmd>

L<App::Cmd> integration for Moose

=head3 L<MooseX::Role::Cmd>

Easily wrap command line apps with Moose

=head2 Logging

=head3 L<MooseX::LogDispatch>

L<Log::Dispatch> support for Moose

=head3 L<MooseX::LazyLogDispatch>

Lazy loaded L<Log::Dispatch> support for Moose

=head3 L<MooseX::Log::Log4perl>

L<Log::Log4perl> support for Moose

=head2 Async

=head3 L<MooseX::POE>

Moose wrapped L<POE>

=head3 L<MooseX::Workers>

Sub-process management for asynchronous tasks using Moose and L<POE>

=head2 Utility Roles

=head3 L<MooseX::Daemonize>

Daemonization support roles for Moose

=head3 L<MooseX::Param>

CGI-style parameter role

=head3 L<MooseX::Iterator>

Moose-ish iterator support role

=head3 L<MooseX::Clone>

More robust and flexible cloning support

=head3 L<MooseX::Storage>

Moose serialization

=head2 Other Useful Extensions

=head3 L<Moose::Autobox>

L<Autoboxing|autobox> support

=head3 L<MooseX::ClassAttribute>

Class attributes for Moose

=head3 L<MooseX::SemiAffordanceAccessor>

Support for PBP style accessors

=head3 L<namespace::autoclean>

Keep imported subroutines out of your class's namespace

=head2 Utilities

=head3 L<Pod::Coverage::Moose>

L<Pod::Coverage> extension for Moose

=head1 NOTES

L<MooseX::AttributeHelpers> has been removed from this list because
its functionality has been subsumed into L<Moose> itself. See
L<Moose::Meta::Attribute::Native> for more details.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

Chris Prather E<lt>chris@prather.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
