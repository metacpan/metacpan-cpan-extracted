package Platform::Unix;
$Platform::Unix::AUTHORITY = 'cpan:TOBYINK';
$Platform::Unix::VERSION   = '0.002';
$ENV{PERL_PLATFORM_OVERRIDE}||($^O =~ /^(Linux|.*BSD.*|.*UNIX.*|Darwin|Solaris|SunOS|Haiku|Next|dec_osf|svr4|sco_sv|unicos.*|.*x)$/i);

__END__

=head1 NAME

Platform::Unix - an empty module that can only be installed on Linux/Unix

=head1 SYNOPSIS

  use Platform::Unix;

=head1 DESCRIPTION

This module does nothing, but its installer only works on Unix.
The platform test is:

 $^O =~ /^(Linux|.*BSD.*|.*UNIX.*|Darwin|Solaris|SunOS|Haiku|Next|dec_osf|svr4|sco_sv|unicos.*|.*x)$/i

Adding a dependency on Platform::Unix is a way of explicitly
indicating that your module requires Unix.

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
