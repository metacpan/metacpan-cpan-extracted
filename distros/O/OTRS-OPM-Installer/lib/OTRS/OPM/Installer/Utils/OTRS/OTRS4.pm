package OTRS::OPM::Installer::Utils::OTRS::OTRS4;
$OTRS::OPM::Installer::Utils::OTRS::OTRS4::VERSION = '0.02';
# ABSTRACT: helper functions for OTRS4 (and higher)

use strict;
use warnings;

sub _get_db {
    my ($self) = @_;

    push @INC, @{ $self->inc };

    my $object;
    eval {
        require Kernel::System::ObjectManager;
        $Kernel::OM = Kernel::System::ObjectManager->new;

        $object = $Kernel::OM->Get('Kernel::System::DB');
    } or die $@;

    $object;
}

sub _build_manager {
    my ($self) = @_;

    push @INC, @{ $self->inc };

    my $manager;
    eval {
        require Kernel::System::ObjectManager;
        $Kernel::OM = Kernel::System::ObjectManager->new;

        $manager = $Kernel::OM->Get('Kernel::System::Package');
    } or die $@;

    $manager;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Installer::Utils::OTRS::OTRS4 - helper functions for OTRS4 (and higher)

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
