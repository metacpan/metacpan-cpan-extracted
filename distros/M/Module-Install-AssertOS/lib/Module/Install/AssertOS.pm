package Module::Install::AssertOS;

use strict;
use warnings;
use base qw(Module::Install::Base);
use File::Spec;
use vars qw($VERSION);

$VERSION = '0.12';

sub assertos {
  my $self = shift;
  my @oses = @_;
  return unless scalar @oses;

  unless ( $Module::Install::AUTHOR ) {
     require Devel::AssertOS;
     Devel::AssertOS->import( @oses );
     return;
  }

  _author_side( @oses );
}

sub _author_side {
  my @oses = @_;

  require Data::Compare;

  foreach my $os (@oses) {
    my $oldinc = { map { $_ => $INC{$_} } keys %INC }; # clone
    eval "use Devel::AssertOS qw($os)";
    if(Data::Compare::Compare(\%INC, $oldinc)) {
        print STDERR "Couldn't find a module for $os\n";
        exit(1);
    }
  }
  my @modulefiles = keys %{{map { $_ => $INC{$_} } grep { /Devel/i && /(Check|Assert)OS/i } keys %INC}};

  mkdir 'inc';
  mkdir 'inc/Devel';
  mkdir 'inc/Devel/AssertOS';
  print "Extra directories created under inc/\n";

  foreach my $modulefile (@modulefiles) {
    my $fullfilename = '';
    SEARCHINC: foreach (@INC) {
        if(-e File::Spec->catfile($_, $modulefile)) {
            $fullfilename = File::Spec->catfile($_, $modulefile);
            last SEARCHINC;
        }
    }
    die("Can't find a file for $modulefile\n") unless(-e $fullfilename);

    (my $module = join('::', split(/\W+/, $modulefile))) =~ s/::pm/.pm/;
    my @dircomponents = ('inc', (split(/::/, $module)));
    my $file = pop @dircomponents;

    mkdir File::Spec->catdir(@dircomponents);

    open(PM, $fullfilename) ||
        die("Can't read $fullfilename: $!");
    my $lsep = $/;
    $/ = undef;
    (my $pm = <PM>) =~ s/package Devel::/package #\nDevel::/;
    close(PM);
    $/ = $lsep;
    open(PM, '>'.File::Spec->catfile(@dircomponents, $file)) ||
        die("Can't write ".File::Spec->catfile(@dircomponents, $file).": $!");
    print PM $pm;
    print "Copied $fullfilename to\n       ".File::Spec->catfile(@dircomponents, $file)."\n";
    close(PM);

  }
  return 1;
}

'Assert this';

__END__

=head1 NAME

Module::Install::AssertOS - A Module::Install extension to require that we are running on a particular OS

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  assertos qw(Linux FreeBSD Cygwin);

The Makefile.PL will die unless the platform the code is running on is Linux, FreeBSD or Cygwin.

=head1 DESCRIPTION

Module::Install::AssertOS is a L<Module::Install> extension that integrates L<Devel::AssertOS> so that CPAN authors
may easily stipulate which particular OS environments their distributions may be built and installed on.

The author specifies which OS or OS families are supported. The necessary L<Devel::AssertOS> files are copied to the 
C<inc/> directory along with the L<Module::Install> files.

On the module user side, the bundled C<inc/> L<Devel::AssertOS> determines whether the current environment is 
supported or not and will die accordingly.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<assertos>

Requires a list of OS or OS families that you wish to support. Check with L<Devel::CheckOS> and L<Devel::CheckOS::Families>
for more details of what you may specify.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

Based on L<use-devel-assertos> by David Cantrell

=head1 LICENSE

Copyright E<copy> Chris Williams and David Cantrell

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

L<Devel::AssertOS>

L<Devel::CheckOS>

=cut
