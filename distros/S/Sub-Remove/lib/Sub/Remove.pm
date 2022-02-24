package Sub::Remove;

use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    sub_remove
);

our $VERSION = '0.01';

sub __placeholder {}

sub sub_remove {
    my ($sub_name, $class) = @_;

    if (! defined $sub_name) {
        croak "sub_remove() requires a subroutine name as parameter";
    }

    if (! defined $class) {
        $class = 'main';
    }

    if (! $class->can($sub_name)) {
        croak "Subroutine named '${class}::${sub_name}' doesn't exist";
    }

    my $src;

    # get the calling package symbol table name
    {
        no strict 'refs';
        $src = \%{ $class . '::' };
    }

    # loop through all symbols in calling package, looking for subs
    for my $symbol ( keys %$src ) {
        # get all code references, make sure they're valid
        my $sub = *{ $src->{$symbol} }{CODE};
        next unless defined $sub and defined &$sub;

        # save all other slots of the typeglob
        my @slots;

        for my $slot (qw( SCALAR ARRAY HASH IO FORMAT )) {
                my $elem = *{ $src->{$symbol} }{$slot};
                next unless defined $elem;
                push @slots, $elem;
        }

        # clear out the source glob
        undef $src->{$symbol};

        # replace the sub in the source
        if ($symbol ne $sub_name) {
            $src->{$symbol} = sub {
                my @args = @_;
                return $sub->(@_);
            };
        }

        # replace the other slot elements
        for my $elem (@slots) {
                $src->{$symbol} = $elem;
        }
    }
}

1;
__END__

=head1 NAME

Sub::Remove - Remove a subroutine from the symbol table and its associated CODE glob

=for html
<a href="https://github.com/stevieb9/sub-remove/actions"><img src="https://github.com/stevieb9/sub-remove/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/sub-remove?branch=master'><img src='https://coveralls.io/repos/stevieb9/sub-remove/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 SYNOPSIS

    use Sub::Remove qw(sub_remove);

    # In a different class

    sub_remove('sub_name', 'My::Class);

    # In main

    sub_remove('sub_name');

=head1 DESCRIPTION

Removes a subroutine (function or method) from the namespace.

=head1 METHODS

=head2 sub_remove($sub_name, $class)

Removes a sub and all traces to it.

I<Parameters>:

    $sub_name

I<Mandatory, String>: The name of the subroutine to remove.

    $class

I<Optional, String>: The name of the class to remove the symbol from.
Defaults to C<main> if not sent in.

I<Returns>: True (C<1>) upon success.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
