package Object::Anon;
$Object::Anon::VERSION = '0.003';
# ABSTRACT: Create objects on the fly

use strict;
use warnings;

use Carp qw(croak);

use Exporter qw(import);
our @EXPORT = qw(anon);

sub anon (%) {
    my ($hash) = @_;
    return _objectify($hash);
}

use overload ();
my %overload_ops = map { $_ => 1 } map { split /\s+/, $_ } values %overload::ops;

my $anon_class_id = 0;

sub _objectify {
    my ($hash, $seen) = @_;
    $seen ||= {};

    if ($seen->{$hash}) {
        croak "circular reference detected";
    }
    $seen->{$hash} = 1;

    my $class_id = $anon_class_id++;
    my $class = "Object::Anon::__ANON__::".$class_id;

    for my $key (keys %$hash) {
        if ($overload_ops{$key}) {
            $class->overload::OVERLOAD($key => _value_sub($hash->{$key}, $seen));
        }
        else {
            no strict 'refs';
            *{$class."::".$key} = _value_sub($hash->{$key}, $seen);
        }
    }

    do {
      no strict 'refs';
      *{$class."::DESTROY"} = sub {
        my $symtab = *{$class.'::'}{HASH};
        %$symtab = ();
        delete *Object::Anon::__ANON__::{HASH}->{$class_id.'::'};
      };
    };

    return bless do { \my %o }, $class;
}

sub _value_sub {
    my ($value, $seen) = @_;

    do {
        {
            HASH  => sub { my $o = _objectify($value, $seen); sub { $o } },
            ARRAY => sub { my @o = map { _value_sub($_, $seen)->() } @$value; sub { \@o } },
            CODE  => sub { $value },
        }->{ref $value} || sub { sub { $value } }
    }->();
}

1;
__END__

=pod

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Object-Anon.png)](http://travis-ci.org/robn/Object-Anon)

=encoding UTF-8

=head1 NAME

Object::Anon - Create objects on the fly

=head1 SYNOPSIS

    use Object::Anon;

    # create an object from a hash
    my $o = anon { foo => "bar" };
    say $o->foo; # prints "bar";
    say $o->baz; # dies, no such method

    # deep hashes will turn into deep objects
    my $o = anon { foo => { bar => "baz" } };
    say $o->foo->bar; # prints "baz"

    # so do arrays
    my $o = anon { foo => [ { n => 1 }, { n => 2 }, { n => 3 } ] };
    say $o->foo->[2]->n; # prints "3"

    # overloading
    my $o = anon { foo => "bar", '""' => "baz" };
    say $o->foo; # prints "bar"
    say $o;      # prints "baz"

=head1 WARNING

This module is highly experimental. I think the idea is sound, but there's a
bunch of important design points that I haven't yet finalised. See L<TODO> for
details, and take care when using this in your own code.

=head1 DESCRIPTION

This modules exports a single function C<anon> that takes a hash as its
argument and returns an object with methods corresponding to the hash keys.

Why would you want this? Well, its not at all uncommon to want to return a hash
from some function. The problem is the usual one with hashes - its too easy to
mistype a key and silently fail without knowing exactly where you went wrong.

Returning an object fixes this problem since an attempt to call a missing
method results in a fatal error. Unfortunately there's lots of boilerplate
required to create a class for every kind of return type. And that's why this
module exists - it make it trivially easy to convert a hash into an object,
with nothing else to worry about.

=head1 INTERFACE

This module exports a single function C<anon>. When called with a hashref as
its argument, it returns an object with methods named for the hash keys that
return the corresponding value.

It does this by installing simple read accessors into a class with a randomised
name, then blessing an empty hash into that class and returning it. The methods
are named for the keys, and return a copy of the value found in the hash key.

The call:

    $o = anon { foo => "bar", baz => "quux" };

produces similar results to the following code:

    package random::class::1;
    sub foo { "bar" }
    sub baz { "quux" }
    $o = bless {}, "random::class::1";

=head2 Value handling

There is special handling for certain value types to make them more useful.

=over 4

=item hashes

Hashes will be converted to objects in turn. So this:

    $o = anon { foo => { bar => "baz" } };

becomes similar in function to:

    package random::class::1;
    sub bar { "baz" }
    package random::class::2;
    sub foo { bless {}, "random::class::1" }
    $o = bless {}, "random::class::2";

except that all the bless stuff happens up-front, not at call time.

=item arrays

Arrays of hashes are similarly handled, returning instead an array of objects.

=item coderefs

Coderefs are installed as-is, that is:

    $o = anon { foo => sub { "bar" } };

becomes:

    package random::class::1;
    sub foo { "bar" }
    $o = bless {}, "random::class::1";

=back

=head2 Overloading

If a hash key is one of the overload operators (see L<overload>) then an
overload function will be installed instead of the named key:

    $o = anon { foo => "bar", '""' => "baz" };

becomes something like:

    package random::class::1;
    sub foo { "bar" }
    use overload '""' => sub { "baz" };
    $o = bless {}, "random::class::1";

Be aware that simple strings won't suffice for many kinds of overload (like
comparison operators), so much of the time you'll want to pass a coderef.
C<Object::Anon> won't do anything special with the code it generates for
overloads, so things like this can give odd results:

    $o = anon { "+" => "foo" }; # addition overload
    say $o + 3; # prints "foo";

=head1 TODO

Much of this is design that I haven't quite figured out yet (mostly because I
haven't had a strong need for it yet). If you have thoughts about any of this,
please let me know!

=over 4

=item *

Class caching. It'd be nice for the same return in a busy function to be able
to reuse the class that was generated last time. The only difficulty is
determining when to do this. L<Net::Twitter> does this with data returned from
the Twitter API by taking a SHA1 of the returned keys and uses that as a cache
key for a Moose metaclass. That's a nice approach when you know the incoming
hash is always JSON, but doesn't work as well when you can't predict the value
type (especially if the value is a coderef). Including the value type in the
cache key and not caching at all when coderefs are seen might work, but may be
too limiting. Another approach might involve looking at the caller, on the
basis that the same point in the code is probably returning the same structure
each time.

=item *

Overload clashes. Some overloaded operators are common words. If a hash had a
key of that name it would generate an overload, not a method of that name,
which isn't want you want. The only ways I can think of to deal with this is to
either limit the set of possible overload operators to ones unlikely to clash
(the symbol ones), or to make overload specified by an option or similar.
Neither of these options particularly appeal to me though.

=item *

Return hash. Should it be filled with the original data so you can access the
data as a hash as well as via the methods? I'm inclined to think not,
particularly since that makes it modifiable which then brings up a question of
whether or not those changes should be reflected in the the data return from
the methods. But if you wanted to then pass the hash to something else, it
won't do the right thing either. Maybe a hash deref overload?

=back

=head1 SEE ALSO

=over 4

=item *

L<Object::Result> - another way of addressing the same problem. This was
actually the direct inspiration for C<Object::Anon>. I liked the idea, but
hated that it defined its own syntax and required L<PPI>.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Object-Anon/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Object-Anon>

  git clone https://github.com/robn/Object-Anon.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
