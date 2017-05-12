package Solution::Tag::Capture;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    BEGIN { our @ISA = qw[Solution::Tag]; }
    Solution->register_tag('capture', __PACKAGE__) if $Solution::VERSION;

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
            if !defined $args->{'attrs'};
        if ($args->{'attrs'} !~ qr[^(\S+)\s*?$]) {
            raise Solution::SyntaxError {
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
            };
        }
        my $self = bless {name          => 'c-' . $1,
                          nodelist      => [],
                          tag_name      => $args->{'tag_name'},
                          variable_name => $1,
                          end_tag       => 'end' . $args->{'tag_name'},
                          template      => $args->{'template'},
                          parent        => $args->{'parent'},
                          markup        => $args->{'markup'},
        }, $class;
        return $self;
    }

    sub render {
        my ($self) = @_;
        my $var    = $self->{'variable_name'};
        my $val    = '';
        for my $node (@{$self->{'nodelist'}}) {
            my $rendering = ref $node ? $node->render() : $node;
            $val .= defined $rendering ? $rendering : '';
        }
        $self->resolve($var, $val);
        return '';
    }
}
1;

=pod

=head1 NAME

Solution::Tag::Capture - Extended variable assignment construct

=head1 Synopsis

    {% capture triple_x %}
        {% for x in (1..3) %}{{ x }}{% endfor %}
    {% endcapture %}

=head1 Description

If you want to combine a number of strings into a single string and save it to
a variable, you can do that with the C<capture> tag. This tag is a block which
"captures" whatever is rendered inside it, then assigns the captured value to
the given variable instead of rendering it to the screen.

=head1 See Also

The L<assign|Solution::Tag::Assign> tag.

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Solution|Solution/"Create your own filters">'s docs on custom filter creation

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
