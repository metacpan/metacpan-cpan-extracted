package Perl6::Build;
use strict;
use warnings;

our $VERSION = '0.100';

1;

__END__

=encoding utf-8

=head1 NAME

Perl6::Build - build rakudo Perl6

=head1 SYNOPSIS

  $ perl6-build [options] VERSION   PREFIX [-- [configure options]]
  $ perl6-build [options] COMMITISH PREFIX [-- [configure options]]

See L<perl6-build|https://metacpan.org/pod/distribution/Perl6-Build/script/perl6-build>.

=head1 INSTALLATION

There are 3 ways:

=over 4

=item CPAN

  $ cpm install -g Perl6::Build

=item Self-contained version

  $ wget https://raw.githubusercontent.com/skaji/perl6-build/master/bin/perl6-build
  $ chmod +x perl6-build
  $ ./perl6-build --help

=item As a p6env plugin

  $ git clone https://github.com/skaji/perl6-build ~/.p6env/plugins/perl6-build
  $ p6env install -l

See L<https://github.com/skaji/p6env>.

=back

=head1 DESCRIPTION

Perl6::Build builds rakudo Perl6.

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
