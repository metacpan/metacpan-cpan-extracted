package Template::Liquid::Tag::Capture;
our $VERSION = '1.0.14';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
BEGIN { use base 'Template::Liquid::Tag'; }
sub import { Template::Liquid::register_tag('capture') }

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
    if ($args->{'attrs'} !~ qr[^(\S+)\s*?$]o) {
        raise Template::Liquid::Error {
                       type    => 'Syntax',
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
        };
    }
    my $s = bless {name          => 'c-' . $1,
                   nodelist      => [],
                   tag_name      => $args->{'tag_name'},
                   variable_name => $1,
                   end_tag       => 'end' . $args->{'tag_name'},
                   template      => $args->{'template'},
                   parent        => $args->{'parent'},
                   markup        => $args->{'markup'},
    }, $class;
    return $s;
}

sub render {
    my ($s) = @_;
    my $var = $s->{'variable_name'};
    my $val = '';
    for my $node (@{$s->{'nodelist'}}) {
        my $rendering = ref $node ? $node->render() : $node;
        $val .= defined $rendering ? $rendering : '';
    }
    $s->{template}{context}->set($var, $val);
    return '';
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Capture - Extended variable assignment construct

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

The L<assign|Template::Liquid::Tag::Assign> tag.

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
