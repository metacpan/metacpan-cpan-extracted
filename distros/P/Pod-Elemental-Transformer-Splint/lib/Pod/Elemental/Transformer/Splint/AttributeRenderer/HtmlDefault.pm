use 5.10.1;
use strict;
use warnings;

package Pod::Elemental::Transformer::Splint::AttributeRenderer::HtmlDefault;

our $VERSION = '0.1201'; # VERSION
# ABSTRACT: Default html attribute renderer

use Moose;
use namespace::autoclean;
use Path::Tiny;
use Pod::Simple::XHTML;
use syntax 'qs';

with 'Pod::Elemental::Transformer::Splint::AttributeRenderer';

sub render_attribute {
    my $self = shift;
    my $data = shift;

    my $settings = $data->{'settings'};
    my $documentation_alts = $data->{'documentation_alts'};
    my $documentation = $data->{'documentation'};

    my $items = [];
    push @$items => $settings->{'type'} if defined $settings->{'type'};
    my $req_and_default = '';

    if(!$settings->{'has_init_arg'}) {
        $req_and_default = 'not in constructor';
    }
    elsif(!defined $settings->{'default'}) {
        $req_and_default = $settings->{'required_text'};
    }
    elsif($settings->{'is_default_a_coderef'}) {
        if(defined $settings->{'documentation_default'}) {
            $req_and_default = $self->parse_pod(sprintf '%s, default: C<%s>', $settings->{'required_text'}, $settings->{'documentation_default'});
        }
        else {
            $req_and_default = $self->parse_pod(sprintf '%s, default is a C<coderef>', $settings->{'required_text'});
        }
    }
    else {
        $req_and_default = $self->parse_pod(sprintf '%s, default: C<%s>', $settings->{'required_text'}, $settings->{'default'});
    }

    push @$items => $req_and_default;
    push @$items => $settings->{'is_text'};

    my $last_item = pop @$items;
    my $cells = [ map { $self->make_cell_with_border(nowrap => 1, text => $_) } @$items ];

    push @$cells => scalar @{ $documentation_alts } ? $self->make_cell_with_border(nowrap => 1, text => $last_item)
                 :                                    $self->make_cell_without_border(nowrap => 1, text => $last_item)
                 ;

    if(scalar @{ $documentation_alts }) {
        my $first_doc_alt = shift @{ $documentation_alts };

        push @$cells => $self->make_cell_without_border_right_aligned(nowrap => 0, text => $self->parse_pod(sprintf 'C<%s>:', $first_doc_alt->[0]) ),
                       $self->make_cell_extra_padded_without_border(nowrap => 0, text => $first_doc_alt->[1]);
    }

    my $rows = [ $cells ];

    if(scalar @{ $documentation_alts} ){
        my $number_of_cells_left_of_doc = scalar @$cells - 2;

        foreach my $doc_alt (@{ $documentation_alts }) {
            my $row = [ ('    <td>&#160;</td>') x $number_of_cells_left_of_doc ];
            push @{ $row } => $self->make_cell_without_border_right_aligned(nowrap => 0, text => $self->parse_pod(sprintf 'C<%s>:', $doc_alt->[0]) ),
                              $self->make_cell_extra_padded_without_border(nowrap => 0, text => $doc_alt->[1]);
            push @{ $rows } => $row;
        }
    }

    my @table = ();
    foreach my $row (@{ $rows }) {
        push @table => ('<tr>');
        push @table => @{ $row };
        push @table => ('</tr>');
    }

    my $content =  sprintf qs{
        =begin %s

            <table cellpadding="0" cellspacing="0">
                %s
            </table>

            <p>%s</p>

        =end %s
    }, $self->for, join ("\n" => @table), ($documentation // ''), $self->for;

    return $content;
}

sub make_cell_without_border {
    my $self = shift;
    my %args = @_;
    my $text = $args{'text'};
    my $nowrap = !$args{'nowrap'} ? '' : ' white-space: nowrap;';

    return qq{    <td style="padding-left: 6px; padding-right: 6px;$nowrap">$text</td>};
}
sub make_cell_extra_padded_without_border {
    my $self = shift;
    my %args = @_;
    my $text = $args{'text'};
    my $nowrap = !$args{'nowrap'} ? '' : ' white-space: nowrap;';

    return qq{    <td style="padding-left: 12px;$nowrap">$text</td>};
}
sub make_cell_with_border {
    my $self = shift;
    my %args = @_;
    my $text = $args{'text'};
    my $nowrap = !$args{'nowrap'} ? '' : ' white-space: nowrap;';

    return qq{    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8;$nowrap">$text</td>};
}
sub make_cell_without_border_right_aligned {
    my $self = shift;
    my %args = @_;
    my $text = $args{'text'};
    my $nowrap = !$args{'nowrap'} ? '' : ' white-space: nowrap;';

    return qq{    <td style="text-align: right; padding-right: 6px; padding-left: 6px;$nowrap">$text</td>};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Splint::AttributeRenderer::HtmlDefault - Default html attribute renderer

=head1 VERSION

Version 0.1201, released 2016-02-03.

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Elemental-Transformer-Splint>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Elemental-Transformer-Splint>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
