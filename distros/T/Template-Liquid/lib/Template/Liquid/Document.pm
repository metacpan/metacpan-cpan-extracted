package Template::Liquid::Document;
our $VERSION = '1.0.17';
require Template::Liquid::Variable;
require Template::Liquid::Utility;
use strict;
use warnings;
#
sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type    => 'Context',
                                   message => 'Missing template argument',
                                   fatal   => 1
        }
        if !defined $args->{'template'};
    return
        bless {template => $args->{'template'},
               parent   => $args->{'template'}
        }, $class;
}

sub parse {
    my ($class, $args, $tokens);
    (scalar @_ == 3 ? ($class, $args, $tokens) : ($class, $tokens)) = @_;
    my $s     = ref $class ? $class : $class->new($args);
    my %_tags = $s->{template}->tags;
NODE: while (my $token = shift @{$tokens}) {
        if ($token =~ $Template::Liquid::Utility::TagMatch) {
            my ($tag, $attrs) = (split ' ', $1, 2);
            my $package = $_tags{$tag};
            my $call    = $package ? $package->can('new') : ();
            if (defined $call) {
                my $_tag = $call->($package,
                                   {template => $s->{template},
                                    parent   => $s,
                                    tag_name => $tag,
                                    markup   => $token,
                                    attrs    => $attrs
                                   }
                );
                push @{$s->{'nodelist'}}, $_tag;
                if ($_tag->conditional_tag) {
                    push @{$_tag->{'blocks'}},
                        Template::Liquid::Block->new(
                                            {tag_name => $tag,
                                             attrs    => $attrs,
                                             template => $_tag->{template},
                                             parent   => $_tag
                                            }
                        );
                    $_tag->parse($tokens);
                    {    # finish previous block
                        ${$_tag->{'blocks'}[-1]}{'nodelist'}
                            = $_tag->{'nodelist'};
                        $_tag->{'nodelist'} = [];
                    }
                }
                elsif ($_tag->end_tag) {
                    $_tag->parse($tokens);
                }
            }
            elsif ($s->can('end_tag') && $tag =~ $s->end_tag) {
                $s->{'markup_2'} = $token;
                last NODE;
            }
            elsif ($s->conditional_tag && $tag =~ $s->conditional_tag) {
                $s->push_block({tag_name => $tag,
                                attrs    => $attrs,
                                markup   => $token,
                                template => $s->{template},
                                parent   => $s
                               },
                               $tokens
                );
            }
            else {
                raise Template::Liquid::Error {type => 'Syntax',
                                         message => 'Unknown tag: ' . $token};
            }
        }
        elsif ($token =~ $Template::Liquid::Utility::VarMatch) {
            my ($variable, $filters) = split qr[\s*\|\s*]o, $1, 2;
            my @filters;
            for my $filter (split $Template::Liquid::Utility::FilterSeparator,
                            $filters || '') {
                my ($filter, $args)
                    = split
                    $Template::Liquid::Utility::FilterArgumentSeparator,
                    $filter, 2;
                $filter =~ s[\s*$][]o;    # XXX - the splitter should clean...
                $filter =~ s[^\s*][]o;    # XXX -  ...this up for us.
                my @args
                    = !defined $args ? () : grep { defined $_ }
                    $args
                    =~ m[$Template::Liquid::Utility::VariableFilterArgumentParser]g;
                push @filters, [$filter, \@args];
            }
            push @{$s->{'nodelist'}},
                Template::Liquid::Variable->new(
                                               {template => $s->{template},
                                                parent   => $s,
                                                markup   => $token,
                                                variable => $variable,
                                                filters  => \@filters
                                               }
                );
        }
        else {
            push @{$s->{'nodelist'}}, $token;
        }
    }
    return $s;
}

sub render {
    my ($s) = @_;
    my $return = '';
    for my $node (@{$s->{'nodelist'}}) {
        my $rendering = ref $node ? $node->render() : $node;
        $return .= defined $rendering ? $rendering : '';
    }
    return $return;
}
sub conditional_tag { return $_[0]->{'conditional_tag'} || undef; }
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Document - Generic Top-level Object

=head1 Description

This shouldn't be used. ...unless you're really interested in how things work.
This is the grandfather class; everything is a child or subclass of this
object.

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
