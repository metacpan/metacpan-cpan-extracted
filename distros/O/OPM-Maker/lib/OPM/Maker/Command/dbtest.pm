package OPM::Maker::Command::dbtest;
$OPM::Maker::Command::dbtest::VERSION = '1.00';
# ABSTRACT: Test db definitions in .sopm files

use strict;
use warnings;

use OPM::Maker -command;

sub abstract {
    return "Check if DatabaseInstall and DatabaseUninstall sections in the .sopm are correct";
}

sub usage_desc {
    return "opmbuild dbtest <path_to_sopm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error( 'need path to .sopm' ) if
        !$args or
        'ARRAY' ne ref $args or
        !defined $args->[0] or
        $args->[0] !~ /\.sopm\z/ or
        !-f $args->[0];
}

sub execute {
    my ($self, $opt, $args) = @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::dbtest - Test db definitions in .sopm files

=head1 VERSION

version 1.00

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
