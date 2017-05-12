package Pickles::Dispatcher::Auto;
use parent qw/Pickles::Dispatcher/;
use strict;
use warnings;
use Class::Load ":all";
use Module::Pluggable::Object;
use Pickles::Context;
use String::CamelCase qw/camelize decamelize/;

our $VERSION = '0.03';

sub match {
    my $self = shift;
    my ($req) = @_;

    my $match = $self->SUPER::match(@_);

    if (exists $match->{controller} && exists $match->{action}) {
        return $match;
    }

    my $path_info = $req->env->{PATH_INFO} || $req->path_info;
    $path_info =~ s{^/}{};

    my $is_index = $path_info =~ m{/$};

    my @parts = split "/", $path_info;
    my $action = $is_index ? "index" : pop @parts || "index";

    my $controller = "";
    my %args;
    if (@parts) {
        my @camelized_parts = map { camelize $_ } @parts;
        $controller .= join "::", @camelized_parts;
        $controller .= "::Root";
    }
    else {
        $controller = "Root";
    }

    $match = +{
        controller => $controller,
        action => $action,
    };
    for my $key( keys %{$match} ) {
        next if $key =~ m/^(controller|action)$/;
        $args{$key} = delete $match->{$key};
    }
    $match->{args} = \%args;

    return $match;
}

sub load_controllers {
    my ($self, $prefix) = @_;

    my @controllers = Module::Pluggable::Object->new(
        require => 1,
        search_path => ["$prefix\::Controller"],
    )->plugins;

    for my $controller (@controllers) {
        load_class($controller);
    }

    1;
}

my $_sub_controller_class = sub {
    my ($self) = @_;
    my $match = $self->match;
    my $controller = $match->{controller} or return;
    (my $class = sprintf "%s::Controller::%s", $self->appname, camelize($controller)) =~ s{/}{::}g;
    return $class;
};

my $_sub__prepare = sub {
    my $self = shift;
    my $match = $self->dispatcher->match($self->req);
    my @paths = split '::', decamelize($match->{controller});
    my $controller = $match->{controller};
    my $view_template;
    $controller =~ /Root$/ and pop @paths;
    $view_template = join("/", map { $_ } @paths) . "/" . decamelize($match->{action});
    $self->stash->{'VIEW_TEMPLATE'} = $view_template;
};

no warnings "redefine";
*Pickles::Context::_prepare = $_sub__prepare;
*Pickles::Context::controller_class = $_sub_controller_class;

1;
__END__

=head1 NAME

Pickles::Dispatcher::Auto - Pickles dispatcher without routes.pl

=head1 SYNOPSIS

  package MyApp::Dispatcher;
  use strict;
  use warnings;
  use parent qw/Pickles::Dispatcher::Auto/;

=head1 DESCRIPTION

if exists routing in routes.pl, follow the rule.

else, auto match via path_info.

=head1 AUTHOR

hirafoo E<lt>hirafoo atmk cpan.orgE<gt>

=head1 SEE ALSO

L<Pickles>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
