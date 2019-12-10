package Mojo::Zabbix;

use strict;
use warnings;

use Mojo::UserAgent;
use Scalar::Util qw(reftype refaddr);
use Carp;
use Time::HiRes qw(gettimeofday tv_interval);
use POSIX qw(strftime);


our $VERSION = '0.14';

sub new {
    my $class    = shift;
    my $required = 1;
    my $args     = {
        url        => \$required,
        trace      => 0,
        debug      => 0,
        username   => \$required,
        password   => \$required,
        @_,
    };

    for my $k ( keys %$args ) {
        if ( ref $args->{$k}
            && refaddr( $args->{$k} ) == refaddr( \$required ) )
        {
            die "Missing value for $k";
        }
    }

    $args->{url} =~ s,/+$,,g;

    my $self = bless {
        UserAgent   => undef,
        Request     => undef,
        Count       => 1,
        Auth        => undef,
        API_URL     => $args->{url},
        Output      => "extend",
        Debug       => $args->{debug} ? 1 : 0,
        Trace       => $args->{trace} ? 1 : 0,
        User        => $args->{username},
        Password    => $args->{password},
        _call_start => 0,
    }, $class;

    # init json object
    $self->_json;

    # init useragent
    $self->ua;

    # authenticate
    $self->auth;
    return $self;
}

sub output {
    my $self = shift;

    $self->{Output} = $_[0]
      if (@_);

    return $self->{Output};
}

sub ua {
    my $self = shift;

    unless ( $self->{UserAgent} ) {

        $self->{UserAgent} = Mojo::UserAgent->new;
        $self->{UserAgent}->transactor->name("Mojo::Zabbix");
        $self->{UserAgent}->inactivity_timeout(10);
    }

    return $self->{UserAgent};
}

sub _json {
    my $self = shift;

    unless ( defined $self->{JSON} ) {
        $self->{JSON} = JSON::PP->new;
        $self->{JSON}->ascii->pretty->allow_nonref->allow_blessed
          ->allow_bignum;
    }
    return $self->{JSON};
}

sub trace {
    my $self = shift;

    $self->{Trace} = $_[0]
      if (@_);

    return $self->{Trace};
}

sub debug {
    my $self = shift;

    $self->{Debug} = $_[0]
      if (@_);

    return $self->{Debug};
}

sub auth {
    my $self = shift;
    if ( not defined $self->{Auth} ) {
        $self->{Auth} = ''; 
        my $res = $self->http_request(
            'user', 'login',
            {
                user     => $self->{User},
                password => $self->{Password},
            }
        );
        #confess $res->{error}->{data}
        warn "$res->{error}->{data}\nError Code: $res->{error}->{code} 
            \nResponse: $res->{error}->{message}"
          if defined $res->{error};

        #print "$res->{error}";
        $self->{Password} = '***';
        $self->{Auth}     = $res->{result};
    }
    elsif ( $self->{Auth} eq '' ) {
        return ();    # empty for first auth call
    }

    return $self->{Auth} unless defined wantarray;
    return ( auth => $self->{Auth} );
}

sub next_id {
    return ++shift->{'Count'};
}

sub int_debug {
    my ( $self, $data ) = @_;
    my $tempass;
    if (    defined $data->{'params'}
        and ref( $data->{'params'} ) eq 'HASH'
        and exists $data->{'params'}->{'password'} )
    {
        $tempass = $data->{'params'}->{'password'};
        $data->{'params'}->{'password'} = '******';
    }
    my $json = $self->{JSON}->encode($data);

    $self->_dbgmsg( "TX: " . $json )
      if $self->{Debug};
    $data->{'params'}->{'password'} = $tempass
      if ( ref( $data->{'params'} ) eq 'HASH'
        and exists $data->{'params'}->{'password'} );

}

sub out_debug {
    my ( $self, $data ) = @_;
    my $json = $self->{JSON}->encode($data);
    $self->_dbgmsg( "RX: " . $json )
      if $self->{Debug};

}

sub get {
    my ( $self, $object, $params ) = @_;
    return $self->http_request( $object, "get", $params );
}

sub update {
    my ( $self, $object, $params ) = @_;
    return $self->http_request( $object, "update", $params );
}

sub delete {
    my ( $self, $object, $params ) = @_;
    return $self->http_request( $object, "delete", $params );
}

sub create {
    my ( $self, $object, $params ) = @_;
    return $self->http_request( $object, "create", $params );
}

sub exists {
    my ( $self, $object, $params ) = @_;
    return $self->http_request( $object, "exists", $params );
}

sub http_request {
    my ( $self, $object, $op, $params ) = @_;

    if ( $self->{Trace} ) {
        $self->{_call_start} = [gettimeofday];
        $self->_dbgmsg("Starting method $object.$op");
    }

    if ($params) {
        $params->{output} = $self->{Output}
          if ( reftype($params) eq 'HASH' and not defined $params->{output} and $object.$op ne "userlogin" );
    }
    else {
        $params = [];
    }
    my $zrurl  = "$self->{API_URL}/api_jsonrpc.php";
    my $myjson = {
        jsonrpc => "2.0",
        method  => "$object.$op",
        params  => $params,
        id      => $self->next_id,
        ( $self->auth ),
    };
    $self->int_debug($myjson) if $self->{Debug};

    my $res = $self->ua->post( $zrurl, json => $myjson );

    unless ( $res->success ) {
        my $err = $res->error;
        warn "$err->{code} response: $err->{message}" if $err->{code};
        warn "Connection error: $err->{message}";

    }

    if ( $self->{Trace} ) {
        $self->_dbgmsg("Finished method $object.$op");
        $self->_dbgmsg( "Spent "
              . tv_interval( $self->{_call_start} )
              . "s on $object.$op" );
    }
    $self->out_debug( $res->res->json ) if $self->{Debug};
    return $res->res->json;
}

sub _dbgmsg {
    my $self = shift;
    warn strftime( '[%F %T]', localtime ) . ' '
      . __PACKAGE__ . ' @ #'
      . $self->{Count} . ' '
      . join( ', ', @_ ) . "\n";
}

1;
 
__END__

=encoding utf8

=head1 NAME

Mojo::Zabbix - A simple perl wrapper of Zabbix API.

Mojo::Zabix - 是对zabbix api函数的简单打包，以便更易于用perl脚本进行
访问操作zabbix。目前仅支持认证和请求方法，可以用其进行create/get
/update/delete/exists方法调用，见例子。本模块基于Mojo::UserAgent，结果
可以用Mojo:DOM进行处理和内容提取。

=head1 VERSION

Version 0.11

add get group info for zabbix.

=head1 SYNOPSIS

  use Mojo::Zabbix;

  my $z = Net::Zabbix->new(
          url => "https://server/zabbix/",
          username => 'user',
          password => 'pass',
          debug => 1,
          trace => 0,
  );

  my $r = $z->get("host", {
          filter => undef,
          search => {
              host => "test",
          },
      }
  );


=head1 AUTHOR
 
orange, C<< <bollwarm at ijz.me> >>
 
=head1 BUGS
 
Please report any bugs or feature requests to C<bug-Mojo-Zabbix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojo-Zabbix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
    perldoc Mojo-Zabbix
 
 
You can also look for information at:
 
=over 4
 
=item * RT: CPAN's request tracker (report bugs here)
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Zabbix>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Mojo-Zabbix>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Mojo-Zabbix>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Mojo-Zabbix/>
 
=back
 
=head1 Git repo
 
L<https://github.com/bollwarm/Mojo-Zabbix.git>
L<https://git.oschina.net/ijz/Mojo-Zabbix>
=head1 ACKNOWLEDGEMENTS
 
 
=head1 LICENSE AND COPYRIGHT
 
Copyright 2016 orange.
 
This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
