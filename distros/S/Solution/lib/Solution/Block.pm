package Solution::Block;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../lib';
    use Solution::Error;
    our @ISA = qw[Solution::Document];

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
             message => 'else tags are non-conditional: ' . $args->{'markup'},
             fatal   => 1
            }
            if $args->{'tag_name'} eq 'else' && $args->{'attrs'};
        my $self = bless {tag_name   => 'b-' . $args->{'tag_name'},
                          conditions => undef,
                          nodelist   => [],
                          template   => $args->{'template'},
                          parent     => $args->{'parent'},
        }, $class;
        $self->{'conditions'} = (
            $args->{'tag_name'} eq 'else' ?
                [1]
            : sub {    # Oh, what a mess...
                my @conditions
                    = split m[\s+\b(and|or)\b\s+],
                    $args->{parent}->{tag_name} eq 'for' ?
                    1
                    : (defined $args->{'attrs'} ? $args->{'attrs'} : '');
                my @equality;
                while (my $x = shift @conditions) {
                    push @equality, (
                        $x =~ m[\b(?:and|or)\b]    # XXX - ARG
                        ?
                            bless({template  => $args->{'template'},
                                   parent    => $self,
                                   condition => $x,
                                   lvalue    => pop @equality,
                                   rvalue =>
                                       Solution::Condition->new(
                                          {template => $args->{'template'},
                                           parent   => $self,
                                           attrs    => shift @conditions
                                          }
                                       )
                                  },
                                  'Solution::Condition'
                            )
                        : Solution::Condition->new(
                                          {attrs    => $x,
                                           template => $args->{'template'},
                                           parent   => $self,
                                          }
                        )
                    );
                }
                \@equality;
                }
                ->()
        );
        return $self;
    }
}
1;

=pod

=head1 NAME

Solution::Block - Simple Node Type

=head1 Description

There's not really a lot to say about basic blocks. The real action is in the
classes which make use of them or subclass it. See L<if|Solution::Tag::If>,
L<unless|Solution::Tag::Unless>, or L<case|Solution::Tag::Case>.

=head1 Bugs

Liquid's (and by extension L<Solution|Solution>'s) treatment of
compound inequalities is broken. For example...

    {% if 'This and that' contains 'that' and 1 == 3 %}

...would be parsed as if it were...

    if ( "'This" && ( "that'" =~ m[and] ) ) { ...

...but it should look like...

    if ( ( 'This and that' =~ m[that]) && ( 1 == 3 ) ) { ...

It's just... not pretty but I'll work on it.

=head1 See Also

See L<Solution::Condition|Solution::Condition> for a list of supported
inequalities.

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
