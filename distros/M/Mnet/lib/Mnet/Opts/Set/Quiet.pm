package Mnet::Opts::Set::Quiet;

=head1 NAME

Mnet::Opts::Set::Quiet - Use this module to enable --quiet option

=head1 SYNOPSIS

    use Mnet::Opts::Set::Quiet;

=head1 DESCRIPTION

This module can be used as a pragma to enable the L<Mnet::Log> --quiet option.

Note that the --quiet and --silent options override this pragma.

=cut

# required modules
use warnings;
use strict;
use Mnet;



=head1 SEE ALSO

L<Mnet>

L<Mnet::Log>

L<Mnet::Opts>

L<Mnet::Opts::Cli>

L<Mnet::Opts::Set>

=cut

# normal end of package
1;

