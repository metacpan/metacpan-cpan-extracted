package Provision::Unix::VirtualOS::FreeBSD::Ezjail;
# ABSTRACT: provision freebsd jails using ezjail
$Provision::Unix::VirtualOS::FreeBSD::Ezjail::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use Params::Validate qw(:all);

my ( $prov, $vos, $util );

sub new {
    my $class = shift;

    my %p = validate( @_, { 'vos' => { type => OBJECT }, } );

    $vos  = $p{vos};
    $prov = $vos->{prov};

    my $self = { prov => $prov };
    bless( $self, $class );

    $prov->audit( $class . sprintf( " loaded by %s, %s, %s", caller ) );
    $util = $prov->get_util;
    return $self;
}

sub create {
    my $self = shift;

    # Templates in ezjail are 'flavours' or archives

    # ezjail-admin create -f default [-r jailroot] [-i|c -s 512]
    # ezjail-admin create -a archive

    my $admin = $util->find_bin( 'ezjail-admin', debug => 0 );

    my $jails_root = _get_jails_root() || '/usr/jails';

    if (   $vos->{disk_root}
        && $vos->{disk_root} ne "$jails_root/$vos->{name}" )
    {
        $admin .= " -r $vos->{disk_root}";
    }

    my $template = $vos->{template} || 'default';
    if ($template) {
        if ( -d "$jails_root/flavours/$template" ) {
            $prov->audit("detected ezjail flavour $template");
            $admin .= " -f $template";
        }
        elsif ( -f "$jails_root/$template.tgz" ) {
            $prov->audit("installing from archive $template");
            $admin .= " -a $jails_root/$template.tgz";
        }
        else {
            $prov->error( "You chose the template ($template) but it is not defined as a flavor in $jails_root/flavours or an archive at $jails_root/$template.tgz"
            );
        }
    }

    $admin .= " -s $vos->{disk_size}" if $vos->{disk_size};

    $prov->audit("cmd: $admin $vos->{name} $vos->{ip}");
    return 1 if $vos->{test_mode};
    return $util->syscmd( $admin );
}

sub is_present {
    my $self = shift;
    my $homedir = $self->get_ve_home();
    return $homedir if -d $homedir;
    return;
};

sub console {
    my $self = shift;
    my $ctid = $vos->{name};
    my $cmd = $util->find_bin( 'ezjail-admin', debug => 0 );
    exec "$cmd console $ctid";
};

sub get_ve_home {
    my $self = shift;
    my $ctid = $vos->{name};
    return "/usr/jails/$vos->{name}";
};

sub _get_jails_root {
    my $r = `grep '^ezjail_jaildir' /usr/local/etc/ezjail.conf`;
    if ($r) {
        chomp $r;
        ( undef, $r ) = split /=/, $r;
        return $r;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::VirtualOS::FreeBSD::Ezjail - provision freebsd jails using ezjail

=head1 VERSION

version 1.08

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
