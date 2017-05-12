package Task::POE::Filter::Compression;
$Task::POE::Filter::Compression::VERSION = '1.04';
#ABSTRACT: A Task to install all compression related POE Filters.

use strict;
use warnings;

'Cmprss';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::POE::Filter::Compression - A Task to install all compression related POE Filters.

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    perl -MCPANPLUS -e 'install Task::POE::Filter::Compression'

=head1 DESCRIPTION

This L<Task> module installs all compression related L<POE::Filter> modules, namely:

  POE 1.0001

  POE::Filter::Bzip2 1.54

  POE::Filter::LZF 1.64

  POE::Filter::LZO 1.64

  POE::Filter::LZW 1.64

  POE::Filter::Zlib 1.93

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
