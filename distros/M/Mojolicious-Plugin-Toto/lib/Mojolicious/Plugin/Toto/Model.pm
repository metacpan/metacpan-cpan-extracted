package Mojolicious::Plugin::Toto::Model;
use Mojo::Base -base;
has 'key';

use overload '""' => sub {
    shift->key;
};

sub autocomplete {
    my $class  = shift;
    my %args   = @_;
    my $q      = $args{q} or return;
    my $object = $args{object};
    my $c      = $args{c};
    my $tab    = $args{tab} || 'default';
    return [
        map +{
            name => "$object $_",
            href => $c->url_for("$object/$tab", key => $_),
        }, 1..10
    ];
}

1;

