package PMLTQ;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::VERSION = '3.0.2';
# ABSTRACT: Query engine and query language for trees in PML format


use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec ();
use File::ShareDir 'dist_dir';

my $home_dir = File::Spec->catdir(dirname(__FILE__), __PACKAGE__);
my $local_shared_dir = File::Spec->catdir(dirname(__FILE__), File::Spec->updir, 'share');
my $shared_dir = eval {	dist_dir(__PACKAGE__) };

# Assume installation
if (-d $local_shared_dir or !$shared_dir) {
  $shared_dir = $local_shared_dir;
}

sub home { $home_dir }

sub shared_dir { $shared_dir }

sub resources_dir { File::Spec->catdir($shared_dir, 'resources') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ - Query engine and query language for trees in PML format

=head1 VERSION

version 3.0.2

=for html <a href="https://travis-ci.org/ufal/perl-pmltq"><img src="https://travis-ci.org/ufal/perl-pmltq.svg?branch=master" alt="Build Status"></a>
<a href="https://coveralls.io/github/ufal/perl-pmltq?branch=master"><img src="https://coveralls.io/repos/ufal/perl-pmltq/badge.svg?branch=master&amp;service=github" alt="Coverage Status"></a>
<a href="https://badge.fury.io/pl/PMLTQ"><img src="https://badge.fury.io/pl/PMLTQ.svg" alt="CPAN version"></a>

=head1 DESCRIPTION

This module concists of libraries for manipulating and querying with PMLTQ. An implementation of a PML-TQ search engine (CGI module) and a
command-line client has been moved to different modules. A graphical client for PML-TQ is part of the tree editor
TrEd (http://ufal.mff.cuni.cz/tred).

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
