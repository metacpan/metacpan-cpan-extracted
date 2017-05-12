package Provision::Unix::User::Linux;
# ABSTRACT: provision user accounts on Linux systems
$Provision::Unix::User::Linux::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use Params::Validate qw( :all );

use lib 'lib';
use Provision::Unix;
my ( $prov, $user, $util );

sub new {
    my $class = shift;
    my %p = validate(
        @_,
        {   prov  => { type => OBJECT },
            user  => { type => OBJECT },
            debug => { type => BOOLEAN, optional => 1, default => 1 },
            fatal => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    $prov = $p{prov};
    $user = $p{user};

    my $self = {
        prov  => $prov,
        user  => $user,
        debug => $p{debug},
        fatal => $p{fatal},
    };
    bless( $self, $class );

    $prov->audit("loaded User/Linux");
    $util = $prov->get_util;
    return $self;
}

sub create {
    my $self = shift;
    my %p = validate(
        @_,
        {   'username' => { type => SCALAR },
            'uid'      => { type => SCALAR, optional => 1 },
            'gid'      => { type => SCALAR, optional => 1 },
            'shell'    => { type => SCALAR | UNDEF, optional => 1 },
            'password' => { type => SCALAR | UNDEF, optional => 1 },
            'homedir'  => { type => SCALAR | UNDEF, optional => 1 },
            'gecos'    => { type => SCALAR | UNDEF, optional => 1 },
            'domain'   => { type => SCALAR | UNDEF, optional => 1 },
            'expire'   => { type => SCALAR | UNDEF, optional => 1 },
            'quota'    => { type => SCALAR | UNDEF, optional => 1 },
            'debug'    => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => SCALAR, optional => 1 },
        }
    );

    my $debug    = $p{debug};
    my $username = $p{username};
    my $password = $p{password};
    $prov->audit("creating user '$username' on $OSNAME");

    $user->_is_valid_username( $username ) or return;
    my $group = $p{gid} || $self->exists_group( $username );

    my $cmd = $util->find_bin( 'useradd', debug => 0 );
    $cmd .= " -c '$p{gecos}'" if $p{gecos};
    $cmd .= " -d $p{homedir}" if $p{homedir};
    $cmd .= " -e $p{expire}"  if $p{expire};
    $cmd .= " -u $p{uid}"     if $p{uid};
    $cmd .= " -s $p{shell}"   if $p{shell};
    $cmd .= " -g $group"      if $group;
    $cmd .= " -m $username";

    return $prov->audit("\ttest mode early exit") if $p{test_mode};
    $util->syscmd( $cmd, debug => 0, fatal => 0 ) or return;

    if ( $password ) {
        my $passwd = $util->find_bin( 'passwd', debug => $p{debug} );
        ## no critic
        my $FH;
        unless ( open $FH, "| $passwd --stdin $username" ) {
            return $prov->error( "opening passwd failed for $username" );
        }
        print $FH "$password\n";
        close $FH;
        ## use critic
    }

    $self->exists() or 
        return $prov->error( "failed to create user $username", fatal => 0 );
    
    $prov->audit( "created user $username successfully");
    return 1;
}

sub create_group {

    my $self = shift;

    my %p = validate(
        @_,
        {   'group' => { type => SCALAR },
            'gid'   => { type => SCALAR, optional => 1, },
            'debug' => { type => SCALAR, optional => 1, default => 1 },
            'fatal' => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    # see if the group exists
    if ( $self->exists_group( $p{group} ) ) {
        $prov->audit("create_group: '$p{group}', already exists");
        return 2;
    }

    $prov->audit("create_group: installing $p{group} on $OSNAME");

    my $cmd = $util->find_bin( 'groupadd', debug => $p{debug} );
    $cmd .= " -g $p{gid}" if $p{gid};
    $cmd .= " $p{group}";

    return $util->syscmd( $cmd, debug => $p{debug} );
}

sub destroy {
    my $self = shift;
    my %p = validate(
        @_,
        {   'username'  => { type => SCALAR, },
            'homedir'   => { type => SCALAR, optional => 1, },
            'archive'   => { type => BOOLEAN, optional => 1, default => 0 },
            'prompt'    => { type => BOOLEAN, optional => 1, default => 0 },
            'test_mode' => { type => BOOLEAN, optional => 1, default => 0 },
            'fatal'     => { type => SCALAR, optional => 1, default => 1 },
            'debug'     => { type => SCALAR, optional => 1, default => 1 },
        },
    );

    my $username = $p{username};
    $prov->audit("removing user $username on $OSNAME");

    $user->_is_valid_username( $username ) or return;
    my $homedir = ( getpwnam( $username ) )[7];

    return $prov->audit("\ttest mode early exit") if $p{test_mode};

    # make sure user exists
    if ( !$self->exists() ) {
        return $prov->progress(
            num  => 10,
            desc => 'error',
            err  => "\tno such user '$username'",
        );
    }

    my $userdel = $util->find_bin( 'userdel', debug => $p{debug} );

    my $opts = " -f";
    $opts .= " -r" if -d $homedir && $homedir ne '/tmp';
    $opts .= " $username";

    my $r = $util->syscmd( "$userdel $opts", debug => 0, fatal => $p{fatal} );

    # validate that the user was removed
    if ( !$self->exists() ) {
        return $prov->progress(
            num  => 10,
            desc => "\tdeleted user $username"
        );
    }

    return $prov->progress(
        num   => 10,
        desc  => 'error',
        'err' => "\tfailed to remove user '$username'",
    );
}

sub destroy_group {

    my $self = shift;

    my %p = validate(
        @_,
        {   'group'     => { type => SCALAR, },
            'gid'       => { type => SCALAR, optional => 1 },
            'test_mode' => { type => BOOLEAN, optional => 1, default => 0 },
            'fatal'     => { type => SCALAR, optional => 1, default => 1 },
            'debug'     => { type => SCALAR, optional => 1, default => 1 },
        },
    );

    my $group = $p{group};
    my $fatal = $p{fatal};
    my $debug = $p{debug};
    $prov->audit("destroy group $group on $OSNAME");

    $prov->progress( num => 1, desc => 'validating' );

    if ( !$self->exists_group( $group ) ) {
        $prov->progress( num => 10, desc => "group $group does not exist" );
        return 1;
    }

    my $cmd = $util->find_bin( 'groupdel', debug => 0 );
    $cmd .= " $group";

    return 1 if $p{test_mode};
    $prov->audit("destroy group cmd: $cmd");

    $util->syscmd( $cmd, debug => $debug, fatal => $fatal )
        or return $prov->progress(
        num   => 10,
        desc  => 'error',
        'err' => $prov->{errors}->[-1]->{errmsg},
        );

    # validate that the group was removed
    if ( !$self->exists_group( $group ) ) {
        return $prov->progress( num => 10, desc => 'completed' );
    }

    return;
}

sub exists {
    my $self = shift;
    my $username = shift || $user->{username};

    $user->_is_valid_username($username)
        or return $prov->error( "missing/invalid username param in request",
            fatal => 0,
        );

    $username = lc $username;

    if ( -f '/etc/passwd' ) {
        my $exists = `grep '^$username:' /etc/passwd`; 
        return if ! $exists;
        chomp $exists;
        $prov->audit("\t'$username' exists (passwd: $exists)");
        return $exists;
    }

    restart_nscd();

    my $uid = getpwnam $username;
    return $prov->error("could not find user $user", fatal => 0 ) if ! defined $uid;

    $prov->audit("'$username' exists (uid: $uid)");
    $self->{uid} = $uid;
    return $uid;
}

sub exists_group {
    my $self = shift;
    my $group = shift || $user->{group} || $prov->error( "missing group" );

    if ( -f '/etc/group' ) {
        my $exists = `grep '^$group:' /etc/group`;
        return if ! $exists;

        my (undef, undef, $gid) = split /:/, $exists;
        $prov->audit("found group $group at gid $gid");
        return $gid;
    };

    restart_nscd();

    my $gid = getgrnam($group);
    if ( defined $gid ) {
        $prov->audit("found group $group at gid $gid");
        return $gid;
    };
}

sub modify {
    my $self = shift;
    my %p = validate(
        @_,
        {   'username'  => { type => SCALAR },
            'shell'     => { type => SCALAR, optional => 1 },
            'password'  => { type => SCALAR, optional => 1 },
            'ssh_key'   => { type => SCALAR, optional => 1 },
            'gecos'     => { type => SCALAR, optional => 1 },
            'expire'    => { type => SCALAR, optional => 1 },
            'quota'     => { type => SCALAR, optional => 1 },
            'debug'     => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => SCALAR, optional => 1 },
        }
    );

    if ( $p{password} ) {
        $self->set_password( 
            username => $p{username}, 
            password => $p{password}, 
            ssh_key  => $p{ssh_key},
        );
    };
};

sub set_password {
    my $self = shift;
    my %p = validate(
        @_,
        {   username   => { type => SCALAR },
            password   => { type => SCALAR, optional => 1 },
            ssh_key    => { type => SCALAR, optional => 1 },
            ssh_restricted => { type => SCALAR, optional => 1 },
            debug      => { type => SCALAR, optional => 1, default => 1 },
            fatal      => { type => SCALAR, optional => 1, default => 1 },
            test_mode  => { type => SCALAR, optional => 1 },
        }
    );

    my $fatal = $p{fatal};
    my $username = $p{username};

    $prov->error( "user '$username' not found", fatal => $fatal ) 
        if ! $self->exists( $username );

    my $pass_file = "/etc/shadow";  # SYS 5
    if ( ! -f $pass_file ) {
        $pass_file = "/etc/passwd";
        -f $pass_file or return $prov->error( "could not find password file", fatal => $fatal );
    };

    my @lines = $util->file_read( $pass_file, fatal => $fatal, debug => 0 );
    my $entry = grep { /^$username:/ } @lines;
    $entry or return $prov->error( "could not find user '$username' in $pass_file!", fatal => $fatal);

    my $crypted = $user->get_crypted_password( $p{password} );

    foreach ( @lines ) {
        s/$username\:.*?\:/$username\:$crypted\:/ if m/^$username\:/;
    };
    $util->file_write( $pass_file, lines => \@lines, debug => 0, fatal => 0)
        or $prov->error("failed to update password for $username", fatal => $fatal);

    if ( $p{ssh_key} ) {
        @lines = $util->file_read( '/etc/passwd', debug => 1, fatal => $fatal );
        ($entry) = grep { /^$username:/ } @lines;
        my $homedir = (split(':', $entry))[5];
        $homedir && -d $homedir or 
            return $prov->error("unable to determine home directory for $username", fatal => 0);
        $user->install_ssh_key( 
            homedir        => $homedir, 
            ssh_key        => $p{ssh_key}, 
            ssh_restricted => $p{ssh_restricted},
            username       => $username,
            fatal          => $fatal,
        );
    };
    return 1;
};

sub restart_nscd {

    my $nscd = '/var/run/nscd/nscd.pid';
    return if ! -f $nscd;

    my $pid = `cat $nscd`; chomp $pid;
    return if ! $pid;

    $nscd = $util->find_bin( 'nscd', debug => 0 );
    return if ! -x $nscd;

    `killall -w nscd`;
    `$nscd`;
    sleep 1; # give the daemon a chance to get started

    $prov->audit("restarted nscd caching daemon");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::User::Linux - provision user accounts on Linux systems

=head1 VERSION

version 1.08

=head1 SYNOPSIS

Handles provisioning operations (create, modify, destroy) for system users on UNIX based operating systems.

    use Provision::Unix::User::Linux;

    my $provision_user = Provision::Unix::User::Linux->new();
    ...

=head1 FUNCTIONS

=head2 new

Creates and returns a new Provision::Unix::User::Linux object.

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-user at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Provision-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Provision-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Provision-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/Provision-Unix>

=back

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
