package SVG::Convert;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/drivers parser/);

use Carp::Clan;
use Module::Load;
use Module::Pluggable::Fast (
    name => '_drivers',
    search => ['SVG::Convert::Driver'],
    require => 1
);
use Params::Validate qw(:all);
use Scalar::Util qw(weaken);
use XML::LibXML;

=head1 NAME

SVG::Convert - The fantastic new SVG::Convert!

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use SVG::Convert;
  
  my $svgconv = SVG::Convert->new();
  print $svgconv->convert(format => "xaml", src_file => "examples/01.svg", output => "string");

=head1 METHODS

=head2 new

Constructor.
The "$args" arguments is HASHREF.
See below more details about $args.

=over 4

=item driver_opts

The driver_opts parameter is HASHREF.
The keys of HASHREF are lower-cased suffix of driver module name.

For example, If driver is L<SVG::Convert::XAML>, then the key is "xaml".
The values of HASHREF are parameter needed by each of drivers.

  my $sconv = SVG::Convert->new({
    driver_opts => {
      xaml => {
        ## for Driver::XAML
      }
    }
  });

=back

=cut

sub new {
    my ($class, $args) = @_;

    $args ||= {};
    $args = { driver_opts => {}, %$args, drivers => {} };

    my $self = $class->SUPER::new($args);
    $self->parser(XML::LibXML->new);

    for my $driver ($self->_drivers) {
        eval { load $driver; };
        if ($@) {
            croak($@);
        }

        my ($suffix) = map { lc } $driver =~ m/SVG::Convert::Driver::(.+)/;

        my $driver_opts = (
            exists $args->{driver_opts}->{$suffix} && 
            ref $args->{driver_opts}->{$suffix} eq 'HASH'
        ) ? $args->{driver_opts}->{$suffix} : {};

        $self->drivers->{$suffix} = $driver->new({
            parser => $self->parser,
            %$driver_opts
        });
    }

    return $self;
}

=head2 convert(%args)

See below about %args details.

  my $xaml_doc = $sconv->convert(
    format => "xaml",
    src_file => $src_file,
    output => "doc"
  );

=over 4

=item format

The format parameter is string value represented format type for converting.
This value is lower-cased suffix of driver module name.

For example, If the driver module is L<SVG::Convert::Driver::XAML>, then this value is "xaml".

=item src_file

The src_file parameter is string value represented SVG source file name.

=item src_string

The src_file parameter is string value represented SVG source string.

=item src_doc

The src_doc parameter is L<XML::LibXML::Document> object value represented SVG source document.

=item output

The output parameter is "file" or "string" or "doc".

=item output_file

The output_file parameter is output filename.

=item convert_opts

The convert_opts parameter is extra params for driver.

=back

=cut

sub convert {
    my $self = shift;
    my %args = validate_with(
        params => \@_, 
        spec => {
            format => {
                type => SCALAR,
                callbacks => {
                    'installed driver' => sub {
                        exists $self->drivers->{$_[0]};
                    }
                }
            },
            src_file => {
                type => SCALAR,
                optional => 1,
                callbacks => {
                    'exists file' => sub {
                        -e $_[0] && -f $_[0];
                    }
                }
            },
            src_string => {
                type => SCALAR,
                optional => 1,
            },
            src_doc => {
                type => OBJECT,
                optional => 1,
                isa => [qw/XML::LibXML::Document/]
            },
            output => {
                type => SCALAR,
                default => 'string',
                callbacks => {
                    'enable parameters' => sub {
                        $_[0] eq 'file' || $_[0] eq 'string' || $_[0] eq 'doc'
                    }
                }
            },
            output_file => {
                type => SCALAR,
                optional => 1,
                depends => [qw/output/]
            },
            convert_opts => {
                type => HASHREF,
                optional => 1,
            },
        }
    );

    my $driver = $self->drivers->{$args{format}};
    my $src_doc = $args{src_doc} || 
        ($args{src_file}) ? 
            $self->parser->parse_file($args{src_file}) :
            $self->parser->parse_string($args{src_string});;

    my $convert_opts = ($args{convert_opts}) ? $args{convert_opts} : {};

    my $method = "convert_" . $args{output};
    return $driver->$method($src_doc, $args{output_file}, $convert_opts);
}

=head1 SEE ALSO

=over 4

=item L<Carp::Clan>

=item L<Module::Load>

=item L<Module::Pluggable::Fast>

=item L<Params::Validate>

=item L<Scalar::Util>

=item L<XML::LibXML>

=item L<SVG::Convert::Driver::XAML>

=item L<SVG::Convert::Driver::PNG>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svg-convert@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SVG::Convert
