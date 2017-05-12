package Plack::Middleware::Compile;
BEGIN {
  $Plack::Middleware::Compile::VERSION = '0.01';
}

#ABSTRACT: Compile HAML/SASS/Coffeescript/whatever on demand

use warnings;
use strict;

use base 'Plack::Middleware';
use Plack::Util::Accessor qw(pattern lib blib mime map compile);

use File::Spec;

=head1 NAME

Plack::Middleware::Compile

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Compile' => (
            pattern => qr{\.coffee$},
            lib     => 'coffee',
            blib    => 'js',
            mime    => 'text/plain',
            map     => sub { 
                my $filename = shift;
                $filename =~ s/coffee$/js/;
                return $filename;
            },
            compile => sub { 
                my ($in, $out) = @_;
                system("coffee --compile --stdio < $in > $out");
            }
        );
    }

=head1 DESCRIPTION

Enable this middleware to serve compiled content (Coffeescript -> Javascript,
Sass -> CSS, HAML -> HTML, etc). The content will only be compiled when the
source is changed.

=head1 CONFIGURATION

=head2 pattern

A regex which will be matched against PATH_INFO to determine if the middleware
should handle this request.

=head2 lib

A directory in which to find the source files.

=head2 blib

An output directory to send the compiled files to. This will be the same as
your lib directory if you don't specify it.

=head2 mime

The mime type to serve the files as.  Defaults to 'text/plain'.

=head2 map

A function that maps input filenames to output filenames.

=head2 compile

A function that takes the input and output filenames as arguments and produces
the compiled file from the input.

=cut

sub _text {
    my ($code, $text) = @_;
    use bytes;
    [ 
        $code, 
        [
            'Content-Type'   => 'text/plain',
            'Content-Length' => length($text),
        ],
        [ $text ]
    ];
}

sub call {
    my ($self, $env) = @_;
    my $in = $env->{PATH_INFO};
    
    return $self->app->($env) unless $in =~ $self->pattern;

    my $lib  = $self->lib;
    my $blib = $self->blib || $lib;
    my $out  = File::Spec->catfile($blib, $self->map->($in));
    $in      = File::Spec->catfile($lib, $in);
    return _text(404, 'Not Found') unless (-r $in);

    my @os = stat($out);
    my @is = stat($in);
    if ( !@os || $is[9] > $os[9] ) {
        eval { $self->compile->($in, $out) };
        return _text(500, $@) if $@;
        @os = stat($out);
    }
    
    return _text(404, 'Not Found') unless (-r $out);
    return _text(500, $!) unless open my $fh, '<', $out;

    return [
        200, 
        [
            'Content-Length' => $os[7],
            'Content-Type'   => $self->mime || 'text/plain',
        ],
        $fh
    ];
}

1;