#
# This file is part of Plack-Middleware-ExtractUriLanguage
#
# This software is Copyright (c) 2013 by BURNERSK.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
package Plack::Middleware::ExtractUriLanguage;
use strict;
use warnings FATAL => 'all';
use utf8;

BEGIN {
  our $VERSION = '0.004'; # VERSION
}

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(
  ExtractUriLanguageOrig
  ExtractUriLanguageTag
  ExtractUriLanguageList
);
use Plack::Middleware::ExtractUriLanguage::Type ':all';

############################################################################
# Called once.
sub prepare_app {
  my ($self) = @_;

  # Precompose language tag regex.
  if ( my $list = $self->ExtractUriLanguageList ) {
    if ( defined $list && ref($list) ne 'ARRAY' ) {
      my ( $package, $filename, $line ) = caller(6);
      die sprintf "ExtractUriLanguageList is not an array reference at %s line %s.\n", $filename, $line;
    }
    elsif ( defined $list ) {
      my $list_qm = join q{|}, map { quotemeta } @{$list};
      $self->{extracturilanguage_list_qr} = [
        qr{^/($list_qm)/?$},
        qr{^/($list_qm)/(.*)$},
      ];
    }
  }
  if ( !$self->{extracturilanguage_list_qr} ) {
    $self->{extracturilanguage_list_qr} = [
      qr{^/([[:alpha:]]{2}(?:\-[[:alpha:]]{2})?)/?$},
      qr{^/([[:alpha:]]{2}(?:\-[[:alpha:]]{2})?)/(.*)$},
    ];
  }

  return;
}

############################################################################
# Called on every reqeust.
sub call {
  my ( $self, $env ) = @_;
  my $language_tag;
  my $orig_name = $self->ExtractUriLanguageOrig || $DEFAULT_PATH_INFO_ORIG_FIELD;
  my $tag_name  = $self->ExtractUriLanguageTag  || $DEFAULT_LANGUAGE_TAG_FIELD;
  my $list      = $self->ExtractUriLanguageList || undef;
  my $path_info = $env->{$PATH_INFO_FIELD}; # is "/en-us/some-site" when "http://example.com/en-us/some-site".

  my ( $qr1, $qr2 ) = @{ $self->{extracturilanguage_list_qr} };
  if ( $path_info =~ $qr1 || $path_info =~ $qr2 ) {
    my ( $tag, $uri ) = ( $1, $2 );
    {
      no warnings 'uninitialized';
      $uri = "/$uri";
    }
    $language_tag = $tag;
    $path_info    = $uri;
  }

  # Manipulate environment only when a language tag was identified.
  if ($language_tag) {
    $env->{$tag_name}        = $language_tag;             # The language tag wich was found.
    $env->{$orig_name}       = $env->{$PATH_INFO_FIELD};  # The original PATH_INFO.
    $env->{$PATH_INFO_FIELD} = $path_info;                # The new manupulated PATH_INFO.
  }

  # Dispatch request to application.
  return $self->app->($env);
}

############################################################################
1;
__END__
=pod

=encoding utf8

=head1 NAME

Plack::Middleware::ExtractUriLanguage - Cuts off language tags out of the request's PATH_INFO to simplify internationalization route handlers.

=head1 VERSION

This documentation describes
L<ExtractUriLanguage|Plack::Middleware::ExtractUriLanguage> within version
0.004.

B<Current development state: BETA release>

=head1 SYNOPSIS

    # with Plack::Middleware::ExtractUriLanguage
    enable 'Plack::Middleware::ExtractUriLanguage',
      ExtractUriLanguageOrig => 'extracturilanguage.path_info',
      ExtractUriLanguageTag  => 'extracturilanguage.language';

=head1 DESCRIPTION

L<ExtractUriLanguage|Plack::Middleware::ExtractUriLanguage> cuts off
language tags out of the request's PATH_INFO to simplify
internationalization route handlers. The extracted language tag will be
stored within the environment variable C<extracturilanguage.language>
(configurable). The original unmodified C<PATH_INFO> is additionaly saved
within the environment variable C<extracturilanguage.path_info>
(configurable).

=head1 CONFIGURATION AND ENVIRONMENT

=head2 ExtractUriLanguageOrig

    ExtractUriLanguageOrig  => 'extracturilanguage.path_info';

Environment variable name for the original unmodified C<PATH_INFO>. The
default is "extracturilanguage.path_info".

=head2 ExtractUriLanguageTag

    ExtractUriLanguageTag  => 'extracturilanguage.language';

Environment variable name for the detected language tag. The default is
"extracturilanguage.language".

=head2 ExtractUriLanguageList

    ExtractUriLanguageList => [qw( de de-de en en-us en-gb )];

Only detect and extract the language tags defined with this list. The
default is C<undef>. When C<undef>
L<ExtractUriLanguage|Plack::Middleware::ExtractUriLanguage> will try to
guess the language tag based on the following formats:

=over

=item ISO 639-1 "-" ISO 3166 ALPHA-2 ( "de-de", "en-us", "en-gb" )

=item ISO 639-1 ( "de", "en" )

=back

=head1 BUGS AND LIMITATIONS

Please report all bugs and feature requests at
L<GitHub Issues|https://github.com/burnersk/Plack-Middleware-ExtractUriLanguage/issues>.

=head1 AUTHOR

BURNERSK E<lt>burnersk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This file is part of Plack-Middleware-ExtractUriLanguage

This software is Copyright (c) 2013 by BURNERSK.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
