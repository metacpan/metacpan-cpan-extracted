package Template::Plugin::Nbsp;
$VERSION = 0.01;

use strict;
use base 'Template::Plugin';

sub new {
    my ($self, $context) = @_;

    $context->define_filter('nbsp', \&nbsp, '');

    return $self;
}

sub nbsp {
    my $text = shift;

    # undef?
    return '&nbsp;' unless defined $text;

    # empty string?
    return '&nbsp;' if ($text eq '');

    return $text;
}


1;
__END__

=head1 NAME

Template::Plugin::Nbsp - TT2 plugin that inserts non-breaking space
(usefull for empty table cells)

=head1 SYNOPSIS

  [% USE Nbsp %]

  <table>
    <tr>
      <td>[% variable | nbsp %]</td>
    </tr>
  </table>

=head1 DESCRIPTION

This plugin helps preventing empty table cells. If the value is
undef or empty it returns C<&nbsp;>.

=head1 NOTE

If you use cascading style sheets (css), you can use
C<empty-cells: show;> to get the same results without this plugin.

=head1 AUTHOR

Uwe Voelker E<lt>uwe.voelker@gmx.deE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut
