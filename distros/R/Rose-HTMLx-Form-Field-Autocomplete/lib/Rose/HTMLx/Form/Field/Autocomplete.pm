package Rose::HTMLx::Form::Field::Autocomplete;

use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

use base qw( Rose::HTML::Form::Field::Text );

use Rose::Object::MakeMethods::Generic (scalar => [qw( autocomplete limit )]);

sub url
{
    my $self = shift;
    my $u    = $self->autocomplete or croak "no autocomplete URL set";
    my $n    = $self->name || $self->local_name;
    my $l    = $self->limit || 30;
    return [$u, {c => $n, l => $l}];
}

# borrowed from TT::Plugin::URL
sub url_as_string
{
    my $self = shift;
    my $url  = $self->url;
    my $args = $url->[1];
    my $esc  = join('&amp;',
                   map { _url_args($_, $args->{$_}) }
                     grep { defined $args->{$_} && length $args->{$_} }
                     sort keys %$args);

    return $url->[0] . '?' . $esc;
}

# borrowed from TT::Plugin::URL
sub _url_args
{
    my ($key, $val) = @_;
    $key = _escape($key);

    return map { "$key=" . _escape($_); } ref $val eq 'ARRAY' ? @$val : $val;
}

# borrowed from TT::Plugin::URL, which borrowed froM CGI.pm
sub _escape
{
    my $toencode = shift;
    return undef unless defined($toencode);
    $toencode =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

1;

__END__

=head1 NAME

Rose::HTMLx::Form::Field::Autocomplete - Ajax autocompletion for text fields

=head1 SYNOPSIS

 my $field = Rose::HTMLx::Form::Field::Autocomplete->new(
    label           => 'Complete Me',
    name            => 'completer',
    size            => 30,
    maxlength       => 128,
    autocomplete    => 'http://myserver.foo/completer/url,
    limit           => 30
 );
 
 print $field->xhtml;
 
 ...

=head1 DESCRIPTION

This subclass of Rose::HTML::Form::Field::Text is intended to make it easier
to integrate Ajax autocompletion into your web applications. You define
a URL where your web application can find suggested values for the field,
and optionally, a limit on the number of suggestions returned by the server.

This subclass is expected to be used with 
Catalyst::Controller::Rose::Autocomplete but that is not required.

=head1 METHODS

Only changes from Rose::HTML::Form::Field::Text are documented here.

=head2 autocomplete

Expects a URL value but any string is acceptable. See url().

=head2 limit

Expects an integer, which will be used in the construction of url().

=head2 url

Returns the URL for use in your template. The return value is an array
ref, with the first value being the base URI and the second value being
a hashref of param key/value pairs. The hashref keys are in the syntax
that Catalyst::Controller::Rose::Autocomplete expects.

See the Catalyst::Controller::Rose example application for examples
of using the url() method with Template Toolkit.

=head2 url_as_string

Like url() but the return value is a scalar string, not an array ref.
The value is the URI-escaped value of url().

=head1 AUTHOR

Peter Karman <perl@peknet.com>

Thanks to Atomic Learning, Inc for sponsoring the development of this module.

=head1 LICENSE

This library is free software. You may redistribute it and/or modify it under
the same terms as Perl itself.


=head1 SEE ALSO

Catalyst::Controller::Rose::Autocomplete,
Rose::HTML::Objects, Rose::HTML::Form::Field

=cut

