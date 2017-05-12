package Module::New::Recipe::Dist;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Basic;

available_options qw( make=s test|t=s@ edit|e no_dirs xs );

flow {
  set_distname;

  create_distdir;

  create_maketool;

  create_general_files;

  create_tests;

  create_files(qw( MainModule ));

  create_manifest;

  edit_mainfile( optional => 1 );
};

1;

__END__

=head1 NAME

Module::New::Recipe::Dist - create a new distribution

=head1 USAGE

From the shell/command line:

=over 4

=item module_new dist Module::Name

creates C<Module-Name> directory for the distribution, and C<trunk>, C<branches>, C<tags> directories there, and also several files and tests (including C<lib/Module/Name.pm>) in the <Module-Name/trunk> directory.

=back

=head1 OPTIONS

=over 4

=item in

  module_new dist Module::Name --in t

creates a distribution in C<t/> directory, instead of the current directory.

=item no_dirs

  module_new dist Module::Name --no_dirs

doesn't creates C<Module-Name/trunk>, C<Module-Name/branches>, C<Module-Name/tags> directories for C<subversion>, and creates various files including C<lib/Module/Name.pm> just under the C<Module-Name> directory.

=item xs

  module_new dist Module::Name --xs

creates extra XS stuff like C<Name.xs>, C<Name.h> and C<ppport.h> (if you have installed L<Devel::PPPort>). Also, the content of C<lib/Module/Name.pm> changes to load L<XSLoader>.

=item make

  module_new dist Module::Name --make=ModuleBuild

by default, L<Module::New> creates L<ExtUtils::MakeMaker::CPANfile>-based C<Makefile.PL>, but with this option, you can make it to create C<Build.PL> to use L<Module::Build> (set this to C<ModuleBuild> or C<MB> for shortcut), or C<Makefile.PL> powered by L<ExtUtils::MakeMaker> (set this to C<MakeMaker>, or C<EUMM>).

=item edit

  module_new dist Module::Name --edit

If set to true, you can edit C<lib/Module/Name.pm> you created.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
