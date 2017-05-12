package Template::Plugin::CaseVMethods;
use Template::Plugin::VMethods;
use base qw(Template::Plugin::VMethods);

use strict;
#use warnings;

use vars qw($VERSION @SCALAR_OPS);
$VERSION = 0.01;

sub uppercase        { uc      $_[0] }
sub lowercase        { lc      $_[0] }
sub uppercase_first  { ucfirst $_[0] }
sub lowercase_first  { lcfirst $_[0] }

@SCALAR_OPS = ( "uc" => \&uppercase,
		"lc" => \&lowercase,
                "ucfirst" => \&uppercase_first,
		"lcfirst" => \&lowercase_first, );

=head1 NAME

Template::Plugin::CaseVMethods - uppercase and lowercase letters

=head1 SYNOPSIS

  [% USE CaseVMethods %]

  Hello [% name.ucfirst %].
  ...or should I say...
  HEY [% name.uc %] PAY ATTENTION I'M SPEAKING TO YOU.

=head1 DESCRIPTION

Provides four vmethods (uc, ucfirst, lc, lcfirst) that perform the
same actions as their Perl counterparts (return the string in
uppercase, return the string as is but with the first letter
capitalised, return the string in lower case, and return the string as
is but with the first letter lowercased.)

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copyright Profero 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

The tests might fail on locales where uppercase "z" isn't "Z" (and
vice versa) but the module will do the right thing (where the right
thing is defined as what your perl does.)

Bugs should be reported to the open source development team
at Profero via the CPAN RT system.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template::Plugin::CaseVMethods>.

=head1 SEE ALSO

L<Template::Plugin::VMethods>

=cut

1;
