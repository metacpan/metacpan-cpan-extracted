package Task::CPANPLUS::Metabase;
BEGIN {
  $Task::CPANPLUS::Metabase::VERSION = '0.08';
}

# ABSTRACT: Install everything for CPANPLUS to use Metabase

use strict;
use warnings;

1;


__END__
=pod

=head1 NAME

Task::CPANPLUS::Metabase - Install everything for CPANPLUS to use Metabase

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  cpanp -i Task::CPANPLUS::Metabase

  metabase_cpanp

=head1 DESCRIPTION

Task::CPANPLUS::Metabase is a L<Task> module that installs the modules
required for using L<Test::Reporter::Transport::Metabase> with L<CPANPLUS>
for submitting CPAN test reports to the L<Metabase>.

Also included is L<metabase_cpanp> script which will generate an appropriate
id file and configure L<CPANPLUS> for submitting CPAN test reports.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

