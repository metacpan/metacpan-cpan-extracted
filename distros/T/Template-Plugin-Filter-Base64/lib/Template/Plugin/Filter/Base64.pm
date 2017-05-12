package Template::Plugin::Filter::Base64;
use 5.008001;
use strict;
use warnings;

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use Encode;
use MIME::Base64 qw(encode_base64);
use HTML::Entities qw(encode_entities_numeric);

our $VERSION = "0.02";

sub init {
    my ($self) = @_;
    $self->install_filter('b64');
    return $self;
}

sub filter {
    my ($self, $text) = @_;

    my %options = ();
    if ($self->{ _CONFIG } && (ref($self->{ _CONFIG }) eq 'HASH')) {
        if ($self->{ _CONFIG }->{trim}) {
            $text =~ s/^\s+//ms;
            $text =~ s/\s+$//ms;
        }
        if ($self->{ _CONFIG }->{use_html_entity}) {
            my $charset = $self->{ _CONFIG }->{use_html_entity};
            $text = encode('UTF8', decode($charset, $text));
            Encode::_utf8_on($text);
            $text = encode_entities_numeric($text);
        }
    }

    my $encoded = encode_base64($text);

    return $encoded
}


1;
__END__

=encoding utf-8

=head1 NAME

Template::Plugin::Filter::Base64 - encoding b64 filter for Template Toolkit

=head1 SYNOPSIS

    [% USE Filter.Base64 trim => 1, use_html_entity => 'cp1251' %]
    [% FILTER b64 %]
        Hello, world!
    [% END %]

=head1 OPTIONS

=over

=item trim

Optional. If true, removes trailing blank characters (and lf, cr) of an input string

=back

=over

=item use_html_entity (string)

Optional. Value means default charset (e.g. 'cp1251'). Result - convert text with html entities before base64-encoding

=back

=head1 SEE ALSO

MIME::Base64 - Encoding and decoding of base64 strings L<http://search.cpan.org/~gaas/MIME-Base64/Base64.pm>

=head1 LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

bbon <bbon@mail.ru>

=cut
