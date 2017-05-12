package Module::Install::AutoLicense;

use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.10';

my %licenses = (
    perl         => 'Software::License::Perl_5',
    apache       => 'Software::License::Apache_2_0',
    artistic     => 'Software::License::Artistic_1_0',
    artistic_2   => 'Software::License::Artistic_2_0',
    lgpl2        => 'Software::License::LGPL_2_1',
    lgpl3        => 'Software::License::LGPL_3_0',
    bsd          => 'Software::License::BSD',
    gpl          => 'Software::License::GPL_1',
    gpl2         => 'Software::License::GPL_2',
    gpl3         => 'Software::License::GPL_3',
    mit          => 'Software::License::MIT',
    mozilla      => 'Software::License::Mozilla_1_1',
);

sub auto_license {
  my $self = shift;
  return unless $Module::Install::AUTHOR;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $holder = $opts{holder} || _get_authors( $self );
  #my $holder = $opts{holder} || $self->author;
  my $license = $self->license();
  unless ( defined $licenses{ $license } ) {
     warn "No license definition for '$license', aborting\n";
     return 1;
  }
  my $class = $licenses{ $license };
  eval "require $class";
  my $sl = $class->new( { holder => $holder } );
  open LICENSE, '>LICENSE' or die "$!\n";
  print LICENSE $sl->fulltext;
  close LICENSE;
  $self->postamble(<<"END");
distclean :: license_clean

license_clean:
\t\$(RM_F) LICENSE
END

  return 1;
}

sub _get_authors {
  my $self = shift;
  my $joined = join ', ', @{ $self->author() || [] };
  return $joined;
}

'Licensed to auto';
__END__

=head1 NAME

Module::Install::AutoLicense - A Module::Install extension to automagically generate LICENSE files

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  author 'Vestan Pants';
  license 'perl';
  auto_license;

An appropriate C<LICENSE> file will be generated for your distribution.

=head1 DESCRIPTION

Module::Install::AutoLicense is a L<Module::Install> extension that generates a C<LICENSE> file automatically 
whenever the author runs C<Makefile.PL>. On the user side it does nothing.

When C<make distclean> is invoked by the author, the C<LICENSE> is removed.

The appropriate license to determined from the meta provided with the C<license> command and the holder of the
license from the C<author> command.

L<Software::License> is used to generate the C<LICENSE> file.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<auto_license>

Does nothing on the user-side. On the author-side it will generate a C<LICENSE> file according to the previously
supplied C<license> command. The C<holder> of the license is determined from the C<author> meta or may be specified
using the C<holder> parameter. 

  auto_license( holder => 'Vestan Pants and Ivor Biggun' );

It is important to note that the C<auto_license> must follow C<author> and C<license> commands in the C<Makefile.PL>
( as demonstrated in the SYNOPSIS above ), otherwise the meta these commands provide will be unavailable to C<auto_license>.
Call it a feature.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

L<Software::License>

=cut
