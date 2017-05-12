#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

{
    package App::BloodDonation::Donor;

    use Moose 0.89_01; # for native traits
    use MooseX::Types::Moose::MutualCoercion qw(StrToArrayRef NumToInt);

    use namespace::clean -except => [qw(meta)];

    has visited_countries => (
        traits          => [qw(
            Array
        )],
        is              => 'rw',
        isa             => StrToArrayRef,
        coerce          => 1,
        handles         => {
            all_visited_countries => 'elements',
        },
    );

    # minimum(diastolic_blood_pressure), maximum(systolic_blood_pressure)
    has [qw(min_blood_pressure max_blood_pressure)] => (
        is              => 'rw',
        isa             => NumToInt,
        coerce          => 1,
        required        => 1,
    );

    __PACKAGE__->meta->make_immutable;
    1;
}

{
    package App::BloodDonation::Examination;

    use Moose 0.89_01; # for native traits
    use MooseX::Types::Moose::MutualCoercion qw(ArrayRefToHashKeys);

    use namespace::clean -except => [qw(meta)];

    has donor => (
        is              => 'rw',
        isa             => 'App::BloodDonation::Donor',
        required        => 1,
        trigger         => sub {
            $_[0]->clear_can_gather,
        },
    );

    has dangerous_countries => (
        traits          => [qw(
            Hash
        )],
        is              => 'rw',
        isa             => ArrayRefToHashKeys,
        coerce          => 1,
        required        => 1,
        trigger         => sub {
            $_[0]->clear_can_gather,
        },
        handles         => {
            visited_dangerous_countries => 'exists',
        },
        documentation   => 'spread variant Creutzfeldt-Jakob disease(vCJD)',
    );

    has can_gather => (
        is              => 'ro',
        isa             => 'Bool',
        init_arg        => undef,
        lazy_build      => 1,
    );

    sub _build_can_gather {
        my $self = shift;

        return ! grep {
            $self->visited_dangerous_countries($_);
        } $self->donor->all_visited_countries;
    }

    __PACKAGE__->meta->make_immutable;
    1;
}

sub main {
    my $examination = App::BloodDonation::Examination->new(
        donor => App::BloodDonation::Donor->new(
            visited_countries  => 'gb',
            max_blood_pressure => 123.45,
            min_blood_pressure =>  67.89,
        ),
        # See http://www.jrc.or.jp/donation/refrain/detail/detail09.html
        dangerous_countries => [qw(
            gb
            ie it nl sa es de fr be pt
            ch
            at gr se dk fi lu
            is al ad hr sm sk si rs cz va hu bg pl ba mk mt mc me no li ro
        )],
    );

    die sprintf (
        "Regrettably, we cannot gather your blood because "
      . "you have visited a vCJD-related country in past times. "
      . "For your reference, your blood pressure is about %d over %d. "
      . "Thank you for your kindness.\n",
        $examination->donor->max_blood_pressure,
        $examination->donor->min_blood_pressure,
    )
        unless $examination->can_gather;

    return;
}

main()
    unless caller();

__END__

=pod

=head1 NAME

blood_donation.pl - An example of MooseX::Types::Moose::MutualCoercion

=head1 DESCRIPTION

This trifling script is an example of
L<MooseX::Types::Moose::MutualCoercion|MooseX::Types::Moose::MutualCoercion>.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This script is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
