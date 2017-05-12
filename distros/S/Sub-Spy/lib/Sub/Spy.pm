package Sub::Spy;
use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.04';

use parent qw/Exporter/;
our @EXPORT_OK = qw/spy inspect/;

use Hash::FieldHash qw/fieldhash/;

use Sub::Spy::Result;
use Sub::Spy::Call;


fieldhash our %f_store;

sub spy {
    my $subref = shift;

    my $store = +{};

    my $spy = sub {
        my @args = @_;
        my ($result, @array_result, $e);

        if ( wantarray ) {
            @array_result = eval { $subref->(@args); };
        }
        else {
            $result = eval { $subref->(@args); };
        }
        if ( $@ ) {
            $e = $@;
        }

        push @{$store->{calls}}, Sub::Spy::Call->new({
            args => \@args,
            exception => $e,
            return_value => wantarray ? \@array_result : $result,
        });

        return wantarray ? @array_result : $result;
    };

    $f_store{$spy} = $store;

    return $spy;
}

sub inspect {
    my $spy = shift;
    my $param = $f_store{$spy} or die "given subroutine reference is not a spy!";
    return Sub::Spy::Result->new($param);
}


1;
__END__

=head1 NAME

Sub::Spy - Sub::Spy is subref wrapper that records arguments, return value, and exception thrown.

=head1 VERSION

This document describes Sub::Spy version 0.01.

=head1 SYNOPSIS

    use Sub::Spy qw/spy inspect/;

    my $subref = sub { return $_[0] * $_[1]; };
    my $spy = spy($subref);

    $spy->(2, 5);
    my $i = inspect($spy);

    $i->called; # 1 (true)
    $i->called_once; # 1 (true)

    $i->args; # [[2, 5]]
    $i->return_values; # [10]

    $i->get_args(0); # [2, 5]
    $i->get_return_value(0); # 10


    $spy->(3, 3);

    $i->called_twice; # 1 (true)

    $i->get_call(0)->args; # [2, 5]
    $i->get_call(0)->return_value; # 10

    $i->get_call(1)->args; # [3, 3]
    $i->get_call(1)->return_value; # 9

=head1 DESCRIPTION

Sub:Spy provies the way to inspect each subref calls.
It might be useful for testing callback-style interface or asyncronous subref call. (e.g. AnyEvent)

=head1 FUNCTIONS

=head2 C<spy($subref)>

returns wrapped subref as 'spy'

=head2 C<inspect($spy)>

inspect the 'spy' subref and returns Sub::Spy::Result instance


=head1 INTERFACE of Sub::Spy::Result

=head2 C<get_call(i)>

returns Sub::Spy::Call instance which represents (i+1)th call


=head2 C<call_count>

returns how many times subref called

=head2 C<called>

returns 1 if subref called at least once

=head2 C<called_once>

returns 1 if subref called just once

=head2 C<called_twice>

returns 1 if subref called just twice

=head2 C<called_thrice>

returns 1 if subref called just thrice

=head2 C<called_times(n)>

returns 1 if subref called just n times


=head2 C<args>

returns arguments that passed to subref

=head2 C<get_args(i)>

returns arguments that passed to subref at (i+1)th call


=head2 C<exceptions>

returns exceptions that raised in subref

=head2 C<get_exception(i)>

returns exceptions that raised in subref at (i+1)th call

=head2 C<threw>

returns 1 if exception raised in subref at least once


=head2 C<return_values>

returns return values that subref yield

=head2 C<get_return_value(i)>

returns return value that subref yield at (i+1)th call



=head1 INTERFACE of Sub::Spy::Call

=head2 C<args>

returns arguments at that call

=head2 C<exception>

returns exception raised at that call

=head2 C<threw>

returns 1 if exception raised at that call

=head2 C<return_value>

returns return value yielded at that call



=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Naosuke Yokoe E<lt>yokoe.naosuke@dena.jpE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Naosuke Yokoe. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
