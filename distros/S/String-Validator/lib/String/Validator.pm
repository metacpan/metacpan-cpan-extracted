package String::Validator;

use 5.006;
use strict;
use warnings;

=head1 NAME 

String::Validator

=head2 A Collection of Routines for validating strings

You have a string and you need to know if it is what you need it to be.
You just wasted three hours before you realized it was going to take
longer than you thought and just started to poke around cpan to find
something to use instead. The String Validator Collection is what you are looking for.

Since as often as not you're not just validating strings, but also
trying to get them into a specific format, many String::Validator Modules
will do this.

=head3 This Module is Empty

The Core Module, String::Validator is empty. It contains some common
documentation, and all other String::Validator Modules are dependencies
to install it. You can type cpanm String::Validator to install the current
version of all of the Modules.

=head1 Methods Common to String::Validator Modules

=head2 The New Method

The new method for String-Validators takes as an argument a hash of
parameters, these will be different for each module. See the specific
Module's Documentation.

=head2 The Postive and Negative Method

The negative method B<IsNot_Valid> will return 0 (false) for a valid string
and the reason as a string for an invalid one.

The positive method B<Is_Valid> will return 1 (true) and 0 (false). To find out
why a string failed use the errstr method.

Both Is_Valid and IsNot_Valid will take either one string or two strings as
arguments. If two strings are provided they are compared. When two strings are
provided and do not match only 1 error is observed, because String::Validator cannot
know which (if either) to continue evaluating. If called subsequently the String() method will
return Null and the errorcnt() method will return 1.

=head2 errstr, errcnt

B<errcnt> returns the number of errors seen on the last call to Is/IsNot_Valid.
B<errstr> returns a string describing the errors encountered.

=head2 String, Reformatting

The String method always returns the internal representation of the
last string evaluated by Is/IsNot_Valid. The exceptions are that a new
String::Validator Object will return a NULL value, as it will following
a mismatch error when the string is passed twice.
String-Validators may provide reformat methods appropriate to their purpose
and will be documented in their own POD.

=head2 Example

 my $Validator = String::Validator::Demo->new(
    format => 'fake', min_length => 6, max_length => 17 ) ;
 if ( $Validator->IsNot_Valid('ThisString') { do something }
     or
 unless ( $Validator->IsNot_Valid('ThatString') { die $Validator->errstr() }
     maybe
 if ( $Validator->IsNot_Valid('ThisString', 'RepeatThisString') { do something }
 say  $Validator->String ;
 
=head2 CamelCase lowercase

The base class String::Validator::Common provides both the CamelCase and lowercase
versions of the methods it provides for use by the end user of the inheriting module,
this is done to make it even more convenient.

=head1 Making Validator Better

Everything Validator does is a waste of time (if you had to do it yourself).
So if you find you've wasted time validating something that fits
with the Validator theme, write it up and send it in. If you think
Validator does a poor job of something, send us a better solution.
If you already made a module even better, Validator is all
about dependency on other modules that do validation just suggest.
If you read the sub-modules you'll see that many of them are just
wrappers around other validation modules.


=head1 VERSION

Version 0.97

=cut

our $VERSION = '0.97';

return 0;



=head1 AUTHOR

John Karr, C<< <brainbuz at brainbuz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-validor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Validator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 John Karr.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of Validator
