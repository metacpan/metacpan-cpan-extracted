package Template::Liquid::Tag::Assign;
our $VERSION = '1.0.18';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
BEGIN { use base 'Template::Liquid::Tag'; }
sub import { Template::Liquid::register_tag('assign') }

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type    => 'Context',
                                   message => 'Missing template argument',
                                   fatal   => 1
        }
        if !defined $args->{'template'};
    raise Template::Liquid::Error {type => 'Context',
                             message => 'Missing parent argument', fatal => 1}
        if !defined $args->{'parent'};
    raise Template::Liquid::Error {
                   type    => 'Syntax',
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
        }
        if !defined $args->{'attrs'};
    ($args->{'variable'}, $args->{'value'}, my $filters)
        = split m[\s*[=\|]\s+?]o, $args->{'attrs'}, 3;
    $args->{'name'}    = 'a-' . $args->{'attrs'};
    $args->{'filters'} = [];
    if ($filters) {
        for my $filter (split $Template::Liquid::Utility::FilterSeparator,
                        $filters) {
            my ($filter, $f_args)
                = split $Template::Liquid::Utility::FilterArgumentSeparator,
                $filter, 2;
            $filter =~ s[\s*$][]o;    # XXX - the splitter should clean...
            $filter =~ s[^\s*][]o;    # XXX -  ...this up for us.
            my @f_args
                = !defined $f_args ? () : grep { defined $_ }
                $f_args
                =~ m[$Template::Liquid::Utility::VariableFilterArgumentParser]g;
            push @{$args->{'filters'}}, [$filter, \@f_args];
        }
    }
    return bless $args, $class;
}

sub render {
    my $s   = shift;
    my $var = $s->{'variable'};
    my $val = $s->{template}{context}->get($s->{'value'});
    {    # XXX - Duplicated in Template::Liquid::Variable::render
        if (scalar @{$s->{filters}}) {
            my %_filters = $s->{template}->filters;
        FILTER: for my $filter (@{$s->{filters}}) {
                my ($name, $args) = @$filter;
                map { $_ = $s->{template}{context}->get($_) || $_ } @$args;
                my $package = $_filters{$name};
                my $call    = $package ? $package->can($name) : ();
                if ($call) {
                    $val = $call->($val, @$args);
                    next FILTER;
                }
                raise Template::Liquid::Error {
                                        type    => 'Filter',
                                        message => "Filter '$name' not found",
                                        fatal   => 1
                };
            }
        }
    }
    $s->{template}{context}->set($var, $val);
    return '';
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Assign - Variable assignment construct

=head1 Synopsis

    {% assign some.variable = 'this value' %}

=head1 Description

You can store data in your own variables for later use as output or in other
tags. The simplest way to create a variable is with the C<assign> tag which a
rather straightforward syntax.

    {% assign person.name = 'john' %}
    Hello, {{ person.name | capitalize }}.

You can modify the value C<before> assignment with
L<filters|Template::Liquid::Filters>.

    {% assign person.name = 'john' | capitalize %}
    Hello, {{ person.name }}.

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
