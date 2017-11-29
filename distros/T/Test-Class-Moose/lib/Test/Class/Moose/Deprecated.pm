package Test::Class::Moose::Deprecated;

# ABSTRACT: Managed deprecation warnings for Test::Class::Moose

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

our $VERSION = '0.90';

use Package::DeprecationManager 0.16 -deprecations => {
    'Test::Class::Moose::Config::args' => '0.79',
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Deprecated - Managed deprecation warnings for Test::Class::Moose

=head1 VERSION

version 0.90

=head1 DESCRIPTION

    use Test::Class::Moose::Deprecated -api_version => $version;

=head1 FUNCTIONS

This module manages deprecation warnings for features that have been
deprecated in L<Test::Class::Moose>.

If you specify C<< -api_version => $version >>, you can use deprecated features
without warnings. Note that this special treatment is limited to the package
that loads C<Test::Class::Moose::Deprecated>.

=head1 DEPRECATIONS BY VERSION

The following features were deprecated in past versions and will now warn:

=head2 Test::Class::Moose::Config->args

This was deprecated in version 0.79.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/test-class-moose/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/houseabsolute/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2017 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
