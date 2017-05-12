package Tapper::Fake;
# git description: v4.1.0-1-g736828f

BEGIN {
  $Tapper::Fake::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Fake::VERSION = '4.1.1';
}
# ABSTRACT: Tapper - Fake modules for testing the automation layer

use strict;
use warnings;

use Tapper::Config;
use Moose;

extends 'Tapper::Base';


sub cfg
{
        my ($self) = @_;
        return Tapper::Config->subconfig();
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Fake - Tapper - Fake modules for testing the automation layer

=head2 cfg

Returns the Tapper config.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

