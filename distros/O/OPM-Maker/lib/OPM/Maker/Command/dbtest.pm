package OPM::Maker::Command::dbtest;
$OPM::Maker::Command::dbtest::VERSION = '1.11';
# ABSTRACT: Test db definitions in .sopm files

use strict;
use warnings;

use OPM::Maker -command;

use OPM::Maker::Utils qw(check_args_sopm);

sub abstract {
    return "Check if DatabaseInstall and DatabaseUninstall sections in the .sopm are correct";
}

sub usage_desc {
    return "opmbuild dbtest <path_to_sopm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $sopm = check_args_sopm( $args );

    $self->usage_error( 'need path to .sopm' ) if
        !$sopm;
}

sub execute {
    my ($self, $opt, $args) = @_;

    die "not implemented yet";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::dbtest - Test db definitions in .sopm files

=head1 VERSION

version 1.11

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
