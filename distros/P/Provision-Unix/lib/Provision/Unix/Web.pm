package Provision::Unix::Web;
# ABSTRACT: provision web hosting accounts
$Provision::Unix::Web::VERSION = '1.08';
use strict;
use warnings;

use Params::Validate qw( :all );

use lib "lib";

my ( $prov, $util );

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
        debug => $p{debug},
        fatal => $p{fatal},
    };
    bless( $self, $class );

    $prov = $p{prov};
    $prov->audit("loaded Web");
    $self->{server} = $self->_get_server( debug => $p{debug}, fatal => $p{fatal} )
        or return;

    $util = $prov->get_util;
    return $self;
}

sub create {
    my $self = shift;
    return $self->{server}->create(@_);
}

sub enable {
    my $self = shift;
    return $self->{server}->enable(@_);
};

sub disable {
    my $self = shift;
    return $self->{server}->disable(@_);
};

sub _get_server {

    my $self = shift;

    my %p = validate(
        @_,
        {   debug => { type => BOOLEAN, optional => 1, default => 1 },
            fatal => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $chosen_server = $prov->{config}{Web}{server}
        or $prov->error( 'missing [Web] server setting in provision.conf',
        debug   => $p{debug},
        fatal   => $p{fatal},
        );

    return if ! $chosen_server;

    if ( $chosen_server eq "apache" ) {
        require Provision::Unix::Web::Apache;
        return Provision::Unix::Web::Apache->new( 
            prov => $prov,
            web  => $self,
            debug => $p{debug},
            fatal => $p{fatal},
        );
    }
    elsif ( $chosen_server eq "lighttpd" ) {
        require Provision::Unix::Web::Lighttpd;
        return Provision::Unix::Web::Lighttpd->new(
            prov  => $prov,
            web   => $self,
            debug => $p{debug},
            fatal => $p{fatal},
        );
    }
    else {
        return $prov->error( "unknown web server. Supported values are lighttpd and apache.",
            debug => $p{debug},
            fatal => $p{fatal},
        );
    }

    return;

    #    use Data::Dumper;
    #    print "\n\n";
    #    print Dumper($request);
}

sub get_vhost_attributes {

    my $self = shift;

    my %p = validate(
        @_,
        {   'request' => { type => HASHREF, optional => 1 },
            'prompt'  => { type => BOOLEAN, optional => 1, default => 0 },
        },
    );

    my $vals = $p{'request'};

    if ( $p{'prompt'} ) {
        $vals->{'vhost'} ||= $util->ask( 'vhost name' );
    }

    my $vhost = $vals->{'vhost'}
        or $prov->error( "vhost is required" );

    if ( $p{'prompt'} ) {
        $vals->{'ip'} ||= $util->ask( 'ip', default => '*:80' );
        $vals->{'serveralias'}
            ||= $util->ask( 'serveralias', default => "www.$vhost" );
    }

    if ( !$vals->{'documentroot'} ) {

        # calculate a default documentroot
        my $vdoc_root   = $prov->{config}{'Web'}{'vdoc_root'}   || "/home";
        my $vdoc_suffix = $prov->{config}{'Web'}{'vdoc_suffix'} || "html";
        my $docroot     = "$vdoc_root/$vhost/$vdoc_suffix";

        if ( $p{'prompt'} ) {

            # prompt with a sensible default
            $vals->{'documentroot'}
                = $util->ask( 'documentroot', default => $docroot );
        }
        else {
            $vals->{'documentroot'} = $docroot;
        }
    }

    if ( $p{'prompt'} ) {
        $vals->{'ssl'} ||= $util->ask( 'ssl' );
    }

    if ( $vals->{'ssl'} ) {
        my $certs = $prov->{config}{'Web'}{'sslcerts'}
            || "/usr/local/etc/apache2/certs";

        if ( $p{'prompt'} ) {
            $vals->{'sslcert'} ||= $util->ask( 'sslcert',
                default => "$certs/$vhost.crt"
            );
            $vals->{'sslkey'} ||= $util->ask( 'sslkey',
                default => "$certs/$vhost.key"
            );
        }
    }

    while ( my ( $key, $val ) = each %$vals ) {
        next if $key eq "debug";
        next if $key eq "phpmyadmin";
        next if $key =~ /ssl/;
        next if $key =~ /custom/;
        next if $key eq "options";
        next if $key eq "verbose";
        next if $key eq "redirect";

        $util->ask( $key ) if !defined $val;
    }

    return $vals;
}

sub check_apache_setup {

    my $self = shift;
    my $conf = $self->{'conf'};

    my %r;

    # make sure apache etc dir exists
    my $dir = $conf->{'apache_dir_etc'};
    unless ( $dir && -d $dir ) {
        return {
            'error_code' => 401,
            'error_desc' =>
                'web_check_setup: cannot find Apache\'s conf dir! Please set apache_dir_etc in sysadmin.conf.\n'
        };
    }

    # make sure apache vhost setting exists
    $dir = $conf->{'apache_dir_vhosts'};

    #unless ( $dir && (-d $dir || -f $dir) )  # can also be a fnmatch pattern!
    unless ($dir) {
        return {
            'error_code' => 401,
            'error_desc' =>
                'web_check_setup: cannot find Apache\'s vhost file/dir! Please set apache_dir_vhosts in sysadmin.conf.\n'
        };
    }

    # all is well
    return {
        'error_code' => 200,
        'error_desc' => 'web_check_setup: all tests pass!\n'
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::Web - provision web hosting accounts

=head1 VERSION

version 1.08

=head1 SYNOPSIS

Provision web hosting accounts.

    use Provision::Unix::Web;

    my $foo = Provision::Unix::Web->new();
    ...

=head1 FUNCTIONS

=head2 new

Creates and returns a new Provision::Unix::Web object.

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-web at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

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

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
