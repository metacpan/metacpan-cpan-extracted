package Template::Liquid::Variable;
our $VERSION = '1.0.20';
use strict;
use warnings;
use base 'Template::Liquid::Document';
use Template::Liquid::Error;

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type     => 'Context',
                                   template => $args->{template},
                                   message  => 'Missing template argument',
                                   fatal    => 1
        }
        if !defined $args->{'template'} ||
        !$args->{'template'}->isa('Template::Liquid');
    raise Template::Liquid::Error {type     => 'Context',
                                   template => $args->{template},
                                   message  => 'Missing parent argument',
                                   fatal    => 1
        }
        if !defined $args->{'parent'};
    raise Template::Liquid::Error {
                   template => $args->{template},
                   type     => 'Syntax',
                   message => 'Missing variable name in ' . $args->{'markup'},
                   fatal   => 1
        }
        if !defined $args->{'variable'};
    return bless $args, $class;
}

sub render {
    my ($s) = @_;
    my $val = $s->{template}{context}->get($s->{variable});
    {    # XXX - Duplicated in Template::Liquid::Assign::render
        if (scalar @{$s->{filters}}) {
            my %_filters = $s->{template}->filters;
        FILTER: for my $filter (@{$s->{filters}}) {
                my ($name, $args) = @$filter;
                my $package = $_filters{$name};
                my $call    = $package ? $package->can($name) : ();
                if ($call) {

            #use Data::Dump qw[dump];
            #warn sprintf 'Before %s(%s): %s', $name, dump($args), dump($val);
            #warn $s->{template}{context}->get($args->[0]) if ref $args;
                    $val = $call->(
                              $val,
                              map { $s->{template}{context}->get($_); } @$args
                    );

            #warn sprintf 'After  %s(%s): %s', $name, dump($args), dump($val);
                    next FILTER;
                }
                raise Template::Liquid::Error {type     => 'UnknownFilter',
                                               template => $s->{template},
                                               message  => $name,
                                               fatal    => 0
                };
            }
        }
    }

    #warn '---> ' . $s->{variable} . ' ===> ' .$val;
    return join '', @$val      if ref $val eq 'ARRAY';
    return join '', keys %$val if ref $val eq 'HASH';
    return $val;
}
1;

=pod

=head1 NAME

Template::Liquid::Variable - Generic Value Container

=head1 Description

This class can hold just about anything. This is the class responsible for
handling echo statements:

    Hello, {{ name }}. It's been {{ lastseen | date_relative }} since you
    logged in.

Internally, a variable is the basic container for everything; lists, scalars,
hashes, and even objects.

L<Filters|Template::Liquid::Filters> are applied to variables during the render
stage.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2022 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

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
