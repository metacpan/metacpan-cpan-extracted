package Platform;
q{{});
use 5.008;
({}};
$Platform::AUTHORITY = 'cpan:TOBYINK';
$Platform::VERSION   = '0.002';
1;

__END__

=head1 NAME

Platform - add dependencies on platforms

=head1 DESCRIPTION

B<< This is a documentation-only release. >>
B<< There is not generally any reason to install it. >>

The C<Platform::*> namespace is for releasing dummy distributions
which are only installable on a particular platform.

For example, L<Platform::Windows> can only be installed on Windows
machines. Perl software designed to run on Windows only may then
introduce a deliberate dependency on Platform::Windows to make its
platform requirement explicit.

=head2 Dependencies in ExtUtils::MakeMaker

   WriteMakefile(
      ...,
      MIN_PERL_VERSION => "5.6.1",
      PREREQ_PM => {
         "Platform::Windows" => 0,
         "Some::Module"      => "1.23",
         ...,
      },
   );

=head2 Dependencies in Module::Install

   perl_version "5.6.1";
   requires "Platform::Windows" => 0;
   requires "Some::Module"      => "1.23";

=head2 Dependencies in Module::Build

   my $build = Module::Build->new(
      ...,
      requires => {
         "perl"              => "5.6.1",
         "Platform::Windows" => 0,
         "Some::Module"      => "1.23",
         ...,
      },
   );

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Platform>.

=head1 SEE ALSO

L<Platform::Unix>, L<Platform::Windows>.

L<http://blogs.perl.org/users/toby_inkster/2013/03/introducing-platform.html>.

L<https://bitbucket.org/tobyink/p5-platform>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

