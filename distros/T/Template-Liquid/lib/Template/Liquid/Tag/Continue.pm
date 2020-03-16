package Template::Liquid::Tag::Continue;
our $VERSION = '1.0.19';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use base 'Template::Liquid::Tag::Break';
sub import { Template::Liquid::register_tag('continue') }

sub render {
    my $s = shift;
    $s->{template}->{continue} = 1;
    return '';
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Continue - For-block jitter construct

=head1 Synopsis

    {% for item in collection %}
        {% if item.other_condition %}
            {% continue %}
        {% endif %}
    {% endfor %}

=head1 Description

You can use the C<{% continue %}> tag to fall through the current iteration of
the enclosing C<for|Template::Liquid::Tag::For> block.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Create your own filters">'s docs on custom
filter creation

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
