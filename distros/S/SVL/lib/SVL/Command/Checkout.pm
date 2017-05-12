package SVL::Command::Checkout;
use strict;
use warnings;
use URI;
use base qw(SVL::Command);

sub options {
  ('depot=s' => 'depot');
}

sub run {
  my $self   = shift;
  my $url = shift;
  die "No target" unless $url;
  
  my $name = $url;
  $name =~ s{^svn://}{};
  $name =~ s/\W/_/g;
  
  my $path = URI->new($url)->path;
  $path =~s/^.*\///;

  my $depotname = $self->{depot} || '';
  my $mirrorpath = "/$depotname/mirror/$name";
  my $localpath  = "/$depotname/$path";
  $self->svk->mirror($mirrorpath, $url);
  $self->svk->sync($mirrorpath);
  my $svk = SVK::Simple->new;
  $svk->cp($mirrorpath => $localpath, -m => "branch", '-p');
  $svk->co($localpath);
}

1;

__END__

=head1 NAME

SVL::Command::Checkout - Check out the repository

=head1 SYNOPSIS

  svl checkout svn://10.10.12.245:48513/svl/svl

=head1 OPTIONS

None.
