package Spreadsheet::HTML::File::Loader;
use Carp;
use strict;
use warnings FATAL => 'all';

eval "use Spreadsheet::Read";
our $NO_READER = $@;

eval "use URI";
our $NO_URI = $@;
eval "use LWP::Simple";
our $NO_LWP = $@;
eval "use File::Temp";
our $NO_TEMP = $@;
eval "use File::Basename";
our $NO_BASE = $@;


sub _parse {
    my ($args,$data) = @_;

    if ($args->{file} =~ m{^https?://}) {
        if ($NO_URI or $NO_LWP or $NO_TEMP or $NO_BASE) {
            return [[ "cannot download $args->{file}" ],[ 'please install URI, LWP::Simple, File::Basename and/or File::Temp' ]];
        } else {
            my $uri = URI->new( $args->{file} );
            my @ext = qw( .html .htm .json .jsn .yaml .yml .gif .png .jpg .jpeg .csv .xls .xlsx .sxc .ods );
            my (undef,undef,$suffix) = File::Basename::fileparse( $uri->path, @ext );
            my (undef,$newfile) = File::Temp::tmpnam();
            unlink $newfile;
            $args->{file} = $newfile . $suffix;
            my $error = LWP::Simple::getstore( $uri->as_string, $args->{file} );
            return [[ "cannot download " . $uri->as_string ],[ "RC code $error" ]] if LWP::Simple::is_error( $error );
            $args->{_unlink} = defined( $args->{_unlink} ) ? $args->{_unlink} : 1;
        }
    }

    my $file = $args->{file};
    if ($file =~ /\.html?$/) {
        return Spreadsheet::HTML::File::HTML::_parse( $args );
    } elsif ($file =~ /\.jso?n$/) {
        return Spreadsheet::HTML::File::JSON::_parse( $args );
    } elsif ($file =~ /\.ya?ml$/) {
        return Spreadsheet::HTML::File::YAML::_parse( $args );
    } elsif ($file =~ /\.(gif|png|jpe?g)$/) {
        return Spreadsheet::HTML::File::Image::_parse( $args, $data );
    }

    return [[ "cannot load $file" ],[ 'No such file or directory' ]] unless -r $file or $file eq '-';
    return [[ "cannot load $file" ],[ 'please install Spreadsheet::Read' ]] if $NO_READER;

    my $workbook = ReadData( $file,
        attr    => $args->{preserve},
        clip    => $args->{clip},
        cells   => $args->{cells},
        rc      => $args->{rc} || 1,
        sep     => $args->{sep},
        strip   => $args->{strip},
        quote   => $args->{quote},
        parser  => $args->{parser},
    );

    close $file if ref($file) eq 'GLOB';

    my $parsed = $workbook->[ $args->{worksheet} ];

    if ($args->{preserve} and ref $parsed->{attr} eq 'ARRAY' and scalar@{$parsed->{attr}}) {

        my %attr_map = _attr_map();
        for my $row (1 .. $#{ $parsed->{attr} }) {
            for my $col (1 .. $#{ $parsed->{attr}[$row] }) {
                my $attr = $parsed->{attr}[$row][$col];
                my %styles;
                for my $key (keys %$attr) {
                    my $map = $attr_map{$key};
                    next unless $map and $attr->{$key};
                    if ($map->[0]) {
                        $styles{$map->[1]} = $map->[2];
                    } else {
                        $styles{$map->[1]} = $attr->{$key};
                    }
                }
                $args->{ sprintf '-r%sc%s', $col - 1, $row - 1 } = { style => { %styles } };
            }
        }
    }

    return [ Spreadsheet::Read::rows( $parsed ) ];
}

sub _attr_map {(
    font        => [ 0, 'font-family' ],
    size        => [ 0, 'font-size' ],
    valign      => [ 0, 'vertical-align' ],
    halign      => [ 0, 'text-align' ],
    fgcolor     => [ 0, 'color' ],
    bgcolor     => [ 0, 'background-color' ],
    bold        => [ 1, 'font-weight', 'bold' ],
    uline       => [ 1, 'text-decoration', 'underline' ],
    italic      => [ 1, 'font-style', 'italic' ],
    hidden      => [ 1, 'display', 'none' ],
)}

=head1 NAME

Spreadsheet::HTML::File::Loader - Load data from files.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> file loading methods.
These package is not meant to be directly used. Instead, use the
Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new( file => 'foo.xls' );
  print $generator->generate();

  # or
  use Spreadsheet::HTML qw( generate );
  print generate( file => 'foo.xls' );

=head1 SUPPORTED FORMATS

=over 4

=item * CSV/XLS

Parses with (requires) L<Spreadsheet::Read>. (See its documentation for
customizing its options, such as C<sep> for specifying separators other
than a comma.

  generate( file => 'foo.csv' )
  generate( file => 'foo.csv', sep => '|' )

=item * HTML

Parses with (requires) L<HTML::TableExtract>.

  generate( file => 'foo.htm' )
  generate( file => 'foo.html' )

=item * JSON

Parses with (requires) L<JSON>.

  generate( file => 'foo.jsn' )
  generate( file => 'foo.json' )

=item * YAML

Parses with (requires) L<YAML>.

  generate( file => 'foo.yml' )
  generate( file => 'foo.yaml' )

=item * JPEG

Parses with (requires) L<Imager::File::JPEG>.

  generate( file => 'foo.jpg' )
  generate( file => 'foo.jpeg' )
  generate( file => 'foo.jpeg', block => 2 )
  generate( file => 'foo.jpeg', block => 2, blend => 1 )
  generate( file => 'foo.jpeg', alpha => '#ffffff' )

=item * PNG

Parses with (requires) L<Imager::File::PNG>.

  generate( file => 'foo.png' )
  generate( file => 'foo.png', block => 2 )
  generate( file => 'foo.png', block => 2, blend => 1 )
  generate( file => 'foo.png', alpha => '#ffffff' )

=item * GIF

Parses with (requires) L<Imager::File::GIF>.

  generate( file => 'foo.gif' )
  generate( file => 'foo.gif', block => 2 )
  generate( file => 'foo.gif', block => 2, blend => 1 )
  generate( file => 'foo.gif', alpha => '#ffffff' )

=back

=head1 SEE ALSO

=over 4

=item * L<Spreadsheet::HTML>

The interface for this functionality.

=back

=cut

1;



package Spreadsheet::HTML::File::YAML;
use Carp;
use strict;
use warnings FATAL => 'all';

eval "use YAML";
our $NOT_AVAILABLE = $@;

sub _parse {
    my $args = shift;
    my $file = $args->{file};
    return [[ "cannot load $file" ],[ 'No such file or directory' ]] unless -r $file;
    return [[ "cannot load $file" ],[ 'please install YAML' ]] if $NOT_AVAILABLE;

    my $data = YAML::LoadFile( $file );
    return $data;
}

1;



package Spreadsheet::HTML::File::JSON;
use Carp;
use strict;
use warnings FATAL => 'all';

eval "use JSON";
our $NOT_AVAILABLE = $@;

sub _parse {
    my $args = shift;
    my $file = $args->{file};
    return [[ "cannot load $file" ],[ 'No such file or directory' ]] unless -r $file;
    return [[ "cannot load $file" ],[ 'please install JSON' ]] if $NOT_AVAILABLE;

    open my $fh, '<', $file or return [[ "cannot load $file" ],[ $! ]];
    my $data = decode_json( do{ local $/; <$fh> } );
    close $fh;
    return $data;
}

1;



package Spreadsheet::HTML::File::HTML;
use Carp;
use strict;
use warnings FATAL => 'all';

eval "use HTML::TableExtract";
our $NOT_AVAILABLE = $@;

sub _parse {
    my $args = shift;
    my $file = $args->{file};
    return [[ "cannot load $file" ],[ 'No such file or directory' ]] unless -r $file;
    return [[ "cannot load $file" ],[ 'please install HTML::TableExtract' ]] if $NOT_AVAILABLE;

    my @data;
    my $extract = HTML::TableExtract->new( keep_headers => 1, decode => 0 );
    $extract->parse_file( $file );
    my $table = ($extract->tables)[ $args->{worksheet} - 1 ];
    return [ $table ? $table->rows : [undef] ];
}

1;



package Spreadsheet::HTML::File::Image;
use Carp;
use strict;
use warnings FATAL => 'all';

eval "use Imager";
our $NOT_AVAILABLE = $@;

sub _parse {
    my ($args,$data) = @_;
    my $file = $args->{file};
    return [[ "cannot load $file" ],[ 'No such file or directory' ]] unless -r $file;
    return [[ "cannot load $file" ],[ 'please install Imager' ]] if $NOT_AVAILABLE;

    my $imager = Imager->new;
    my @images = $imager->read_multi( file => $file ) or return [[ "cannot load $file" ],[ $imager->errstr ]];
    my $image = $images[ $args->{worksheet} - 1 ] || $images[0];
    
    $args->{block} = $args->{block} && $args->{block} =~ /\D/ ? 8 : ($args->{block} || 0) < 1 ? 8 : $args->{block};
    $args->{fill}  = join( 'x', int( $image->getheight / $args->{block} ), int( $image->getwidth / $args->{block} ) );
    $args->{table} ||= { cellspacing => 0, border => 0, cellpadding => 0 };

    my $r = 0;
    for (my $x = 0; $x < $image->getwidth; $x += $args->{block}) {
        my $c = 0;
        for (my $y = 0; $y < $image->getheight; $y += $args->{block}) {
            
            my (@x,@y);
            for my $i ($x .. $x + $args->{block}) {
                for my $j ($y .. $y + $args->{block}) {
                    push @x, $i;
                    push @y, $j;
                }
            }

            my $primary;
            if ($args->{block} == 1) {
                $primary = join '', map sprintf( "%02X", $_ ), ($image->getpixel( x => $x[0], y => $y[0] )->rgba)[0..2];
            } else {
                if ($args->{blend}) {
                    my %average = ( r => 0, g => 0, b => 0 );
                    for my $pixel ($image->getpixel( x => \@x, y => \@y )) {
                        next unless ref $pixel;
                        my @rgba = $pixel->rgba;
                        $average{r} += $rgba[0];
                        $average{g} += $rgba[1];
                        $average{b} += $rgba[2];
                    }
                    $_ /= ($args->{block} * $args->{block}) for values %average;
                    $primary = join '', map sprintf( "%02X", $_ ), @average{qw(r g b)};
                } else {
                    my %block;
                    for my $pixel ($image->getpixel( x => \@x, y => \@y )) {
                        next unless ref $pixel;
                        my $color = join '', map sprintf( "%02X", $_ ), ($pixel->rgba)[0..2];
                        $block{$color}++;
                    }
                    $primary = (sort { $block{$b} <=> $block{$a} } keys %block)[0];
                }
            }

            if ($args->{alpha}) {
                $args->{alpha} =~ s/^#//;
                $args->{alpha} = uc( $args->{alpha} );
            }

            $args->{"-r${c}c${r}"} = {
                width  => $args->{block} * 2,
                height => $args->{block},
                style  => { 'background-color' => "#$primary" },
            } unless $args->{alpha} and $args->{alpha} eq $primary;

            $c++;
        }

        $r++;
    }

    return $data;
}

1;



=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
