package Solution::Tag::If;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('if') if $Solution::VERSION;

    sub new {
        my ($class, $args) = @_;
        raise Solution::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'};
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        raise Solution::SyntaxError {
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'} || $args->{'attrs'} !~ m[\S$];
        my $condition = $args->{'attrs'};
        my $self = bless {name     => $args->{'tag_name'} . '-' . $condition,
                          blocks   => [],
                          tag_name => $args->{'tag_name'},
                          template => $args->{'template'},
                          parent   => $args->{'parent'},
                          markup   => $args->{'markup'},
                          end_tag  => 'end' . $args->{'tag_name'},
                          conditional_tag => qr[^(?:else|else?if)$]
        }, $class;
        return $self;
    }

    sub push_block {
        my ($self, $args) = @_;
        my $block =
            Solution::Block->new({tag_name => $args->{'tag_name'},
                                  attrs    => $args->{'attrs'},
                                  template => $args->{'template'},
                                  parent   => $self
                                 }
            );
        {    # finish previous block
            ${$self->{'blocks'}[-1]}{'nodelist'} = $self->{'nodelist'};
            $self->{'nodelist'} = [];
        }
        push @{$self->{'blocks'}}, $block;
        return $block;
    }

    sub render {
        my ($self) = @_;
        for my $block (@{$self->{'blocks'}}) {
            return $block->render()
                if grep { $_ || 0 } @{$block->{'conditions'}};
        }
    }
}
1;

=pod

=head1 NAME

Solution::Tag::If - Basic If/Elsif/Else Construct

=head1 Description

If I need to describe if/else to you... Oy. C<if> executes the statement once
if and I<only> if the condition is true. If the condition is false, the first
C<elseif> condition is evaluated. If that is also false it continues in the
same pattern until we find a true condition or a fallback C<else> tag.

=head2 Compound Inequalities

Solution supports compund inequalities. Try these...

    {% if some.value == 3 and some.string contains 'find me' %}
        Wow! It's a match...
    {% elseif some.value == 4 or 3 < some.value %}
        Wow! It's a... different... match...
    {% endif %}

=head1 Bugs

Liquid's (and by extension L<Solution|Solution>'s) treatment of
compound inequalities is broken. For example...

    {% if 'This and that' contains 'that' and 1 == 3 %}

...would be parsed as if it were...

    if ( "'This" && ( "that'" =~ m[and] ) ) { ...

...but it should look like...

    if ( ( 'This and that' =~ m[that]) && ( 1 == 3 ) ) { ...

It's just... not pretty but I'll work on it. The actual problem is in
L<Solution::Block|Solution::Block> if you feel like lending a hand. Wink,
wink.

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
