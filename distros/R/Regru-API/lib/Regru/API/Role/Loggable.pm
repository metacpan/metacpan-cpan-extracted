package Regru::API::Role::Loggable;

# ABSTRACT: something that produces a debug messages

use strict;
use warnings;
use Moo::Role;
use namespace::autoclean;
use Data::Dumper;
use Carp;

our $VERSION = '0.047'; # VERSION
our $AUTHORITY = 'cpan:IMAGO'; # AUTHORITY

sub debug_warn {
    my ($self, @garbage) = @_;

    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Indent     = 0;
    local $Data::Dumper::Useqq      = 1;
    local $Data::Dumper::Pair       = ': ';
    local $Data::Dumper::Sortkeys   = 1;

    my $msg = join ' ' => map { (ref $_ ? Dumper($_) : $_) } @garbage;

    carp $msg;
}

1;  # End of Regru::API::Role::Loggable

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Role::Loggable - something that produces a debug messages

=head1 VERSION

version 0.047

=head1 SYNOPSIS

    package Regru::API::Dummy;
    ...
    with 'Regru::API::Role::Loggable';

    # inside some method
    sub foo {
        my ($self) = @_;
        ...
        $ref = { -answer => 42 };
        $sclr = 'quux';

        $self->debug_warn('Foo:', 'bar', 'baz', $ref, $sclr, qw(knock,  knock));
        # will warn
        # Foo: bar baz {"-answer": 42} quux knock, knock at ...
    }

=head1 DESCRIPTION

Role provides the method which will be useful for debugging requests and responses.

=head1 METHODS

=head2 debug_warn

Produces a warning message for a given list of agruments. All passed references (ArrayRef, HashRef or blessed)
will be flatten to the scalars. Output message will be done by joining scalars with C<space> character as separator.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
