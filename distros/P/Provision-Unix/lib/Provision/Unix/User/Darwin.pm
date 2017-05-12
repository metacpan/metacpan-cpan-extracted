package Provision::Unix::User::Darwin;
# ABSTRACT: provision user accounts on Darwin systems
$Provision::Unix::User::Darwin::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use Params::Validate qw( :all );

use lib 'lib';

my ( $util, $prov, $p_user );

sub new {
    my $class = shift;
    my %p     = validate(
        @_,
        {   'prov' => { type => OBJECT },
            'user' => { type => OBJECT },
        }
    );
    my $self = {
        prov => $p{prov},
        user => $p{user},
    };
    bless( $self, $class );

    $p_user = $p{user};
    $prov   = $p{prov};
    $util   = $prov->get_util;
    return $self;
}

sub create {

    my $self = shift;

    my %p = validate(
        @_,
        {   'username'  => { type => SCALAR },
            'uid'       => { type => SCALAR },
            'gid'       => { type => SCALAR },
            'password'  => { type => SCALAR | UNDEF, optional => 1 },
            'shell'     => { type => SCALAR | UNDEF, optional => 1 },
            'homedir'   => { type => SCALAR | UNDEF, optional => 1 },
            'gecos'     => { type => SCALAR | UNDEF, optional => 1 },
            'domain'    => { type => SCALAR | UNDEF, optional => 1 },
            'expire'    => { type => SCALAR | UNDEF, optional => 1 },
            'quota'     => { type => SCALAR | UNDEF, optional => 1 },
            'debug'     => { type => SCALAR, optional => 1, default => 1 },
            'fatal'     => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => BOOLEAN, optional => 1, default => 0 },
        }
    );

    $prov->progress( num => 1, desc => 'gathering input' );

    $p_user->{username} = $p{username};
    $p_user->{uid}      = $p{uid};
    $p_user->{gid}      = $p{gid};
    $p_user->{debug}    = $p{debug};

    $p_user->{password} ||= $p{password};
    $p_user->{shell}   ||= $p{shell} ||= $prov->{config}{User}{shell_default};
    $p_user->{homedir} ||= $p{homedir}
        || $prov->{config}{User}{home_base} eq '/home'
        ? "/Users/$p{username}"
        : "$prov->{config}{User}{home_base}/$p{username}";
    $p_user->{gecos}  ||= $p{gecos}  || '';
    $p_user->{expire} ||= $p{expire} || '';
    $p_user->{quota}  ||= $p{quota}  || $prov->{config}{User}{quota_default};

    $prov->progress( num => 2, desc => 'validating input' );
    $p_user->_is_valid_request() or return;

    $prov->progress( num => 3, desc => 'dispatching' );

    # return success if testing
    return $prov->progress( num => 10, desc => 'ok' ) if $p{test_mode};

    # finally, create the user
    my $dirutil
        = $util->find_bin( "dscl", debug => $p{debug}, fatal => 0 );

    $prov->progress(
        num  => 5,
        desc => "adding Darwin user $p_user->{username}"
    );
    if   ($dirutil) { $self->_create_dscl(); }      # 10.5+
    else            { $self->_create_niutil(); }    # 10.4 and previous

## TODO
    # set the password for newly created accounts

    # validate user creation
    my $uid = $self->exists();
    if ($uid) {
        $prov->progress( num => 10, desc => 'created successfully' );
        return $uid;
    }

    return $prov->progress(
        num  => 10,
        desc => 'error',
        err  => $prov->{errors}->[-1]->{errmsg},
    );
}

sub _next_uid {

# echo $[$(dscl . -list /Users uid | awk '{print $2}' | sort -n | tail -n1)+1]
}

sub _create_dscl {
    my $self = shift;

    my $user  = $p_user->{username};
    my $debug = $self->{debug};

    my $dirutil = $util->find_bin( "dscl", debug => 0 );

    $util->syscmd( "$dirutil . -create /users/$user",
        debug => $debug,
    );

    $util->syscmd( "$dirutil . -createprop /users/$user uid $p_user->{uid}",
        debug => $debug,
    );

    $util->syscmd( "$dirutil . -createprop /users/$user gid $p_user->{gid}",
        debug => $debug,
    );

    $util->syscmd( "$dirutil . -createprop /users/$user shell $p_user->{shell}",
        debug => $debug,
    );

    my $homedir = $p_user->{homedir};

    $util->syscmd( "$dirutil . -createprop /users/$user home $homedir",
        debug => $debug,
    ) if $homedir;

    $util->syscmd( "$dirutil . -createprop /users/$user passwd '*'",
        debug => $debug,
    );

    if ($homedir) {
        mkdir $homedir, 0755
            or $util->mkdir_system(
            dir   => $homedir,
            mode  => '0755',
            debug => 0
            );
        $util->chown( $homedir, uid => $user, gid=>$p_user->{gid}, debug => $debug );
    }

    return getpwnam($user);
}

sub _create_niutil {
    my $self  = shift;
    my $user  = $p_user->{username};
    my $debug = $p_user->{debug};

    # use niutil on 10.4 and prior
    my $dirutil = $util->find_bin( "niutil", debug => 0 );

    $util->syscmd( "$dirutil -create . /users/$user",
        debug => $debug,
    ) or die "failed to create user $user\n";

    $prov->progress( num => 6, desc => "configuring $user" );

    $util->syscmd( "$dirutil -createprop . /users/$user uid $p_user->{uid}",
        debug => $debug,
    );

    $util->syscmd( "$dirutil -createprop . /users/$user gid $p_user->{gid}",
        debug => $debug,
    );

    $util->syscmd( "$dirutil -createprop . /users/$user shell $p_user->{shell}",
        debug => $debug,
    );

    my $homedir = $p_user->{homedir};
    $util->syscmd( "$dirutil -createprop . /users/$user home $homedir",
        debug => $debug,
    );

    $util->syscmd( "$dirutil -createprop . /users/$user _shadow_passwd",
        debug => $debug,
    );

    $util->syscmd( "$dirutil -createprop . /users/$user passwd '*'",
        debug => $debug,
    );

    if ($homedir) {
        mkdir $homedir, 0755;
        $util->chown( $homedir, uid => $user, gid=>$p_user->{gid}, debug => $debug );
    }

    return getpwnam($user);
}

sub destroy {
    my $self = shift;

    my %p = validate(
        @_,
        {   'username' => { type => SCALAR },
            'debug'    => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => SCALAR, optional => 1, },
        }
    );

    my $user = $p{username};

    $prov->progress( num => 5, desc => "destroy Darwin user $user" );

    return $prov->progress( num => 10, desc => 'test completed' )
        if $p{test_mode};

    # this works on 10.5
    my $dirutil = $util->find_bin( "dscl", debug => 0, fatal => 0 );

    my $cmd;

    if ($dirutil) {    # 10.5
        $cmd = "$dirutil . -destroy /users/$user";
    }
    else {

        # this works on 10.4 and previous
        $dirutil = $util->find_bin( "niutil", debug => 0 );
        $cmd = "$dirutil -destroy . /users/$user";
    }

    $util->syscmd( $cmd, debug => 0 );

    # flush the cache
    my $cacheutil = $util->find_bin( "dscacheutil", debug => 0, fatal => 0 );
    if ( -x $cacheutil ) {
        $util->syscmd( "$cacheutil -flushcache", debug=>0, fatal=>0);
    };

    return $self->exists($user)
        ? $prov->progress( num => 10, 'err' => 'failed' )
        : $prov->progress( num => 10, desc  => 'user destroyed' );
}

sub create_group {

    my $self = shift;

    my %p = validate(
        @_,
        {   'group' => { type => SCALAR },
            'gid'   => { type => SCALAR },
            'debug' => { type => SCALAR, optional => 1, default => 1 },
        }
    );

    my $group = $p{group};
    my $gid   = $p{gid};

    $prov->progress( num => 5, desc => "adding Darwin group $group" );

    my $dirutil
        = $util->find_bin( "dscl", debug => $p{debug}, fatal => 0 );

    if ($dirutil) {    # 10.5+
        $util->syscmd( "$dirutil . -create /groups/$group",
            debug => $p{debug}
        );
        $util->syscmd( "$dirutil . -createprop /groups/$group gid $gid",
            debug => $p{debug}
        ) if $gid;
        $util->syscmd( "$dirutil . -createprop /groups/$group passwd '*'",
            debug => $p{debug}
        );
    }
    else {
        $dirutil = $prov->find_bin( "niutil", debug => $p{debug} );
        $util->syscmd( "$dirutil -create . /groups/$group",
            debug => $p{debug}
        );
        $util->syscmd( "$dirutil -createprop . /groups/$group gid $gid",
            debug => $p{debug}
        ) if $gid;
        $util->syscmd( "$dirutil -createprop . /groups/$group passwd '*'",
            debug => $p{debug}
        );
    }

    return $self->exists_group( $p{group} )
        ? $prov->progress( num => 10, desc  => 'group added' )
        : $prov->progress( num => 10, 'err' => 'failed!' );
}

sub destroy_group {

    my $self = shift;

    my %p = validate(
        @_,
        {   'group' => { type => SCALAR },
            'gid'   => { type => SCALAR, optional => 0 },
            'debug' => { type => SCALAR, optional => 1, default => 1 },
        }
    );

    my $group = $p{group};
    my $gid   = $p{gid};

    $prov->progress( num => 5, desc => "destroy Darwin group $p{group}" );

    my $dirutil
        = $util->find_bin( "dscl", debug => $p{debug}, fatal => 0 );

    if ($dirutil) {    # 10.5
        $util->syscmd( "$dirutil . -delete /groups/$group",
            debug => $p{debug}
        );
    }
    else {             # =< 10.4
        $dirutil = $util->find_bin( "niutil", debug => $p{debug} );
        $util->syscmd( "$dirutil -delete . /groups/$group",
            debug => $p{debug}
        );
    }

    # flush the cache
    my $cacheutil = $util->find_bin( "dscacheutil", debug => 0, fatal => 0 );
    if ( -x $cacheutil ) {
        $util->syscmd( "$cacheutil -flushcache", debug=>0, fatal=>0);
    };

    return getgrnam( $p{group} )
        ? $prov->progress( num => 10, 'err' => 'failed!' )
        : $prov->progress( num => 10, desc  => 'group deleted' );
}

sub exists {

    my ( $self, $user ) = @_;
    $user ||= $p_user->{username};
    $user = lc($user);

    my $uid = getpwnam($user);
    return ( $uid && $uid > 0 ) ? $uid : undef;
}

sub exists_group {

    my ( $self, $group ) = @_;
    $group or die "missing group";

    my $gid = getgrnam($group);

    return ( $gid && $gid > 0 ) ? $gid : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::User::Darwin - provision user accounts on Darwin systems

=head1 VERSION

version 1.08

=head1 SYNOPSIS

Handles provisioning operations (create, modify, destroy) for system users on UNIX based operating systems.

    use Provision::Unix::User::Darwin;

    my $prov_user = Provision::Unix::User::Darwin->new();
    ...

=head1 FUNCTIONS

=head2 new

Creates and returns a new Provision::Unix::User::Darwin object.

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-user at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix::User::Darwin

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
