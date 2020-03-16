package Template::Liquid::Tag::Decrement;
our $VERSION = '1.0.19';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use base 'Template::Liquid::Tag::Increment';
sub import { Template::Liquid::register_tag('decrement') }
#
sub _initial   {-1}
sub _direction {-1}
sub _me        {'decrement'}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Decrement - Document-level Persistant Number

=head1 Description

Creates a new number variable, and decreases its value by one every time it is
called. The initial value is C<-1>.

=head1 Synopsis

    {% decrement my_counter %}
    {% decrement my_counter %}
    {% decrement my_counter %}

...will result in...

    -1
    -2
    -3

=head1 Notes

Like C<increment>, variables declared inside C<decrement> are independent from
variables created through C<assign> or C<capture>.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
