package Provision::Unix::User;
# ABSTRACT: provision unix user accounts
$Provision::Unix::User::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use File::Path;
use Params::Validate qw( :all );

use lib 'lib';
use Provision::Unix::Utility;

my ( $util, $prov );

sub new {
    my $class = shift;

    my %p = validate(
        @_,
        {   prov  => { type => OBJECT },
            debug => { type => BOOLEAN, optional => 1, default => 1 },
            fatal => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $self = {
        prov  => $p{prov},
        debug => $p{debug},
        fatal => $p{fatal},
    };
    bless( $self, $class );

    $prov = $p{prov};
    $prov->audit("loaded User");
    $self->{os} = $self->_get_os() or return;

    $util = Provision::Unix::Utility->new( log => $prov );
    return $self;
}

sub create {

    ############################################
    # Usage      : $user->create( username=>'bob',uid=>501} );
    # Purpose    : creates a new system user
    # Returns    : uid of new user or undef on failure
    # Parameters :
    #   Required : username
    #            : uid
    #            : guid
    #   Optional : password,
    #            : shell
    #            : homedir
    #            : gecos, quota, uid, gid, expire,
    #            : domain  - if set, account homedir is $HOME/$domain
    # Throws     : exceptions

    my $self = shift;
    return $self->{os}->create(@_);
}

sub create_group {

    my $self = shift;
    return $self->{os}->create_group(@_);
}

sub modify {
    my $self = shift;
    $self->{os}->modify(@_);
}

sub destroy {

    my $self = shift;
    return $self->{os}->destroy(@_);
}

sub destroy_group {

    my $self = shift;
    return $self->{os}->destroy_group(@_);
}

sub exists {

    ############################################
    # Usage      : $user->exists('builder_bob')
    # Purpose    : Check if a user account exists
    # Returns    : the uid of the user or undef
    # Parameters :
    # Throws     : no exceptions
    # Comments   : Use this before adding a new user (error trapping)
    #               and also after adding a user to verify success.

    my $self = shift;
    return $self->{os}->exists(@_);
}

sub exists_group {

    ############################################
    # Usage      : $user->exists_group('builder_bob')
    # Purpose    : Check if a group exists
    # Returns    : the gid of the group or undef
    # Parameters :
    # Throws     : no exceptions
    # Comments   : Use this before adding a new group (error trapping)
    #               and also after adding to verify success.

    my $self = shift;
    return $self->{os}->exists_group(@_);
}

sub set_password {
    my $self = shift;
    return $self->{os}->set_password(@_);
};

sub quota_set {

    # Quota::setqlim($dev, $uid, $bs, $bh, $is, $ih, $tlo, $isgrp);
    # $dev     - filesystem mount or device
    # $bs, $is - soft limits for blocks and inodes
    # $bh, $ih - hard limits for blocks and inodes
    # $tlo     - time limits (0 = first user write, 1 = 7 days)
    # $isgrp   - 1 means that uid = gid, group limits set

    my $self = shift;

    # parameter validation here
    my %p = validate(
        @_,
        {   'conf'   => { type => HASHREF, optional => 1, },
            'user'   => { type => SCALAR,  optional => 0, },
            'quota'  => { type => SCALAR,  optional => 1, default => 100 },
            'fatal'  => { type => BOOLEAN, optional => 1, default => 1 },
            'debug'  => { type => BOOLEAN, optional => 1, default => 1 },
        },
    );

    my ( $conf, $username, $quota, $fatal, $debug )
        = ( $p{conf}, $p{user}, $p{quota}, $p{fatal}, $p{debug} );

    require Quota;

    my $dev = $conf->{quota_filesystem} || "/home";
    my $uid = getpwnam($username) or return $prov->error("no such user: $username");

    # set the soft limit a few megs higher than the hard limit
    my $quotabump = $quota + 5;

    print "quota_set: setting $quota MB quota for $username ($uid) on $dev\n"
        if $debug;

    # convert from megs to 1K blocks
    my $bh = $quota * 1024;
    my $bs = $quotabump * 1024;

    my $is = $conf->{quota_inodes_soft} || 0;
    my $ih = $conf->{quota_inodes_hard} || 0;

    Quota::setqlim( $dev, $uid, $bs, $bh, $is, $ih, 1, 0 );

    print "user: end.\n" if $debug;

    # we should test the quota here and then return an appropriate result code
    return 1;
}

sub show {


    my ( $self, $user ) = @_;

    unless ($user) {
        return { 'error_code' => 500, 'error_desc' => 'invalid user' };
    }

    print "user_show: $user show function...\n" if $self->{debug};
    $prov->syscmd( "quota $user" );
    return { 'error_code' => 100, 'error_desc' => 'all is well' };
}

sub disable {


    my ( $self, $user ) = @_;

    my $r;

    my $pw = $util->find_bin( 'pw' ) || '/usr/sbin/pw';

    if ( getpwnam($user) && getpwnam($user) > 0 )    # Make sure user exists
    {
        my $cmd = "$pw usermod -n $user -e -1m";

        if ( $util->syscmd( $cmd ) ) {
            return {
                'error_code' => 200,
                'error_desc' => "disable: success. $user has been disabled."
            };
        }
        else {
            return {
                'error_code' => 500,
                'error_desc' => "disable: FAILED. $user not disabled."
            };
        }
    }
    else {
        return {
            'error_code' => 100,
            'error_desc' => "disable: $user does not exist."
        };
    }
}

sub enable {


    my ( $self, $vals ) = @_;

    my $r;

    my $user = $vals->{user};
    my $pw   = '/usr/sbin/pw';

    if ( $self->exists($user) )    # Make sure user exists
    {
        my $cmd = "$pw usermod -n $user -e ''";

   #        if ( $prov->syscmd( $cmd ) ) {
   #            $r = {
   #                'error_code' => 200,
   #                'error_desc' => "enable: success. $user has been enabled."
   #            };
   #            return $r;
   #        }
   #        else {
        $r = {
            'error_code' => 500,
            'error_desc' => "enable: FAILED. $user not enabled."
        };
        return $r;

        #        }
    }
    else {
        return {
            'error_code' => 100,
            'error_desc' => "disable: $user does not exist."
        };
    }
}

sub install_ssh_key {
    my $self = shift;
    my %p = validate( @_, {
            homedir  => { type => SCALAR },
            ssh_key  => { type => SCALAR },
            ssh_restricted => { type => SCALAR|UNDEF, optional => 1 },
            debug    => { type => BOOLEAN, optional => 1 },
            fatal    => { type => BOOLEAN, optional => 1 },
            username => { type => SCALAR,  optional => 1 },
        }
    );

    my $homedir = $p{homedir};
    my $key   = $p{ssh_key};
    my $restricted = $p{ssh_restricted};
    my $debug = defined $p{debug} ? $p{debug} : $self->{debug};
    my $fatal = defined $p{fatal} ? $p{fatal} : $self->{fatal};

    if ( ! -d $homedir ) {
        return $prov->error( "dir '$homedir' does not exist!",
            debug => $debug,
            fatal => $fatal,
        );
    };

    my $ssh_dir = "$homedir/.ssh";
    mkpath($ssh_dir, 0, oct(700)) if ( ! -d $ssh_dir && ! -e $ssh_dir );
    -d $ssh_dir or return $prov->error( "unable to create $ssh_dir", fatal => $fatal );

    my $line;
    $line .= "command=\"$restricted\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding "
        if $restricted;
    $line .= "$key\n";
    $util->file_write( "$ssh_dir/authorized_keys",
        lines => [ $line ], 
        mode  => '0600',
        debug => 0,
        fatal => 0,
    ) or return;

    if ( $p{username} ) {
        my $uid = getpwnam $p{username};
        if ( $uid ) {
            $util->chown( $ssh_dir, uid => $uid, fatal => 0 );
            $util->chown( "$ssh_dir/authorized_keys", uid => $uid, fatal => 0 );
        }
        else {
            my $chown = $util->find_bin( 'chown', debug => 0 );
            $util->syscmd( "$chown -R $p{username} $homedir/.ssh", fatal => 0, debug => 0 );
        };
    };
};

sub is_valid_password {


    my ( $self, $pass, $user ) = @_;
    my %r = ( error_code => 400 );

    # min 6 characters
    if ( length($pass) < 6 ) {
        $r{error_desc}
            = "Passwords must have at least six characters. $pass is too short.";
        return \%r;
    }

    # max 128 characters
    if ( length($pass) > 128 ) {
        $r{error_desc}
            = "Passwords must have no more than 128 characters. $pass is too long.";
        return \%r;
    }

    # not purely alpha or numeric
    if ( $pass =~ /a-z/ or $pass =~ /A-Z/ or $pass =~ /0-9/ ) {
        $r{error_desc} = "Passwords must contain both letters and numbers!";
        return \%r;
    }

    # does not match username
    if ( $pass eq $user ) {
        $r{error_desc} = "The username and password must not match!";
        return \%r;
    }

    if ( -r "/usr/local/etc/passwd.badpass" ) {

        my @lines = $util->file_read( "/usr/local/etc/passwd.badpass" );
        foreach my $line (@lines) {
            chomp $line;
            if ( $pass eq $line ) {
                $r{error_desc}
                    = "$pass is a weak password. Please select another.";
                return \%r;
            }
        }
    }

    $r{error_code} = 100;
    return \%r;
}

sub get_crypted_password {


    my $self = shift;
    my $pass = shift;
    my $salt = shift || $self->get_salt(8);

    my $crypted = crypt($pass, $salt);
    return $crypted;
};

sub get_salt {
    my $self = shift;
    my $count = shift || 8;  # default to 8 chars
    my @salt_chars = ('.', '/', 0..9, 'A'..'Z', 'a'..'z'); # from perldoc crypt()

    my $salt;
    for (1 .. $count) {
        $salt .= (@salt_chars)[rand scalar(@salt_chars) ];
    }

# ick. crypt may return different results on platforms that support enhanced crypt
# algorithms (ie, DES vs MD5 vs SHA, etc). Use a special prefix to your salt to 
# select the algorith to choose MD5 ($1$), blowfish ($2$), etc...
# real examples with pass 'T3stlN#PaSs' and salt 'ylhEgHiL':
#   Linux $1$   : $1$ylhEgHiL$rNfB2rqa2JDH9/y8nVyKW.   # MD5
#   FreeBSD $1$ : $1$ylhEgHiL$rNfB2rqa2JDH9/y8nVyKW.   # MD5
#   Mac OS 10.5 $1$ : $1eiJVUGcT0JU                    # Gack, no MD5 support!
#   Linux       : yl0FgzQYzpoVU  # DES
#   FreeBSD     : yl0FgzQYzpoVU  # DES
#   Mac OS 10.5 : yl0FgzQYzpoVU  # DES
# More Info
#   http://en.wikipedia.org/wiki/Crypt_(Unix)
#   http://search.cpan.org/~luismunoz/Crypt-PasswdMD5-1.3/PasswdMD5.pm
#   http://sial.org/howto/perl/password-crypt/

    if ( $OSNAME =~ /Linux|FreeBSD|Solaris/i ) {
#warn "using MD5 password\n";
        return '$1$' . $salt;
    };
    return $salt;
}

sub archive {

}

sub _get_os {

    my $self = shift;
    my $prov = $self->{prov};

    my $os = lc($OSNAME);

    if ( $os eq 'darwin' ) {
        require Provision::Unix::User::Darwin;
        return Provision::Unix::User::Darwin->new(
            prov => $prov,
            user => $self
        );
    }
    elsif ( lc($OSNAME) eq 'freebsd' ) {
        require Provision::Unix::User::FreeBSD;
        return Provision::Unix::User::FreeBSD->new(
            prov => $prov,
            user => $self
        );
    }
    elsif ( lc($OSNAME) eq 'linux' ) {
        require Provision::Unix::User::Linux;
        return Provision::Unix::User::Linux->new(
            prov => $prov,
            user => $self
        );
    }
    else {
        $prov->error( "There is no support for $OSNAME yet. Consider submitting a patch.",
                fatal => 0,
        );
    }
    return;
}

sub _is_valid_request {

    my $self = shift;

    $self->{prov}->progress( num => 2, desc => 'validating input' );

    # check for missing username
    if ( !$self->{username} ) {
        return $prov->progress(
            num  => 10,
            desc => 'error',
            err  => 'invalid request, missing a value for username',
        );
    }

    # make sure username is valid
    if ( !$self->_is_valid_username() ) {
        return $prov->progress(
            num  => 10,
            desc => 'error',
            err  => $prov->{errors}->[-1]->{errmsg}
        );
    }

    # is uid set?
    if ( !$self->{uid} ) {
        return $prov->progress(
            num  => 10,
            desc => 'error',
            err  => "no uid in request, using system assigned UID"
        );
    }
    return 1;
}

sub _is_valid_username {

    my $self = shift;

    # set this to fully define your username restrictions. It will
    # get returned every time an invalid username is submitted.

    my $username 
        = shift
        || $self->{username}
        || return $self->{prov}->error( "username missing",
        location => join( ',', caller ),
        fatal    => 0,
        debug    => 0,
        );

    #$prov->audit("checking validity of username $username");
    $self->{username} = $username;

    # min 2 characters
    if ( length($username) < 2 ) {
        return $prov->error( "username $username is too short",
            location => join( ',', caller ),
            fatal    => 0,
            debug    => 0,
        );
    }

    # max 16 characters
    if ( length($username) > 16 ) {
        return $prov->error( "username $username is too long",
            location => join( ',', caller ),
            fatal    => 0,
            debug    => 0,
        );
    }

    # only lower case letters and numbers
    if ( $username =~ /[^a-z0-9]/ ) {
        return $prov->error( "username $username has invalid characters",
            location => join( ',', caller ),
            fatal    => 0,
            debug    => 0,
        );
    }

    my $reserved = "/usr/local/etc/passwd.reserved";
    if ( -r $reserved ) {
        foreach my $line (
            $util->file_read( $reserved, fatal => 0, debug => 0 ) )
        {
            if ( $username eq $line ) {
                return $prov->error( "\t$username is a reserved username.",
                    location => join( ',', caller ),
                    fatal    => 0,
                    debug    => 1,
                );
            }
        }
    }

    $prov->audit("\tusername $username looks valid");
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::User - provision unix user accounts

=head1 VERSION

version 1.08

=head1 SYNOPSIS

Handles provisioning operations (create, modify, destroy) for system users on UNIX based operating systems.

    use Provision::Unix::User;

    my $prov = Provision::Unix::User->new();
    ...

=head2 show

Show user attributes. Right now it only shows quota info.

   $pass->show( {user=>"matt"} );

returns a hashref with error_code and error_desc

=head2 disable

Disable an /etc/passwd user by expiring their account.

  $pass->disable( "matt" );

=head2 enable

Enable an /etc/passwd user by removing the expiration date.

  $pass->enable( {user=>"matt"} );

input is a hashref

returns a hashref with error_code and error_desc

=head2 is_valid_password

Check a password for sanity.

    $r =  $user->is_valid_password($password, $username);

$password  is the password the user is attempting to use.

$username is the username the user has selected. 

Checks: 

    Passwords must have at least 6 characters.
    Passwords must have no more than 128 characters.
    Passwords must not be the same as the username
    Passwords must not be purely alpha or purely numeric
    Passwords must not be in reserved list 
       (/usr/local/etc/passwd.badpass)

$r is a hashref that gets returned.

$r->{error_code} will contain a result code of 100 (success) or (4-500) (failure)

$r->{error_desc} will contain a string with a description of which test failed.

=head2 get_crypted_password

	$user->get_crypted_password($pass, [$salt] )

get the DES/MD5 digest of the plain text password that is passed in

=head1 FUNCTIONS

=head2 new

Creates and returns a new Provision::Unix::User object.

=head2 is_valid_username

   $user->is_valid_username($username, $denylist);

$username is the username. Pass it along as a scalar (string).

$denylist is a optional hashref. Define all usernames you want reserved (denied) and it will check to make sure $username is not in the hashref.

Checks:

   * Usernames must be between 2 and 16 characters.
   * Usernames must have only lower alpha and numeric chars
   * Usernames must not be defined in $denylist or reserved list

The format of $local/etc/passwd.reserved is one username per line.

=head2 archive

Create's a tarball of the users home directory. Typically done right before you rm -rf their home directory as part of a de-provisioning step.

    if ( $user->archive("user") ) 
    {
        print "user archived";
    };

returns a boolean.

=head2 create_group

Installs a system group. 

    $r = $pass->create_group($group, $gid)

    $r->{error_code} == 200 ? print "success" : print $r->{error_desc}; 

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-user at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix::User

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
