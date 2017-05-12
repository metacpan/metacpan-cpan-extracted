package Provision::Unix::User::FreeBSD;
# ABSTRACT: provision user accounts on FreeBSD systems
$Provision::Unix::User::FreeBSD::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use Params::Validate qw( :all );

use lib 'lib';

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

    my $self = {
        prov  => $p{prov},
        user  => $p{user},
        debug => $p{debug},
        fatal => $p{fatal},
    };
    bless( $self, $class );

    $prov = $p{prov};
    $user = $p{user};
    $prov->audit("loaded User/FreeBSD");
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
            'disable_paranoi' => { type => SCALAR, optional => 1 },
            'debug'    => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => SCALAR, optional => 1 },
        }
    );

    my $debug = $p{'debug'};
    $prov->audit("creating FreeBSD user");

    my $username = $p{'username'};
    my $shell    = $p{'shell'} || "/sbin/nologin";
    my $homedir  = $p{'homedir'};
    my $uid      = $p{'uid'};
    my $gid      = $p{'gid'};

    $user->{username} = $username;
    $user->_is_valid_username() or return;

    if ( ! $p{disable_paranoi} ) {
        my $bak = $util->archive_file( "/etc/master.passwd",
            fatal => 0,
            debug => 0,
            destdir => '/var/backups',
            mode    => oct(0),
        );
        $prov->audit("user->create: backed up master.passwd to $bak");
    };

    # pw creates accounts using defaults from /etc/pw.conf
    my $pw = $util->find_bin( "pw", debug => 0 );
    my $pwcmd = "$pw useradd -n $username ";

    $pwcmd .= "-d $homedir "    if $homedir;
    $pwcmd .= "-u $uid "        if $uid;
    $pwcmd .= "-g $gid "        if $gid;
    if ( $p{'gecos'} ) {
        $p{'gecos'} =~ s/"//g;
        $pwcmd .= "-c \"$p{'gecos'}\" ";
    };
    $pwcmd .= "-u 89 -g 89 -c Vpopmail-Master "
        if ( $username eq "vpopmail" );
    $pwcmd .= "-n $username -d /nonexistent -c Clam-AntiVirus "
        if ( $username eq "clamav" );
    $pwcmd .= "-s $shell ";
    $pwcmd .= "-m ";

    $prov->audit("pw command is: $pwcmd");
    return 1 if $p{test_mode};

    if ( $p{password} ) {
        $prov->audit("pw command is: $pwcmd -h 0 (****)");

        ## no critic
        my $FH;
        unless ( open $FH, "| $pwcmd -h 0" ) {
            return $prov->error( "user_add: opening pw failed for $username" );
        }
        print $FH "$p{password}\n";
        close $FH;
        ## use critic
    }
    else {
        $prov->audit("pw command is: $pwcmd -h-");
        $util->syscmd( "$pwcmd -h-", debug => 0 );
    }

### TODO
    # call verify_master_passwd

    # set up user quotas
    # $user->quota_set( user => $username )

    return $self->exists($username)
        ? $prov->progress( num => 10, desc => 'created successfully' )
        : $prov->error( 'create user failed' );
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
        $prov->audit("create_group: $p{group} exists");
        return 2;
    }

    $prov->audit("create_group: installing $p{group} on $OSNAME");

    # use the pw tool to add the user
    my $pw = $util->find_bin( "pw", debug => $p{debug} );
    $pw .= " groupadd -n $p{group}";
    $pw .= " -g $p{gid}" if $p{gid};

    return $util->syscmd( $pw, debug => $p{debug} );
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

    $prov->audit("destroy user $p{username} on FreeBSD");

    $prov->progress( num => 1, desc => 'validating' );

    return 1 if $p{test_mode};

    # make sure user exists
    if ( !$user->exists( $p{username} ) ) {
        return $prov->progress(
            num  => 10,
            desc => 'error',
            err  => 'no such user'
        );
    }

### TODO
    # this would be a good time to archive the user if desired.

    my $bak = $util->archive_file( "/etc/master.passwd",
        fatal => $p{fatal},
        debug => $p{debug},
        destdir => '/var/backups',
        mode    => oct(0),
    );
    $prov->progress( num => 2, desc => "backed up master.passwd." );

    my $pw = $util->find_bin( 'pw', debug => 0 );
    $pw .= " userdel -n $p{username} -r";

    my $r = $util->syscmd( $pw, debug => $p{debug},
        fatal => $p{fatal} );
    $prov->progress( num => 3, desc => "deleted user" );

## TODO
    # verify_master_passwd

    # validate that the user was removed
    if ( !$user->exists( $p{username} ) ) {
        return $prov->progress( num => 10, desc => 'completed' );
    }

    return $prov->progress(
        num   => 10,
        desc  => 'error',
        'err' => $prov->{errors}->[-1]->{errmsg},
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

    $prov->audit("destroy group $p{group} on FreeBSD");

    $prov->progress( num => 1, desc => 'validating' );

    # make sure group exists
    if ( !$user->exists_group( $p{group} ) ) {
        return $prov->progress(
            num  => 10,
            desc => 'error',
            err  => 'no such group'
        );
    }

    my $bak = $util->archive_file( "/etc/group",
        fatal => $p{fatal},
        debug => $p{debug},
        destdir => '/var/backups',
        mode    => oct(0),
    );
    $prov->progress( num => 2, desc => "backed up /etc/group" );

    my $pw = $util->find_bin( 'pw', debug => 0 );
    $pw .= " groupdel -n $p{group}";

    my $r = $util->syscmd( $pw, debug => $p{debug} );
    $prov->progress( num => 3, desc => "deleted group" );

    # validate that the group was removed
    if ( !$user->exists_group( $p{group} ) ) {
        return $prov->progress( num => 10, desc => 'completed' );
    }

    return $prov->progress(
        num   => 10,
        desc  => 'error',
        'err' => $prov->{errors}->[-1]->{errmsg},
    );
}

sub exists {
    my $self = shift;
    my $username = lc(shift) || $user->{username} || die "missing user";

    my $uid = getpwnam($username);
    $self->{uid} = $uid;
    return ( $uid && $uid > 0 ) ? $uid : undef;
}

sub exists_group {

    my $self = shift;
    my $group = lc(shift) or die "missing group";

    my $gid = getgrnam($group);

    return ( $gid && $gid > 0 ) ? $gid : undef;
}

sub verify_master_passwd {

  #    my $r = $user->verify_master_passwd ($passwd, $change, $debug)
  #    $r->{'error_code'} == 200 ? print "success" : print $r->{'error_desc'};
  #    $passwd is the filename of your master.passwd file.
  #    $change is whether the file should "shrink" or "grow"

    my ( $self, $passwd, $change, $debug ) = @_;
    my %r;

    my $new = ( stat($passwd) )[7];
    my $old = ( stat("$passwd.bak") )[7];

    # do we expect it to change?
    if ($change) {
        if ( $change eq "grow" ) {
            if ( $new > $old ) {

                # yay, it grew. response with a success code
                print
                    "verify_master_passwd: The file grew ($old to $new) bytes.\n"
                    if $debug;
                $r{'error_code'} = 200;
                $r{'error_desc'}
                    = "Success: the file grew from $old to $new bytes.";
                return \%r;
            }
            else {

                # boo, it didn't grow. return a failure code and
                # make an archived copy of it for recovery
                print
                    "verify_master_passwd: WARNING: new $passwd size ($new) is not larger than $old and we expected it to $change.\n"
                    if $debug;
                $util->archive_file( "$passwd.bak", destdir => '/var/backups', mode => oct(0) );
                $r{'error_code'} = 500;
                $r{'error_desc'}
                    = "new $passwd size ($new) is not larger than $old and we expected it to $change.\n";
                return \%r;
            }
        }
        elsif ( $change eq "shrink" ) {
            if ( $new < $old ) {

                # yay, it shrank. response with a success code
                print
                    "verify_master_passwd: The file shrank ($old to $new) bytes.\n"
                    if $debug;
                $r{'error_code'} = 200;
                $r{'error_desc'}
                    = "The file shrank from $old to $new bytes.\n";
                return \%r;
            }
            else {

                # boo, it didn't shrink. return a failure code and
                # make an archived copy of it for recovery
                print
                    "verify_master_passwd: WARNING: new $passwd size ($new) is not smaller than $old and we expected it to $change.\n"
                    if $debug;
                $r{'error_code'} = 500;
                $r{'error_desc'}
                    = "new $passwd size ($new) is not smaller than $old and we expected it to $change.\n";
                $util->archive_file( "$passwd.bak", destdir => '/var/backups', mode => oct(0) );
                return \%r;
            }
        }
    }

    # just report
    if ( $new == $old ) {
        print "verify_master_passwd: The files are the same size ($new)!\n"
            if $debug;
    }
    else {
        print
            "verify_master_passwd: The files are different sizes new: $new old: $old!\n"
            if $debug;
    }
}

sub archive {


    my ( $self, $user, $debug ) = @_;

    my $tar = $util->find_bin( "tar" );
    my $rm  = $util->find_bin( "rm" );

    if ( !$self->exists($user) ) {
        $prov->error( "user $user does not exist!" );
    }

    my $homedir = ( getpwnam($user) )[7];
    unless ( -d $homedir ) {
        $prov->error( "The home directory does not exist!" );
    }

    my ( $path, $userdir ) = $util->path_parse( { dir => $homedir } );

    chdir($path)
        or $prov->error( "couldn't cd to $path: $!\n" );

    if ( -e "$path/$user.tar.gz" && -d "$path/$user" ) {
        warn "user_archive:\tReplacing old tarfile $path/$user.tar.gz.\n";
        system "$rm $path/$user.tar.gz";
    }

    print "\tArchiving $user\'s files to $path/$user.tar.gz...." if $debug;
    print "$tar -Pzcf $homedir.tar.gz $userdir\n";
    system "$tar -Pzcf $homedir.tar.gz $userdir";

    if ( -e "${homedir}.tar.gz" ) {
        print "done.\n" if $debug;
        return 1;
    }
    else {
        warn "\nFAILED: user_archive couldn't complete $homedir.tar.gz.\n\n";
        return 0;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::User::FreeBSD - provision user accounts on FreeBSD systems

=head1 VERSION

version 1.08

=head1 SYNOPSIS

Handles provisioning operations (create, modify, destroy) for system users on UNIX based operating systems.

    use Provision::Unix::User::FreeBSD;

    my $user_fbsd = Provision::Unix::User::FreeBSD->new();
    ...

=head2 archive

Create's a tarball of the users home directory. Typically done right before you rm -rf their home directory as part of a de-provisioning step.

    if ( $prov->user_archive("user") ) 
    {
        print "user archived";
    };

returns a boolean.

=head1 FUNCTIONS

=head2 verify_master_passwd

Verify that new master.passwd is the right size. I found this necessary on some versions of FreeBSD as a race condition would cause the master.passwd file to get corrupted. Now I verify that after I'm finished making my changes, the new file is a small amount larger (or smaller) than the original.

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
