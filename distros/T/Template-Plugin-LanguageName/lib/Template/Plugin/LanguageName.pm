package Template::Plugin::LanguageName;

use strict;
use warnings;
use parent qw(Template::Plugin::Filter);
use Locale::Codes::Language;

=head1 NAME

Template::Plugin::LanguageName - Template filter to lookup the name for a ISO639-1 or ISO639-2 language code

=head1 VERSION

Version 0.0101

=cut

our $VERSION = '0.0101';

=head1 SYNOPSIS

    [% USE LanguageName %]

    [% "fr" | language_name %]
    => "French"
    [% "gre" | language_name %]
    => "Greek, Modern (1453-)"
    [% "xx" | language_name %]
    => undef

=cut

my $FILTER_NAME = 'language_name';

sub init {
    my $self = $_[0];
    $self->install_filter($FILTER_NAME);
    $self;
}

sub filter {
    my $code = $_[1];
    code2language($code, length($code) == 3 ? LOCALE_LANG_ALPHA_3 : LOCALE_LANG_ALPHA_2);
}

=head1 SEE ALSO

L<Locale::Codes::Language>.

=cut

1;
