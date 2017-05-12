package Platform::Windows;
$Platform::Windows::AUTHORITY = 'cpan:TOBYINK';
$Platform::Windows::VERSION   = '0.002';
$ENV{PERL_PLATFORM_OVERRIDE}||($^O =~ /^(MSWin32|cygwin)$/i);

__END__

=head1 NAME

Platform::Windows - an empty module that can only be installed on Windows

=head1 SYNOPSIS

  use Platform::Windows;

=head1 DESCRIPTION

This module does nothing, but its installer only works on Windows.
The platform test is:

 $^O =~ /^(MSWin32|cygwin)$/i

Adding a dependency on Platform::Windows is a way of explicitly
indicating that your module requires Windows.

=head1 SEE ALSO

L<Platform>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
