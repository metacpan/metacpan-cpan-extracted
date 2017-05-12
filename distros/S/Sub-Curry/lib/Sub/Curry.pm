package Sub::Curry;

$VERSION = 0.80;

use 5.006;
use strict;
use base 'Exporter';
use Carp;

BEGIN {
    my @consts = qw/
        ANTISPICE
        HOLE
        ANTIHOLE
        BLACKHOLE
        WHITEHOLE
    /;

    for (@consts) {
        my $val = \(__PACKAGE__ . ".$_");
        no strict 'refs';
        *$_ = sub () { $val };
        *{"is$_"} = sub {
            return @_
                ? ref $_[0] && $_[0] == $val
                : ref $_    && $_    == $val;
        };
    }

    our %EXPORT_TAGS = (
        CONST => [ @consts ],
    );
    our @EXPORT_OK = qw/ curry /;
    push @EXPORT_OK => map @$_ => values %EXPORT_TAGS;
    $EXPORT_TAGS{ALL} = \@EXPORT_OK;
}

sub spice_eq {
    my $x = shift;
    my $y = @_ ? shift : $_;

    return ref $x && ref $y && $x == $y;
}

our (
    $Verbose,
);

# Compability:
sub Hole (;$){
    return map { HOLE() } ( 1 .. ( shift || 1 ) ) if wantarray;
    return HOLE();
}

###############################################################################

BEGIN {
    my %Instance_Data;

    foreach (qw/ uncurried _real_spice _code_str /) {
        no strict 'refs';
        my $prop = $_;
        *$prop = sub {
            my $self = shift;
            if (@_) {
                croak("Don't set '$prop' property outside " . __PACKAGE__)
                    unless caller eq __PACKAGE__;
                return $Instance_Data{$self}->{$prop} = $_[0] if @_;
            }
            return $Instance_Data{$self}->{$prop};
        };
    }

=cut
    foreach ('holes', 'antispices', 'blackholes') {
        no strict 'refs';
        my $prop = $_;
        *$prop = sub {
            my $self = shift;
            if (@_) {
                require Carp;
                Carp::croak("Don't set '$prop' property outside " . __PACKAGE__)
                    unless caller eq __PACKAGE__;
                return @{$Instance_Data{$self}->{$prop} = $_[0]} if @_;
            }
            return @{$Instance_Data{$self}->{$prop}};
        };
    }
=cut

    DESTROY { delete $Instance_Data{+shift} }
}

# Note that the curry sub isn't equivalent to the new method.
# &curry doesn't care if the code ref is an object or not,
# while new does.

sub _alias { \@_ }

sub curry { __PACKAGE__->new(@_) }
sub new {
    if (not ref $_[0]) {
        my $class = shift;

        my $cb = shift;
        my $spice = \@_;

        my @str;
        my $arg_offset = 0;
        my $inc_arg_offset = sub {
            $arg_offset =~ /^\@_/
                ? $arg_offset .= '+1'
                : $arg_offset++;
            return;
        };
        for (my $c = 0; $c < @$spice; $c++) {
            local $_ = $spice->[$c];
            if (! defined $spice->[$c]) {
                push @str => "\$spice->[$c]";
            }
            elsif (spice_eq(HOLE)) {
                push @str => sprintf '$_[%s]', $arg_offset;
                #$arg_offset .= '+1';
                $inc_arg_offset->();
            }
            elsif (spice_eq(ANTISPICE)) {
                $arg_offset .= '+1';
                $inc_arg_offset->();
            }
            elsif (spice_eq(BLACKHOLE)) {
                push @str => sprintf '@_[%s .. $#_]', $arg_offset;
                $arg_offset = '@_';
            }
            else {
                push @str => "\$spice->[$c]";
            }
        }

        #push @str, sprintf '@_[%s .. $#_]', $arg_offset;
        if (1) {
            if ($arg_offset) {
                if ($arg_offset !~ /^\@_/) {
                    push @str, sprintf '@_[%s .. $#_]', $arg_offset;
                }
                # Otherwise you'll get something bigger than @_ in the range,
                # e.g. @_+1 .. $#_ and that will always evaluate to a
                # zero-length slice.
            }
            else {
                # No spice. Just do a regular pass-along.
                push @str, '@_';
            }
        }

        my $code_str = "sub { \$cb->(@{[join ', ', @str]}) }";
        my $self = eval $code_str or die;

        #return $self if $nobless;

        bless $self => $class;

        _code_str($self => $code_str);
        _real_spice($self => $spice);
        $self->uncurried($cb);

        return $self;
    }
    else {
        my $self = shift;

        my $spice = _real_spice($self);

        my $special = grep {
               spice_eq(HOLE)
            or spice_eq(ANTISPICE)
            or spice_eq(BLACKHOLE)
        } @$spice;

        my $new_spice;
        if ($special) {
            my $arg_offset = 0;
            my @str;
            #my $blackhole;
            my $c;
            for ($c = 0; $c < @$spice and $arg_offset < @_; $c++) {
                local $_ = $spice->[$c];
                if (not defined) {
                    push @str => "\$spice->[$c]";
                }
                elsif (spice_eq(ANTISPICE)) {
                    $arg_offset++;
                }
                elsif (spice_eq(HOLE)) {
                    push @str => sprintf '$_[%d]', $arg_offset
                        unless spice_eq(ANTIHOLE, $_[$arg_offset]);
                    $arg_offset++;
                }
                elsif (spice_eq(BLACKHOLE)) {
                    while ($arg_offset < @_ and not spice_eq(WHITEHOLE, $_[$arg_offset])) {
                        push @str => sprintf '$_[%d]', $arg_offset++;
                    }

                    if ($arg_offset < @_) {
                        $arg_offset++; # Skip the whitehole.
                    }
                    else {
                        push @str => "\$spice->[$c]"; # Keep the blackhole.
                    }
                }
                else {
                    push @str => "\$spice->[$c]";
                }
            }

            if ($c < @$spice) {
                push @str => map "\$spice->[$_]" => $c .. $#$spice;
            }
            else {
                push @str, sprintf '@_[%d .. $#_]', $arg_offset;
            }

            $new_spice = eval "_alias(@{[join ', ', @str]})" or die;
        }
        else {
            $new_spice = _alias(@$spice, @_);
        }

        return ref($self)->new($self->uncurried, @$new_spice);
    }
}

sub clone { $_[0]->new }

sub call { goto &{$_[0]} }

sub spice { @{_real_spice($_[0])} }

sub cursed {
    my $self = shift;

    my $cb = $self->uncurried;
    my $spice = _real_spice($self);
    my $cursed = eval _code_str($self);
    die "Internal error: $@" if $@;

    return $cursed;
}

__PACKAGE__;

__END__

=head1 NAME

Sub::Curry - Create curried subroutines


=head1 SYNOPSIS

    use Sub::Curry;
    use Sub::Curry qw/ :CONST curry /; # Import spice constants
                                       # and the &curry function.

    #my $f1 = Sub::Curry::->new(\&foo, 1, 2); # Same as below.
    my $f1 = curry(\&foo, 1, 2);
    my $f2 = $cb1->new(3, 4);

    my $f3 = curry(\&foo, 1, HOLE, 3);
    my $f4 = $f3->new(2, 4);

    $f1->('a'); # foo(1, 2, 'a');
    $f2->('a'); # foo(1, 2, 3, 4, 'a');

    $f3->('a'); # foo(1, 'a', 3);
    $f4->('a'); # foo(1, 2, 3, 4, 'a');

    $f4->call('a'); # Same as $cb4->('a');


=head1 DESCRIPTION

C<Sub::Curry> is a module that provides the currying technique known from functional languages. This module, unlike many other modules that borrow techniques from functional languages, doesn't try to make Perl functional. Instead it tries to make currying Perlish.

This module aims to be a base for other modules that use/provide currying techniques.

This module supports a unique set of special spices (argument features). It doesn't just support holes, but also introduces antiholes, blackholes, whiteholes, and antispices. All these extra special spices effect how the spice is applied to the subroutine. They make functions such as C<&rcurry> superfluous. See L</"Currying"> and L<Sub::Curry::Cookbook>.

An oft-missed feature is argument aliasing. This module preserves the aliasing.

C<Sub::Curry> does explicit currying. For more automatic ways to use currying, look in the C<Sub::Curry::*> namespace.

When version hits 1.00 the interface will be stable.

As of now, this is a beta release. It is and will continue to be compatible with Sub::Curry version 0.08.


=head2 Currying

Currying is when you attach arguments to subroutines. This is sometimes called "partial application". Currying is already done manually every here and there in existing Perl code. It typically looks like

    my $curried_foo = sub { foo($arg, @_) };
    $curried_foo->(@more_args);
    # foo($arg, @more_args);

That's all there is to primitive currying: you store arguments. The stored arguments are called the spice. This module however, extends the concept further by introducing several special spices.

See the C<&call> method for how special spices are treated if left when the original function will be called.

There's no need for a C<&rcurry> subroutine--that's done with a blackhole, see L<Sub::Curry::Cookbook/"Right-currying">.

=head3 Holes - C<Sub::Curry::HOLE>

A hole is what it sounds like: a gap in the argument list. Later, when the subroutine is called the holes are filled in. So if the spice is C<< 1, <HOLE>, 3 >> and then C<2, 4> is applied to the curried subroutine, the resulting argument list is C<1, 2, 3, 4>.

This can be handy if you want to curry a method. Just leave a hole as the first spice for the object.

Holes can be called "scalar inserters" that defaults to C<undef>.

=head3 Antiholes - C<Sub::Curry::ANTIHOLE>

An antihole put in a hole makes the hole disappear. If the spice is C<< 1, <HOLE>, 3, <HOLE>, 4 >> and C<< 2, <ANTIHOLE>, 5 >> is applied then the result will become C<1, 2, 3, 4, 5>.

=head3 Blackholes - C<Sub::Curry::BLACKHOLE>

A blackhole is like a hole for lists that never gets full. There's an imaginary untouchable blackhole at the end of the spice. The blackhole thusly inserts the new spice before itself. The blackhole never gets full because nothing is ever stored in a blackhole as it isn't a hole really...

Blackholes are used to move the point of insertion from the end to somewhere else, so you can curry the end of the argument list.

Blackholes can be called "list inserters" that defaults to the empty list.

=head3 Whiteholes - C<Sub::Curry::WHITEHOLE>

A whitehole removes the blackhole, but the spice that has been put into the blackhole remains since blackholes themselves don't store anything.

=head3 Antispices - C<Sub::Curry::ANTISPICE>

An antispice is like a hole except that when it's filled it disappears. It's like a combination of a hole and an antihole. If the spice is C<< 1, <ANTISPICE>, 3 >> and C<2, 4> is applied, then the result will become C<1, 3, 4>.

This can be handy if you want to provide a function as a method. Just put an antispice to remove the object when called.


=head1 METHODS

=over

=item C<< my $curried = Sub::Curry::->new($subref, @spice) >>

C<new> is different depending on the invocant.

If the invocant is a class name then the first argument is the subroutine reference that should be curried, and following arguments are the spice. The special spices that can be used here are holes, blackholes, and antispices.

The returned value is a spiced up closure that also is a C<Sub::Curry> object.

No special treatment is given if the subroutine reference is a C<Sub::Curry> object, see the other form of C<new> instead.

=item C<< my $other = $curried->new(@spice) >>

If the invocant is an object then all arguments are the spice, and a new object will be returned.

This spice will not just be added to the previous spice. The arguments will be interpreted as arguments to the already curried subroutine and processed accordingly. This means that holes will be filled in, but unfilled holes remain holes. The same applies to the other special spices. If the spice doesn't hold spices that act on spices, i.e. antiholes and whiteholes, then the I<call> C<< $curried->new(@spice)->() >> is equivalent to C<< curry($curried, @spice)->() >>.

The new object won't be wrapped around the old -- that would be a performance hit. Instead the processed spice is put on the same subroutine that the old object spiced up. This is important to realize as the C<uncurried> method will return the same subroutine reference for C<$curried> and C<$other>.

Here all special spices can be used. This is the only place where antiholes and whiteholes can be used.

=item C<call>

Just an OO alias for dereferencing. I.e. C<< $curried->call(...) >> is the same as C<< $curried->(...) >>.

Holes that are not filled in will become C<undef>. Antispices and blackholes will be removed. Antiholes and whiteholes cannot be used here, due to optimization and implementation. If this is needed do C<< $curried->new(@spice_with_antiholes_or_whiteholes)->() >> since the second form of C<new> is the only place that handle antiholes.

=item C<spice>

Experimental! This may be removed in future versions.

In scalar context C<spice> returns the length of the spice. In list context it returns the spice. This is the unprocessed spice. Special spices will be present.

=item C<uncurried>

Experimental! This may be removed in future versions.

Returns the original subroutine reference passed to the first form of C<new>, that is the class invocation C<< Sub::Curry::->new(...) >>.

=item C<cursed>

Returns a copy of the subroutine/object that isn't blessed, i.e. lost all its properties and possibility to invoke method calls. There's no speed gain in using the copy returned by C<cursed>.

    my $f1 = curry(sub { ... }, @spice);
    my $f2 = $f1->cursed;

    $f1->();   # IDENTICAL
    $f2->();   # CALLS

=back

=head1 EXPORTED SYMBOLS

No symbols are exported by default. C<:ALL> exports all functions. C<:CONST> exports all constants.

=head2 Functions

=over

=item C<&curry>

Perhaps you think it's tiresome to write C<< Sub::Curry::->new >> and want a C<&curry> function instead. Well, make one yourself!

    *curry = Sub::Curry::->new(Sub::Curry::->can('new'), Sub::Curry::);

OK, you don't have to do it yourself. You can do

    use Sub::Curry 'curry';

instead and let the module do that currying for you. Note that C<$c1> and C<$c2> in

    my $curried = curry(\&foo, @foo);

    my $c1      = curry($curried, @bar);
    my $c2      = $curried->new(@bar);

isn't equivalent. See the second form of C<new> for an explanation.

=back

=head2 Constants

See L</"Currying">.


=head1 BACKWARDSCOMPABILITY

For backwardscompability the subroutine C<&Sub::Curry::Hole> is provided. It takes one optional integer argument. If no argument is given one hole is returned. If an argument is given it returns that many holes in list context. The new way of doing that is

    (HOLE) x $n

where C<$n> is the number of holes you want.


=head1 BUGS

=over

=item * Doesn't handle prototypes

If you feel the need for this module to handle prototypes in any way, please e-mail me with an idea of how you want it or an interface suggestion.

=back


=head1 WARNING

Don't do C<&$curried;>, because that B<will> break your program! See L<perlfaq7/"What's the difference between calling a function as &foo and foo()?">.

C<< $curried->() >> is the recommended syntax.


=head1 ACKNOWLEDGMENTS

This module has been partly inspired by the CPAN modules listed in L</"SEE ALSO"> and credits go to David Helgason (CPAN ID: DAVIDH) who introduced holes to me by writing C<Sub::Curry> versions 0.0x and passed me the namespace.


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2004 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<Attribute::Curried>

L<Callback>

L<Sub::DeferredPartial>

=cut