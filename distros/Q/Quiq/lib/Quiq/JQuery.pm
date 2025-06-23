# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery - Basisfunktionalität zu jQuery

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::JQuery;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 cdnUrl() - Liefere CDN URL

=head4 Synopsis

  $url = $this->cdnUrl;

=head4 Returns

URL (String)

=head4 Description

Liefere den CDN URL der neusten Version von jQuery.

=head4 Example

  $url = Quiq::JQuery->cdnUrl;
  ==>
  https://code.jquery.com/jquery-latest.min.js

=cut

# -----------------------------------------------------------------------------

sub cdnUrl {
    my $this = shift;
    return 'https://code.jquery.com/jquery-latest.min.js';
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
