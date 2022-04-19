package OPM::Installer::Utils::Linux;

# ABSTRACT: helper functions for ticketsystem addon installations on Linux

use strict;
use warnings;

our $VERSION = '1.0.1'; # VERSION

use Moo::Role;

use File::Spec;
use File::Basename;
use List::Util qw(first);
use File::Glob qw(bsd_glob);

sub _find_path {
    my ($self) = @_;

    my @checks    = qw(/opt/otrs /srv/otrs /etc/otrs);
    my ($testdir) = grep { -d $_ }@checks;

    return $testdir if $testdir;

    # try to find apache installation and read from config
    my ($apachedir) = grep{ -d $_ }qw(/etc/apache2 /etc/httpd);
    return if !$apachedir;

    
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Installer::Utils::Linux - helper functions for ticketsystem addon installations on Linux

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
