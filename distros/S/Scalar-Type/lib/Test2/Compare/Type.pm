package Test2::Compare::Type;

use strict;
use warnings;

use base 'Test2::Compare::Base';

our $VERSION = '1.0.1';

use Test2::Compare qw(compare strict_convert);
use Test2::Compare::Negatable;
use Test2::Tools::Type ();
use Test2::Util::HashBase qw(type);
use Scalar::Type qw(bool_supported);
use Scalar::Util qw(reftype blessed);

use Carp qw(croak);

sub init {
    my $self = shift;

    croak "'type' requires at least one argument" unless(@{$self->{+TYPE}});

    foreach my $type (@{$self->{+TYPE}}) {
        croak "'$type' is not a valid argument, must either be Test2::Tools::Type checkers or Test2::Compare::* object"
            unless(
                Test2::Tools::Type->can("is_$type") ||
                (blessed($type) && $type->isa('Test2::Compare::Base'))
            );
    }

    $self->SUPER::init();
}

sub name {
    join(
        " and ",
        map {
            blessed($_) ? blessed($_) : $_
        } @{shift->{+TYPE}}
    );
}

sub operator { join(' ', 'is', (shift->{+NEGATE} ? 'not' : ()), 'of type') }

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $exists;

    my $result = 1;
    foreach my $type (@{$self->{+TYPE}}) {
        if(Test2::Tools::Type->can("is_$type")) {
            local $Test2::Compare::Type::verifying = 1;
            no strict 'refs';
            $result &&= "Test2::Tools::Type::is_$type"->($got);
        } else {
            $result &&= !compare($got, $type, \&strict_convert);
        }
    }
    $result = !$result if($self->{+NEGATE});
    return $result;
}

1;

=head1 NAME

Test2::Compare::Type - Use a type to validate values in a deep comparison.

=head1 DESCRIPTION

This allows you to validate a value's type in a deep comparison.
Sometimes a value just needs to look right, it may not need to be exact. An
example is that you care that your code always returns an integer, but you
don't care whether it is 192 or 3.

=head1 CAVEATS

The definitions of Boolean, integer and number are exactly the same as those in
L<Scalar::Type>, which this is a thin wrapper around.

=head1 SEE ALSO

L<Scalar::Type>

L<Test2::Tools::Type>

L<Test2>

=head1 BUGS

If you find any bugs please report them on Github, preferably with a test case.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Mostly cargo-culted from L<Test2::Compare::Pattern>. Differences from that are
Copyright 2024 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut
