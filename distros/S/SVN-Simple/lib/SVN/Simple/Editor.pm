package SVN::Simple::Editor;
use strict;

=head1 NAME

SVN::Simple::Editor - A simple interface for writing a delta editor

=head1 SYNOPSIS

my $editor = SVN::Simple::Editor->new 
             ( );

package MyEditor;

package main;

SVN::Repos::dir_delta($base_root, '', undef, $root, '',
                      SVN::Simple::Editor->new(_editor => 'MyEditor'),
                      1,1,0,1);

=head1 DESCRIPTION

not currently implement.ed

=cut

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
1;
