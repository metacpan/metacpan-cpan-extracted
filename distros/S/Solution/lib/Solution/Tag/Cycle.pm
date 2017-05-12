package Solution::Tag::Cycle;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('cycle') if $Solution::VERSION;

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
        my ($name, $self);
        if ($args->{'attrs'} =~ m[^\s*(.+?)\s*\:\s*(.*)$]) {    # Named syntax
            ($name, $args->{'attrs'}) = ($1, $2);
            $name = $2 if $name =~ m[^(['"])(.+)\1$];
        }
        elsif ($args->{'attrs'} =~ m[^(.+)$]) {    # Simple syntax
            $name = $args->{'attrs'};
        }
        else {
            raise Solution::SyntaxError {
                message => sprintf(
                    q[Syntax Error in '%s %s' - Valid syntax: cycle [name :] var [, var2, var3 ...]],
                    $args->{'tag_name'}, $args->{'attrs'}
                ),
                fatal => 1
            };
        }

        #$name = $args->{'tag_name'} . '-' . $name;
        # XXX - Cycle objects are stored in Solution::Document objects
        if (defined $args->{'template'}->document->{'_CYCLES'}{$name}) {
            $self = $args->{'template'}->document->{'_CYCLES'}{$name};
        }
        else {
            my @list
                = split $Solution::Utility::VariableFilterArgumentParser,
                $args->{'attrs'};
            $self = bless {name     => $name,
                           blocks   => [],
                           tag_name => $args->{'tag_name'},
                           list     => \@list,
                           template => $args->{'template'},
                           parent   => $args->{'parent'},
                           markup   => $args->{'markup'},
                           position => 0
            }, $class;
            $args->{'template'}->document->{'_CYCLES'}{$name} = $self;
        }
        return $self;
    }

    sub render {
        my ($self) = @_;
        my $name = $self->resolve($self->{'name'})
            || $self->{'name'};
        $self = $self->template->document->{'_CYCLES'}{$name} || $self;
        my $node = $self->{'list'}[$self->{'position'}++];
        my $return
            = ref $node
            ? $node->render()
            : $self->resolve($node);
        $self->{'position'} = 0
            if $self->{'position'} >= scalar @{$self->{'list'}};
        return $return;
    }
}
1;

=pod

=head1 NAME

Solution::Tag::Cycle - Document-level Persistant Lists

=head1 Description

Often you have to alternate between different colors or similar tasks.
L<Solution|Solution> has built-in support for such operations, using the
C<cycle> tag.

=head1 Synopsis

    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}

...will result in...

    one
    two
    three
    one

If no name is supplied for the cycle group, then it’s assumed that multiple
calls with the same parameters are one group.

If you want to have total control over cycle groups, you can optionally
specify the name of the group. This can even be a variable.

    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}

...will result in...

    one
    two
    one
    two

=head1 See Also

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
