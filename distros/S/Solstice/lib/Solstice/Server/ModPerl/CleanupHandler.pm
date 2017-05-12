package Solstice::Server::ModPerl::CleanupHandler;

use strict;
use warnings;
use 5.006_000;

use Solstice::Database;
use Solstice::Service;
use Solstice::Configure;
use Solstice::LogService;

sub handler {
    Solstice::Service::TempFile->new()->cleanupFiles();
    if(0 == int rand(1000)){

#        my $db = Solstice::Database->new();
#        my $sessions_db = Solstice::Configure->new()->getSessionDB();
#        
#
#        $db->writeQuery("delete from $sessions_db.Session where date_sub(now(), interval 24 hour) > last_modified;");
#        $db->writeQuery("delete from $sessions_db.Subsession where date_sub(now(), interval 24 hour) > timestamp;");
#        $db->writeQuery("delete from $sessions_db.Button where date_sub(now(), interval 24 hour) > timestamp;");
#        $db->writeQuery("delete from $sessions_db.ButtonAttribute where date_sub(now(), interval 24 hour) > timestamp;");
#
        Solstice::Service::TempFile->new()->cleanupOldFiles();

        Solstice::LogService->new()->log({
                content => 'Cleanup ran.',
                username => 'dummy_cleanup_is_too_late_for_userservice',
            });

        #These stores will need to be re-cleared if we have run the cleanup script
        $Solstice::Service::data_store = {};
    }
}

1;
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

