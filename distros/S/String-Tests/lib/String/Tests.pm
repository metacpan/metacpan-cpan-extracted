package String::Tests;

use strict;
use warnings;
use Carp 'croak';

=head1 NAME

String::Tests - run a series of tests on a string

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    use String::Tests;
    my $boolean = String::Tests->pass( $string, \@tests );

=head1 DESCRIPTION

It is very common (for example when doing user input validation) to have to run
a series of tests on a single string of data. This module attempts to ease the
burden of doing so, by amalgamating all tests into a single boolean method call.

=head2 EXPORT

None by default

=head1 METHODS

=head2 pass

=cut

sub pass {
    shift if $_[0] eq __PACKAGE__ or ref $_[0];
    my ($string, $tests) = @_;
    my $type = ref $tests;
    if ($type eq 'ARRAY') {
        for my $test (@$tests) { # boolean return values only when in list context
            my $test_type = ref $test;
            if ($test_type eq 'Regexp') {
                return if $string !~ $test; # simple boolean test
            } elsif ($test_type eq 'CODE') {
                return if not $test->($string); # callback
            } else {
                croak "ERROR: type of tests must be 'Regexp' or 'CODE'.\n";
            }
        }
        return 1; # boolean all tests passed
    } elsif ($type eq 'Regexp') {
        return ( $string =~ /$tests/g ) if wantarray; # assumes capture syntax
        return $string =~ $tests; # simple boolean test
    } elsif ($type eq 'CODE') {
        return $tests->($string); # return whatever the code ref returned
    }
    croak "ERROR: type of tests must be 'ARRAY', 'Regexp' or 'CODE'.\n";
    return;
}

=head1 EXAMPLES

The most useful case is of course to run a series of code and/or regexp tests on a
string. The example below shows a simple way to validate user password creation.

    my $boolean = String::Tests->pass( 'wimpy_password', [
        qr/^[\w[:punct:]]{8,16}\z/, # character white list
        qr/[A-Z]/, # force 1 upper case
        qr/[a-z]/, # force 1 lower case
        qr/\d/, # force 1 digit
        qr/[[:punct:]]/, # force 1 punctuation symbol
        sub {$self->SUPER::password_tests(@_)}}, # whatever else...
    ]);

When needed you can also run a single code ref or regexp. Whatever function you
implement will receive the string to be tested (in the example below,
'email@address.com') as $_[0].

    my $boolean = String::Tests->pass( 'email@address.com',
        sub { use Email::Valid; return Email::Valid->rfc822(shift) }
    );
    my $boolean = String::Tests->pass( 'some_string', qr/some_regexp/ );

While it's unlikely to be useful in most cases, you can also capture return values
from a regexp test into an array.

    my @blocks_abcd = String::Tests->pass( '10.0.0.1', 
        qr/^ (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \z/x
    );

When running a single code ref, pass() simply returns whatever your function does.

    my @domain_parts = String::Tests->pass( 'x.y.z.sub.domain.tld.stld',
        sub {return split_domain_name(shift)}
    );

The pseduo-code below provides a simple example of form validation useful for
providing feedback to the user about errors. Use of constants can help optimize
complex sets of tests when operating in a persistant environment (such as
mod_perl).

    package MyPackage;

    use String::Tests;

    use constant PARAM_TESTS => {
        username => [
            q| must be 2-32 alpha-numeric, "." or "_" characters |,
            [
                qr/^[\w\.\-]{2,32}\z/,
                qr/[a-z0-9]/i,
            ],
        ],
        password => [
            q| must have 8-16 dual case letters, numbers, and punctations |,
            [
                qr/^[\w[:punct:]]{8,16}\z/,
                qr/[A-Z]/,
                qr/[a-z]/,
                qr/\d/,
                qr/[[:punct:]]/,
            ],
        ],
        email => [
            q| must be a valid email address |,
            sub { use Email::Valid; return Email::Valid->rfc822(shift) },
        ],
    };

    sub test_params { # ->test_params(qw( username password email ))
        my ( $self, @param_fields ) = @_;
        for my $field (@param_fields) {
            my ( $error_message, $tests ) = @{ __PACKAGE__->PARAM_TESTS->{$field} };
            # set error messages (if any) so you can alert the user
            $self->errors->{$field} = $error_message
                unless String::Tests->pass( $http_request->param($field), $tests );
        }
    }

=head1 AUTHOR

Shaun Fryer, C<< <pause.cpan.org at sourcery.ca> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-tests at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Tests>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Tests


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Tests>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Tests>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Tests>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Tests>

=back


=head1 ACKNOWLEDGEMENTS

Everybody. :)
L<http://en.wikipedia.org/wiki/Standing_on_the_shoulders_of_giants>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shaun Fryer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of String::Tests
