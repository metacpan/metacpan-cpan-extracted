package Tapper::Installer::Precondition::Fstab;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::Fstab::VERSION = '5.0.3';
use strict;
use warnings;

use Moose;
use YAML;
use File::Basename;
extends 'Tapper::Installer::Precondition';




sub install {
        my ($self, $precond) = @_;

        my ($filename, $path, $retval);

        my $basedir = $self->cfg->{paths}{base_dir};
        my $line = $precond->{line};

        my $cmd = '(echo "" ; echo "# precond::fstab" ; echo "'.$line.'" ) >> '.$basedir.'/etc/fstab';

        $self->log->debug($cmd);

        system($cmd) == 0 or return ("Could not patch /etc/fstab: $!");
        return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition::Fstab

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Fstab;

=head1 NAME

Tapper::Installer::Precondition::Fstab - Insert a line into /etc/fstab

=head1 FUNCTIONS

=head2 install

Install a file from an nfs share.

@param hash reference - contains all precondition information

@return success - 0
@return error   - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
