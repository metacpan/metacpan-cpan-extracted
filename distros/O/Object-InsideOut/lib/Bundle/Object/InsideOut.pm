package Bundle::Object::InsideOut;

use strict;
use warnings;

our $VERSION = '4.04';
$VERSION = eval $VERSION;

1;

__END__

=head1 NAME

Bundle::Object::InsideOut - A bundle of modules for full Object::InsideOut support

=head1 SYNOPSIS

 perl -MCPAN -e "install Bundle::Object::InsideOut"

=head1 CONTENTS

Test::Harness 3.36              - Used for module testing

Test::Simple 1.302059           - Used for module testing

Scalar::Util 1.47               - Used by Object::InsideOut

Pod::Escapes 1.07               - Used by Pod::Simple

Pod::Simple 3.35                - Used by Test::Pod

Test::Pod 1.51                  - Checks POD syntax

Devel::Symdump 2.18             - Used by Pod::Coverage

File::Spec 3.63                 - Used by Pod::Parser

Pod::Parser 1.63                - Used by Pod::Coverage

Pod::Coverage 0.23              - Used by Test::Pod::Coverage

Test::Pod::Coverage 1.10        - Tests POD coverage

threads 2.15                    - Support for threads

threads::shared 1.55            - Support for sharing objects between threads

Want 0.29                       - :lvalue accessor support

Data::Dumper 2.161              - Object serialization support

Storable 2.56                   - Object serialization support

Devel::StackTrace 2.02          - Used by Exception::Class

Class::Data::Inheritable 0.08   - Used by Exception::Class

Exception::Class 1.42           - Error handling

Object::InsideOut 4.04          - Inside-out object support

URI 1.71                        - Used by LWP::UserAgent

HTML::Tagset 3.20               - Used by LWP::UserAgent

HTML::Parser 3.72               - Used by LWP::UserAgent

LWP::UserAgent 6.21             - Used by Math::Random::MT::Auto

Win32::API 0.82                 - Used by Math::Random::MT::Auto (Win XP only)

Math::Random::MT::Auto 6.22     - Support for :SECURE mode

=head1 DESCRIPTION

This bundle includes all the modules used to test and support
Object::InsideOut.

=head1 CAVEATS

For ActivePerl on Win XP, if L<Win32::API> doesn't install using CPAN, then
try installing it using PPM:

 ppm install Win32-API

Obviously, Win32::API will not install on all platforms - just Windows and
Cygwin.

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2012 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
