package Template::Plugin::GD::Text;

use strict;
use warnings;
use base qw( GD::Text Template::Plugin );

our $VERSION = sprintf("%d.%02d", q$Revision: 1.56 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    push(@_, %{pop(@_)}) if ( @_ & 1 && ref($_[@_-1]) eq "HASH" );
    return $class->SUPER::new(@_);
}

sub set {
    my $self = shift;
    push(@_, %{pop(@_)}) if ( @_ & 1 && ref($_[@_-1]) eq "HASH" );
    $self->SUPER::set(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::GD::Text - Text utilities for use with GD

=head1 SYNOPSIS

    [% USE gd_text = GD.Text %]

=head1 EXAMPLES

    [%
        USE gd_c = GD.Constants;
        USE t = GD.Text;
        x = t.set_text('Some text');
        r = t.get('width', 'height', 'char_up', 'char_down');
        r.join(":"); "\n";     # returns 54:13:13:0.
    -%]

    [%
        USE gd_c = GD.Constants;
        USE t = GD.Text(text => 'FooBar Banana', font => gd_c.gdGiantFont);
        t.get('width'); "\n";  # returns 117.
    -%]

=head1 DESCRIPTION

The GD.Text plugin provides an interface to the GD::Text module.
It allows attributes of strings such as width and height in pixels
to be computed.

See L<GD::Text> for more details. See
L<Template::Plugin::GD::Text::Align> and
L<Template::Plugin::GD::Text::Wrap> for plugins that
allow you to render aligned or wrapped text in GD images.

=head1 AUTHOR

Thomas Boutell wrote the GD graphics library.

Lincoln D. Stein wrote the Perl GD modules that interface to it
and Martien Verbruggen wrote the GD::Text module.

Craig Barratt E<lt>craig@arraycomm.comE<gt> wrote the original GD
plugins for the Template Toolkit (2001).

Andy Wardley E<lt>abw@cpan.orgE<gt> extracted them from the TT core
into a separate distribution for TT version 2.15.

=head1 COPYRIGHT

Copyright (C) 2001 Craig Barratt E<lt>craig@arraycomm.comE<gt>,
2006 Andy Wardley E<lt>abw@cpan.orgE<gt>.

GD::Text is copyright 1999 Martien Verbruggen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::GD>, L<Template::Plugin::GD::Text::Wrap>, L<Template::Plugin::GD::Text::Align>, L<GD|GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
