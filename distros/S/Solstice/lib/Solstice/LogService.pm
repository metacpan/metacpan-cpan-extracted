package Solstice::LogService;

# $Id: LogService.pm 3364 2006-05-05 07:18:21Z mcrawfor $
#
=head1 NAME

Solstice::LogService - Provides a centralized logging facility to applications.

=head1 SYNOPSIS


    $self->getLogService()->log({
        content     => 'User did blah',     #the content of the log message
        namespace   => 'appname',           #optional - the directory in the data root to use - defaults to the app's namespace
        username    => 'mcrawfor',          #optional - current user is pulled from userservice if not provided
        log_file    => 'blah_log',          #optional - defaults to 'log';
        model       => $model->getName(),   #Optional - a textual description of a model
        model_id    => $model->getID(),     #optional - the id of the model in question
    

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::DateTime;
use Solstice::Model::LogMessage;

use constant DEFAULT_LOGFILE => 'log';

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new([$namespace])

Creates a new Solstice::LogService object.

=cut

sub new {
    my $class = shift;
    my $namespace = shift;
    
    my $self = $class->SUPER::new(@_);

    unless (defined $namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    $self->setNamespace($namespace);

    return $self;
}


=item log(\%params)

=cut

sub log {
    my $self = shift;
    my $params = shift;
    return unless defined $params;
    
    my $message = Solstice::Model::LogMessage->new();
   
    if ($params->{'username'}) {
        $message->setUsername($params->{'username'});
    } else {
        my $user_service = $self->getUserService();
        $message->setUsername($user_service->getOriginalUser() ? $user_service->getOriginalUser()->getScopedLoginName() : undef);
        $message->setActingUsername($user_service->getUser() ? $user_service->getUser()->getScopedLoginName() : undef);
    }
        
    $message->setContent($params->{'content'});
    $message->setNamespace($params->{'namespace'} || $self->getNamespace());
    $message->setLogName($params->{'log_file'} || DEFAULT_LOGFILE);
    $message->setModel($params->{'model'});
    $message->setModelID($params->{'model_id'});
    $message->setDateTime(Solstice::DateTime->new(time));
    
    return $self->_dispatch($message);
}

=item logAnonymous(\%params)

This is equivalent to log(), but the username and timestamp won't be passed on to the logging modules

=cut

sub logAnonymous {
    my $self = shift;
    my $params = shift;
    return unless defined $params;

    my $message = Solstice::Model::LogMessage->new();
    $message->setContent($params->{'content'});
    $message->setNamespace($params->{'namespace'} || $self->getNamespace());
    $message->setLogName($params->{'log_file'} || DEFAULT_LOGFILE);
    $message->setModel($params->{'model'});
    $message->setModelID($params->{'model_id'});

    return $self->_dispatch($message);
}

=item add(\%params)

Alias for log().

=cut

sub add {
    my $self = shift;
    return $self->log(@_);
}

=back

=head2 Private Methods

=over 4

=cut

=item _dispatch($message)

=cut

sub _dispatch {
    my $self = shift;
    my $message = shift;

    for my $module (@{ $self->getConfigService()->getLogModules() }){
        $self->loadModule($module);
        my $logger = $module->new();
        $logger->writeLog($message) if $logger->can('writeLog');
    }
    return; 
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::LogService';
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>,
L<Solstice::Model::LogMessage|Solstice::Model::LogMessage>.

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
