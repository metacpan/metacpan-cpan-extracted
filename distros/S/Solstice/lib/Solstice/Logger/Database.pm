package Solstice::Logger::Database;

# $Id: Database.pm 2393 2005-07-18 17:12:40Z jlaney $

=head1 NAME

Solstice::Logger::Database - Dispatches a log message to a database 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Logger);

use Solstice::Database;
use Solstice::Model::LogMessage;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 1 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=item writeLog($message)

=cut

sub writeLog {
    my $self   = shift;
    my $message = shift;
    
    return FALSE unless (defined $message && defined $message->getContent());
    
    my $service = $self->getLogService('Solstice');

    if($service->get('logger_db_already_logging')){
        warn "Recursive writeLog() call detected! I think we died while logging.";
        return FALSE;
    }
    $service->set('logger_db_already_logging', TRUE);
    
    my $config  = $self->getConfigService();
    my $db_name = $config->getDBName();
    my $log_db_name = $config->get('log_db_name');

    unless ($log_db_name) {
        warn "Config variable 'log_db_name' not defined!";
        return FALSE;
    }

    my $db = Solstice::Database->new();
    $db->writeQuery("INSERT INTO $log_db_name.Log
            (timestamp, user, acting_user, namespace, type, model_id, model, content)
        VALUES (?,?,?,?,?,?,?,?)", 
        $message->getDateTime() ? $message->getDateTime->toSQL() : undef,
        $message->getUsername(),
        $message->getActingUsername(),
        $message->getNamespace(),
        $message->getLogName(),
        $message->getModelID(),
        $message->getModel(),
        $message->getContent()
    );
    
    $service->set('logger_db_already_logging', FALSE);

    return TRUE;
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Logger|Solstice::Logger>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: 3177 $

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

