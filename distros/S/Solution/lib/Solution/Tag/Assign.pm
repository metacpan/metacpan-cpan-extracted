package Solution::Tag::Assign;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../../lib';
    use Solution::Error;
    use Solution::Utility;
    BEGIN { our @ISA = qw[Solution::Tag]; }
    Solution->register_tag('assign', __PACKAGE__) if $Solution::VERSION;

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
        ($args->{'variable'}, $args->{'value'}, my $filters)
            = split m[\s*[=\|]\s+?],
            $args->{'attrs'}, 3;
        $args->{'name'}    = 'a-' . $args->{'attrs'};
        $args->{'filters'} = [];
        if ($filters) {

            for my $filter (split $Solution::Utility::FilterSeparator,
                            $filters)
            {   my ($filter, $f_args)
                    = split $Solution::Utility::FilterArgumentSeparator,
                    $filter, 2;
                $filter =~ s[\s*$][];    # XXX - the splitter should clean...
                $filter =~ s[^\s*][];    # XXX -  ...this up for us.
                my @f_args
                    = $f_args ?
                    split $Solution::Utility::VariableFilterArgumentParser,
                    $f_args
                    : ();
                push @{$args->{'filters'}}, [$filter, \@f_args];
            }
        }
        return bless $args, $class;
    }

    sub render {
        my ($self) = @_;
        my $var    = $self->{'variable'};
        my $val    = $self->resolve($self->{'value'});
        {    # XXX - Duplicated in Solution::Variable::render
        FILTER: for my $filter (@{$self->{'filters'}}) {
                my ($name, $args) = @$filter;
                map { $_ = m[^(['"])(.+)\1\s*$] ? $2 : $self->resolve($_) }
                    @$args;
            PACKAGE: for my $package (@{$self->template->filters}) {
                    if (my $call = $package->can($name)) {
                        $val = $call->($val, @$args);
                        next FILTER;
                    }
                    else {
                        raise Solution::FilterNotFound $name;
                    }
                }
            }
        }
        $self->resolve($var, $val);
        return '';
    }
}
1;

=pod

=head1 NAME

Solution::Tag::Assign - Variable assignment construct

=head1 Synopsis

    {% assign some.variable = 'this value' %}

=head1 Description

You can store data in your own variables for later use as output or in other
tags. The simplest way to create a variable is with the C<assign> tag which
a rather straightforward syntax.

    {% assign person.name = 'john' %}
    Hello, {{ person.name | capitalize }}.

You can modify the value C<before> assignment with L<filters|Solution::Filters>.

    {% assign person.name = 'john' | capitalize %}
    Hello, {{ person.name }}.

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
