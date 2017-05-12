package PkgForge::App::InitServer; # -*-perl-*-
use strict;
use warnings;

# $Id: InitServer.pm.in 15153 2010-12-17 09:10:40Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15153 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/App/InitServer.pm.in $
# $Date: 2010-12-17 09:10:40 +0000 (Fri, 17 Dec 2010) $

our $VERSION = '1.1.10';

use Moose;

extends qw(PkgForge::Handler::Initialise MooseX::App::Cmd::Command);

sub abstract { return q{Initialise the Package Forge server environment} };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

