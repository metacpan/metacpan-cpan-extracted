# Copyright (c) 2003 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Module::Install::InstallDirs;
use Module::Install::Base; @ISA = qw(Module::Install::Base);
use Config;

$VERSION = '0.02';
use strict;

sub installdirs {
  my $self = shift;
  my @dirs = ($Config{privlib},$Config{archlib});
  foreach my $module (@_) {
    (my $path = "$module.pm") =~ s,::,/,g;
    foreach my $dir (@dirs) {
      if (-f "$dir/$path") {
	$self->makemaker_args(INSTALLDIRS => 'perl');
	return;
      }
    }
  }
}

1;

__END__

=head1 NAME

Module::Install::InstallDirs - Module::Install extension to detect INSTALLDIR settings

=head1 SYNOPSIS

  use inc::Module::Install;

  installdirs(qw(Foo::Bar Bar::Foo));

=head1 DESCRIPTION

C<installdirs> is intended for use with distributions that are distributed on CPAN and also
as part of the main perl distribution. If any of the module names passed are found in the
library directories that are used when perl itself is installed, then the MakeMaker
C<INSTALLDIRS> argument is set to C<perl>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 2003 Graham Barr <gbarr@pobox.com>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
