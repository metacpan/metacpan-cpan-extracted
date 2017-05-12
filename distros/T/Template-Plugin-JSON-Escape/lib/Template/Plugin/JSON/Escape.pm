package Template::Plugin::JSON::Escape;
use strict;
use warnings;

use base qw/Template::Plugin/;
use JSON ();

our $VERSION = 0.02;

sub new {
    my ($class, $context, $args) = @_;
    my $self = bless { json => undef, args => $args }, $class;

    my $encode = sub { $self->json_encode( @_ ) };
    $context->define_vmethod( $_ => json => $encode ) for qw/hash list scalar/;
    $context->define_filter( json => \&json_filter );

    return $self;
}

sub json {
    my $self = shift;
    return $self->{json} if $self->{json};

    my $json = JSON->new->allow_nonref;
    my $args = $self->{args};
    for ( keys %$args ) {
        $json->$_( $args->{ $_ } ) if $json->can( $_ );
    }
    return $self->{json} = $json;
}

sub json_encode {
    my ($self, $value) = @_;
    json_filter( $self->json->encode( $value ) );
}

sub json_decode {
    my ($self, $value) = @_;
    $self->json->decode( $value );
}

sub json_filter {
    my $value = shift;
    $value =~ s!&!\\u0026!g;
    $value =~ s!<!\\u003c!g;
    $value =~ s!>!\\u003e!g;
    $value =~ s!\+!\\u002b!g;
    $value =~ s!\x{2028}!\\u2028!g;
    $value =~ s!\x{2029}!\\u2029!g;
    $value;
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::JSON::Escape - Adds a .json vmethod and a json filter.

=head1 SYNOPSIS

    [% USE JSON.Escape( pretty => 1 ) %];

    <script type="text/javascript">

        var foo = [% foo.json %];
        var bar = [% json_string | json %]

    </script>

    or read in JSON

    [% USE JSON.Escape %]
    [% data = JSON.Escape.json_decode(json) %]
    [% data.thing %]

=head1 DESCRIPTION

This plugin allows you to embed JSON strings in HTML.  In the output, special characters such as C<E<lt>> and C<&> are escaped as C<\uxxxx> to prevent XSS attacks.

It also provides decoding function to keep compatibility with L<Template::Plugin::JSON>.

=head1 FEATURES

=head2 USE JSON.Escape

Any options on the USE line are passed through to the JSON object, much like L<JSON/to_json>.

=head2 json vmethod

A C<.json> vmethod converts scalars, arrays and hashes into corresponding JSON strings.

    [% json_stuct = { foo => 42, bar => [ 1, 2, 3 ] } %]
    
    <script>
        var json = [% json_struct.json %];
    </script>
    
    <span onclick="doSomething([% json_struct.json %]);">

=head2 json filter

A C<json> filter escapes C<E<lt>>, C<E<gt>>, C<&>, C<+>, C<U+2028> and C<U+2029> as C<\uxxxx>. In the attribute, you may just use an C<html> filter.

    [% json_string = '{ "foo": 42, "bar": [ 1, 2, 3 ] }' %]
    
    <script>
        var json = [% json_string | json %];
    </script>
    
    <span onclick="doSomething([% json_string | html %]);">

=head2 json_decode method

A C<json_decode> method allow you to convert from a JSON string into a corresponding data structure.

    [% SET json_struct = JSON.Escape.json_decode(json_string) %]
    [% json_struct.foo | html %]

=head1 SEE ALSO

L<Template::Plugin::JSON>, L<JSON>, L<Template::Plugin>

=head1 VERSION CONTROL

L<https://github.com/nanto/perl-Template-Plugin-JSON-Escape>

=head1 AUTHOR

nanto_vi (TOYAMA Nao) <nanto@moon.email.ne.jp>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 nanto_vi (TOYAMA Nao).

Copyright (c) 2006, 2008 Infinity Interactive, Yuval Kogman.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
