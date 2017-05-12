=head1 NAME

RunApp::Cron

=head1 DESCRIPTION

A RunApp controller that will build from template and install/remove a crontab

=cut

package RunApp::Cron;
use warnings;
use strict;
use Cwd;
use File::Spec::Functions;

use base qw( RunApp::Template );

=head2 new()

creates a new controller

=cut

sub new {
  my $self = shift;
  $self = $self->SUPER::new(@_);
  unless ($self->{source}) {
    $self->{source} = catfile(cwd(), "templates", "crontab",
      $self->{file} =~ /crontab_master/ ? "crontab_master" : "crontab_slave"
    );
  
    if (! -e $self->{source}) {
      warn "source file $self->{source} doesn't exist";
      $self->{source} = \"";
    }
  }
  return $self;
}

=head2 start()

installs the crontab

=cut

sub start {
  my $self = shift;
  die "no generated file" unless $self->{file};
  my $user = $self->{user} ? "-u $self->{user}" : "";
  print `crontab $user $self->{file}`;
}

=head2 stop()

removes the crontab

=cut

sub stop {
  my $self = shift;
  my $user = $self->{user} ? "-u $self->{user}" : "";
  print `crontab $user -r`;
}

1;
