package Perl6::Attributes;

use 5.006001;
use strict;
no warnings;

our $VERSION;
$VERSION = '0.04';

use Filter::Simple sub {
    s/([\$@%&])\.(\w+)/
        $1 eq '$' ? "\$self->{'$2'}" : "$1\{\$self->{'$2'}\}"/ge;
    s[\./(\w+)][\$self->$1]g;
};

=head1 NAME

Perl6::Attributes - Perl 6-like member variable syntax

=head1 SYNOPSIS

    package Foo;
    use Perl6::Attributes;
    
    sub new {
        my ($class) = @_;
        bless { 
            a  => 1,
            b  => [ 2, 3, 4 ],
            c  => { hello => "World" },
        } => ref $class || $class;
    }

    sub example {
        my ($self) = @_;
        $.a;        # 1
        $.b[2];     # 4
        @.b;        # 2 3 4
        $#.b;       # 3
        $.c{hello}; # World
        keys %.c;   # hello
        print "I get the idea";
    }

=head1 DESCRIPTION

I found myself annoyed when I wrote the following code in one of my recent
projects:

    sub populate {
        my ($self, $n) = @_;
        for (1..$n) {
            push @{$self->{organisms}}, Organism->new(rand($self->{width}), rand($self->{height}));
        }
    }

Three C<$self>s in one line!  And it's really not encoding any information, 
it's just clutter that results from Perl's lack of I<explicit> object-oriented
support.  However, Using the magic of source filters, we can now write it:

    sub populate {
        my ($self, $n) = @_;
        for (1..$n) {
            push @.organisms, Organism->new(rand($.width), rand($.height));
        }
    }

Perl6::Attributes takes the Perl 6 secondary sigil C<.> and translates it into
a hash access on C<$self>.  No, it doesn't support other names for your
invocant (but it could very easily; I'm just lazy), and no, it doesn't support
objects written by crazy people based on array, scalar, or (!) glob references.

You still inflect the primary sigil, unlike in Perl 6.  See L<Perl6::Variables>
for a way to use Perl 6's uninflected sigils... but don't expect it to work
with this module.

There's also a nice little "feature" that you get for trading the ability to
name your variables the same with different sigils (by the way, you can't do
that).  Say $self->{foo} is an array ref:

    @.foo;       # the array itself
    $.foo;       # the reference

Which means that even if you're using an array referentially, you can usually
avoid writing those pesky C<@{}>s everywhere.

Perl6::Attributes now also translates C<./method> and C<./method(args)> to 
C<$self->method> and C<$self->method(args)>.

=head1 SEE ALSO

L<Perl6::Variables>, L<Lexical::Attributes>

=head1 AUTHOR

Luke Palmer <luke@luqui.org>

=head1 COPYRIGHT

    Copyright (C) 2005 by Luke Palmer

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself, either Perl version 5.8.3 or,
    at your option, any later version of Perl 5 you may have available.
