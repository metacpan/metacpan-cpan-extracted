package Template::Liquid::Tag::If;
our $VERSION = '1.0.23';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('if') }

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
    my $condition = $args->{'attrs'};
    my $s = bless {name            => $args->{'tag_name'} . '-' . $condition,
                   blocks          => [],
                   tag_name        => $args->{'tag_name'},
                   template        => $args->{'template'},
                   parent          => $args->{'parent'},
                   markup          => $args->{'markup'},
                   end_tag         => 'end' . $args->{'tag_name'},
                   conditional_tag => qr[^(?:else|else?if)$]o
    }, $class;
    return $s;
}

sub push_block {
    my ($s, $args) = @_;
    my $block
        = Template::Liquid::Block->new({tag_name => $args->{'tag_name'},
                                        attrs    => $args->{'attrs'},
                                        template => $args->{'template'},
                                        parent   => $s
                                       }
        );
    {    # finish previous block
        ${$s->{'blocks'}[-1]}{'nodelist'} = $s->{'nodelist'};
        $s->{'nodelist'} = [];
    }
    push @{$s->{'blocks'}}, $block;
    return $block;
}

sub render {
    my ($s) = @_;
    for my $block (@{$s->{'blocks'}}) {
        return $block->render() if grep {$_} @{$block->{'conditions'}};
    }
}
1;

=pod

=encoding UTF-8

=begin stopwords

Lütke jadedPixel

=end stopwords

=head1 NAME

Template::Liquid::Tag::If - Basic If/Elsif/Else Construct

=head1 Description

If I need to describe if/else to you... Oy. C<if> executes the statement once
if and I<only> if the condition is true. If the condition is false, the first
C<elseif> condition is evaluated. If that is also false it continues in the
same pattern until we find a true condition or a fallback C<else> tag.

=head2 Compound Inequalities

Liquid supports compound inequalities. Try these...

    {% if some.value == 3 and some.string contains 'find me' %}
        Wow! It's a match...
    {% elseif some.value == 4 or 3 < some.value %}
        Wow! It's a... different... match...
    {% endif %}

=head1 Bugs

Liquid's (and by extension L<Template::Liquid|Template::Liquid>'s) treatment of
compound inequalities is broken. For example...

    {% if 'This and that' contains 'that' and 1 == 3 %}

...would be parsed as if it were...

    if ( "'This" && ( "that'" =~ m[and] ) ) { ...

...but it I<should> look like...

    if ( ( 'This and that' =~ m[that]) && ( 1 == 3 ) ) { ...

It's just... not pretty but I'll work on it. The actual problem is in
L<Template::Liquid::Block|Template::Liquid::Block> if you feel like lending a
hand. Wink, wink.

=head1 See Also

See L<Template::Liquid::Condition|Template::Liquid::Condition> for a list of
supported inequality types.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias LÃ¼tke (http://blog.leetsoft.com/).

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
