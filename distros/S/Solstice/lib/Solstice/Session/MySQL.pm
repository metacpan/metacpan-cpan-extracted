package Solstice::Session::MySQL;

# $Id: Session.pm 3364 2006-05-05 07:18:21Z mcrawfor $

# TODO break new() into discrete methods, e.g. create_session(), login(), etc.
# TODO look into nuking seemingly unneccessary attr's cookie, cookie_name, and cookie_path

=head1 NAME

Solstice::Session - Manage a Solstice Tools session.

=head1 SYNOPSIS

  use CGI;
  use Solstice::Session;

  my $session = Solstice::Session->new;

  #or, if you'd like to use a custom session name for the cookie
  my $session = Solstice::Session->new('custom_name');

  my $cookie = $session->cookie();
  print CGI->header(-cookie => $cookie);

  ## To retrieve the session information
  my $session = Solstice::Session->new;
  $session->set('mydata', $mydata);
  $session->get('mydata');

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Session);

use Solstice::Configure;
use Solstice::Database;
use CGI::Cookie;
use Solstice::Service;
use Solstice::Subsession;
use Digest::MD5;
use Data::Dumper;
use Compress::Zlib qw(compress uncompress);
use Time::HiRes qw(usleep);

use constant TRUE  => 1;
use constant FALSE => 0;
use constant SESSION_SERVICE_KEY => '_solstice_session_service';
use constant MAX_SUBSESSION_LOAD_ATTEMPTS => 20;

# in my trials, the time/increased compression ratio was not worth increasing this
use constant COMPRESSION_LEVEL => 1;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

=item new($cookie_name, $database_name)

Constructor.  Values for C<$cookie_name> and C<$database_name> are provided by
the configuration file if they are not specified in the constructor.

=cut


=item _store()

=cut

sub _store {
    my $self = shift;
    my $session_id = shift;

    my $session_data;
    {
        local $Data::Dumper::Purity = 1;
        local $Data::Dumper::Indent = 0;
        $session_data = Dumper $self;
    }

    # $session_data = compress($session_data, COMPRESSION_LEVEL);
    # God DAMN it, the version of compress zlib on the production cluster is 5 years old!
    # we can't choose a compression level
    $session_data = compress($session_data);

    my $database_name = Solstice::Configure->new()->getSessionDB();
    my $sol_db_name = Solstice::Configure->new()->getDBName();
    my $db = Solstice::Database->new();

    $db->writeQuery("use $database_name");
    $db->writeQuery("REPLACE INTO Session (session_id, session_data) VALUES (?, ?)", $session_id, $session_data);
    $db->writeQuery("use $sol_db_name");
    return;
}

=back

=head2 Private Methods

=over 4

=cut


=item _loadSessionByID($session_id)

Fetch session data identified by $session_id

=cut

sub _loadSessionByID {
    my $pkg = shift;
    my $session_id = shift;

    my $database_name = Solstice::Configure->new()->getSessionDB();
    my $db = Solstice::Database->new();
    $db->writeQuery("SELECT session_data from $database_name.Session WHERE session_id = ?",$session_id);
    
    my $row = $db->fetchRow();
    my $serialized_session = $row->{'session_data'};

    my $VAR1;
    my $self;
    if ($serialized_session) {
        eval uncompress($serialized_session); ## no critic
        die "Failed to unthaw session $session_id : $@\n" if $@;
        $self = $VAR1;
    }

    return $self;
}

=item _getSessionLock($session_id)

=cut

sub _getSessionLock {
    my $self = shift;
    my $session_id = shift;

    # We used to release the lock after reading data, however, we were noticing problems with 
    # overlapping page loads.  Things were disappearing from sessions, and this fixed it in 
    # the one reproducable case we could find (loading a participant side url simulateously in 
    # two browser windows, in the same browser session)
    # 28k is almost 8 hours... making it a nice long timeout, just so we can avoid creating a 
    # screen for when we were unable to restore session.
    my $db = Solstice::Database->new();
    $db->writeQuery('SELECT GET_LOCK(?, 10000)', "Solstice-Session-Lock-$session_id");

    return TRUE;    
}

=item _releaseSessionLock()

=cut

sub _releaseSessionLock { 
    my $self = shift;
    my $session_id = shift;

    my $db = Solstice::Database->new();
    $db->writeQuery('SELECT RELEASE_LOCK(?)', 'Solstice-Session-Lock-'. $session_id);

    return TRUE;
}

1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
