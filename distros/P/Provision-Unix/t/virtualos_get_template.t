
use strict;
use warnings;

use Data::Dumper qw( Dumper );
use English qw( -no_match_vars );
use Test::More;

use lib "lib";
use Provision::Unix;
use Provision::Unix::VirtualOS;

my $prov = Provision::Unix->new( debug => 0 );
my $util = $prov->get_util;
my $vos;

eval { $vos = Provision::Unix::VirtualOS->new( prov => $prov, fatal => 0, debug => 0 ) };
if ( $EVAL_ERROR ) {
    my $message = $EVAL_ERROR; chop $message;
    $message .= " on " . $OSNAME;
    plan skip_all => $message;
} 
else {
    plan 'no_plan';
};

# basic OO mechanism
ok( defined $vos, 'get Provision::Unix::VirtualOS object' );
ok( $vos->isa('Provision::Unix::VirtualOS'), 'check object class' );

my $virt_class = ref $vos->{vtype};
my @parts = split /::/, $virt_class;
my $virt_type = lc( $parts[-1] );
$virt_type = 'ovz' if $virt_type eq 'openvz';
ok( $virt_type, "virtualization type: $virt_type");

my $template_dir;
my $template_that_exists = 'debian-5.0-i386-default';
if ( $virt_type =~ /virtuozzo|ovz|openvz|xen|ezjail/ ) {

# get_template_dir
$template_dir = $vos->get_template_dir( v_type => $virt_type );
ok( $template_dir, "get_template_dir, $template_dir");

    foreach my $brand ( qw/ spry vpslink / ) {

        next if ( $brand eq 'spry' && $virt_type eq 'xen' );

        my $r = $util->get_url( 
            "http://$brand-$virt_type.templates.int.spry.com/$template_that_exists.tar.gz",
            dir   => $template_dir,
            fatal => 0,
            debug => 1,
        );
        ok( $r , "get_template") or $prov->error($r, fatal => 0);

# get_template_list
        my $templates = $vos->get_template_list( v_type => $virt_type );
        my $count = scalar @$templates;
        ok( $count, "get_template_list, local only, $count templates" );
        #warn "local templates:\n" . Dumper($templates);

        $r = $vos->get_template_list( 
            v_type => $virt_type,
            url    => "http://$brand-$virt_type.templates.int.spry.com/",
        );
        ok( $count, "get_template_list, brand $brand, $count templates" ) 
            or $prov->error( $r, fatal => 0);

        #warn "remote templates for $brand $virt_type:\n" . Dumper($r);
    };
};

#$prov->error("dump");
