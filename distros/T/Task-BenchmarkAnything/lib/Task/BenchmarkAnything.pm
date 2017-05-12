use 5.008;
use strict;
use warnings;
package Task::BenchmarkAnything;
# git description: v0.002-2-gc214c60

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Max dependencies for BenchmarkAnything
$Task::BenchmarkAnything::VERSION = '0.003';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::BenchmarkAnything - Max dependencies for BenchmarkAnything

=head1 VERSION

version 0.003

=head1 TASK CONTENTS

=head2 benchmarkanything

=head3 L<BenchmarkAnything::Schema>

=head3 L<BenchmarkAnything::Storage::Frontend::Tools>

=head3 L<BenchmarkAnything::Storage::Frontend::HTTP>

=head3 L<BenchmarkAnything::Storage::Frontend::Lib>

=head3 L<BenchmarkAnything::Storage::Backend::SQL>

=head2 dbdrivers

=head3 L<DBD::mysql>

=head3 L<DBD::SQLite>

=head2 application support

=head3 L<IO::Socket::SSL>

1;

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
