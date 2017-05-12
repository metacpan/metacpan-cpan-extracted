package PkgForge::BuildCommand; # -*-perl-*-
use strict;
use warnings;

# $Id: BuildCommand.pm.in 16785 2011-04-22 09:43:34Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16785 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildCommand.pm.in $
# $Date: 2011-04-22 10:43:34 +0100 (Fri, 22 Apr 2011) $

our $VERSION = '1.1.10';

use Moose::Role;
use MooseX::Types::Moose qw(Str);

requires 'run';

has 'name' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  lazy     => 1,
  builder  => 'build_name',
  documentation => 'The name of the command module',
);

has 'tools' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef[Str]',
  required => 1,
  default  => sub { [] },
  handles  => {
    tools_list => 'elements',
  },
  documentation => 'The list of tools which are used by this command',
);

no Moose::Role;

sub build_name {
  my ($self) = @_;

  return ( split /::/, $self->meta->name )[-1],
}

sub stringify {
    my ($self) = @_;
    return $self->name;
}

sub verify_environment {
  my ($self) = @_;

  for my $tool ($self->tools_list) {
    if ( !-x $tool ) {
      die "Cannot find $tool\n";
    }
  }

  return 1;
}

1;
__END__
