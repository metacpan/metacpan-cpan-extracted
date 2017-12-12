package OTRS::OPM::Installer::Utils::OTRS::OTRS3;
$OTRS::OPM::Installer::Utils::OTRS::OTRS3::VERSION = '0.03';
# ABSTRACT: helper functions for OTRS3

use strict;
use warnings;

sub _get_db {
    my ($self) = @_;

    return $self->manager->{DBObject};
}

sub _build_manager {
    my ($self) = @_;

    push @INC, @{ $self->inc };

    my $manager;
    eval {
        require Kernel::Config;
        require Kernel::System::Main;
        require Kernel::System::Encode;
        require Kernel::System::Log;
        require Kernel::System::DB;
        require Kernel::System::Time;
        require Kernel::System::Package;

        my %objects = ( ConfigObject => Kernel::Config->new );

        for my $module (qw/Main Encode Log DB Time Package/) {
            my $class = 'Kernel::System::' . $module;
            $objects{$module . 'Object'} = $class->new( %objects );
        }

       $manager = $objects{PackageObject};
    } or die $@;

    $manager;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Installer::Utils::OTRS::OTRS3 - helper functions for OTRS3

=head1 VERSION

version 0.03

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
