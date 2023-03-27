package MySQL::GrantParser;

use strict;
use warnings;
use 5.008_005;

our $VERSION = '1.004';

use DBI;
use Carp;

sub new {
    my($class, %args) = @_;

    my $self = {
        dbh             => undef,
        need_disconnect => 0,
    };
    if (exists $args{dbh}) {
        $self->{dbh} = delete $args{dbh};
    } else {
        if (!$args{hostname} && !$args{socket}) {
            Carp::croak("missing mandatory args: hostname or socket");
        }

        my $dsn = "DBI:mysql:";
        for my $p (
            [qw(hostname hostname)],
            [qw(port port)],
            [qw(socket mysql_socket)],
        ) {
            my $arg_key   = $p->[0];
            my $param_key = $p->[1];
            if ($args{$arg_key}) {
                $dsn .= ";$param_key=$args{$arg_key}";
            }
        }

        $self->{need_disconnect} = 1;
        $self->{dbh} = DBI->connect(
            $dsn,
            $args{user}||'',
            $args{password}||'',
            {
                AutoCommit => 0,
            },
        ) or Carp::croak("$DBI::errstr ($DBI::err)");
    }

    $self->{server_version} =  exists $self->{dbh}->{mysql_serverversion} ? $self->{dbh}->{mysql_serverversion} : 0;

    return bless $self, $class;
}

sub parse {
    my $self = shift;
    my %grants;

    # select all user
    my $rset = $self->{dbh}->selectall_arrayref('SELECT user, host FROM mysql.user');

    for my $user_host (@$rset) {
        my ($user, $host) = @{$user_host};
        my $quoted_user_host = $self->quote_user($user, $host);
        my $rset = $self->{dbh}->selectall_arrayref("SHOW GRANTS FOR ${quoted_user_host}");
        my @stmts;
        for my $rs (@$rset) {
            push @stmts, @{$rs};
        }
        if ($self->{server_version} >= 50706) {
            # As of MySQL 5.7.6, SHOW GRANTS output does not include IDENTIFIED BY PASSWORD clauses. Use the SHOW CREATE USER statement instead.
            # https://dev.mysql.com/doc/refman/5.7/en/show-grants.html
            my $rset = $self->{dbh}->selectall_arrayref("SHOW CREATE USER ${quoted_user_host}");
            for my $rs (@$rset) {
                push @stmts, @{$rs};
            }
        }

        %grants = (%grants, %{ parse_stmts(\@stmts) });
    }

    return \%grants;
}

sub parse_stmts {
    my $stmts = shift;
    my @grants = ();
    my $q = q{['`]};
    my $Q = q{[^'`]};

    for my $stmt (@$stmts) {
        my $parsed = {
            with       => '',
            require    => '',
            identified => '',
            privs      => [],
            object     => '',
            user       => '',
            host       => '',
        };

        if ($stmt =~ s/\AGRANT (.+?) ON (.+?) TO ${q}(${Q}+?)${q}\@${q}(${Q}+?)${q}\s*//) {
            $parsed->{privs}  = parse_privs($1);
            $parsed->{object} = $2;
            $parsed->{user}   = $3;
            $parsed->{host}   = $4;
        }
        if ($stmt =~ s/\ACREATE USER ${q}(${Q}+?)${q}\@${q}(${Q}+?)${q}\s*//) {
            $parsed->{user}   = $1;
            $parsed->{host}   = $2;
        }

        if ($stmt =~ s/\AIDENTIFIED BY PASSWORD ${q}(${Q}+?)${q}\s*//) {
            $parsed->{identified} = "PASSWORD '$1'";
        }
        if ($stmt =~ s/\AIDENTIFIED WITH ${q}(${Q}+?)${q} AS ${q}(${Q}+?)${q}\s*//) {
            # my $auth_plugin = $1; # eg: mysql_native_password
            $parsed->{identified} = "PASSWORD '$2'";
        }
        if ($stmt =~ s/\AIDENTIFIED WITH ${q}(${Q}+?)${q}\s*//) {
            # no AS
            # my $auth_plugin = $1; # eg: mysql_native_password
            $parsed->{identified} = '';
        }

        if ($stmt =~ s/\AREQUIRE //) {
            if ($stmt =~ s/\ANONE\s*//) {
                $parsed->{require} = '';
            } elsif ($stmt =~ s/\A(SSL|X509)\s*//) {
                $parsed->{require} = $1;
            } else {
                my @tls_options = ();
                while ($stmt =~ s/\A((?:CIPHER|ISSUER|SUBJECT) ${q}${Q}+?${q})\s*//g) {
                    push @tls_options, $1;
                }
                $parsed->{require} = join ' ', @tls_options;
            }
        }

        if ($stmt =~ s/\AWITH //) {
            my @with = ();
            if ($stmt =~ s/\AGRANT OPTION\s*//) {
                push @with, 'GRANT OPTION';
            }
            while ($stmt =~ s/\A(MAX_\w+ \d+)\s*//g) {
                push @with, $1;
                $parsed->{object} ||= '*.*';
                $parsed->{privs} = ['USAGE'] unless @{ $parsed->{privs} };
            }
            $parsed->{with} = join ' ', @with;
        }

        push @grants, $parsed;
    }

    return pack_grants(@grants);
}

sub pack_grants {
    my @grants = @_;
    my $packed;

    for my $grant (@grants) {
        my $user       = delete $grant->{user};
        my $host       = delete $grant->{host};
        my $user_host  = join '@', $user, $host;
        my $object     = delete $grant->{object};
        my $identified = delete $grant->{identified};
        my $required   = delete $grant->{require};

        unless (exists $packed->{$user_host}) {
            $packed->{$user_host} = {
                user    => $user,
                host    => $host,
                objects => {},
                options => {
                    required   => '',
                    identified => '',
                },
            };
        }
        $packed->{$user_host}{objects}{$object}  = $grant if $object;
        $packed->{$user_host}{options}{required} = $required if $required;

        if ($identified) {
            $packed->{$user_host}{options}{identified} = $identified;
        }
    }

    return $packed;
}

sub quote_user {
    my $self = shift;
    my($user, $host) = @_;
    sprintf q{%s@%s}, $self->{dbh}->quote($user), $self->{dbh}->quote($host);
}

sub parse_privs {
    my $privs = shift;
    $privs .= ',';

    my @priv_list = ();

    while ($privs =~ /\G([^,(]+(?:\([^)]+\))?)\s*,\s*/g) {
        my $priv = $1;
        $priv =~ s/`//g; # trim quote for MySQL 8.0
        push @priv_list, $priv;
    }

    return \@priv_list;
}

sub DESTROY {
    my $self = shift;
    if ($self->{need_disconnect}) {
        $self->{dbh} && $self->{dbh}->disconnect;
    }
}

1;

__END__

=encoding utf8

=begin html

<a href="https://travis-ci.org/hirose31/MySQL-GrantParser"><img src="https://travis-ci.org/hirose31/MySQL-GrantParser.png?branch=master" alt="Build Status" /></a>
<a href="https://coveralls.io/r/hirose31/MySQL-GrantParser?branch=master"><img src="https://coveralls.io/repos/hirose31/MySQL-GrantParser/badge.png?branch=master" alt="Coverage Status" /></a>

=end html

=head1 NAME

MySQL::GrantParser - parse SHOW GRANTS and return as hash reference

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

    use MySQL::GrantParser;
    
    # connect with existing dbh
    my $dbh = DBI->connect(...);
    my $grant_parser = MySQL::GrantParser->new(
        dbh => $dbh;
    );
    
    # connect with user, password
    my $grant_parser = MySQL::GrantParser->new(
        user     => 'root',
        password => 'toor',
        hostname => '127.0.0.1',
    );
    
    # and parse!
    my $grants = $grant_parser->parse; # => HashRef


=head1 DESCRIPTION

MySQL::GrantParser is SHOW GRANTS parser for MySQL, inspired by Ruby's L<Gratan|http://gratan.codenize.tools/>.

This module returns privileges for all users as following hash reference.

    {
        'USER@HOST' => {
            'user' => USER,
            'host' => HOST,
            'objects' => {
                'DB_NAME.TABLE_NAME' => {
                    privs => [ PRIV_TYPE, PRIV_TYPE, ... ],
                    with  => 'GRANT OPTION',
                },
                ...
            },
            'options' => {
                'identified' => '...',
                'required'   => '...',
            },
        },
        {
            ...
        },
    }

For example, this GRANT statement

    GRANT SELECT, INSERT, UPDATE, DELETE ON orcl.* TO 'scott'@'%' IDENTIFIED BY 'tiger' WITH GRANT OPTION;

is represented as following.

    {
        'scott@%' => {
            user => 'scott',
            host => '%',
            objects => {
                '*.*' => {
                    privs => [
                        'USAGE'
                    ],
                    with => '',
                },
                '`orcl`.*' => {
                    privs => [
                        'SELECT',
                        'INSERT',
                        'UPDATE',
                        'DELETE',
                    ],
                    with => 'GRANT OPTION',
                }
            },
            options => {
                identified => "PASSWORD XXX",
                required => '',
            },
        },
    }


=head1 METHODS

=head2 Class Methods

=head3 B<new>(%args:Hash) :MySQL::GrantParser

Creates and returns a new MySQL::GrantParser instance. Dies on errors.

%args is following:

=over 4

=item dbh => DBI:db

Database handle object.

=item user => Str

=item password => Str

=item hostname => Str

=item socket => Str

Path of UNIX domain socket for connecting.

=back

Mandatory arguments are C<dbh> or C<hostname> or C<socket>.

=head2 Instance Methods

=head3 B<parse>() :HashRef

Parse privileges and return as hash reference.

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31@gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/MySQL-GrantParser>

    git clone https://github.com/hirose31/MySQL-GrantParser.git

patches and collaborators are welcome.

=head1 SEE ALSO

L<Gratan|http://gratan.codenize.tools/>,
L<http://dev.mysql.com/doc/refman/5.6/en/grant.html>

=head1 COPYRIGHT

Copyright HIROSE Masaaki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
