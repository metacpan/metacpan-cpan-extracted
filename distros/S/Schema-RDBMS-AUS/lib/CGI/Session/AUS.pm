#!perl

package CGI::Session::AUS;

use strict;
use warnings;
use CGI;
use CGI::Session;
use Schema::RDBMS::AUS::User;
use CGI::Session::Driver::aus;
use CGI::Session::ID::md5;
use CGI::Session::Serialize::yaml;
use base q(CGI::Session);

# workaround CGI::Session::Serialize::storable bug in 4.03

if(!@CGI::Session::Serialize::storable::ISA) {
    @CGI::Session::Serialize::storable::ISA = ("CGI::Session::ErrorHandler");
}

return 1;

# Utility methods

sub remote_ip {
    my $self = shift;
    my $ip;
    
    if($ENV{REMOTE_ADDR}) {
        $ip = $ENV{REMOTE_ADDR};
    } elsif($self->param('_SESSION_REMOTE_ADDR')) {
        $ip = $self->param('_SESSION_REMOTE_ADDR');
    }
    
    return $ip;
}

sub log_opts {
    my $self = shift;
    my %log_opts;
    
    if(defined(my $ip = $self->remote_ip)) {
        $log_opts{ip} = $ip;
    }
    
    $log_opts{session_id} = $self->id;
    $log_opts{_dbh} = $self->_driver->{Handle} unless exists $log_opts{_dbh};
    
    if(my $user = $self->user) {
        $log_opts{name} = $user->{name} unless exists $log_opts{name};
        $log_opts{id} = $user->{id} unless exists $log_opts{id};
    }
    
    return %log_opts;
}

# User methods

sub login {
    my($self, $name, $pass, %o) = @_;
    
    %o = ($self->log_opts, %o);
    
    if(my $user = eval { Schema::RDBMS::AUS::User->login($name, $pass, %o) }) {
        $self->{_user} = $user;
        $self->_set_status($self->STATUS_MODIFIED);
        $self->flush();
        return $user;
    } else {
        delete $self->{_user};
        die $@;
    }
}

sub logout {
    my($self, %log_opts) = shift;

    %log_opts = ($self->log_opts, %log_opts);
    
    if(my $user = $self->{_user}) {
        $user->{_dbh}->transaction(sub {
            $user->refresh;
            $user->log('logout', %log_opts);
            $user->save;
        });
        delete $self->{_user};
    }

    $self->flush();
    return 1;
}

# Overriden methods

sub flush {
    my $self = shift;

    return unless $self->id;            # <-- empty session
    return if $self->{_STATUS} == 0;    # <-- neither new, deleted nor modified

    if (
        $self->_test_status($self->STATUS_NEW) &&
        $self->_test_status($self->STATUS_DELETED)
    ) {
        $self->{_DATA} = {};
        delete $self->{_user};
        delete $self->{_session_meta};
        return $self->_unset_status($self->STATUS_NEW, $self->STATUS_DELETED);
    }

    my $driver      = $self->_driver();
    my $serializer  = $self->_serializer();

    if ($self->_test_status($self->STATUS_DELETED)) {
        defined($driver->remove($self->id)) or
            return $self->set_error(
                "flush(): couldn't remove session data: " . $driver->errstr
        );
        
        $self->{_DATA} = {};    # <-- removing all the data, making sure
                                # it won't be accessible after flush()
        delete $self->{_user};
        delete $self->{_session_meta};
        return $self->_unset_status($self->STATUS_DELETED);
    }

    if (
        $self->_test_status($self->STATUS_NEW) ||
        $self->_test_status($self->STATUS_MODIFIED)
    ) {
        my $datastr = $serializer->freeze( $self->dataref );
        unless (defined $datastr) {
            return $self->set_error(
                "flush(): couldn't freeze data: " . $serializer->errstr
            );
        }
        defined($driver->store($self->id, $datastr, $self)) or
            return $self->set_error(
                "flush(): couldn't store datastr: " . $driver->errstr
            );
        $self->_unset_status($self->STATUS_NEW, $self->STATUS_MODIFIED);
    }
    
    return 1;
}

sub load {
    my $class = shift;
    @_ = (undef, undef, undef) if !@_;
    $_[0] = "d:aus;s:yaml;i:md5" unless defined $_[0] || @_ < 2;
    $_[1] = $ENV{AUS_SESSION_ID} if $ENV{AUS_SESSION_ID} && !defined $_[1];
    if(my $self = $class->SUPER::load(@_)) {
        my $meta = $self->_driver->retrieve_meta($self->id);
        $self->{_session_meta} = $meta;
        if(my $uid = $meta->{'user_id'}) {
            $self->{_user} = Schema::RDBMS::AUS::User->load(
                id => $uid, _dbh => $self->_driver->{Handle}
            );
        }
        return $self;
    }
}

# Metadata methods

sub user {
    my $self = shift;
    return $self->{_user};
}

sub created {
    my $self = shift;
    return $self->{_session_meta}->{created};
}

sub time_last {
    my $self = shift;
    return $self->{_session_meta}->{time_last};
}
