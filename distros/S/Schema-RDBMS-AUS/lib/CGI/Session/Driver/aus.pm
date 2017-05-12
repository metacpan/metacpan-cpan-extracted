#!perl

package CGI::Session::Driver::aus;

use strict;
use warnings;
use CGI::Session::Driver::DBI;
use base qw(CGI::Session::Driver::DBI);
use Schema::RDBMS::AUS;
use Carp qw(croak);

return 1;

sub driver_required { 0; }
sub driver_required_here { 0; }

sub session_class { "CGI::Session::Driver::DBI" }

sub session_method {
    my($self, $method, @args) = @_;
    my $class = $self->session_class;
    my $coderef = $class->can($method) or croak "$class can not do $method!";
    return $coderef->($self, @args);
}

sub session_txn_method {
    my($self, $method, @args) = @_;
    return $self->{Handle}->transaction(
        sub { $self->session_method($method, @args); }
    );
}

sub new {
    my($class, $args) = @_;
    $args = {} unless $args;
        
    unless(exists $args->{Handle}) {
        my @db_opts = Schema::RDBMS::AUS->db_opts(
            @$args{qw(DataSource User Password)}
        );
        
        $args->{Handle} = Schema::RDBMS::AUS->dbh(@db_opts);
    }
    
    $args->{TableName} = 'aus_session'
        unless exists $args->{TableName};
    
    $args->{_aus_driver} = $args->{Handle}->{Driver}->{Name}
        unless exists $args->{_aus_driver};
        
    return $class->SUPER::new($args);
}

sub init {
    my $self = shift;
    return $self->session_method('init', @_);
}

sub store_update_sth {
    my $self = shift;
    my $sth = $self->{Handle}->prepare_cached(q{
        UPDATE aus_session
            SET user_id = ?, time_last = now()
            WHERE id = ?
    });
    return $sth;
}

sub store {
    my($self, $sid, $data, $session) = @_;
    my @args = @_;
    shift @args;

    return $self->{Handle}->transaction(sub {
        my $dataref = $session->dataref;
        my $rv = $self->session_method('store', @args);
        
        if($rv) {
            my $sth = $self->store_update_sth;
            my $uid = $session->{_user} ? $session->{_user}->{id} : undef;
            if($sth->execute($uid, $session->id)) {
                return $rv;
            } else {
                warn "execute() failed: ", $sth->errstr;
                return 0;
            }
        } else {
            return $rv;
        }
    });
}

sub traverse {
    my $self = shift;
    return $self->session_txn_method('traverse', @_);
}

sub remove {
    my $self = shift;
    return $self->session_txn_method('remove', @_);
}

sub retrieve_meta {
    my($self, $session_id) = @_;
    return $self->{Handle}->transaction(sub {
        my $sth = $self->{Handle}->prepare_cached(q{
            SELECT created, time_last, user_id FROM aus_session WHERE id = ?
        });

        if($sth->execute($session_id)) {
            my $rv = $sth->fetchrow_hashref;
            $sth->finish;
            return $rv;
        } else {
            die "Fetching session metadata failed: ", $self->{Handle}->errstr;
        }
    });
}

sub retrieve {
    my $self = shift;
    return $self->session_txn_method('retrieve', @_);
}

sub DESTROY {
    my $self = shift;
    $self->{Handle}->disconnect() if($self->{_disconnect});
}
