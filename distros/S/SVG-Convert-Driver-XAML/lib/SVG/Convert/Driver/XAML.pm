package SVG::Convert::Driver::XAML;

use strict;
use warnings;

use base qw(SVG::Convert::BaseDriver);

__PACKAGE__->mk_accessors(qw/stylesheet/);

use Carp::Clan;
use Path::Class qw(file);
use XML::LibXML;
use XML::LibXSLT;

our $STYLE_FILE = file(__FILE__)->dir->file('XAML', 'svg2xaml.xsl')->stringify;

=head1 NAME

SVG::Convert::Driver::XAML - SVG::Convert XAML driver.

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

=head1 METHODS

=head2 new($args)

=cut

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);
    my $xslt = XML::LibXSLT->new;
    my $stylesheet = $xslt->parse_stylesheet_file($STYLE_FILE);

    $self->stylesheet($stylesheet);

    return $self;
}

=head2 convert_string($src_doc, $convert_opts)

Convert to string.

=cut

sub convert_string {
    my ($self, $src_doc, $convert_opts) = @_;

    return $self->_convert($src_doc, $convert_opts);
}

=head2 convert_doc($src_doc, $convert_opts)

Convert to L<XML::LibXML::Document> object.

=cut

sub convert_doc {
    my ($self, $src_doc, $convert_opts) = @_;

    return $self->parser->parse_string(
        $self->convert_string($src_doc, $convert_opts)
    );
}

=head2 convert_file($src_doc, $out_file, $convert_opts)

Convert to file.

=cut

sub convert_file {
    my ($self, $src_doc, $out_file, $convert_opts) = @_;
    return $self->convert_doc($src_doc)->toFile($out_file);
}

###
### protected methods
###

sub _convert {
    my ($self, $src_doc, $convert_opts) = @_;

    my $result;
    eval { $result = $self->stylesheet->transform($src_doc); };
    if ($@) { croak($@); }

    my $xaml_str = $self->stylesheet->output_string($result);
    $xaml_str =~ s/&#13;/\n/g;

    return $xaml_str;
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svg-convert-driver-xaml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SVG::Convert::Driver::XAML
