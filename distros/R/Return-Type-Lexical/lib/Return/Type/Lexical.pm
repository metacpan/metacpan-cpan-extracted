package Return::Type::Lexical;
# ABSTRACT: Same thing as Return::Type, but lexical

use 5.008;
use warnings;
use strict;

use parent 'Return::Type';

our $VERSION = '0.002'; # VERSION

sub import {
    my ($class, %args) = @_;
    $^H{'Return::Type::Lexical/in_effect'} = exists $args{check} && !$args{check} ? 0 : 1;
}

sub unimport {
    $^H{'Return::Type::Lexical/in_effect'} = 0;
}

sub _in_effect {
    my ($level) = @_;
    $level = 0 if !defined $level;
    my $hinthash = (caller($level))[10];
    my $in_effect = $hinthash->{'Return::Type::Lexical/in_effect'};
    return !defined $in_effect || $in_effect;
}

# XXX This is kind of janky. It relies upon Return::Type using Attribute::Handlers, and it assumes
# some internal Attribute::Handlers behavior. If it proves to be too fragile, we may need to copy
# the Return::Type code to here. Or make Return::Type lexical if that can be done without breaking
# backward-compatibility.
my $handler;
BEGIN {
    $handler = $UNIVERSAL::{ReturnType};
    delete $UNIVERSAL::{ReturnType};
    delete $UNIVERSAL::{_ATTR_CODE_ReturnType};
}
sub UNIVERSAL::ReturnType :ATTR(CODE,BEGIN) {
    my $in_effect = _in_effect(4);
    return if !$in_effect;

    return $handler->(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Return::Type::Lexical - Same thing as Return::Type, but lexical

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Return::Type::Lexical;
    use Types::Standard qw(Int);

    sub foo :ReturnType(Int) { return "not an int" }

    {
        no Return::Type::Lexical;
        sub bar :ReturnType(Int) { return "not an int" }
    }

    my $foo = foo();    # throws an error
    my $bar = bar();    # returns "not an int"

    # Can also be used with Devel::StrictMode to only perform
    # type checks in strict mode:

    use Devel::StrictMode;
    use Return::Type::Lexical check => STRICT;

=head1 DESCRIPTION

This module works just like L<Return::Type>, but type-checking can be enabled and disabled within
lexical scopes.

There is no runtime penalty when type-checking is disabled.

=head1 METHODS

=head2 import

The C<check> attribute can be used to set whether or not types are checked.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/Return-Type-Lexical/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
