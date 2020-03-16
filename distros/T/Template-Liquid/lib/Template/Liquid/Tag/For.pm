package Template::Liquid::Tag::For;
our $VERSION = '1.0.19';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use base 'Template::Liquid::Tag::If';
my $Help_String = 'TODO';
sub import { Template::Liquid::register_tag('for') }

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
        if !defined $args->{'attrs'};
    if ($args->{'attrs'} !~ qr[^([\w\.]+)\s+in\s+(.+?)(?:\s+(.*)\s*?)?$]o) {
        raise Template::Liquid::Error {
                       template => $args->{template},
                       type     => 'Syntax',
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
        };
    }
    my ($var, $range, $attr) = ($1, $2, $3 || '');
    my $reversed = $attr =~ s[^reversed\b][]o ? 1 : 0;
    my %attr     = map {

        #my $blah = $_;
        #my ($k, $v)
        #    = grep { defined $_ }
        #    $_
        #    =~ m[$Template::Liquid::Utility::VariableFilterArgumentParser]g;
        #use Data::Dump;
        ##ddx [$k, $v];
        my ($k, $v) = $_ =~ m[$Template::Liquid::Utility::TagAttributes]g;
        { $k => $v };
    } grep { defined && length } split qr[\s+]o, $attr || '';
    my $s = bless {attributes      => \%attr,
                   collection_name => $range,
                   name            => $var . '-' . $range,
                   blocks          => [],
                   conditional_tag => 'else',
                   reversed        => $reversed,
                   tag_name        => $args->{'tag_name'},
                   variable_name   => $var,
                   end_tag         => 'end' . $args->{'tag_name'},
                   template        => $args->{'template'},
                   parent          => $args->{'parent'},
                   markup          => $args->{'markup'}
    }, $class;
    return $s;
}

sub render {
    my ($s)      = @_;
    my $range    = $s->{'collection_name'};
    my $attr     = $s->{'attributes'};
    my $reversed = $s->{'reversed'};
    my $sorted
        = exists $attr->{'sorted'}
        ? $s->{template}{context}->get($attr->{'sorted'}) ||
        $attr->{'sorted'} ||
        'key'
        : ();
    $sorted = 'key'
        if (defined $sorted && (($sorted ne 'key') && ($sorted ne 'value')));
    my $offset
        = defined $attr->{'offset'}
        ? $s->{template}{context}->get($attr->{'offset'})
        : ();
    my $limit
        = defined $attr->{'limit'}
        ? $s->{template}{context}->get($attr->{'limit'})
        : ();
    my $list = $s->{template}{context}->get($range);
    my $type = 'ARRAY';

    #warn $list;
    #
    my $_undef_list = 0;
    if (ref $list eq 'HASH') {
        $list  = [map { {key => $_, value => $list->{$_}} } keys %$list];
        @$list = sort {
            $a->{$sorted} =~ m[^\d+$]o &&
                $b->{$sorted} =~ m[^\d+$]o
                ? ($a->{$sorted} <=> $b->{$sorted})
                : ($a->{$sorted} cmp $b->{$sorted})
        } @$list if defined $sorted;
        $type = 'HASH';
    }
    elsif (defined $sorted) {
        @$list = sort {
            $a =~ m[^\d+$] &&
                $b =~ m[^\d+$]
                ? ($a <=> $b)
                : ($a cmp $b)
        } @$list;
    }
    if (!defined $list || !$list || !@$list) {
        $_undef_list = 1;
        $list        = [1];
    }
    else {    # Break it down to only the items we plan on using
        my $min = (defined $offset ? $offset : 0);
        my $max
            = (defined $limit
               ? $limit + (defined $offset ? $offset : 0) - 1
               : $#$list);
        $max  = $#$list if $max > $#$list;
        $list = [@{$list}[$min .. $max]]
            ;    # make a copy so we can use the list again
        @$list  = reverse @$list if $reversed;
        $limit  = defined $limit ? $limit : scalar @$list;
        $offset = defined $offset ? $offset : 0;
    }
    return $s->{template}{context}->stack(
        sub {
            my $return = '';
            my $steps  = $#$list;
            $_undef_list = 1 if $steps == -1;
            my $nodes = $s->{'blocks'}[$_undef_list]{'nodelist'};
        FOR: for my $index (0 .. $steps) {
                $s->{template}{context}
                    ->set($s->{'variable_name'}, $list->[$index]);
                $s->{template}{context}->set(
                                       'forloop',
                                       {length => $steps + 1,
                                        limit  => $limit,
                                        offset => $offset,
                                        name   => $s->{'name'},
                                        first  => ($index == 0 ? !!1 : !1),
                                        last => ($index == $steps ? !!1 : !1),
                                        index   => $index + 1,
                                        index0  => $index,
                                        rindex  => $steps - $index + 1,
                                        rindex0 => $steps - $index,
                                        type    => $type,
                                        sorted  => $sorted
                                       }
                );
                for my $node (@$nodes) {
                    my $rendering = ref $node ? $node->render() : $node;
                    $return .= defined $rendering ? $rendering : '';
                    if ($s->{template}{break}) {
                        $s->{template}{break} = 0;
                        last FOR;
                    }
                    if ($s->{template}{continue}) {
                        $s->{template}{continue} = 0;
                        next FOR;
                    }
                }
            }
            return $return;
        }
    );
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::For - Simple loop construct

=head1 Synopsis

    {% for x in (1..10) %}
        x = {{ x }}
    {% endfor %}

=head1 Description

For loops... uh, loop over collections.

=head2 Loop-scope Variables

During every for loop, the following helper variables are available for extra
styling needs:

=over

=item * C<forloop.length>

length of the entire for loop

=item * C<forloop.index>

index of the current iteration

=item * C<forloop.index0>

index of the current iteration (zero based)

=item * C<forloop.rindex>

how many items are still left?

=item * C<forloop.rindex0>

how many items are still left? (zero based)

=item * C<forloop.first>

is this the first iteration?

=item * C<forloop.last>

is this the last iternation?

=item * C<forloop.type>

are we looping through an C<ARRAY> or a C<HASH>?

=back

=head2 Attributes

There are several attributes you can use to influence which items you receive
in your loop:

=over

=item C<limit:int>

lets you restrict how many items you get.

=item C<offset:int>

lets you start the collection with the nth item.

=back

    # array = [1,2,3,4,5,6]
    {% for item in array limit:2 offset:2 %}
        {{ item }}
    {% endfor %}
    # results in 3,4

=head3 Reversing the Loop

You can reverse the direction the loop works with the C<reversed> attribute. To
comply with the Ruby lib's functionality, C<reversed> B<must> be the first
attribute.

    {% for item in collection reversed %} {{item}} {% endfor %}

=head3 Sorting

You can sort the variable with the C<sorted> attribute. This is an extention
beyond the scope of Liquid's syntax and thus incompatible but it's useful. The

    {% for item in collection sorted %} {{item}} {% endfor %}

If you are sorting a hash, the values are sorted by keys by default. You may
decide to sort by values like so:

    {% for item in hash sorted:value %} {{item.value}} {% endfor %}

...or make the default obvious with...

    {% for item in hash sorted:key %} {{item.key}} {% endfor %}

=head2 Numeric Ranges

Instead of looping over an existing collection, you can define a range of
numbers to loop through. The range can be defined by both literal and variable
numbers:

    # if item.quantity is 4...
    {% for i in (1..item.quantity) %}
        {{ i }}
    {% endfor %}
    # results in 1,2,3,4

=head2 Hashes

To deal with the possibility of looping through hash references, I have chosen
to extend the Liquid Engine's functionality. When looping through a hash, each
item is made a single key/value pair. The item's actual key and value are in
the C<item.key> and C<item.value> variables. ...here's an example:

    # where var = {A => 1, B => 2, C => 3}
    { {% for x in var %}
        {{ x.key }} => {{ x.value }},
    {% endfor %} }
    # results in {  A => 1, C => 3, B => 2, }

The C<forloop.type> variable will contain C<HASH> if the looped variable is a
hashref. Also note that the keys/value pairs are left unsorted.

=head2 C<else> tag

The else tag allows us to do this:

    {% for item in collection %}
        Item {{ forloop.index }}: {{ item.name }}
    {% else %}
        There is nothing in the collection.
    {% endfor %}

The C<else> branch is executed whenever the for branch will never be executed
(e.g. collection is blank or not an iterable or out of iteration scope).

=for basis https://github.com/Shopify/liquid/pull/56

=head1 TODO

Since this is a customer facing template engine, Liquid should provide some way
to limit L<ranges|Template::Liquid::Tag::For/"Numeric Ranges"> and/or depth to
avoid (functionally) infinite loops with code like...

    {% for w in (1..10000000000) %}
        {% for x in (1..10000000000) %}
            {% for y in (1..10000000000) %}
                {% for z in (1..10000000000) %}
                    {{ 'own' | replace:'o','p' }}
                {%endfor%}
            {%endfor%}
        {%endfor%}
    {%endfor%}

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Create your own filters">'s docs on custom
filter creation

L<Template::Liquid::Tag::Break|Template::Liquid::Tag::Break> and
L<Template::Liquid::Tag::Continue|Template::Liquid::Tag::Continue>

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of L<The Artistic License
2.0|http://www.perlfoundation.org/artistic_license_2_0>. See the F<LICENSE>
file included with this distribution or L<notes on the Artistic License
2.0|http://www.perlfoundation.org/artistic_2_0_notes> for clarification.

When separated from the distribution, all original POD documentation is covered
by the L<Creative Commons Attribution-Share Alike 3.0
License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>. See the
L<clarification of the
CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
