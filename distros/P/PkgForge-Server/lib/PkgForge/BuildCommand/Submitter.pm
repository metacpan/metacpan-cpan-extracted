package PkgForge::BuildCommand::Submitter;    # -*-perl-*-
use strict;
use warnings;

# $Id: Submitter.pm.in 16781 2011-04-22 09:41:46Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16781 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildCommand/Submitter.pm.in $
# $Date: 2011-04-22 10:41:46 +0100 (Fri, 22 Apr 2011) $

our $VERSION = '1.1.10';

use Moose::Role;
use MooseX::Types::Moose qw(Str);

with 'PkgForge::BuildCommand';

has 'platform' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  documentation => 'The platform to build on',
);

has 'architecture' => (
  is        => 'ro',
  isa       => Str,
  required  => 0,
  predicate => 'has_architecture',
  documentation => 'The architecture to build on',
);

no Moose::Role;

1;
__END__


