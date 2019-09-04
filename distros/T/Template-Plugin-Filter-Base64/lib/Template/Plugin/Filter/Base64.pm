package Template::Plugin::Filter::Base64;
use 5.008001;
use strict;
use warnings;

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use Encode;
use MIME::Base64 qw(encode_base64);
use HTML::Entities qw(encode_entities_numeric);

our $VERSION = "0.07";

sub init {
    my ($self) = @_;
    $self->{_DYNAMIC} = 1;
    $self->install_filter('b64');
    return $self;
}

sub filter {
    my ($self, $text, $args, $conf) = @_;

    $conf = $self->merge_config($conf);
    
    if ($conf->{trim}) {
        $text =~ s/^\s+//ms;
        $text =~ s/\s+$//ms;
    }
    if($conf->{safeurl}){
        return MIME::Base64::encode_base64url($text);
    }

    my @encode_args = ();

  
    if ($conf->{use_html_entity}) {
        my $charset = $conf->{use_html_entity};
        if($charset){
            $text = decode($charset, $text)
        }
        $text = Encode::encode('UTF-8',$text);
        Encode::_utf8_on($text);

        $text = encode_entities_numeric($text);

    }else{
        utf8::encode($text) if utf8::is_utf8($text);
    }
    if ($conf->{dont_broken_into_lines_each_76_char}) {
        push @encode_args, '';
    }
    
    unshift @encode_args, $text;

    my $encoded = &encode_base64(@encode_args);

    return $encoded
}

1;
__END__

=encoding utf-8

=head1 NAME

Template::Plugin::Filter::Base64 - encoding b64 filter for Template Toolkit

=head1 SYNOPSIS

    [% USE Filter.Base64 trim => 1, use_html_entity => 'cp1251', dont_broken_into_lines_each_76_char => 1 %]
    [% FILTER b64 %]
        Hello, world!
    [% END %]

    [% USE Filter.Base64 trim => 1 %]
    [% FILTER b64 safeurl => 1 %]
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

=over

=item dont_broken_into_lines_each_76_char

Optional. If true, call the function MIME::Base64::encode_base64( $bytes, '' ) whith empty string for the parameter $eol. The returned encoded string is broken into lines of no more than 76 characters each and it will end with $eol unless it is empty. Pass an empty string as second argument if you do not want the encoded string to be broken into lines

=back

=over

=item safeurl (bool)

Optional. If true call MIME::Base64::encode_base64url, no other options do matter except L</trim>

=back

=head1 SEE ALSO

MIME::Base64 - Encoding and decoding of base64 strings L<https://metacpan.org/pod/MIME::Base64>

=head1 LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS

gnatyna L<https://github.com/gnatyna>

gilgamesh44

=head1 AUTHOR

bbon <bbon@mail.ru>

=cut
