# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer.pm 43085 2008-03-01T12:28:42.888222Z daisuke  $

package R::Writer;
use strict;
use warnings;
use 5.008;
use base qw(Class::Accessor::Fast);
use R::Writer::Call;
use R::Writer::Encoder;
use R::Writer::Range;
use R::Writer::Var;

__PACKAGE__->mk_accessors($_) for qw(encoder statements);

our $VERSION = '0.00001';
use Sub::Exporter -setup => {
    exports => [ 'R' ]
};

sub R { return __PACKAGE__->new(@_) }

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new({
        encoder    => R::Writer::Encoder->new,
        @_,
        statements => [],
        delimiter  => undef,
    });
    return $self;
}

sub __push_statement { push @{ $_[0]->statements }, $_[1]; }

# Call is a statement to call functions
sub call
{
    my ($self, $function, @args) = @_;

    # If this is the end of the call chain, then push the
    # statement. Otherwise, return it
    my $end_of_call_chain = ! defined wantarray;
    my $call = R::Writer::Call->new(
        call => $function,
        args => [@args],
        end_of_call_chain => $end_of_call_chain,
    );

    if ($end_of_call_chain) {
        $self->__push_statement( $call );
    }
    return $call;
}

BEGIN
{
    foreach my $method qw(c expression) {
        eval sprintf(<<'        EOSUB', $method, $method);
            sub %s {
                my $self = shift;
                return R::Writer::Call->new(
                    call => '%s',
                    args => [ @_ ],
                );
            }
        EOSUB
        die if $@;
    }
}

sub var
{
    my ($self, $var, $value) = @_;

    my $obj = R::Writer::Var->new($var, $value, $self);
    $self->__push_statement($obj);
    return $obj;
}

sub range
{
    my ($self, $start, $end) = @_;
    my $obj = R::Writer::Range->new($start, $end);
    $obj;
}

# Turn myself into a string
sub as_string
{
    my $self = shift;
    my $ret = "";

    for my $s (@{$self->{statements}}) {
        my $delimiter = defined $s->{delimiter}  ? $s->{delimiter} : ";";
        if (my $c = $s->{code}) {
            $ret .= $c;
        }
        else {
            $ret .= $s->as_string($self);
        }
        $ret .= $delimiter unless $ret =~ /$delimiter\s*$/s;
        $ret .= "\n";
    }
    return $ret;
}

# Turn arbitrary objects to string
sub __obj_as_string
{
    my ($self, $obj) = @_;

    my $ref = ref($obj);

    if ($ref eq 'CODE') {
        return $self->__obj_as_string($obj->());
    }
    elsif ($ref =~ /^R::Writer/) {
        return $obj->as_string($self);
    }
    elsif ($ref eq "SCALAR") {
        return $$obj
    }
    elsif ($ref eq 'ARRAY') {
        my @ret = map {
            $self->__obj_as_string($_)
        } @$obj;

        return "[" . join(",", @ret) . "]";
    }
    elsif ($ref eq 'HASH') {
        my %ret;
        while (my ($k, $v) = each %$obj) {
            $ret{$k} = $self->__obj_as_string($v)
        }
        return "{" . join (",", map { $self->encoder->encode($_) . ":" . $ret{$_} } keys %ret) . "}";
    }
    else {
        return $self->encoder->encode($obj)
    }
}

sub save
{
    my ($self, $file) = @_;

    my $fh;
    my $close = 1;
    my $ref = ref $file;

    if ($ref && ( $ref eq 'GLOB' || eval { $file->can('print') } )) {
        $close = 0;
        $fh = $file;
    } else {
        open($fh, '>', $file) or die "Failed to open $file for writing: $!";
    }
    print $fh $self->as_string;
    close($fh) if $close;
}

sub reset { shift->statements([]) }

1;

__END__

=head1 NAME 

R::Writer - Generate R Scripts From Perl

=head1 SYNOPSIS

  use R::Writer;

  {
    # x <- 1;
    # y <- x + 1;
    # cat(y);

    my $R = R::Writer->new();
    $R->var(x => 1);
    $R->var(y => 'x + 1');
    $R->call('cat' => $R->expr('a * x ^ 2 + 1') );

    print $R->as_string;
    # or save to a file
    $R->save('file');
  }

=head1 DISCLAIMER

** THIS SOFTWARE IS IN ALPHA ** Patches, comments, and contributions are
very much welcome. I'm not really a statistics guy. I just happen to write
Perl code to do it.

I'm sure there are bunch of bugs lurking, but I'd like this module to be
useful, so please let me know if there are problems or missing features.

=head1 DESCRIPTION

R::Writer is a tool to generate R scripts for the "R" Statistical Computing
Tool from within Perl.

It is intended to be a builder tool -- for example, you have a lot of data
in your database, and you want to feed it to R -- and not necessarily a
"sexy" interface to build R scripts like JavaScript::Writer.

Each call constitutes a statement. Unlike JavaScript::Writer (from which this
module was originally based off), you should not be using call chaining to 
chain statement calls.

=head1 EXAAMPLE

=head2 DECLARING A VARIABLE

If you simply want to declare a variable and set the value to a particular
value, you can use the var() method:

  my $value = 1;
  $R->var(x => $value);

This will yield to 'x <- 1;'.

If you want to assign result of an arithmetic expression, you need to specify
the actual string:

  $R->var( y => 'x + 1' );

This will yield to 'y <- x+ 1;'

You can assign the result of a function call this way:

  $R->var( y => $R->call('func', 100, 100) );

Which will yield to 'y <- func(100, 100);'

=head2 CALLING ARBITRARY FUNCTIONS

To call functions, you can use the call() method:

  $R->call( demo => 'plotmath' );

Which will yield to 'demo("plotmath");'.

You can of course use call() to feed the result of a function call to a
function call to a... You get the idea:

  $R->call( func1 => $R->call( func2 => $R->call( func3 => 3 ) ) );

Which will yield to 'func1(func2(func3(3)));'

The call() method can cover most function use cases, including oft-used
functions such as c() and expr(). For convenience, the following methods
are provided as shortcust to equivalent call() invocations:

=head3 expression 

=head3 c

=head2 SPECIFYING A RANGE

R allows you to specify a number range. This is achieved via range() function:

  $R->var(x => $R->c( $R->range(0, 9) ));

Which will yield to 'x <- c(0:9);'

=head1 METHODS

=head2 new()

Creates a new instance of R::Writer

=head2 R()

Shortcut for the constructor call.

  use R::Writer qw(R);
  my $R = R();

=head2 call($funcname [, $arg1, $arg2, ...])

Calls a function with specified arguments

=head2 var($name [, $value])

Declares a variable.

=head2 range($start, $end)

Creates a range of values

=head2 reset()

Resets the accumulated R code, and resets R::Writer state.

=head2 as_string()

Returns the string representation of accumulated R statements in the given
R::Writer instance. 

=head2 save($filename | $fh)

Saves the result of calling as_string() to the specified filename, or a 
handle.

=head1 TODO

=over 4

=item Missing Features

Need way to declare functions, execute loops.
Probably need way to handle datasets.

=item Remove JavaScript-ness

JSON and what not are probably not needed.

=item Document Way To Feed The Script To "R"

=back

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki C<< <daisuke@endeworks.jp> >>

A lot of the concepts and some code is based on JavaScript::Writer,
which is by Kang-min Liu C<< <gugod@gugod.org> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut