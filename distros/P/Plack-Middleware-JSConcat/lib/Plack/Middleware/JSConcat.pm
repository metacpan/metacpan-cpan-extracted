package Plack::Middleware::JSConcat;
use strict;
use warnings;

our $VERSION = '0.29';
use 5.008_001;

use parent qw(Plack::Middleware);
__PACKAGE__->mk_accessors(qw(js_content files key mtime filter));


use IPC::Run3;
use Digest::MD5 'md5_hex';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    local $/;
    $self->js_content(join("\n", map { open my $fh, '<', $_ or die "$_: $!";
                                       "/* $_ */\n".<$fh>
                                   } @{$self->files}));

    $self->minify_js if $self->filter;

    $self->key( md5_hex( $self->js_content ) );
    # XXX: use the latest mtime from $self->files instead
    $self->mtime( time() );

    return $self;
}

sub minify_js {
    my $self = shift;
    my $output = '';
    local $SIG{'CHLD'} = 'DEFAULT';
    run3 [$self->filter], \$self->js_content, \$output, undef;

    $self->js_content($output);
}

sub serve_js {
    my $self = shift;
    my $content_type = 
    return [ 200, [ 'Content-Type' => 'text/javascript',
                    'Content-Length' => length($self->js_content),
                    'Last-Modified'  => HTTP::Date::time2str( $self->mtime ),
                ],
             [$self->js_content] ];
}

sub call {
    my $self = shift;
    my $env  = shift;
    my $url = $env->{'psgix.jsconcat.url'} = '/_js/'.$self->key;
    return $self->serve_js if $env->{PATH_INFO} eq $url;

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::JSConcat - Concatenate javascripts

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
      enable "JSConcat",
          files => [<static/js/*.js>],
          filter => '/usr/local/bin/jsmin';
      $app;
  };

  # use $env{'psgix.jsconcat.url'} to include javascript.

=head1 DESCRIPTION

Plack::Middleware::JSConcat allows you to concatenate multiple
javascripts files into one.  It provides a content-hashed key as the
url for including all the javascript files you specified.  You can
also provide a filter program to minimize the concatenated file.

=head1 CONFIGURATIONS

=over 4

=item files

=item filter

=back

=head1 AUTHOR

Chia-liang Kao <clkao@clkao.org>

=head1 SEE ALSO

L<Plack>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
