package Template::Liquid::Tag::Cycle;
our $VERSION = '1.0.20';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('cycle') }

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type     => 'Context',
                                   template => $args->{template},
                                   message  => 'Missing template argument',
                                   fatal    => 1
        }
        if !defined $args->{'template'};
    raise Template::Liquid::Error {type     => 'Context',
                                   template => $args->{template},
                                   message  => 'Missing parent argument',
                                   fatal    => 1
        }
        if !defined $args->{'parent'};
    raise Template::Liquid::Error {
                   type     => 'Syntax',
                   template => $args->{template},
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
        }
        if !defined $args->{'attrs'} || $args->{'attrs'} !~ m[\S$]o;
    my ($name, $s);
    if ($args->{'attrs'} =~ m[^\s*(.+?)\s*\:\s*(.*)$]o) {    # Named syntax
        ($name, $args->{'attrs'}) = ($1, $2);
        $name = $2 if $name =~ m[^(['"])(.+)\1$];
    }
    elsif ($args->{'attrs'} =~ m[^(.+)$]o) {                 # Simple syntax
        $name = $args->{'attrs'};
    }
    else {
        raise Template::Liquid::Error {
            template => $s->{template},
            type     => 'Syntax',
            message  =>
                sprintf(
                q[Syntax Error in '%s %s' - Valid syntax: cycle [name :] var [, var2, var3 ...]],
                $args->{'tag_name'}, $args->{'attrs'}
                ),
            fatal => 1
        };
    }

    #$name = $args->{'tag_name'} . '-' . $name;
    # XXX - Cycle objects are stored in Template::Liquid::Document objects
    if (defined $args->{'template'}{document}->{'_CYCLES'}{$name}) {
        $s = $args->{'template'}{document}->{'_CYCLES'}{$name};
    }
    else {
        my @list
            = grep { defined $_ }
            $args->{'attrs'}
            =~ m[$Template::Liquid::Utility::VariableFilterArgumentParser]g;
        $s = bless {name     => $name,
                    blocks   => [],
                    tag_name => $args->{'tag_name'},
                    list     => \@list,
                    template => $args->{'template'},
                    parent   => $args->{'parent'},
                    markup   => $args->{'markup'},
                    position => 0
        }, $class;
        $args->{'template'}{document}->{'_CYCLES'}{$name} = $s;
    }
    return $s;
}

sub render {
    my ($s)  = @_;
    my $name = $s->{template}{context}->get($s->{'name'}) || $s->{'name'};
    $s = $s->{template}{document}->{'_CYCLES'}{$name} || $s;
    my $node = $s->{'list'}[$s->{'position'}++];
    my $return
        = ref $node ? $node->render() : $s->{template}{context}->get($node);
    $s->{'position'} = 0 if $s->{'position'} >= scalar @{$s->{'list'}};
    return $return;
}
1;

=pod

=encoding UTF-8

=begin stopwords

L�tke jadedPixel

=end stopwords

=head1 NAME

Template::Liquid::Tag::Cycle - Document-level Persistant Lists

=head1 Description

Often you have to alternate between different colors or similar tasks.
L<Template::Liquid|Template::Liquid> has built-in support for such operations,
using the C<cycle> tag.

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

If you want to have total control over cycle groups, you can optionally specify
the name of the group. This can even be a variable.

    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}

...will result in...

    one
    two
    one
    two

=head1 Notes

The cycle tag is the only one which retains state between calls to render For a
particular document. So...

    use Template::Liquid;
    my $solution = Template::Liquid->parse(<<'TEMPLATE');
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    TEMPLATE
    print $solution->render() for 1..3;

...would print...

    one
    one
    two
    three
    two
    one
    two
    three
    three

...rather than...

    one
    one
    two
    one
    one
    two
    one
    one
    two

...which is what would happen if the state was reset after every render.

Remember than state is held for each document so...

    use Template::Liquid;
    my $solution_a = Template::Liquid->parse(<<'TEMPLATE');
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    TEMPLATE
    my $solution_b = Template::Liquid->parse(<<'TEMPLATE');
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    TEMPLATE
    my $solution_c = Template::Liquid->parse(<<'TEMPLATE');
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    TEMPLATE

    print $solution_a->render();
    print $solution_b->render();
    print $solution_c->render();

...would print...

    one
    one
    two
    one
    one
    two
    one
    one
    two

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2022 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
