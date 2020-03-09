package Template::Liquid::Tag::Case;
our $VERSION = '1.0.18';
use strict;
use warnings;
use base 'Template::Liquid::Tag::If';
require Template::Liquid::Error;
require Template::Liquid::Utility;
sub import { Template::Liquid::register_tag('case') }

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
    if ($args->{'attrs'} !~ m[\S$]o) {
        raise Template::Liquid::Error {
                       type    => 'Syntax',
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
        };
    }
    my $s = bless {name     => $args->{'tag_name'} . '-' . $args->{'attrs'},
                   blocks   => [],
                   tag_name => $args->{'tag_name'},
                   template => $args->{'template'},
                   parent   => $args->{'parent'},
                   markup   => $args->{'markup'},
                   value    => $args->{'attrs'},
                   first_block     => 0,
                   end_tag         => 'end' . $args->{'tag_name'},
                   conditional_tag => qr[^(?:else|when)$]o
    }, $class;
    return $s;
}

sub push_block {
    my ($s, $args) = @_;
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
        if !defined $args->{'attrs'} && $args->{'tag_name'} eq 'when';
    if ($args->{'tag_name'} eq 'when') {
        $args->{'attrs'} = join ' or ',
            map  { sprintf '%s == %s', $_, $args->{'parent'}{'value'} }
            grep { defined $_ }
            $args->{'attrs'} =~ m[(${Template::Liquid::Utility::Expression})
                        (?:(?:\s+or\s+|\s*\,\s*)
                           (${Template::Liquid::Utility::Expression}.*)
                        )?]ox;
    }
    my $block =
        Template::Liquid::Block->new({tag_name => $args->{'tag_name'},
                                      end_tag  => 'end' . $args->{'tag_name'},
                                      attrs    => $args->{'attrs'},
                                      template => $args->{'template'},
                                      parent   => $s
                                     }
        );

    # finish previous block if it exists
    ${$s->{'blocks'}[-1]}{'nodelist'} = $s->{'nodelist'}
        if scalar @{$s->{'blocks'}};
    $s->{'nodelist'} = [];    # Unline {%if%}, we *always* empty the

    # nodelist. This way, we ignore nodes that come before the first
    # when/else block just like Liquid
    push @{$s->{'blocks'}}, $block;
    shift @{$s->{'blocks'}}    # S::D->parse() pushes a dead first block
        if $s->{'first_block'}++ == 0;
    return $block;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Case - Switch Statement Construct

=head1 Description

If you need more conditions, you can use the C<case> tag. Note that, stuff that
comes before the first C<when> or C<else> is ignored. ...just as it is in
Liquid.

=head1 Synopsis

    {% case condition %}
        {% when 1 %}
            hit 1
        {% when 2 or 3 %}
            hit 2 or 3
        {% else %}
            ... else ...
    {% endcase %}

...or even...

    {% case template %}

        {% when 'label' %}
            // {{ label.title }}
        {% when 'product' %}
            // {{ product.vendor | link_to_vendor }} / {{ product.title }}
        {% else %}
            // {{page_title}
    {% endcase %}

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
