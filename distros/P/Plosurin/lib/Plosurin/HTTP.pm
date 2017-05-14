#===============================================================================
#
#  DESCRIPTION:  HTTP server
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Plosurin::HTTP - Serve web mode

=head1 SYNOPSIS

         plosurin.p5 -t web 

=head1 DESCRIPTION

Plosurin::HTTP - Serve web mode

=cut

package Plosurin::HTTP;
use strict;
use warnings;
use base qw/WebDAO::Engine/;
use Data::Dumper;
use Plosurin;
use open ':utf8';

sub __any_path {
    my $self = shift;
    my $sess = shift;
    my ( $res, $epath ) = $self->SUPER::__any_path( $sess, @_ );
    return $res if $res;
    my $path = join( "/", @_ );
    my $r = $self->response();

    #check pathes
    return $r->error404("File $path not found.") unless -e $path;
    if ( !-d $path ) {
        my %args = ();
        $args{-type} = $r->get_mime_for_filename( $path, 1 );
        if ( !$args{-type} && -T $path ) {
            $args{-type} = 'text/plain';
        }
        return $r->send_file( $path, %args );
    }
    return $self->Index( subpath => $path );
}

sub _traverse_ {
    my $self = shift;
    my ( $sess, @path ) = @_;
    unless ( scalar(@path) ) {
        return $self, $self->Index();
    }
    return $self->SUPER::_traverse_( $sess, @path );
}

=head2 _parse_file <full_path>

Parse .soy file and return code and template records

Return ref to array [$code, @tmpls]
or string if  error

=cut

sub _parse_file {
    my $self  = shift;
    my $fpath = shift;
    my $p     = Plosurin->new;
    my $str;
    open FH, "<$fpath";
    { undef $/; $str = <FH> };
    close FH;
    my $file = $p->parse( $str, $fpath )
      || return "Cant parse " . "<pre>$str</pre>";
    my ( $code, @tmpls );
    eval {
        ( $code, @tmpls ) = $p->as_perl5( { package => "Test::App" }, $file );
    };

    if ($@) {
        return "Erorr export: $@";
    }
    return [ $code, @tmpls ];
}

=head 2 RenderSoy

param 
    path = /path/to/file.soy
    tempalate = .name || [.html]
=cut

sub RenderSoy {
    my $self  = shift;
    my %args  = @_;
    my $r     = $self->response;
    my $fpath = $args{path} || return $r->error404("Need argument <path>!");
    return $r->error404("File $fpath not found") unless -e $fpath;
    my $content = $self->_parse_file($fpath);
    unless ( ref($content) ) {
        return $r->error404("Error while parse $fpath: $content");
    }
    my ( $code, @tmpls ) = @$content;

    #template to render
    my $name2render = $args{template} || ".html";
    my $tmpl;
    foreach my $t (@tmpls) {
        next unless $t->{name} eq $name2render;
        $tmpl = $t;
        last;
    }

    #template not found -> error !
    unless ($tmpl) {
        my $str;
        open FH, "<$fpath";
        { undef $/; $str = <FH> };
        close FH;
        return $r->error404(
            "Template $name2render not found in $fpath : <pre>$str</pre>");
    }
    no warnings;
    my $f = eval("$code");
    use warnings;
    if ($@) {
        return $r->error404( "Bad code for eval " . $@ . "<pre>$code</pre>" );
    }
    no strict 'refs';
    my $call_name = $tmpl->{package_name};
    return $call_name->();
}

sub Index {
    my $self      = shift;
    my %arg       = @_;
    my $list      = '';
    my $root_path = $arg{subpath} || '.';
    my $r         = $self->response;
    return $r->error404("File $root_path not found") unless -e $root_path;
    opendir DIR, $root_path;
    while ( my $el = readdir DIR ) {
        my $fpath = $root_path . "/" . $el;
        _log1 $self "List dir: $fpath";

        if ( -d $fpath ) {
            $el = qq!<a href="/$fpath">$el</a>!;
        }
        elsif ( $el =~ /\.soy$/ ) {

            #get list of tempaltes
            $el =
              qq!<a style="color:green;" href="/RenderSoy?path=$fpath">$el</a>!;
            my $content = $self->_parse_file($fpath);
            unless ( ref($content) ) {
                $el .= qq!<p style="color: red;">$content</p>!;
            }
            else {
                my ( $code, @tmpls ) = @$content;
                foreach my $t (@tmpls) {
                    $el .=
qq! &nbsp;&nbsp;<a href="/RenderSoy?path=$fpath&template=$t->{name}">$t->{name}</a>!;
                }

            }

        }
        $list .= <<REC
     $el <br/>
REC
    }
    close DIR;
    <<TXT;
<html>
  <head>
  </head>
  <body>
  <h1>List path: $root_path</h1>
  <hr>
$list
  <hr>
  <p>Plosurin v$Plosurin::VERSION</p>
  </body>
</html>
TXT
}
1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

