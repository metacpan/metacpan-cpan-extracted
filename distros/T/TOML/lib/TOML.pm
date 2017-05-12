package TOML;

# -------------------------------------------------------------------
# TOML - Parser for Tom's Obvious, Minimal Language.
#
# Copyright (C) 2013 Darren Chamberlain <darren@cpan.org>
# -------------------------------------------------------------------

use 5.008005;
use strict;
use warnings;
use Exporter 'import';

our ($VERSION, @EXPORT, @_NAMESPACE, $PARSER);

use B;
use Carp qw(croak);
use TOML::Parser 0.03;

$VERSION = "0.97";
@EXPORT = qw(from_toml to_toml);
$PARSER = TOML::Parser->new(inflate_boolean  => sub { $_[0] });

sub to_toml {
    my $stuff = shift;
    local @_NAMESPACE = ();
    _to_toml($stuff);
}

sub _to_toml {
    my ($stuff) = @_;

    if (ref $stuff eq 'HASH') {
        my $res = '';
        my @keys = sort keys %$stuff;
        for my $key (grep { ref $stuff->{$_} ne 'HASH' } @keys) {
            my $val = $stuff->{$key};
            $res .= "$key = " . _serialize($val) . "\n";
        }
        for my $key (grep { ref $stuff->{$_} eq 'HASH' } @keys) {
            my $val = $stuff->{$key};
            local @_NAMESPACE = (@_NAMESPACE, $key);
            $res .= sprintf("[%s]\n", join(".", @_NAMESPACE));
            $res .= _to_toml($val);
        }
        return $res;
    } else {
        croak("You cannot convert non-HashRef values to TOML");
    }
}

sub _serialize {
    my $value = shift;
    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;

    return $value
        if $flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?

    my $type = ref($value);
    if (!$type) {
        return string_to_json($value);
    } elsif ($type eq 'ARRAY') {
        return sprintf('[%s]', join(", ", map { _serialize($_) } @$value));
    } elsif ($type eq 'SCALAR') {
        if (defined $$value) {
            if ($$value eq '0') {
                return 'false';
            } elsif ($$value eq '1') {
                return 'true';
            } else {
                croak("cannot encode reference to scalar");
            }
        }
        croak("cannot encode reference to scalar");
    }
    croak("Bad type in to_toml: $type");
}

my %esc = (
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
    "\'" => '\\\'',
);
sub string_to_json {
    my ($arg) = @_;

    $arg =~ s/([\x22\x5c\n\r\t\f\b])/$esc{$1}/g;
    $arg =~ s/([\x00-\x08\x0b\x0e-\x1f])/'\\u00' . unpack('H2', $1)/eg;

    return '"' . $arg . '"';
}

sub from_toml {
    my $string = shift;
    local $@;
    my $toml = eval { $PARSER->parse($string) };
    return wantarray ? ($toml, $@) : $toml;
}

1;

__END__

=encoding utf-8

=for stopwords versa

=head1 NAME

TOML - Parser for Tom's Obvious, Minimal Language.

=head1 SYNOPSIS

    use TOML qw(from_toml to_toml);

    # Parsing toml
    my $toml = slurp("~/.foo.toml");
    my $data = from_toml($toml);

    # With error checking
    my ($data, $err) = from_toml($toml);
    unless ($data) {
        die "Error parsing toml: $err";
    }

    # Creating toml
    my $toml = to_toml($data); 

=head1 DESCRIPTION

C<TOML> implements a parser for Tom's Obvious, Minimal Language, as
defined at L<https://github.com/mojombo/toml>. C<TOML> exports two
subroutines, C<from_toml> and C<to_toml>,

=head1 FAQ

=over 4

=item How change how to de-serialize?

You can change C<$TOML::PARSER> for change how to de-serialize.

example:

    use TOML;
    use TOML::Parser;

    local $TOML::PARSER = TOML::Parser->new(
        inflate_boolean => sub { $_[0] eq 'true' ? \1 : \0 },
    );

    my $data = TOML::from_toml('foo = true');

=back

=head1 FUNCTIONS

=over 4

=item from_toml

C<from_toml> transforms a string containing toml to a perl data
structure or vice versa. This data structure complies with the tests
provided at L<https://github.com/mojombo/toml/tree/master/tests>.

If called in list context, C<from_toml> produces a (C<hash>,
C<error_string>) tuple, where C<error_string> is C<undef> on
non-errors. If there is an error, then C<hash> will be undefined and
C<error_string> will contains (scant) details about said error.

=item to_toml

C<to_toml> transforms a perl data structure into toml-formatted
string.

=back

=head1 SEE ALSO

L<TOML::Parser>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02111-1301 USA

=head1 AUTHOR

Darren Chamberlain <darren@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item Tokuhiro Matsuno <tokuhirom@cpan.org>

=item Matthias Bethke <matthias@towiski.de>

=item Sergey Romanov <complefor@rambler.ru>

=item karupanerura <karupa@cpan.org>

=back
