package String::Defer;

use warnings;
use strict; 
no warnings "uninitialized"; # SHUT UP

our $VERSION = "3";

=head1 NAME

String::Defer - Strings with deferred interpolation

=head1 SYNOPSIS

    my $defer = String::Defer->new(\my $targ);
    my $str = "foo $defer bar";

    $targ = "one";  say $str;   # foo one bar
    $targ = "two;   say $str;   # foo two bar

=head1 DESCRIPTION

C<String::Defer> objects provide delayed interpolation. They have concat
(C<q/./>) overloading, which means that an interpolation like

    "foo $defer bar"

will itself produce a C<String::Defer> object, and the stringification
of C<$defer> will be delayed until I<that> object is stringified.

=cut

use overload        (
    q/""/       => "force",
    q/./        => "concat",
    fallback    => 1, # Why is this not the default?
);
use Exporter "import";
our @EXPORT_OK = qw/djoin/;

use Carp;
use Scalar::Util    qw/reftype blessed/;

=head1 METHODS

=head2 C<< String::Defer->new(\$scalar | \&code) >>

This is the usual constructor (though C<concat> and C<join> can also be
seen as constructors). The argument is either a scalar ref or a code
ref, unblessed, and specifies a piece of the string that should be lazily
evaluated. When C<force> is called, a scalar ref will be dereferenced
and the referent stringified; a code ref will be called with no
arguments.

It currently isn't possible to pass an object with C<${}> or C<&{}>
overloading; see L</BUGS> below. If you wish to defer stringification of
an object with stringify overloading, you need to pass a B<reference> to
(your existing reference to) the object, like this:

    my $obj = Some::Class->new(...);
    my $defer = String::Defer->new(\$obj);

It currently B<is> possible to pass a ref to a scalar which happens to
be holding a bare glob, like this:

    my $targ = *FOO;
    my $defer = String::Defer->new(\$targ);

but that may not be the case in the future. I'd like, at some point, to
support passing a globref as a filehandle, and I'm not sure it's
possible to distinguish between 'a ref to a scalar variable which
happens to be currently holding a glob' and 'a ref to a real glob'.

It is also possible to pass a ref to a substring of another string,
like this:

    my $targ = "one two three";
    my $defer = String::Defer->new(\substr $targ, 4, 3);

    say $defer;                     # two
    $targ = uc $targ; say $defer;   # TWO

The C<String::Defer> will track that substring of the target string as
it changes. Before perl 5.16, the target string must be long enough at
the time the reference is created for this to work correctly; this has
been fixed in the development version of perl, which will be released as
5.16.

=cut

# This list is a little bizarre, but so is the list of things
# that can legitimately be stuffed into a scalar variable. If
# BIND ever sees the light of day this will need revisiting.
my %reftypes = map +($_, 1), (
    "CODE",     # ->new(sub { })
    "SCALAR",   # my $x;            ->new(\$x)
    "VSTRING",  # my $x = v1;       ->new(\$x)
    "REF",      # my $x = \1;       ->new(\$x)
    "REGEXP",   # my $x = ${qr/x/}; ->new(\$x)

    # This should be considered experimental. It may be more beneficial
    # to treat a globref as a filehandle. I don't know if there's any
    # way to distinguish between    my $x = *STDIN; \$x
    # and either of                 \*STDIN
    #                               open my $x, ...; $x
    # SvFAKE on the glob seems to be the key, here, but I don't know if
    # that's visible from Perl. (...of course it is, that's what B's
    # there for.)
    "GLOB",     # my $x = *STDIN;   ->new(\$x)
    "LVALUE",   # my $x = "foo";    ->new(\substr($x, 0, 2))
                # This will track that substring of the variable as it
                # changes, which is pretty nifty.
);

sub new {
    my ($class, $val) = @_;
    # XXX What about objects with ${}/&{} overload? Objects pretending
    # to be strings can be passed by (double) ref, and will be allowed
    # by the REF entry, but not objects pretending to be references.
    ref $val and not blessed $val and $reftypes{reftype $val}
        or croak "I need a SCALAR or CODE ref, not " .
            (blessed $val ? "an object" : reftype $val);
    bless [$val], $class;
}

=head2 C<< $defer->concat($str, $reverse) >>

Concatentate C<$str> onto C<$defer>, and return a new C<String::Defer>
containing the result. This is the method which implements the C<q/./>
overloading.

Passing another C<String::Defer> will B<not> force the object out to a
plain string. Passing any other object with string overload, however,
B<will>. If you want to defer the stringification, wrap it in a
C<String::Defer>.

=cut

# This will force a stringify now, which is what happens with a
# normal concat. I don't think allowing other random stringifyable
# objects to be deferred (when the user hasn't explicitly asked for it)
# is going to be helpful.
sub _expand { eval { $_[0]->isa(__PACKAGE__) } ? @{$_[0]} : "$_[0]" }

sub concat {
    my ($self, $str, $reverse) = @_;
#    {   local $" = "|"; no overloading;
#        carp "CONCAT: [@$self] [$str] $reverse";
#    }
    my $class = Scalar::Util::blessed $self
        or croak "String::Defer->concat is an object method";

    my @str = _expand $str;
    bless [
        grep ref || length,
            ($reverse ? (@str, @$self) : (@$self, @str))
    ], $class;
}

=head2 C<< $defer->force >>

Stringify the object, including all its constituent pieces, and return
the result as a plain string. This implements the C<q/""/> overload.

Note that while this returns a plain string, it leaves the object itself
unaffected. You can C<< ->force >> it again later, and potentially get a
different result.

=cut

sub force {
    my ($self) = @_;
#    {   local $" = "|"; no overloading;
#        carp "FORCE: [@$self]";
#    }
    join "", map +(
        ref $_ 
            # Any objects should have been rejected or stringified by
            # this point (but see XXX above)
            ? reftype $_ eq "CODE"
                ? $_->() 
                : $$_
            : $_
    ), @$self;
}

=head2 C<< String::Defer->join($with, @strs) >>

Join strings without forcing, and return a deferred result.

Arguments are as for L<C<CORE::join>|perlfunc/join>, but while the
builtin will stringify immediately and return a plain string, this will
allow any of C<$with> or C<@strs> to be deferred, and will carry the
deferral through to the result.

Note that this is, in fact, a constructor: it must be called as a class
method, and the result will be in that class. (But see L</BUGS>.)

=cut

# Join without forcing. The other string ops might be useful, and could
# certainly be implemented with closures, but would be substantially
# more complicated.
sub join {
    my ($class, $with, @strs) = @_;

    # This is a class method (a constructor, in fact), to allow
    # subclasses later, but the implementation may need adjusting. I
    # probably shouldn't be poking in the objects' guts directly, and
    # using a ->pieces method or something instead. 
    # OTOH, @{} => "pieces" would Just Work...
    ref $class and croak "String::Defer->join is a class method";

#    {   local $" = "|"; no overloading;
#        carp "JOIN: [$with] [@strs] -> [$class]";
#    }

    # This could be optimised, but stick with the simple implementation
    # for now.
    my @with = _expand $with;
    my @last = @strs ? _expand(pop @strs) : ();
    bless [
        grep ref || length,
        (map { (_expand($_), @with) } @strs),
        @last,
    ], $class;
}

=head2 C<< djoin $with, @strs >>

This is a shortcut for C<< String::Defer->join >> as an exportable
function. Obviously this won't be any use if you're subclassing.

=cut

# Utility sub since C<String::Defer->join()> is rather a mouthful. This
# always creates a String::Defer, rather than a subclass.
sub djoin { __PACKAGE__->join(@_) }

=head1 BUGS

Please report any bugs to <bug-String-Defer@rt.cpan.org>.

=head2 Bugs in perl

=head3 Assignment to an existing lexical

Under some circumstances an assignment like

    my $defer = String::Defer->new(\my $targ);
    my $x;
    $x = "A $defer B";

will leave C<$x> holding a plain string rather than a C<String::Defer>,
because perl calls stringify overloading earlier than it needed to. This
happens if (and only if)

=over 4

=item -

a double-quoted string (with an interpolated C<String::Defer>) is assigned
to a lexical scalar;

=item -

that lexical has already been declared;

=item -

no other operators intervene between the interpolation and the
assignment;

=item -

the interpolation has at least three pieces (so, two constant sections
with a variable between them, or vice versa, or more pieces than that).

=back

So the following are all OK:

    my $x   = "A $defer B";         # newly declared lexical
    my %h;
    $h{x}   = "A $defer B";         # hash element, not lexical scalar
    $x      = "A $defer";           # only two pieces
    $x      = "" . "A $defer B";    # intervening operator

The simplest workaround is to turn at least one section of the
interpolation into an explicit concatenation, or even just to
concatenate an empty string as in the last example above.

This applies to C<state> as well as to C<my> variables, but not to
C<our> globals, despite their partially lexical scope.

=head3 C<++> and C<-->

The increment and decrement operators don't appear to honour the
stringify overloading, and instead operate on the numerical refaddr of
the object. Working aroung this in this module is a little tricky, since
the calling convention of the C<++> and C<--> overloads assume you want
the object to stay an object, whereas what we want here is a plain
string. C<+=> and C<-=> work correctly, and B<do> leave you with a plain
string.

=head3 Tied scalars

Before perl 5.14, tied scalars don't always honour overloading properly.
A tied scalar whose C<FETCH> returns a C<String::Defer> will instead
appear to contain a plain string at least the first time it is
evaluated. As of 5.14, this has been fixed.

=head2 Subclassing

Subclassing is currently rather fragile. The implementation assumes the
object is implemented as an array of pieces, where those pieces are
either plain strings, scalar refs, or code refs, but I would like to
change this to something like a C<< ->pieces >> method. While it ought
to be possible to override C<< ->force >> to create an object which
builds the final string differently, it's not very clear how to best
handle cases like an object of one subclass being concatenated with an
object of another.

=head2 C<x> and C<x=>; other string ops

The repeat ops C<x> and C<x=> currently force deferred strings. It would
be better if they produced deferred results, and better still if they
could do so without duplicating the contents of the internal array.
(Allowing the RHS to be deferred as well might be a nice touch.)

Much the same applies to all the other string ops. While functions like
C<substr> and C<reverse> can't be overloaded, they can be provided as
class methods. I suspect the best way forward here will be to provide a
set of subclasses of C<String::Defer>, each of which knows how to
implement one string operation. This would mean that C<< ->join >> would
no longer return a C<String::Defer>, but rather a C<String::Defer::join>
with internal references to its constituent pieces.

=head2 Objects pretending to be refs

Objects with C<${}> and C<&{}> overloads ought to be accepted as
stand-ins for scalar and code refs, but currently they aren't. In part
this is because I'm not sure which to give precedece to if an object
implements both.

=head2 Efficiency

The implementation of both C<concat> and C<join> is rather simple, and
makes no attempt to merge adjacent constant strings. Join, in
particular, will return a deferred string even if passed all plain
strings, which should really be fixed.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 COPYRIGHT

Copyright 2011 Ben Morrow <ben@morrow.me.uk>.

Released under the BSD licence.

=head1 SEE ALSO

L<Scalar::Defer> for a more generic but more intrusive deferral
mechanism.

=cut

1;

