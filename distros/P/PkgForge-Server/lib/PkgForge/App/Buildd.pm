package PkgForge::App::Buildd; # -*-perl-*-
use strict;
use warnings;

# $Id: Buildd.pm.in 15153 2010-12-17 09:10:40Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15153 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/App/Buildd.pm.in $
# $Date: 2010-12-17 09:10:40 +0000 (Fri, 17 Dec 2010) $

our $VERSION = '1.1.10';

use Moose;

extends qw(PkgForge::Handler::Buildd MooseX::App::Cmd::Command);

sub abstract { return q{Build the next job in the queue} };

around 'execute' => sub {
    my ( $orig, $self ) = @_;

    # throw away the command-line args
    return $self->$orig()
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

