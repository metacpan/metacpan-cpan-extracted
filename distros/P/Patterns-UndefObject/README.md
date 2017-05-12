# NAME

Patterns::UndefObject - A version of the undefined object (null object) pattern

# SYNOPSIS

    use Patterns::UndefObject 'Maybe';

    my $name = Maybe($user_rs->find(100))->name
      || 'Unknown Username';

# DESCRIPTION

Sometimes when you are calling methods on a object you can't be sure that a
particular call chain is going to be valid.  For example, if you are using
something like [DBIx::Class](https://metacpan.org/pod/DBIx::Class) you might start by finding out if a given user
exists in a database and then following that user's relationships for a given
purpose:

    my $primary = $schema
      ->resultset('User')
      ->find(100)
      ->telephone_numbers
      ->primary;

However this call chain will die hard during dynamic invocation should the
method call `find(100)` fail to find a user.  This failure would return a
value of `undef` and then a subsequent "Can't call method 'telephone\_numbers'
on an undefined value.

This often leads to writing a lot of defensive code:

    my $primary;
    if(my $user = $schema->resultset('User')) {
      $primary = $user
        ->telephone_numbers
        ->primary;
    } else {
      $primary = "Unknown Number";
    }

Of course, to be truly safe, you'll need to write defensive code all the way
down the chain should the relationships not be required ones.

I believe this kind of boilerplate defensive code is time consuming and
distracting to the reader.  Its verbosity draws one's attention away from the
prime purpose of the code.  Additionally, it feels like a bit of a code smell
for good object oriented design.  [Patterns::UndefObject](https://metacpan.org/pod/Patterns::UndefObject) offers one possible
approach to addressing this issue.  This class defined a factory method called
["maybe"](#maybe) which accepts one argument and returns that argument if it is defined.
Otherwise, it returns an instance of [Patterns::UndefObject](https://metacpan.org/pod/Patterns::UndefObject), which defines
`AUTOLOAD` such that no matter what method is called, it always returns itself.
This allows you to call any arbitrary length of method chains of that initial
object without causing an exception to stop your code.

This object overloads boolean context such that when evaluated as a bool, it
always returns false.  If you try to evaluate it in any other way, you will
get an exception.  This allows you to replace the above code sample with the
following:

    use Patterns::UndefObject;
    my $primary = Patterns::UndefObject
      ->maybe($schema->resultset('User')->find(100))
      ->telephone_numbers
      ->primary || 'Unknown Number';

You can use the available export `Maybe` to make this a bit more concise (
particularly if you need to use it several times).

    use Patterns::UndefObject 'Maybe';
    my $primary = Maybe($schema->resultset('User')->find(100))
      ->telephone_numbers
      ->primary || 'Unknown Number';

Personally I find this pattern leads to more concise and readable code and it
also provokes deeper though about ways one can use similar techniques to better
encapsulate certain types of presentation logic.

# AUTHOR NOTE

Should you actually use this class?  Personally I have no problem with people
using it and asking for me to support it, however I tend to think this module
is probably more about inspiring thoughts related to object oriented code,
polymorphism, and clean separation of ideas.

**Note:** Please be aware that the undefined object pattern is not a cure-all
and in fact can have some significant issues, among the being the fact that it
can lead to difficult to debug typos and similar bugs.  Think of its downsides
as being similar to how Perl autovivifies Hashs, expect possibly worse!  In
particular this problem can manifest when deeply chaining methods (something
you might wish to avoid in most cases anyway).

# METHODS

This class exposes the following public methods

## maybe

    my $user = Patterns::UndefObject->maybe( $user->find(100)) || "Unknown";

Accepts a single argument which should be an object or an undefined value.  If
it is a defined object, return that object, otherwise return an instance of
[Patterns::UndefObject](https://metacpan.org/pod/Patterns::UndefObject).

This is considered a class method.

# EXPORTS

This class defines the following exports functions.

## Maybe

    use Patterns::UndefObject 'Maybe';
    my $user = Maybe($user->find(100)) || "Unknown";

Is a function that wraps the class method ["maybe"](#maybe) such as to provide a
more concise helper.

# SEE ALSO

The following modules or resources may be of interest.

[Sub::Exporter](https://metacpan.org/pod/Sub::Exporter), [Scalar::Util](https://metacpan.org/pod/Scalar::Util)

# AUTHOR

    John Napiorkowski C<< <jjnapiork@cpan.org> >>

# COPYRIGHT & LICENSE

Copyright 2015, John Napiorkowski `<jjnapiork@cpan.org>`

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
