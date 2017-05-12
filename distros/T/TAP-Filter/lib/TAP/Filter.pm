package TAP::Filter;

use warnings;
use strict;
use Carp qw( confess croak );
use TAP::Filter::Iterator;

use base qw( TAP::Harness );

=head1 NAME

TAP::Filter - Filter TAP stream within TAP::Harness

=head1 VERSION

This document describes TAP::Filter version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

In a program:

    use TAP::Filter qw( MyFilter );

    my $harness = TAP::Filter->new;
    $harness->runtests( @tests );

With prove:

    prove --harness=TAP::Filter=MyFilter -rb t

=head1 DESCRIPTION

C<TAP::Filter> allows arbitrary filters to be placed in the TAP
processing pipeline of L<TAP::Harness>. Installed filters see the parsed
TAP stream a line at a time and can modify the stream by

=over

=item * replacing a result

=item * injecting extra results

=item * removing results

=back

C<TAP::Filter> exists mainly to load a number of filters into the TAP
processing pipeline. Filters are generally subclasses of
L<TAP::Filter::Iterator>. See the documentation for that module for
information about writing filters.

=head2 Loading filters

Filters may be installed into the TAP processing pipeline in a number of
different ways...

=head3 From the prove command line

The C<prove> command that is supplied with L<Test::Harness> allows tests
to be run interactively from the command line. By default it will use
L<TAP::Harness> to run these tests it can be told to use a different
harness. C<TAP::Filter> (which is a subclass of L<TAP::Harness>) may be
used with C<prove> in this way:

    prove --harness=TAP::Filter=MyFilter,OtherFilter -rb t

C<TAP::Filter> will attempt to load two filters, C<MyFilter> and
C<OtherFilter>. If the name of the filter class to be loaded starts with
C<TAP::Filter::> that prefix may be omitted, so the example above would
load filter classes called C<TAP::Filter::MyFilter> and
C<TAP::Filter::OtherFilter>.

=head3 C<< use TAP::Filter qw( MyFilter ) >>

If you are writing a program that uses L<TAP::Harness> you can load
filters by replacing

    use TAP::Harness;
    my $harness = TAP::Harness->new;

with

    use TAP::Filter qw( MyFilter OtherFilter );
    my $harness = TAP::Filter->new;

As with the prove command line invocation above C<TAP::Filter> will
attempt to load the specified filter classes from the C<TAP::Filter::>
namespace. If that fails the classnames are taken to be absolute.

=head3 Calling C<< TAP::Filter->add_filter >>

As an alternative to the concise filter loading notation above filters
may be loaded by calling C<add_filter>:

    use TAP::Filter;
    TAP::Filter->add_filter( 'MyFilter' );
    TAP::Filter->add_filter( 'OtherFilter' );
    my $harness = TAP::Filter->new;

Multiple filters may be loaded with a single call to C<add_filter>:

    TAP::Filter->add_filter( 'MyFilter', 'OtherFilter' );

You may also pass a reference to a filter instance:

    my $my_filter = TAP::Filter::MyFilter->new;
    TAP::Filter->add_filter( $my_filter );

=head2 Filter scope

C<TAP::Filter> maintains a single, global list of installed filters.
Once loaded filters can not be removed. If either of these features
proves problematic let me know and I'll consider alternatives.

=head1 INTERFACE

=head2 C<< add_filter >>

Add one or more filters to C<TAP::Filter>'s filter chain. Each argument
to C<add_filter> may be either

=over

=item * a partial class name

=item * a complete class name

=item * a filter instance

=back

If the filter's class name begins with C<TAP::Filter::> it is only
necessary to supply the trailing portion of the name:

    # Looks for TAP::Filter::Foo::Bar then plain Foo::Bar
    TAP::Filter->add_filter( 'Foo::Bar' );

=cut

sub _filter_from_class_name {
    my $class = shift;
    my $name  = shift;
    return $name if !defined $name || ref $name;
    my @err = ();
    for my $prefix ( 'TAP::Filter::', '' ) {
        my $class_name = $prefix . $name;
        eval "use $class_name";
        return $class_name->new unless $@;
        push @err, $@;
    }
    croak "Can't load filter class for $name\n", join( '', @err );
}

{
    my @Filter = ();

    sub add_filter {
        my $class = shift;
        for my $name ( @_ ) {
            my $filter = $class->_filter_from_class_name( $name );
            croak "Filter must have a 'add_to_parser' method"
              unless defined $filter
                  && UNIVERSAL::can( $filter, 'can' )
                  && $filter->can( 'add_to_parser' );
            push @Filter, $filter;
        }
    }

=head2 C<< get_filters >>

Returns a list of currently installed filters. Each item in the list
will be a reference to an instantiated filter - even if the
corresponding filter was specified by class name.

=cut

    sub get_filters {
        my $class = shift;
        return @Filter;
    }
}

=head2 C<< make_parser >>

Subclassed from C<TAP::Harness>. Create a new C<TAP::Parser> and install
any registered filters in its TAP processing pipeline.

Study the implementation of C<make_parser> if you need to implement an
alternative filter loading scheme.

=cut

sub make_parser {
    my ( $self, @args ) = @_;

    my ( $parser, $session ) = $self->SUPER::make_parser( @args );

    for my $filter ( reverse $self->get_filters ) {
        $filter->add_to_parser( $parser );
    }

    return ( $parser, $session );
}

sub import {
    my $class = shift;
    $class->add_filter( @_ );
}

=head2 C<< ok >>

A convenience method for creating new test results to inject into the
TAP stream.

    my $result = TAP::Filter->ok(
        ok          => 1,          # test passed
        description => 'A test',
    );

The returned result is an instance of L<TAP::Parser::Result> suitable
for feeding into the TAP stream. See L<TAP::Filter::Iterator> for more
information about manipulating the TAP stream.

The arguments to C<ok> are a number of key, value pairs. The following
keys are recognised:

=over

=item C<ok>

Boolean. Whether the test passed.

=item C<description>

The textual description of the test.

=item C<directive>

A TODO or SKIP directive.

=item C<explanation>

Text explaining why the test is a skip or todo.

=back

=cut

sub _load_result_maker {
    my @classes = (
        [ 'TAP::Parser::ResultFactory' => 'make_result' ],
        [ 'TAP::Parser::Result'        => 'new' ]
    );

    for my $ctor ( @classes ) {
        my ( $pkg, $method ) = @$ctor;
        eval "use $pkg ()";
        unless ( $@ ) {
            return sub {
                return $pkg->$method( @_ );
            };
        }
    }

    confess "Can't load a suitable TAP::Parser::Result"
      . " factory class, tried ", join( ', ', @classes ), "\n";
}

{
    my $result_maker = undef;
    sub _result_maker { $result_maker ||= _load_result_maker }
}

sub _trim {
    my $data = shift;
    return '' unless defined $data;
    $data =~ s/^\s+//;
    $data =~ s/\s+$//;
    return $data;
}

sub _escape {
    my $str = shift;
    $str =~ s/([#\\])/\\$1/g;
    return $str;
}

sub _make_raw {
    my $spec = shift;
    my @raw = ( $spec->{ok}, '*' );
    push @raw, _escape( $spec->{description} )
      if $spec->{description};
    if ( my $dir = $spec->{directive} ) {
        push @raw, "# $dir";
        push @raw, _escape( $spec->{explanation} )
          if $spec->{explanation};
    }
    return join ' ', @raw;
}

{
    my %spec_filter = (
        type        => sub { 'test' },
        test_num    => sub { 0 },
        explanation => sub { _trim( shift ) },
        description => sub {
            my $desc = _trim( shift );
            return $desc ? "- $desc" : '';
        },
        directive => sub {
            my $dir = shift;
            return uc( defined $dir ? $dir : '' );
        },
        ok => sub { $_[0] ? 'ok' : 'not ok' },
    );

    sub ok {
        my $class = shift;
        croak "ok needs a number of name => value pairs"
          if @_ & 1;
        my %spec = @_;

        for my $name ( keys %spec_filter ) {
            $spec{$name} = $spec_filter{$name}->( $spec{$name} );
        }

        $spec{raw} = _make_raw( \%spec );
        return _result_maker()->( \%spec );
    }
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT

TAP::Filter requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<TAP::Filter> requires L<Test::Harness> version 3.11 or later.

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
