package Path::Extended::Class;

use strict;
use warnings;
use base qw( Path::Extended );

1;

__END__

=head1 NAME

Path::Extended::Class

=head1 SYNOPSIS

    use Path::Extended::Class;
    my $file = file('path/to/file.txt');
    my $dir  = dir('path/to/somewhere');

=head1 DESCRIPTION

If you want some functionality of L<Path::Extended> but also want more L<Path::Class>-compatible API, try L<Path::Extended::Class>, which is built upon L<Path::Extended> and passes many of the L<Path::Class> tests. What you may miss are foreign expressions, and C<absolute>/C<relative> chains (those of L<Path::Extended::Class> return a string instead of an object).

=head1 FUNCTIONS

Both of these two functions are exported by default. As of 0.12, additional C<file_or_dir> and C<dir_or_file> functions are exported as well. See L<Path::Extended> for their details.

=head2 file

takes a file path and returns a L<Path::Extended::Class::File> object. The file doesn't need to exist.

=head2 dir

takes a directory path and returns a L<Path::Extended::Class::Dir> object. The directory doesn't need to exist.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
