package Silki::Plugin::Session::Store::Silki;
{
  $Silki::Plugin::Session::Store::Silki::VERSION = '0.29';
}

use strict;
use warnings;

use base 'Catalyst::Plugin::Session::Store::DBI';

use Silki::Schema;

sub _session_dbic_connect {
    my $self = shift;

    $self->_session_dbh(
        Silki::Schema->DBIManager()->default_source()->dbh() );
}

1;

# ABSTRACT: Provides a database handle to the session using Silki::Schema

__END__
=pod

=head1 NAME

Silki::Plugin::Session::Store::Silki - Provides a database handle to the session using Silki::Schema

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

