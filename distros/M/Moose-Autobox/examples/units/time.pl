#!/usr/bin/perl

use strict;
use warnings;

use Moose::Autobox;

{
    package # hide me from PAUSE
        Units::Time;
    use Moose::Role;
    use Moose::Autobox;

    sub seconds   { $_[0]               }
    sub minutes   { $_[0] * 60          }
    sub hours     { $_[0] * 60->minutes }
    sub days      { $_[0] * 24->hours   }
    sub weeks     { $_[0] * 7->days     }
    sub years     { $_[0] * 365->days   }
    sub centuries { $_[0] * 10->years   }

    sub ago {
        my ($self, $time) = @_;
        $time ||= time();
        $time - $self;
    }

    sub since {
        my ($self, $time) = @_;
        $time ||= time();
        $time + $self;
    }

    {
        no warnings 'once';

        # singular versions
        *second  = \&seconds;
        *minute  = \&minutes;
        *hour    = \&hours;
        *day     = \&days;
        *week    = \&weeks;
        *year    = \&years;
        *century = \&centuries;

        *til      = \&ago;
        *from_now = \&since;
    }

    sub as_string { scalar localtime $_[0] }

}

Moose::Autobox->mixin_additional_role(SCALAR => 'Units::Time');

$\ = "\n";

print "2 days ago was           : " . 2->days->ago->as_string;
print "3 weeks from now will be : " . 3->weeks->from_now->as_string;
my $one_week_ago = 1->week->ago;
print "1 day until 1 week ago   : " . 1->day->til($one_week_ago)->as_string;
print "2 years since 1 week ago : " . 2->years->since($one_week_ago)->as_string;

__END__

=pod

=encoding UTF-8

=head1 NAME

Units::Time

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  Moose::Autobox->mixin_additional_role(SCALAR => 'Units::Time');

  print "2 days ago was           : " . 2->days->ago->as_string;
  print "3 weeks from now will be : " . 3->weeks->from_now->as_string;
  print "1 day until 1 week ago   : " . 1->day->til(1->week->ago)->as_string;
  print "2 years since 1 week ago : " . 2->years->since(1->week->ago)->as_string;

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
