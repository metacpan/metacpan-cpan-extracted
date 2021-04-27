package Template::Plugin::DataPrinter;
use strict;
use warnings;
use base 'Template::Plugin';

# ABSTRACT: Template Toolkit dumper plugin using Data::Printer
our $VERSION = '0.014'; # VERSION

use HTML::FromANSI::Tiny ();
use Hash::Merge::Simple qw< merge >;

sub new {
    my ($class, $context, $params) = @_;

    require Data::Printer;
    Data::Printer->VERSION(1.0.0);
    my $dp_params = merge( {
            colored => 1,
            return_value => 'dump',
            use_prototypes => 0,
        },
        $params->{dp});
    Data::Printer->import(%$dp_params);

    my $hfat_params = merge( {
            class_prefix  => 'ansi_',
            no_plain_tags => 1,
        },
        $params->{hfat});

    my $hfat = HTML::FromANSI::Tiny->new(%$hfat_params);
    my $self = bless {
        _CONTEXT => $context,
        hfat => $hfat,
    }, $class;

    return $self;
}

sub dump {
    my $self = shift;
    my $text = join('', map { p($_) . "\n" } @_);
    return $text;
}

sub dump_html {
    my $self = shift;

    my $html = $self->_css;
    my $text = $self->dump(@_);
    $html .= "<pre>\n" . $self->{hfat}->html($text) . '</pre>';
    return $html;
}

sub _css {
    # Short of a better plan, emit the css on-demand before the first dump_html
    my $self = shift;
    return '' if $self->{done_css};

    $self->{done_css} = 1;
    return $self->{hfat}->style_tag . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::DataPrinter - Template Toolkit dumper plugin using Data::Printer

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    [% USE DataPrinter %]

    [% DataPrinter.dump(variable) %]
    [% DataPrinter.dump_html(variable) %]

=head1 DESCRIPTION

This is a dumper plugin for L<Template::Toolkit|Template::Toolkit> which uses
L<Data::Printer|Data::Printer> instead of L<Data::Dumper|Data::Dumper>.

L<Data::Printer|Data::Printer> is a colorised pretty-printer with nicely
human-readable object output.

=head1 METHODS

The provided methods match those of
L<Template::Plugin::Dumper|Template::Plugin::Dumper>.

=head2 dump

Generates an ansi-colorised dump of the data structures passed.

    [% USE DataPrinter %]
    [% DataPrinter.dump(myvar) %]
    [% DataPrinter.dump(myvar, yourvar) %]

=head2 dump_html

Generates a html-formatted dump of the data structures passed. The ansi
colorisation is converted to html by
L<HTML::FromANSI::Tiny|HTML::FromANSI::Tiny>.

    [% USE DataPrinter %]
    [% DataPrinter.dump_html(myvar) %]
    [% DataPrinter.dump_html(myvar, yourvar) %]

=head1 CONFIGURATION

This plugin has no configuration of its own, but the underlying
L<Data::Printer|Data::Printer> and L<HTML::FromANSI::Tiny|HTML::FromANSI::Tiny>
modules can be configured using the C<dp> and C<hfat> parameters.

    [% USE DataPrinter(dp = { ... }, hfat = { ... }) %]

=over

=item dp

A hashref containing the params to be passed to C<Data::Printer::import>.

See the L<Data::Printer|Data::Printer> documentation for more information.

=item hfat

A hashref containing the params to be passed to C<HTML::FromANSI::Tiny-E<gt>new>.

See the L<HTML::FromANSI::Tiny|HTML::FromANSI::Tiny> documentation for more
information.

=back

=head2 Disabling colorisation

Colorisation is turned on by default. To turn it off, use
L<Data::Printer|Data::Printer>'s C<colored> parameter:

    [% USE DataPrinter(dp = { colored = 0 }) %]

=head2 Using as a drop-in replacement for Template::Plugin::Dumper

This module can be used more-or-less as a drop-in replacement for the default
Dumper plugin by specifying an explicit plugin mapping to the C<Template>
constructor:

    my $template = Template->new(...,
            PLUGINS => {
                Dumper => 'Template::Plugin::DataPrinter',
            },
        );

Then existing templates such as the one below will automatically use the
C<DataPrinter> plugin instead.

    [% USE Dumper(Indent=0, Pad="<br>") %]

    [% Dumper.dump(variable) %]
    [% Dumper.dump_html(variable) %]

Any unrecognised constructor parameters are silently ignored, so the C<Indent>
and C<Pad> parameters above will have no effect.

=head2 Using a custom .dataprinter file

A custom L<Data::Printer|Data::Printer> configuration file can be specified like so:

    [% USE DataPrinter(dp = { rc_file = '/path/to/my/rcfile.conf' }) %]

Beware that setting C<colored = 0> in your F<.dataprinter> file
I<will not work>. This must be specified in the C<USE DataPrinter> code.

    [% USE DataPrinter(dp = { rc_file = '...', colored = 0 }) %]

=head1 BUGS

Setting C<colored = 0> in the F<.dataprinter> file will not work.
The C<colored = 0> setting must appear in the C<USE DataPrinter> line.

=head1 SEE ALSO

=over

=item * L<Template::Toolkit|Template::Toolkit>

=item * L<Data::Printer|Data::Printer>

=item * L<HTML::FromANSI::Tiny|HTML::FromANSI::Tiny>

=back

=head1 AUTHOR

Stephen Thirlwall <sdt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
