package Template::Liquid::Tag::Increment;
our $VERSION = '1.0.18';
use strict;
use warnings;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('increment') }

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
                    message => 'Unused argument list in ' . $args->{'markup'},
                    fatal   => 1
        }
        if defined $args->{'attrs'} && $args->{'attrs'} !~ m[\S$]o;
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
                     type => 'Syntax',
                     message =>
                         sprintf(
                         q[Syntax Error in '%s %s' - Valid syntax: %s [name]],
                         $args->{'tag_name'}, $args->{'attrs'}, $class->_me()
                         ),
                     fatal => 1
        };
    }

    #$name = $args->{'tag_name'} . '-' . $name;
    if (defined $args->{'template'}{document}->{'_INCREMENTS'}{$name}) {
        $s = $args->{'template'}{document}->{'_INCREMENTS'}{$name};
    }
    else {
        $s = bless {name     => $name,
                    blocks   => [],
                    tag_name => $args->{'tag_name'},
                    add      => $class->_direction(),
                    template => $args->{'template'},
                    parent   => $args->{'parent'},
                    markup   => $args->{'markup'},
                    value    => $class->_initial()
        }, $class;
        $args->{'template'}{document}->{'_INCREMENTS'}{$name} = $s;
    }
    return $s;
}
sub _initial {0}

sub _direction {
    1;
}
sub _me {'increment'}

sub render {
    my ($s) = @_;
    my $name = $s->{template}{context}->get($s->{'name'}) || $s->{'name'};
    $s = $s->{template}{document}->{'_INCREMENTS'}{$name} || $s;
    my $node = $s->{'value'};
    my $return
        = ref $node ? $node->render() : $s->{template}{context}->get($node);
    $s->{'value'} += $s->{'add'};
    return $return;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Increment - Document-level Persistant Number

=head1 Description

Creates a new number variable, and increases its value by one every time it is
called. The initial value is C<0>.

=head1 Synopsis

    {% increment my_counter %}
    {% increment my_counter %}
    {% increment my_counter %}

...will result in...

    0
    1
    2

=head1 Notes

Variables created through the C<increment> tag are independent from variables
created through assign or capture.

In the example below, a variable named "var" is created through assign. The
C<increment> tag is then used several times on a variable with the same name.
Note that the C<increment> tag does not affect the value of "var" that was
created through C<assign>.

    {% assign var = 10 %}
    {% increment var %}
    {% increment var %}
    {% increment var %}
    {{ var }}

...would print...

    0
    1
    2
    10

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

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
