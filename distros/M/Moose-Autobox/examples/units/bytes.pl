#!/usr/bin/perl

use strict;
use warnings;

use Moose::Autobox;

{
    package # hide from PAUSE
        Units::Bytes;
    use Moose::Role;
    use Moose::Autobox;

    sub bytes     { $_[0]                   }
    sub kilobytes { $_[0] * 1024            }
    sub megabytes { $_[0] * 1024->kilobytes }
    sub gigabytes { $_[0] * 1024->megabytes }
    sub terabytes { $_[0] * 1024->gigabytes }

    {
        no warnings 'once'; # << squelch the stupid "used only once, maybe typo" warnings
        *byte     = \&bytes;
        *kilobyte = \&kilobytes;
        *megabyte = \&megabytes;
        *gigabyte = \&gigabytes;
        *terabyte = \&terabytes;
    }
}

Moose::Autobox->mixin_additional_role(SCALAR => 'Units::Bytes');

$\ = "\n";

print "5 kilobytes are " . 5->kilobytes . " bytes";
print "2 megabytes are " . 2->megabytes . " bytes";
print "1 gigabyte is "   . 1->gigabyte  . " bytes";
print "2 terabyes are "  . 2->terabytes . " bytes";

# PODNAME: Units::Bytes

__END__

=pod

=encoding UTF-8

=head1 NAME

Units::Bytes

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  Moose::Autobox->mixin_additional_role(SCALAR => 'Units::Bytes');

  print "5 kilobytes are " . 5->kilobytes . " bytes";
  print "2 megabytes are " . 2->megabytes . " bytes";
  print "1 gigabyte is "   . 1->gigabyte  . " bytes";
  print "2 terabyes are "  . 2->terabytes . " bytes";

=head1 DESCRIPTION

This is a Moose::Autobox port of the perl6 vmethods example.

=head1 ACKNOWLEDGEMENTS

This code was ported from the version in the Pugs
examples/vmethods/ directory. See that for original author
information.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
