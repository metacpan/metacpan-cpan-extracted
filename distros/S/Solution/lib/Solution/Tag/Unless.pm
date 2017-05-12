package Solution::Tag::Unless;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    our @ISA = qw[Solution::Tag::If];
    Solution->register_tag('unless') if $Solution::VERSION;

    sub render {
        my ($self) = @_;
        return $self->{'blocks'}->[0]->render()
            if !(grep { $_->is_true ? 1 : 0 }
                 @{$self->{'blocks'}->[0]->{'conditions'}}
            );
        for my $index (1 .. $#{$self->{'blocks'}}) {
            my $block = $self->{'blocks'}->[$index];
            return $block->render()
                if grep { $_ || 0 } @{$block->{'conditions'}};
        }
    }
}
1;

=pod

=head1 NAME

Solution::Tag::Unless - Unless: The Opposite of If

=head1 Description

Unless is the opposite of L<if|Solution::Tag::If>. The block is rendered
I<unless> the conditon is true.

=head1 Synopsis

    {% unless value == 5 %}
        Doesn't equal five!
    {% else %}
        Aww... it does equal five.
    {% endunless %}

=head1 Bugs

Since L<unless|Solution::Tag::Unless> is simply a subclass, see the list of
bugs for L<ifSolution::Tag::If>. They basically apply here too.

=head1 See Also

See L<Solution::Condition|Solution::Condition> for a list of supported
inequalities.

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

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
