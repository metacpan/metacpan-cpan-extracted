package TAP::Filter::Iterator;

use warnings;
use strict;
use Carp;
use List::Util qw( max );
use TAP::Parser::Result;

sub _thing_needs_coderef {
    my $thing_name = shift;
    return sub {
        my $thing = shift;
        croak "$thing_name must be a coderef"
          unless 'CODE' eq ref $thing;
    };
}

BEGIN {
    # Methods to alias from TAP::Filter
    my @ALIASES = qw( ok );

    # Named callback hooks
    my @HOOKS = qw( inspect init done );

    my %VALIDATOR = (
        next_iterator => sub {
            my $iter = shift;
            croak "Iterator must have a 'tokenize' method"
              unless defined $iter
                  && UNIVERSAL::can( $iter, 'can' )
                  && $iter->can( 'tokenize' );
        },
        parser => sub {
            my $parser = shift;
            croak "parser must be a TAP::Parser"
              unless !defined $parser
                  || ( UNIVERSAL::can( $parser, 'isa' )
                      && $parser->isa( 'TAP::Parser' ) );
        },
        # *_hook methods
        (
            map { ( "${_}_hook" => _thing_needs_coderef( $_ ) ) } @HOOKS
        ),
    );

    for my $alias ( @ALIASES ) {
        no strict 'refs';
        *{$alias} = *{"TAP::Filter::$alias"};
    }

    for my $hook ( @HOOKS ) {
        no strict 'refs';
        my $hook_accessor = "${hook}_hook";
        *{$hook} = sub {
            my $self = shift;
            if ( my $hook_func = $self->$hook_accessor() ) {
                return $hook_func->( @_ );
            }
            return @_;
        };
    }

    while ( my ( $acc, $valid ) = each %VALIDATOR ) {
        no strict 'refs';
        *{$acc} = sub {
            my $self = shift;
            if ( @_ ) {
                $valid->( my $val = shift );
                $self->{$acc} = $val;
            }
            return $self->{$acc};
        };
    }
}

=head1 NAME

TAP::Filter::Iterator - A TAP filter

=head1 VERSION

This document describes TAP::Filter::Iterator version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use TAP::Parser;
    use TAP::Filter::Iterator;

    my $parser = TAP::Parser->new({ source => 'test.t' });
    my $filter = TAP::Filter::Iterator->new;
    $filter->add_to_parser( $parser );

=head1 DESCRIPTION

C<TAP::Filter> allows arbitrary filters to be placed in the TAP
processing pipeline of L<TAP::Harness>. Installed filters see the parsed
TAP stream a line at a time and can modify the stream by

=over

=item * replacing a result

=item * injecting extra results

=item * removing results

=back

An individual filter in the processing pipeline is a
C<TAP::Filter::Iterator> or a subclass of it. Here is a simple filter:

    package MyFilter;

    use strict;
    use warnings;
    use base qw( TAP::Filter::Iterator );

    sub inspect {
        my ( $self, $result ) = @_;
        # Perform some manipulation here...
        return $result;
    }

    1;

The C<inspect> method is called for each line of TAP. The C<$result>
argument is an instance of L<TAP::Parser::Result>, the class that
represents TAP tokens within L<TAP::Parser>. The return value of
C<inspect> is a list of results that will replace the result being
processed.

Here's a simple C<inspect> implementation that flags an error for any
test that has no description:

    sub inspect {
        my ( $self, $result ) = @_;
        if ( $result->is_test ) {
            my $description = $result->description;
            unless ( defined $description && $description =~ /\S/ ) {
                return (
                    $result,
                    TAP::Filter->ok(
                        ok => 0,
                        description =>
                          'Preceding test has no description'
                    )
                );
            }
        }
        return $result;
    }

Note that C<inspect> sees all TAP tokens; not just those that represent
test results. In this case I'm only interested in test results so I call
C<is_test> to check the type of the result.

If I have a test I then call C<description> to get its descriptive text.
If the description is undefined or contains no non-blank characters I
return the original C<$result> followed by a new, failed test result
that I synthesize by calling C<< TAP::Filter->ok >>.

By returning a pair of values I'm adding an extra result to the TAP
stream. The filter automatically adjust's C<TAP::Parser>'s notion of how
many tests have been planned and renumbers subsequent test results to
account for the additional result.

Any number of additional tests may be injected into the TAP stream in
this way. It is not necessary to return the original C<$result> as
part of the list; the returned list can consist solely of new,
synthetic tokens. If C<$result> is present it need not be the first item
in the list; that is, it is legal to inject additional results before or
after the original C<$result>.

Note that the result tokens you return may be modified by
C<TAP::Filter::Iterator>; for example tests may be renumbered. For this
reason you should not retain a reference to the returned results and
expect them to remain unaltered and should not use the same result
instance more than once.

To remove a token from the TAP stream return an empty list from
C<inspect>.

=head2 Filter lifecycle

When a filter is loaded by L<TAP::Filter> the same filter instance may
be used to process the output of multiple test files. If a filter has
state that it would like to reset before each file it should override
the C<init> method:

    sub init {
        my $self = shift;
        $self->{_test_count} = 0; # for example
    }

Similarly a filter that needs to clean up at the end of each file may
override C<done>:

    sub done {
        my $self = shift;
        close $self->{_log_file}; # for example
    }

=head2 An alternative to subclassing

Instead of subclassing C<TAP::Filter::Iterator> you may use it directly
as a filter by supplying one, two or three closures that correspond to
the C<inspect>, C<init> and C<done> methods:

    my $filter = TAP::Filter::Iterator->new(
        sub {   # inspect
            my $result = shift;
            return $result;
        },
        sub {   # init
            $count = 0;
        },
        sub {   # done
            close $log_file;
        }
    );

Note that unlike the corresponding methods the anonymous subroutines are
not passed a C<$self> reference. In all other ways their interface is
the same.

=head1 INTERFACE

=head2 C<< new >>

Create a new C<TAP::Filter::Iterator>. You may optionally supply one,
two or three subroutine references that provide handlers for C<inspect>,
C<init> and C<done>.

Subclasses that wish to provide their own constructor should look
like this:

    package MyFilter;
    use base qw( TAP::Filter::Iterator );

    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new;
        # Perform our own initialisation
        # Return instance
        return $self;
    }

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->inspect_hook( shift ) if @_;
    $self->init_hook( shift )    if @_;
    $self->done_hook( shift )    if @_;

    return $self;
}

=head2 C<< add_to_parser >>

Add this filter to the specified C<TAP::Parser>. Filters must be added
after the parser is created but before the first TAP is read through it.

    $filter->add_to_parser( $parser );

When filters are loaded by L<TAP::Filter> C<add_to_parser> is called
automatically at the appropriate time.

=cut

sub add_to_parser {
    my ( $self, $parser ) = @_;
    $self = $self->new unless ref $self;
    $self->parser( $parser );
    $self->next_iterator( $parser->_grammar );
    $parser->_grammar( $self );
    $self->_recycle;

    return;
}

sub _recycle {
    my $self = shift;
    delete $self->{_iter};
    $self->{_plan_adjust} = 0;
    $self->init;
}

sub _set_test_number {
    my ( $test, $number ) = @_;
    $test->_number( $number );

    # Nasty encapsulation violation!
    if ( exists $test->{raw} ) {
        $test->{raw} =~ s/^((?:not\s+)?ok\s+)(?:\d+|\*)/$1$number/;
    }
}

sub _set_plan_count {
    my ( $plan, $count ) = @_;

    # Nasty encapsulation violation!
    $plan->{tests_planned} = $count;
}

sub _iter {
    my $self = shift;
    my $iter = $self->next_iterator;

    my @queue       = ();
    my $in_number   = 0;
    my $out_number  = 0;
    my $last_adjust = 0;

    my $renumber = sub {
        my $result = shift;
        if ( $result->is_test ) {
            $out_number++;
            my $number = $result->number;
            _set_test_number( $result,
                  $number == $in_number || $number == 0
                ? $out_number
                : max( 1, $number + $out_number - $in_number ) );
        }
        elsif ( $result->is_plan ) {
            my $adjust = $out_number - $in_number;
            _set_plan_count( $result,
                $result->tests_planned + $adjust );
        }
    };

    return sub {
        my $result;

        RESULT: {
            if ( @queue ) {
                $result = shift @queue;
            }
            else {
                $result = $iter->tokenize;
                if ( defined $result ) {
                    $in_number++ if $result->is_test;
                    my @batch = grep defined, $self->inspect( $result );

                    for my $test ( @batch ) {
                        $renumber->( $test );
                    }

                    push @queue, @batch;

                    # Patch up the parser's test count. We need to do
                    # this continuously because the parser checks test
                    # numbers against the plan as it goes.
                    my $adjust = $out_number - $in_number;
                    $self->_adjust_test_count( $adjust - $last_adjust );
                    $last_adjust = $adjust;
                    redo RESULT;
                }
            }
        }

        unless ( defined $result ) {
            # Drop parser reference at end of stream to remove circular
            # references.
            $self->done;
            $self->parser( undef );
        }

        return $result;
    };
}

=head2 C<< tokenize >>

C<TAP::Filter::Iterator>s implement C<tokenize> so that they can stand
in for a L<TAP::Parser::Grammar>. C<TAP::Parser> calls C<tokenize> to
read the next token from the TAP stream. If you wish to use a filter
directly you may call C<tokenize> repeatedly to read tokens. At the end
of the TAP token stream C<tokenize> returns C<undef>.

=cut

sub tokenize {
    my $self = shift;
    return ( $self->{_iter} ||= $self->_iter )->();
}

sub _adjust_test_count {
    my ( $self, $count ) = @_;
    return unless $count;
    my $parser = $self->parser;
    if ( defined( my $tests_planned = $parser->tests_planned ) ) {
        $parser->tests_planned(
            $tests_planned + $count + $self->{_plan_adjust} );
        $self->{_plan_adjust} = 0;
    }
    else {
        # No plan yet - so remember the offset
        $self->{_plan_adjust} += $count;
    }
}

=head2 C<< inspect >>

Override C<inspect> in a subclass to filter the TAP stream. Called for
each token in the TAP stream. Returns a list of tokens to replace the
input token. See the example implementation of C<inspect> above.

It is not necessary for subclasses to call the superclass C<inspect>.

=head2 C<< init >>

Called before the first TAP token in each test's output is passed to
C<inspect>. Override in a subclass to perform custom initialisation.

=head2 C<< done >>

Called after the last token in a TAP stream has been read. Override to
perform custom cleanup.

=head1 Utility methods

=head2 C<< ok >>

A convenience method for creating new test results to inject into the
TAP stream. This method is an alias for C<TAP::Filter::ok> provided here
for convenient use in subclasses. See L<TAP::Filter> for full documentation.

=head1 Accessors

A C<TAP::Filter::Iterator> has a number of attributes which may be
retrieved or set using the following accessors. To read a value call the
accessor with no arguments:

    my $parser = $filter->parser;

To set the value pass it as an argument:

    $filter->parser( $new_parser );

In many cases it will not be necessary to use these accessors.

=head2 C<< inspect_hook >>

Get or set the closure that the default implementation of C<inspect>
delegates to. This is only relevant if you are using the default
implementation of C<inspect>. Normally closures are passed to C<new>;
see the documentation for C<new> above for more details.

=head2 C<< init_hook >>

Get or set the C<init> closure.

=head2 C<< done_hook >>

Get or set the C<done> closure.

=head2 C<< next_iterator >>

Multiple C<TAP::Filter::Iterator>s may be chained together. The
parser's original C<TAP::Parser::Grammar> tokeniser is at the end of
the iterator chain. An iterator's C<next_iterator> attribute contains a
reference to the next iterator in the chain.

=head2 C<< parser >>

A C<TAP::Filter::Iterator> has a reference, stored in the C<parser>
attribute, to the parser to which it is attached so that it can update
the parser's test count dynamically.

=cut

1;
__END__

=head1 Implementation details and caveats

A filter may vary the number of tests that appear in a TAP stream. To
avoid a plan error it must dynamically adjust the C<TAP::Parser>'s
test count. This is normally effective but may interract badly with
other C<TAP::Parser> features in certain cases.

In particular if you are spooling TAP to a file (by passing the C<spool>
option to C<TAP::Parser>) the plan line that is output to the file will
be incorrect if the filter adjusts the number of tests. Without
buffering the entire TAP stream this is hard to avoid; the plan token
will already have been spooled to disk when the test count adjustments
are applied.

=head1 CONFIGURATION AND ENVIRONMENT

TAP::Filter::Iterator requires no configuration files or environment
variables.

=head1 DEPENDENCIES

C<TAP::Filter::Iterator> requires L<Test::Harness> version 3.11 or
later.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-tap-filter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
