package Syntax::Feature::Try;

use 5.014;
use strict;
use warnings;
use Carp;
use XSLoader;
use Scalar::Util qw/ blessed /;

BEGIN {
    our $VERSION = '1.005';
    XSLoader::load();
}

my @custom_exception_matchers;

sub install {
    $^H{+HINTKEY_ENABLED} = 1;
}

sub uninstall {
    $^H{+HINTKEY_ENABLED} = 0;
}

sub register_exception_matcher {
    my ($code_ref) = @_;

    if (ref($code_ref) ne 'CODE') {
        croak "Invalid parameter: expected CODE reference.";
    }

    if (not grep { $_ == $code_ref } @custom_exception_matchers) {
        push @custom_exception_matchers, $code_ref;
    }
}

# only for tests:
sub _custom_exception_matchers { @custom_exception_matchers }

# TODO convert "our" to "my" variables
our $is_end_of_block;
our $return_values;

sub _statement {
    my ($try_block, $catch_list, $finally_block) = @_;

    my $stm_handler = bless {finally => $finally_block}, __PACKAGE__;

    local $@;
    local $is_end_of_block;
    my $exception = run_block($stm_handler, $try_block, 1);
    if ($exception and $catch_list) {
        my $catch_block = _get_exception_handler($exception, $catch_list);
        if ($catch_block) {
            local $is_end_of_block;
            $exception = run_block($stm_handler, $catch_block, 1, $exception);
        }
    }

    if ($finally_block) {
        delete $stm_handler->{finally};
        local $is_end_of_block;
        run_block($stm_handler, $finally_block);
    }

    if ($exception) {
        _rethrow($exception);
    }

    $return_values = $stm_handler->{return};
    return $stm_handler->{return};
}

sub DESTROY {
    my ($self) = @_;
    local $is_end_of_block;
    run_block($self, $self->{finally}) if $self->{finally};
}

sub _get_exception_handler {
    my ($exception, $catch_list) = @_;

    foreach my $item (@{ $catch_list }) {
        my ($block_ref, @args) = @$item;
        return $block_ref if _exception_match_args($exception, @args);
    }
}

sub _exception_match_args {
    my ($exception, $className) = @_;

    return 1 if not defined $className; # without args catch all exceptions

    foreach my $matcher (@custom_exception_matchers) {
        my $result = $matcher->($exception, $className);
        return $result if defined $result;
    }

    if (Moose::Util::TypeConstraints->can('find_type_constraint')) {
        my $type = Moose::Util::TypeConstraints::find_type_constraint($className);
        return $type->check($exception) if $type;
    }

    return blessed($exception) && $exception->isa($className);
}

sub _rethrow {
    die (@_);
}

sub _set_is_end_of_block {
    $is_end_of_block = 1;
}

sub _get_return_value {
    my $return = $return_values;
    undef $return_values;

    return wantarray ? @$return : $return->[0];
}

1;

__END__

=pod

=head1 NAME

Syntax::Feature::Try - try/catch/finally statement for exception handling

=head1 SYNOPSIS

    use syntax 'try';

    try {
        # run this code and handle errors
    }
    catch (My::Class::Err $e) {
        # handle exception based on class "My::Class::Err"
    }
    catch ($e) {
        # handle other exceptions
    }
    finally {
        # cleanup block
    }

=head1 DESCRIPTION

This module implements syntax for try/catch/finally statement with behaviour
similar to other programming languages (like Java, Python, etc.).

It handles correctly return/wantarray inside try/catch/finally blocks.

It uses perl keyword/parser API. So it requires B<perl E<gt>= 5.14>.

=head1 SYNTAX

=head2 initiliazation

To initialize this syntax feature call:

    use syntax 'try';

=head2 try

The I<try block> is executed.
If it throws an error, then first I<catch block> (in order) that can handle
thrown error will be executed. Other I<catch blocks> will be skipped.

If none of I<catch blocks> can handle the error, it is thrown out of
whole statement. If I<try block> does not throw an error,
all I<catch blocks> are skipped.

=head2 catch error class

    catch (My::Error $err) { ... }

This I<catch block> can handle error that is instance of class C<My::Error>
or any of it's subclasses.

Caught error is accessible inside I<catch block>
via declared local variable C<$err>.

=head2 catch all errors

To catch all errors use syntax:

    catch ($e) { ... }

Caught error is accessible inside I<catch block>
via declared local variable C<$e>.

=head2 catch without variable

Variable name in catch block is not mandatory:

    try {
        ...
    }
    catch (MyError::FileNotFound) {
        print "file not found";
    }
    catch {
        print "operation failed";
    }

=head2 rethrow error

To rethrow caught error call "die $err".

For example (log any Connection::Error):

    try { ... }
    catch (Connection::Error $err) {
        log_error($err);
        die $err;
    }

=head2 finally

The I<finally block> is executed at the end of statement.
It is always executed (even if try or catch block throw an error).

    my $fh;
    try {
        $fh = IO::File->new("/etc/hosts");
        ...
    }
    finally {
        $fh->close if $fh;
    }

B<WARNING>: If finally block throws an exception,
originaly thrown exception (from try/catch block) is discarded.
You can convert errors inside finally block to warnings:

    try {
        # try block
    }
    finally {
        try {
            # cleanup code
        }
        catch ($e) { warn $e }
    }

=head1 Supported features

=head2 Exception::Class

This module is compatible with Exception::Class

    use Exception::Class (
        'My::Test::Error'
    );
    use syntax 'try';

    try {
        ...
        My::Test::Error->throw('invalid password');
    }
    catch (My::Test::Error $err) {
        # handle error here
    }

=head2 Moose::Util::TypeConstraints

This module is able to handle subtypes defined using
L<Moose::Util::TypeConstraints> (but it does not require to be this package
installed if you don't use this feature).

    use Moose::Util::TypeConstraints;

    class_type 'Error' => { class => 'My::Error' };
    subtype 'BillingError', as 'Error', where { $_->category eq 'billing' };

    try {
        ...
    }
    catch (BillingError $err) {
        # handle subtype BillingError
    }

=head2 return from subroutine

This module supports calling "return" inside try/catch/finally blocks
to return values from subroutine.

    sub read_config {
        my $file;
        try {
            $fh = IO::File->new(...);
            return $fh->getline; # it returns value from subroutine "read_config"
        }
        catch ($e) {
            # log error
        }
        finally {
            $fh->close() if $fh;
        }
    }

=head2 using custom exception class matcher

There is possible register own subroutine (custom exception matcher)
for extending internal className-matcher logic.

For example:

    use syntax 'try';

    sub is_expected_ref {
        my ($exception, $className) = @_;
        my ($expected_ref) = $className =~ /^is_ref::(.+)/;

        # use default logic if $className is not begning with 'is_ref::'
        return if not $expected_ref;

        return ( ref($exception) eq $expected_ref ? 1 : 0 );
    }

    Syntax::Feature::Try::register_exception_matcher(\&is_expected_ref);

    ...

    try { ... }
    catch (is_ref::CODE) {
        # there is handled any exception that is CODE-reference,
        # because custom exception matcher returns 1 in this case
    }

Exception matcher subroutine has two arguments:
first ($exception) is tested exception,
second ($className) is className expected in "catch block".
It should return undef if given $className cannon be handled by exception matcher
(in this case next registered matchers or default matcher is executed)
otherwise return 1 or 0 as result of your own match $exception to $className.

Note that multiple custom matchers may be registered.

=head1 CAVEATS

=head2 @_

C<@_> is not accessible inside try/catch/finally blocks,
because these blocks are internally called in different context.

=head2 next, last, redo

C<next>, C<last> and C<redo> is not working inside try/catch/finally blocks,
because these blocks are internally called in different context.

=head2 goto

C<goto> can't be used to get out of a try, catch or finally block.

=head1 BUGS

None bugs known.

=head1 SEE ALSO

L<syntax> - Active syntax extensions

L<Exception::Class> - A module that allows you to declare real exception
classes in Perl

L<Moose::Util::TypeConstraints>

=head2 Other similar packages

L<TryCatch>

=over

=item *

It reports wrong line numbers from warn/die calls inside try/catch blocks.

=item *

It does not support "finally" block.

=item *

It works on perl E<lt> 5.14

=back

L<Try>

=over

=item *

It does not support catching errors by their ISA (i.e. it has only one catch block that takes all errors and you must write additinal if/else code to rethrow other exceptions).

=back

L<Try::Tiny>

=over

=item *

It does not support catching errors by their ISA (i.e. it has only one catch block that takes all errors and you must write additinal if/else code to rethrow other exceptions).

=item *

It generates expression (instead of statement), i.e. it requires semicolon after last block. Missing semicolon before or after try/catch expression may be hard to debug (it is not always reported as syntax error).

=item *

It works on perl E<lt> 5.14 (It is written in pure perl).

=back

=head1 GIT REPOSITORY

L<http://github.com/tomas-zemres/syntax-feature-try>

=head1 AUTHOR

Tomas Pokorny <tnt at cpan dot org>

=head1 COPYRIGHT AND LICENCE

Copyright 2013 - Tomas Pokorny.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=for Pod::Coverage HINTKEY_ENABLED install uninstall run_block register_exception_matcher

=cut
