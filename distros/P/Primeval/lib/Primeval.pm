package Primeval;
    use warnings;
    use strict;
    use Carp;
    use Scalar::Util qw(reftype blessed looks_like_number);
    use Data::Dumper 'Dumper';
    our $DUMP   = 0;
    our $RETURN = 0;

    sub import {
        no strict 'refs';
        *{caller().'::prim'} = \&prim
    }

    sub quote {
        no warnings 'uninitialized';
        local $_ = @_ ? "$_[0]" : "$_";
        looks_like_number $_ ? $_ : do {s/\n/\\n/g; "'$_'"}
    }

    my %string = (
        CODE   => sub {&quote},
        SCALAR => sub {quote ${$_[0]}},
        ARRAY  => sub {'['.(join ', ' => map quote, @{$_[0]}).']'},
        HASH   => sub {'{'.(join ', ' => map {
            (/^\w+$/i ? $_ : quote).' => '.quote $_[0]{$_}
        } keys %{$_[0]}).'}'},
    );

    sub prim (&@) {
        my $eval = shift;
        local $Data::Dumper::Terse = 1;
        local $@;
        my @msg;
        for my $name (map {split /\s+/} @_) {
            $name =~ /^
                [\$@%&*]
                (?: [a-zA-Z_] | (?: '|:: ) (?= \w ) )
                (?: \w        | (?: '|:: ) (?= \w ) )*
            $/x or croak "not a variable name '$name'";

            local *_ = \('\\'.$name);

            my $ref = $eval->()
                or croak "error accessing variable '$name':\n$@";

            $ref = $$ref if $name =~ /\$/;

            my $type  = reftype($ref) || '';
            my $class = blessed $ref;

            my $msg = "$name: ".($class ? "$class=" : '').
                ($DUMP && $type =~ /ARRAY|HASH/
                    ? Dumper($ref)
                    : ($string{$type} or \&quote)->($ref));

            $msg =~ s/((?:^..|).{1,78}(?:\s|$))/$1\n  /g;
            $msg =~ s/\s*$/\n/;
            if ($RETURN) {
                push @msg, $msg
            }
            else {
                print $msg
            }
        }
        "@msg"
    }

    our $VERSION = '0.02';

=head1 NAME

Primeval - terse variable dumping

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Primeval;

    my $foo = 5;
    my @bar = 1..10;
    our %baz = (a => 1, b => 2);

    prim{eval} '$foo @bar %baz';

prints:

    $foo: 5
    @bar: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    %baz: {a => 1, b => 2}

=head1 EXPORT

    prim  # always called as prim{eval}

=head1 SUBROUTINES

=head2 C< prim{eval} LIST >

takes a list of variable names, prints out the names along with their values.
each element of the argument list is split on white-space.

while actually a subroutine named C< prim > the block C< {eval} > must always
be passed to C< prim > as the first argument.  this code block is used to peek
into the calling scope to fetch the values for lexical variables.  using this
code block to access the caller's scope allows this module to have no external
dependencies (normally PadWalker would be required to peek into a lexical scope)

the arguments are checked to make sure they look like perl variable names, so
you don't have to worry about anything accidentally making it into an eval that
you wouldn't want to.

C< prim{eval} > will normally only print the first level of an array or hash
using a simple internal serialization routine.  for full recursive printing,
arrays and hashes can be passed to L<Data::Dumper> by setting
C< $Primeval::DUMP = 1 >

C< prim{eval} > will return a string instead of printing if
C< $Primeval::RETURN > is set to a true value.

if you use C< prim{eval} > in a subroutine with closed over variables, just make
sure that you use every variable passed to C< prim{eval} > somewhere else in the
subroutine.  otherwise, perl's garbage collector will sweep up the variables too
early.

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

C<prim{eval}> only works correctly with closures in perl 5.10+

please report any bugs or feature requests to C<bug-primeval at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Primeval>.  I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__ if 'first require';
