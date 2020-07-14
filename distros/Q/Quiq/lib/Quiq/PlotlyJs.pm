package Quiq::PlotlyJs;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.185';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs - Basisfunktionalität zu Plotly.js

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 cdnUrl() - Liefere CDN URL

=head4 Synopsis

  $url = $this->cdnUrl;

=head4 Returns

URL (String)

=head4 Description

Liefere den CDN URL der neusten Version von Plotly.js.

=head4 Example

  $url = Quiq::PlotlyJs->cdnUrl;
  ==>
  https://cdn.plot.ly/plotly-latest.min.js

=cut

# -----------------------------------------------------------------------------

sub cdnUrl {
    my $this = shift;
    return 'https://cdn.plot.ly/plotly-latest.min.js';
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.185

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2020 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
