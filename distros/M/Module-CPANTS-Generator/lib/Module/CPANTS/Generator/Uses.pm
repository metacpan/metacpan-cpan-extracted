package Module::CPANTS::Generator::Uses;
use strict;
use Carp;
use Clone qw(clone);
use File::Spec::Functions;
use File::Find;
use Module::ExtractUse;
use Storable qw(freeze thaw);
use vars qw($VERSION @modules);
use base 'Module::CPANTS::Generator';

$VERSION = "0.004";

sub generate {
  my $self = shift;

  my $cpants = $self->grab_cpants;
  my $cp = $self->cpanplus || croak("No CPANPLUS object");

  foreach my $dist (sort grep { -d } <*>) {

    if (not exists $cpants->{$dist}->{uses}) {
      my %dist_uses;
      @modules=();
      find(\&find_pms,$dist);
      print "* $dist (".@modules.")\n";
      foreach my $file (@modules) {
	my $p = Module::ExtractUse->new;

	next unless -f $file;
	my @used;
	eval { @used = $p->extract_use($file)->array };
	foreach my $module (@used) {
	  my $d = $cp->module_tree->{$module};
	  next if $d && $d->package eq $dist;
	  $dist_uses{$module}++;
	}
      }
      $cpants->{$dist}->{uses} = [sort keys %dist_uses];
    }
    $cpants->{cpants}->{$dist}->{uses} = 
	clone($cpants->{$dist}->{uses});
  }
  $self->save_cpants($cpants);
}

sub find_pms {
    return unless /\.pm$/;
    return if $File::Find::dir=~m|/t/|;
    push(@Module::CPANTS::Generator::Uses::modules,catfile($File::Find::dir,$_));
}

1;

__END__

=head1 NAME

Module::CPANTS::Generator::Uses - Generate list of used modules

=head1 SYNOPSIS

  use Module::CPANTS::Generator::Uses;

  print "* Generating used modules...\n";
  my $u = Module::CPANTS::Generator::Uses->new;
  $u->directory($unpacked);
  $u->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It scans through an
unpacked CPAN, parses all modules for C<use> statements and generates
a list of modules used.

The parsing is done using Module::ExtractUse, so please see it's
manpage for more info.

=head1 AUTHOR

Thomas Klausner <domm@zsi.at> http://domm.zsi.at

=head1 LICENSE

This code is distributed under the same license as Perl.

=head1 COPYRIGHT

Module::CPANTS::Generator::Uses is Copyright (c) 2003 Thomas Klausner,
ZSI.  All rights reserved.

=cut
