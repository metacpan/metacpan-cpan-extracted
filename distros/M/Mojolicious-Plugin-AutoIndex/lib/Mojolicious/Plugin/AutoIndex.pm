use strict;

# ABSTRACT: Mojolicious plugin for autoindex function at static resource
use warnings;

package Mojolicious::Plugin::AutoIndex;
{
  $Mojolicious::Plugin::AutoIndex::VERSION = '0.0006';
}

use Mojo::Base 'Mojolicious::Plugin';


my $config = { index => [qw/index.html index.htm/] };

sub register {
    my ( $self, $app, $conf ) = @_;
    $config->{index} = $conf->{index} if $conf->{index};
    return unless @{ $config->{index} };
    $app->hook(
        before_dispatch => sub {
            my $c = shift;
            my $path = $c->stash('path') // $c->req->url->path->to_string;
            return unless $path =~ m!/$!;
            my $sv_path = $c->stash('path');
            foreach ( @{ $config->{index} } ) {
                $c->stash->{path} = $path . $_;
                if ( $app->static->dispatch($c) ) {
                    $c->stash->{path} = $sv_path;
                    return $app->plugins->emit_hook( after_static => $c );
                }
            }
            $c->stash->{path} = $sv_path;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::AutoIndex - Mojolicious plugin for autoindex function at static resource

=head1 VERSION

version 0.0006

=head1 SYNOPSIS

This Plugin works just sames Nginx's autoindex directive, which will detect index file in a directory when your request is a directory.

    # use plugin
    $self->plugin('AutoIndex' => { index => [qw/index.html index.htm index.txt/] });

    # then:::

    # view http://www.example.com/dira/
    # mojolicious will detect whether /dira is an static file
    # if found, it will render its conent

    # in use this Plugin, if requst URI ends with a slash : '/',
    # we will automatically append the index page to its path,
    # for example, in above request URI , mojolicious will detect
    # dira/index.html instead.

=head1 DESCRIPTION

=head2 OPTIONS

=over

=item index

index files will used to detect as index page, for example:

   plugin 'AutoIndex => { index => [qw/index.html/] }

=back

=encoding utf8

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
