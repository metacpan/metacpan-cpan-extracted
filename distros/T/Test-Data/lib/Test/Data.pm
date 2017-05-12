package Test::Data;
use strict;

our $VERSION = '1.241';

use Carp qw(carp);

use Test::Builder;

my $Test = Test::Builder->new();

=encoding utf8

=head1 NAME

Test::Data -- test functions for particular variable types

=head1 SYNOPSIS

use Test::Data qw(Scalar Array Hash Function);

=head1 DESCRIPTION

Test::Data provides utility functions to check properties
and values of data and variables.

=cut

$Exporter::Verbose = 0;

sub import {
    my $self   = shift;
    my $caller = caller;

	foreach my $package ( @_ ) {
		my $full_package = "Test::Data::$package";
		eval{ eval "require $full_package" };
		if( $@ ) {
			carp "Could not require Test::Data::$package: $@";
			}

		$full_package->Exporter::export($caller);
		}

	}

=head2 Functions

Plug-in modules define functions for each data type.  See the
appropriate module.

=head2 How it works

The Test::Data module simply emports functions from Test::Data::*
modules.  Each module defines a self-contained function, and puts
that function name into @EXPORT.  Test::Data defines its own
import function, but that does not matter to the plug-in modules.

If you want to write a plug-in module, follow the example of one
that already exists.   Name the module Test::Data::Foo, where you
replace Foo with the right name.  Test::Data should automatically
find it.

=head1 BUGS

I'm not a very good Windows Perler, so some things don't work as
they should on Windows. I recently got a Windows box so I can
test things, but if you run into problems, I can use all the
patches or advice you care to send.

=head1 SEE ALSO

L<Test::Data::Scalar>,
L<Test::Data::Array>,
L<Test::Data::Hash>,
L<Test::Data::Function>,
L<Test::Builder>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/test-data

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"Now is the time for all good men to come to the aid of their country";
