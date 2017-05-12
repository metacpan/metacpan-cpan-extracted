package Object::Declare;

use 5.006;
use strict;
use warnings;

$Object::Declare::VERSION = '0.22';

sub import {
    my $class       = shift;
    my %args        = ((@_ and ref($_[0])) ? (mapping => $_[0]) : @_) or return;
    my $from        = caller;

    my $mapping     = $args{mapping} or return;
    my $aliases     = $args{aliases}    || {};
    my $declarator  = $args{declarator} || ['declare'];
    my $copula      = $args{copula}     || ['is', 'are'];

    # Both declarator and copula can contain more than one entries;
    # normalize into an arrayref if we only have on entry.
    $mapping    = [$mapping]    unless ref($mapping);
    $declarator = [$declarator] unless ref($declarator);
    $copula     = [$copula]     unless ref($copula);

    if (ref($mapping) eq 'ARRAY') {
        # rewrite "MyApp::Foo" into simply "foo"
        $mapping = {
            map {
                my $helper = $_;
                $helper =~ s/.*:://;
                (lc($helper) => $_);
            } @$mapping
        };
    }

    # Convert mapping targets into instantiation closures
    if (ref($mapping) eq 'HASH') {
        foreach my $key (keys %$mapping) {
            my $val = $mapping->{$key};
            next if ref($val); # already a callback, don't bother
            $mapping->{$key} = sub { scalar($val->new(@_)) };
        }
    }

    if (ref($copula) eq 'ARRAY') {
        # add an empty prefix to all copula
        $copula = { map { $_ => '' } @$copula }
    }

    # Install declarator functions into caller's package, remembering
    # the mapping and copula set for this declarator.
    foreach my $sym (@$declarator) {
        no strict 'refs';

        *{"$from\::$sym"} = sub (&) {
            unshift @_, ($mapping, $copula, $aliases);
            goto &_declare;
        };
    }

    # Establish prototypes (same as "use subs") so Sub::Override can work
    {
        no strict 'refs';
        _predeclare(
            (map { "$from\::$_" } keys %$mapping),
            (map { ("UNIVERSAL::$_", "$_\::AUTOLOAD") } keys %$copula),
        );
    }
}

# Same as "use sub".  All is fair if you predeclare.
sub _predeclare {
    no strict 'refs';
    no warnings 'redefine';
    foreach my $sym (@_) {
        *$sym = \&$sym;
    }
}

sub _declare {
    my ($mapping, $copula, $aliases, $code) = @_;
    my $from = caller;

    # Table of collected objects.
    my @objects;

    # Establish a lexical extent for overrided symbols; they will be
    # restored automagically upon scope exit.
    my %subs_replaced;
    my $replace = sub {
        no strict 'refs';
        no warnings 'redefine';
        my ($sym, $code) = @_;

        # Do the "use subs" predeclaration again before overriding, because
        # Sub::Override cannot handle empty symbol slots.  This is normally
        # redundant (&import already did that), but we do it here anyway to
        # guard against runtime deletion of symbol table entries.
        _predeclare($sym);

        # Now replace the symbol for real.
        $subs_replaced{$sym} ||= *$sym{CODE};
        *$sym = $code;
    };

    # In DSL (domain-specific language) mode; install AUTOLOAD to handle all
    # unrecognized calls for "foo is 1" (which gets translated to "is->foo(1)",
    # and UNIVERSAL to collect "is foo" (which gets translated to "foo->is".
    # The arguments are rolled into a Katamari structure for later analysis.
    while (my ($sym, $prefix) = each %$copula) {
        $replace->( "UNIVERSAL::$sym" => sub {
            # Turn "is some_field" into "some_field is 1"
            my ($key, @vals) = ref($prefix) ? $prefix->(@_) : ($prefix.$_[0] => 1) or return;
            # If the copula returns a ready-to-use katamari object,
            # don't try to roll it by ourself.
            return $key
                if ref($key) && ref($key) eq 'Object::Declare::Katamari';
            $key = $aliases->{$key} if $aliases and exists $aliases->{$key};
            unshift @vals, $key;
            bless( \@vals => 'Object::Declare::Katamari' );
        } );
        $replace->( "$sym\::AUTOLOAD" => sub {
            # Handle "some_field is $some_value"
            shift;

            my $field = our $AUTOLOAD;
            return if $field =~ /DESTROY$/;

            $field =~ s/^\Q$sym\E:://;

            my ($key, @vals) = ref($prefix) ? $prefix->($field, @_) : ($prefix.$field => @_) or return;

            $key = $aliases->{$key} if $aliases and exists $aliases->{$key};
            unshift @vals, $key;
            bless( \@vals, 'Object::Declare::Katamari' );
        } );
    }

    my @overridden = map { "$from\::$_" } keys %$mapping;
    # Now install the collector symbols from class mappings
    my $toggle_subs = sub {
        foreach my $sym (@overridden) {
            no strict 'refs';
            no warnings 'redefine';
            ($subs_replaced{$sym}, *$sym) = (*$sym{CODE}, $subs_replaced{$sym});
        }
    };

    while (my ($sym, $build) = each %$mapping) {
        $replace->("$from\::$sym" => _make_object($build => \@objects, $toggle_subs));
    }

    # Let's play Katamari!
    &$code;

    # Restore overriden subs
    while (my ($sym, $code) = each %subs_replaced) {
        no strict 'refs';
        no warnings 'redefine';
        *$sym = $code;
    }

    # In scalar context, returns hashref; otherwise preserve ordering
    return(wantarray ? @objects : { @objects });
}

# Make a star from the Katamari!
sub _make_object {
    my ($build, $schema, $toggle_subs) = @_;

    return sub {
        # Restore overriden subs
        no strict 'refs';
        no warnings 'redefine';

        my $name   = ( ref( $_[0] ) ? undef : shift );
        my $args   = \@_;
        my $damacy = bless(sub {
            $toggle_subs->();

            my $rv = $build->(
                ( $_[0] ? ( name => $_[0] ) : () ),
                map { $_->unroll } @$args
            );

            $toggle_subs->();

            return $rv;
        } => 'Object::Declare::Damacy');

        if (wantarray) {
            return ($damacy);
        } else {
            push @$schema, $name => $damacy->($name);
        }
    };
}

package Object::Declare::Katamari;

use overload "!" => \&negation, fallback => 1;

sub negation {
    my @katamari = @{$_[0]} or return ();
    $katamari[1] = !$katamari[1];
    return bless(\@katamari, ref($_[0]));
}

# Unroll a Katamari structure into constructor arguments.
sub unroll {
    my @katamari = @{$_[0]} or return ();
    my $field = shift @katamari or return ();
    my @unrolled;

    unshift @unrolled, pop(@katamari)->unroll
        while ref($katamari[-1]) eq __PACKAGE__;

    if (@katamari == 1) {
        # single value: "is foo"
        if ( ref( $katamari[0] ) eq 'Object::Declare::Damacy' ) {
            $katamari[0] = $katamari[0]->($field);
        }
        return($field => @katamari, @unrolled);
    }
    else {
        # Multiple values: "are qw( foo bar baz )"
        foreach my $kata (@katamari) {
            $kata = $kata->() if ref($kata) eq 'Object::Declare::Damacy';
        }
        return($field => \@katamari, @unrolled);
    }
}

1;

__END__

=head1 NAME

Object::Declare - Declarative object constructor

=head1 SYNOPSIS

    use Object::Declare ['MyApp::Column', 'MyApp::Param'];

    my %objects = declare {

    param foo =>
       !is global,
        is immutable,
        valid_values are qw( more values );

    column bar =>
        field1 is 'value',
        field2 is 'some_other_value',
        sub_params are param( is happy ), param ( is sad );

    };

    print $objects{foo}; # a MyApp::Param object
    print $objects{bar}; # a MyApp::Column object

    # Assuming that MyApp::Column::new simply blesses into a hash...
    print $objects{bar}{sub_params}[0]; # a MyApp::Param object
    print $objects{bar}{sub_params}[1]; # a MyApp::Param object

=head1 DESCRIPTION

This module exports one function, C<declare>, for building named
objects with a declarative syntax, similar to how L<Jifty::DBI::Schema>
defines its columns.

In list context, C<declare> returns a list of name/object pairs in the
order of declaration (allowing duplicates), suitable for putting into a hash.
In scalar context, C<declare> returns a hash reference.

Using a flexible C<import> interface, one can change exported helper
functions names (I<declarator>), words to link labels and values together
(I<copula>), and the table of named classes to declare (I<mapping>):

    use Object::Declare
        declarator  => ['declare'],     # list of declarators
        copula      => {                # list of words, or a map
            is  => '',                  #  from copula to label prefixes,
            are => '',                  #  or to callback that e.g. turns
            has => sub { has => @_ },   #  "has X" to "has is X" and
                                        #  "X has 1" to "has is [X => 1]"
        },
        aliases     => {                # list of label aliases:
            more => 'less',             #  turns "is more" into "is less"
                                        #  and "more is 1" into "less is 1"
        },
        mapping     => {
            column => 'MyApp::Column',  # class name to call ->new to
            param  => sub {             # arbitrary coderef also works
                bless(\@_, 'MyApp::Param');
            },
        };

After the declarator block finishes execution, all helper functions are
removed from the package.  Same-named functions (such as C<&is> and C<&are>)
that existed before the declarator's execution are restored correctly.

=head1 NOTES

If you export the declarator to another package via C<@EXPORT>, be sure
to export all mapping keys as well.  For example, this will work for the
example above:

    our @EXPORT = qw( declare column param );

But this will not:

    our @EXPORT = qw( declare );

The copula are not turned into functions, so there is no need to export them.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2006, 2007 by Audrey Tang <cpan@audreyt.org>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
