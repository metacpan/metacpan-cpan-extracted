package Provision::Unix::VirtualOS::Linux::Virtuozzo;
# ABSTRACT: provision a linux VPS using Virtuozzo
$Provision::Unix::VirtualOS::Linux::Virtuozzo::VERSION = '1.08';
use strict;
use warnings;

use lib 'lib';
use base 'Provision::Unix::VirtualOS::Linux::OpenVZ';

use English qw( -no_match_vars );
use File::Copy;
use Params::Validate qw(:all);

sub new {
    my $class = shift;
    my %p = validate( @_, { vos => { type => OBJECT } } );

    my $vos   = $p{vos};
    my $prov  = $vos->{prov};
    my $util  = $vos->{util};
    my $linux = $vos->{linux};

    my $self = bless {
        vos   => $vos,
        prov  => $prov,
        util  => $util,
        linux => $linux,
    }, $class;

    $prov->audit( $class . sprintf( " loaded by %s, %s, %s", caller ) );

    $prov->{etc_dir} ||= '/etc/vz/conf';    # define a default

    return $self;
}

sub create {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});
    my $linux = $self->{linux};

    my $ctid = $vos->{name};

    $EUID == 0
        or $prov->error( "That requires root privileges." ); 

    # make sure it doesn't exist already
    return $prov->error( "VE $ctid already exists",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if $self->is_present();

    # make sure $ctid is within accepable ranges
    my $err;
    my $min = $prov->{config}{VirtualOS}{id_min};
    my $max = $prov->{config}{VirtualOS}{id_max};    
    if ( $ctid =~ /^\d+$/ ) {
        $err = "VE must be greater than $min" if ( $min && $ctid < $min );
        $err = "VE must be less than $max"    if ( $max && $ctid > $max );
    };

    if ( $err && $err ne '' ) {
        return $prov->error( $err,
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        );
    }

    $prov->audit("\tVE '$ctid' does not exist, creating...");

#/usr/sbin/vzctl create 72000 --pkgset centos-4 --config vps.256MB

    # build the shell command to create
    my $cmd = $util->find_bin( 'vzctl', debug => 0 );

    $cmd .= " create $ctid";
    $cmd .= " --root $vos->{disk_root}" if $vos->{disk_root};
    $cmd .= " --hostname $vos->{hostname}" if $vos->{hostname};
    $cmd .= " --config $vos->{config}" if $vos->{config};

    return $prov->error( "template required but not specified", fatal => 0)
        if ! $vos->{template};

    my $template = $self->_is_valid_template( $vos->{template} ) or return;
    my @bits = split '-', $template;
    pop @bits;    # remove the stuff after the last hyphen
    my $pkgset = join '-', @bits;
    $cmd .= " --pkgset $pkgset";
    # $cmd .= " --ostemplate $template";
    
    my @configs = glob("/etc/vz/conf/ve-*.conf-sample");
    no warnings;
    my @sorted = 
        sort { ( $b =~ /(\d+)/)[0] <=> ($a =~ /(\d+)/)[0] } 
            grep { /vps/ } @configs;
    use warnings;
    if ( scalar @sorted > 1 ) {
        my ( $config ) = $sorted[0] =~ /ve-(.*)\.conf-sample$/;
        $cmd .= " --config $config";
    };

    $prov->audit("\tcmd: $cmd");

    return $prov->audit("test mode early exit") if $vos->{test_mode};

    if ( $util->syscmd( $cmd, debug => 0, fatal => 0 ) ) {

        $self->set_hostname()    if $vos->{hostname};
        sleep 1;
        $self->set_ips();
        sleep 1;
        $vos->set_nameservers()  if $vos->{nameservers};
        sleep 1;
        $self->set_password()    if $vos->{password};
        sleep 1;
        $self->start();

        return $prov->audit("\tvirtual os created");
    }

    return $prov->error( "create failed, unknown error",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    );
}

sub get_fs_root {
    my $self = shift;  
    return $self->get_ve_home(@_);  # same thing on Virtuozzo
};

sub get_ve_home {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $name = $vos->{name} || shift || die "missing VE name";
    my $disk_root = $vos->{disk_root} || '/vz';
    my $homedir = "$disk_root/private/$name/root";
    return $homedir;
};

sub _is_valid_template {

    my $self     = shift;
    my $template = shift;

    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $template_dir = $self->{prov}{config}{virtuozzo_template_dir} || '/vz/template';
    return $template if -f "$template_dir/$template.tar.gz";

    # is $template a URL?
    my ( $protocol, $host, $path, $file )
        = $template
        =~ /^((http[s]?|rsync):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(.*)?(#[\w\-]+)?$/;
    if ( $protocol && $protocol =~ /http|rsync/ ) {
        $prov->audit("fetching $file with $protocol");

        return $prov->error( 'template does not exist and programmers have not yet written the code to retrieve templates via URL',
            fatal => 0
        );
    }
        
    return $prov->error( 
            "template '$template' does not exist and is not a valid URL",
        debug => $vos->{debug},
        fatal => $vos->{fatal},
    );  
}   


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::VirtualOS::Linux::Virtuozzo - provision a linux VPS using Virtuozzo

=head1 VERSION

version 1.08

=head1 SYNOPSIS

See the documentation for Provision::Unix::VirtualOS::Linux::OpenVZ, of which this 
class is functionally almost identical, containing just a few overrides.  

    use Provision::Unix::VirtualOS::Linux::Virtuozzo;
    my $vz = Provision::Unix::VirtualOS::Linux::Virtuozzo->new();
    ...

=head1 NAME

Provision::Unix::VirtualOS::Linux::Virtuozzo - Provision a VPS using Virtuozzo 

=head1 FUNCTIONS

=head2 create

Creates a new Virtuozzo VPS.

=head2 get_fs_root

Returns the root FS directory for a VPS. Same as VPS home on Virtuozzo.

=head2 get_ve_home

Returns the VPS home directory.

=head2 is_valid_template

Checks to make sure the specified OS template exists.

=head1 AUTHOR

Matt Simerson, C<< <matt at tnpi.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-virtualos at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix::VirtualOS::Linux::Virtuozzo

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

=head1 COPYRIGHT & LICENSE

Copyright 2010 Matt Simerson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
