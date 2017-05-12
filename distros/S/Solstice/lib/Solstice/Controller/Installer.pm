package Solstice::Controller::Installer;

# $Id: $

=head1 NAME

Solstice::Controller::Installer - Controls the process on configuring a new Solstice install 

=head1 SYNOPSIS

=head1 DESCRIPTION

This controls the process of installing/configuring the Solstice Framework, once the initial web presence is in place.  Since most of Solstice isn't ready for use, we can't use almost any of the usual tools for app navigation.

We use a temp file for persistence... ugh.  Better I guess than having hidden form fields with passwords. 

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Controller);

use Digest::MD5 qw(md5_hex);
use File::Path;
use Solstice::View::Installer;
use Solstice::Person;
use DBI;


use Solstice::CGI;

use constant SUCCESS => 1;
use constant FAIL    => 0;
use constant TRUE    => 1;
use constant FALSE   => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->setModel(Solstice::Model::Config::Solstice->new());
    

    return $self;
}

=item getView()

=cut

sub getView {
    my $self = shift;
    
    return Solstice::View::Installer->new($self->getModel());
}

sub update {
    my $self = shift;

    #we pull the data from the form params right into the view, no update is done here
    #The work you would expect in update happens at the top of commit.

    #This is done because using persistence is impossible when the user cannot
    #store a session.

}

sub validate {
    my $self = shift;

    if(param('submit')){
        return $self->_validateBasic() & $self->_validateDB();
    }else{
        return FALSE;
    }
}

sub _validateDB {
    my $self = shift;
    
    $self->createRequiredParam('dbuser');
    $self->createRequiredParam('dbport');
    my $db_const = $self->createRequiredParam('dbhost');
    my $solstice_db_constraint = $self->createRequiredParam('solstice_dbname');
    my $session_db_constraint = $self->createRequiredParam('session_dbname');
    my $pass_const = $self->createRequiredParam('dbpass');
    my $host_name_const = $self->createRequiredParam('host_name');

    my $model = $self->getModel();
    my $host = param('dbhost');
    my $port = param('dbport');
    my $user = param('dbuser');
    my $password = param('dbpass');
    my $password2 = param('dbpass2');
    my $solstice_db = param('solstice_dbname');
    my $session_db = param('session_dbname');

    $pass_const->addConstraint('passwords_do_not_match', sub {
            return $password eq $password2;
        });

    # Make sure the username/password allow us to connect to the host
    $db_const->addConstraint('invalid_credentials', 
        sub {
            my $dbh = DBI->connect("DBI:mysql:mysql:$host:$port", $user, $password, { RaiseError => 0 });
            if (!defined $dbh) {
                $self->getMessageService()->addErrorMessage("Database connection error: $DBI::errstr");
            }
            return defined $dbh;
        }
    );

    # Make sure the solstice db doesn't already exist...
    # Or if it does exist, that it's our version of the db.
    # The version number is the last thing inserted, so it should be safe if that's there.
    $solstice_db_constraint->addConstraint('db_preexists', 
        sub { 
            my $dbh = DBI->connect("DBI:mysql:$solstice_db:$host:$port", $user, $password, { RaiseError => 0 });
            if (!defined $dbh) {
                return TRUE;
            }
            my $sth = $dbh->prepare('SELECT MAX(version) FROM SolsticeVersion');
            $sth->execute();
            unless (defined $DBI::errstr) {
                my ($version) = $sth->fetchrow_array();
                if (defined $version && (1 == $version)) {
                    warn "A full Solstice DB named $solstice_db already exists, not creating or modifying\n";
                    $model->setPersistenceHasSolsticeDB(TRUE);
                    return TRUE;
                }
                warn "A database exists with the name $solstice_db, but it does not appear to be a valid Solstice DB\n";
                   return FALSE;
            }
            else {
                $model->setPersistenceHasSolsticeDB(TRUE);
                $model->setPersistenceHasInvalidSolsticeDB(TRUE);
            }
        }
    );

    $model->setPersistenceHasSessionDB(FALSE);
    $model->setPersistenceHasSolsticeDB(FALSE);

    # Make sure the session db doesn't already exist...
    $session_db_constraint->addConstraint('db_preexists', 
        sub { 
            my $dbh = DBI->connect("DBI:mysql:$session_db:$host:$port", $user, $password, { RaiseError => 0 });
            if (!defined $dbh) {
                return TRUE;
            }
            my $sth = $dbh->prepare('SELECT MAX(version) FROM SessionsVersion');
            $sth->execute();
            unless (defined $DBI::errstr) {
                my ($version) = $sth->fetchrow_array();
                if (defined $version && (1 == $version)) {
                    warn "A full Session DB named $session_db already exists, not creating or modifying\n";
                    $model->setPersistenceHasSessionDB(TRUE);
                    return TRUE;
                }
                warn "A database exists with the name $session_db, but it does not appear to be a valid Session DB\n";
                return FALSE;
            }
            else {
                $model->setPersistenceHasSessionDB(TRUE);
                $model->setPersistenceHasInvalidSessionsDB(TRUE);
            }

        }
    );

    return $self->processConstraints();
}

sub _validateBasic {
    my $self = shift;

    $self->createRequiredParam('server_name');
    my $app_path = $self->createRequiredParam('app_path');
    $self->createRequiredParam('virtual_root');
    $self->createRequiredParam('support_email');
    $self->createRequiredParam('admin_email');
    my $log_path = $self->createRequiredParam('log_directory');
   
    # Make sure we can create the app path 
    $app_path->addConstraint('non_createable_directory', 
        sub { 
            my $path = $self->_cleanupPath($_[0]); 
            return TRUE if (-d $path); 
            return FALSE if (-e $path); 
            my @created;
            eval {
                @created = mkpath($path, 0, oct('0711'));
            };
            if ($@) {
                warn "Error: $@";
                $self->getMessageService()->addErrorMessage(
                    $self->getLangService()->getError('cant_create_path', 
                        {
                            path => $path,
                            error => $@,
                        }
                    )
                );
                return FALSE;
            }
            else {
                return ($path eq $created[$#created]);
            }
        }
    );

    # Make sure the log path doesn't already exist in non-directory format
    $log_path->addConstraint('non_directory', 
        sub { 
            my $path = $self->_cleanupPath($_[0]); 
            return (!-e $path || -d $path); 
        }
    );
    
    # Make sure we can create the log directory
    $log_path->addConstraint('non_createable_directory', 
        sub { 
            my $path = $self->_cleanupPath($_[0]); 
            return TRUE if (-d $path); 
            return FALSE if (-e $path); 
            my @created;
            eval {
                @created = mkpath($path, 0, oct('0711'));  
            };
            if ($@) {
                return FALSE;
            }
            else {
                return ($path eq $created[$#created]); 
            }
        }
    );
    
    # Make sure we can write to our directory
    $log_path->addConstraint('non_writable_directory', 
        sub { 
            my $path = $self->_cleanupPath($_[0]);  
            open (my $TEST, ">", "$path/__solstice_install_test__$$"); 
            close $TEST;  
            my $return = -f "$path/__solstice_install_test__$$"; 
            unlink "$path/__solstice_install_test__$$"; 
            return $return; 
        }
    );
    
    if (!param('generate_key')){
        my $enc_constraint = $self->createRequiredParam('encryption_key');
        $enc_constraint->addLengthConstraint('encryption_length_error', { min => 32, max => 32 });
    }
    
    return $self->processConstraints();
}

sub _cleanupPath {
    my $self = shift;
    my $input = shift;

    $input =~ s/[^a-zA-Z0-9\/\._]//g;
    return $input;
}

sub commit {
    my $self = shift;

    my $model = $self->getModel();
    my $solstice_root = $self->getConfigService()->getRoot();

    my $host = param('dbhost');
    my $port = param('dbport');
    my $user = param('dbuser');
    my $pass = param('dbpass');
    my $solstice_db = param('solstice_dbname');
    my $sessions_db = param('session_dbname');

    # Start by creating the databases
    my $dbh = DBI->connect("DBI:mysql:mysql:$host:$port", $user, $pass, { RaiseError => 0 });

    if (!$model->getPersistenceHasSolsticeDB()) {
        if (!$dbh->do("CREATE DATABASE $solstice_db")) {
            warn "Error: $DBI::errstr\n";
            return;
        }
        if (!$dbh->do("USE $solstice_db")) {
            warn "Error: $DBI::errstr\n";
            return;
        }
        $self->_processMySQLDump($dbh, "$solstice_root/install/solstice.sql");
    }
    if ($model->getPersistenceHasInvalidSolsticeDB()) {
        if (!$dbh->do("USE $solstice_db")) {
            warn "Error: $DBI::errstr\n";
            return;
        }
        $self->_processMySQLDump($dbh, "$solstice_root/install/solstice.sql");
    }
    
    if (!$model->getPersistenceHasSessionDB()) {
        if (!$dbh->do("CREATE DATABASE $sessions_db")) {
            warn "Error: $DBI::errstr\n";
            return;
        }
        if (!$dbh->do("USE $sessions_db")) {
            warn "Error: $DBI::errstr\n";
            return;
        }

        $self->_processMySQLDump($dbh, "$solstice_root/install/sessions.sql");
    }
    if ($model->getPersistenceHasInvalidSessionsDB()) {
        if (!$dbh->do("USE $sessions_db")) {
            warn "Error: $DBI::errstr\n";
            return;
        }
        $self->_processMySQLDump($dbh, "$solstice_root/install/sessions.sql");
    }


    # Write out a new config file.
    $self->_writeNewConfig();
    
    # Force a reload of all solstice data.
    $Solstice::Service::data_store = {};
    $Solstice::Service::Memory::data_store = {};

    $self->getModel()->setPersistenceDone(TRUE);
}


=item _processMySQLDump($dbh, '/path/to/dumpfile.sql')

Takes a mysqldump file, and runs it.

=cut

sub _processMySQLDump {
    my $self = shift;
    my $dbh = shift;
    my $file = shift;

    open (my $DUMP_FILE, "<", $file);

    my $tables_def;
    my @inserts;
    while (<$DUMP_FILE>) {
        # Strip out any comments and drop table lines
        next if (/^--/);
        next if (/^\/\*/);
        next if (/^DROP TABLE/);
        if (/^INSERT INTO/) {
            push @inserts, $_;
            next;
        }
        $tables_def .= $_;
    }

    close $DUMP_FILE;

    my @creates = split(/CREATE TABLE/, $tables_def);

    # Remove the empty first entry...
    shift @creates;

    foreach (@creates) {
        if (!$dbh->do("CREATE TABLE $_")) {
            warn "Error on $_: $DBI::errstr\n";
            return;
        }
    }

    foreach (@inserts) {
        if (!$dbh->do($_)) {
            warn "Error in $_: $DBI::errstr\n";
            return;
        }
    }
}

sub _writeNewConfig {
    my $self = shift;

    my $model = $self->getModel();
    my $solstice_path = $self->getConfigService()->getRoot();
    my $config = Solstice::Model::Config::Solstice->new($solstice_path ."/conf/example_solstice_config.xml");

    # Generate an encryption key, if needed
    my $enc_key = param('encryption_key');
    if (param('generate_key')){
        $enc_key = '';
        for (1 .. 32) {
            # this should give a distribution between ! and ~
            # http://www.lookuptables.com/
            $enc_key .= chr(int(rand(93)+33));
        }
    }

    #Okay, now that we've pulled defaults from the example conf fill out the rest from our data
    $config->setServerString(param('server_name'));
    $config->setRoot(param('solstice_path'));
    $config->setAppDirs([param('app_path')]);
    $config->setDataRoot(param('log_directory'));
    $config->setVirtualRoot(param('virtual_root'));
    $config->setAdminEmail(param('admin_email'));
    $config->setSupportEmail(param('support_email'));
    $config->setDevelopmentMode(param('is_dev')? TRUE : FALSE);
    $config->setEncryptionKey($enc_key); 
    $config->setSessionDB(param('session_dbname'));
    $config->setDBHosts([{
            'password'      => param('dbpass'),
            'database_name' => param('solstice_dbname'),
            'user'          => param('dbuser'),
            'host_name'     => param('dbhost'),
            'type'          => 'master',
            'port'          => param('dbport'),
        }]);
    $config->getKeys()->{'host_name'} = param('host_name');

    my $config_output = $config->store();

    if (open (my $CONFIG, ">", "$solstice_path/conf/solstice_config.xml")) {
        print $CONFIG $config_output;
        close $CONFIG;
    } else {
        $model->setPersistenceNonWritableConfig(TRUE);
        $model->setPersistenceConfigContent($config_output);
    }
}



1;
__END__

=back

=head2 Modules Used

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: $



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
