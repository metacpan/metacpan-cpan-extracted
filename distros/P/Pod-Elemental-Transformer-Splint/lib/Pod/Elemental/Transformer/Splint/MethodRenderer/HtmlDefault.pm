use 5.10.1;
use strict;
use warnings;

package Pod::Elemental::Transformer::Splint::MethodRenderer::HtmlDefault;

# ABSTRACT: Default html method renderer
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1202';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use Pod::Simple::XHTML;
use List::Util qw/any/;
use List::MoreUtils qw/uniq/;
use syntax 'qs';

with 'Pod::Elemental::Transformer::Splint::MethodRenderer';

sub render_method {
    my $self = shift;
    my $data = shift;

    my $positional_params = $data->{'positional_params'};
    my $named_params = $data->{'named_params'};
    my $return_types = $data->{'return_types'};

    my @html = ('');
    my $table_style = q{style="margin-bottom: 10px; margin-left: 10px; border-collapse: bollapse;" cellpadding="0" cellspacing="0"};
    my $th_style = q{style="text-align: left; color: #444; padding-left: 5px; font-weight: bold; background-color:};
    my $tr_style = q{style="vertical-align: top;"};

    my $method_doc = undef;

    my $colspan = $self->get_colspan([ @$positional_params, @$named_params, @$return_types]);

    if(scalar @$positional_params) {

        my @fake_colspans = (qq{    <td $th_style #eee8e8;">&#160;</td>}) x ($colspan - 1);
        push @html => (qq{<tr $tr_style>}, qq{    <td $th_style #eee8e8;">Positional parameters</td>}, @fake_colspans, '</tr>');

        foreach my $param (@$positional_params) {

            $method_doc = $param->{'method_doc'} if defined $param->{'method_doc'};

            push @html => "<tr $tr_style>";
            push @html => $self->make_cell_with_border(nowrap => 1, text => $self->parse_pod(sprintf 'C<%s>', $param->{'name'}));
            push @html => $self->make_cell_with_border(nowrap => 2, text => $param->{'type'});
            push @html => $self->make_cell_with_border(nowrap => 3, text => (join ', ' => $param->{'required_text'}, $param->{'is_required'} ? defined $param->{'default'} ? $self->param_default_text($param) : () : $self->param_default_text($param)));
            push @html => $self->make_cell_with_border(nowrap => 4, text => $self->param_trait_text($param));
            push @html => $self->make_cell_without_border(nowrap => 0, text => join '' => map { "$_<br />" } @{ $param->{'docs'} });

            push @html => '</tr>';
        }
    }
    if(scalar @$named_params) {

        my @fake_colspans = (qq{    <td $th_style #e8eee8;">&#160;</td>}) x ($colspan - 1);
        push @html => (qq{<tr $tr_style>}, qq{    <td $th_style #e8eee8;">Named parameters</td>}, @fake_colspans, '</tr>');

        foreach my $param (@$named_params) {
            $method_doc = $param->{'method_doc'} if defined $param->{'method_doc'};

            push @html => "<tr $tr_style>";
            push @html => $self->make_cell_with_border(nowrap => 5, text => $self->parse_pod(sprintf 'C<%s =E<gt> %s>', $param->{'name_without_sigil'}, '$value'));
            push @html => $self->make_cell_with_border(nowrap => 6, text => $param->{'type'});
            push @html => $self->make_cell_with_border(nowrap => 7, text => join ', ' => $param->{'required_text'}, $param->{'is_required'} && defined $param->{'default'} ? $self->param_default_text($param) : $param->{'is_required'} ? () : $self->param_default_text($param));
            push @html => $self->make_cell_with_border(nowrap => 8, text => $self->param_trait_text($param));
            push @html => $self->make_cell_without_border(nowrap => 0, text => join '<br />' => @{ $param->{'docs'} });

            push @html => '</tr>';
        }
    }
    if(scalar @$return_types) {
        my @fake_colspans = (qq{    <td $th_style #e8e8ee;">&#160;</td>}) x ($colspan - 1);
        push @html => (qq{<tr $tr_style>}, qq{    <td $th_style #e8e8ee;">Returns</td>}, @fake_colspans, '</tr>');

        foreach my $return_type (@$return_types) {
            $method_doc = $return_type->{'method_doc'} if defined $return_type->{'method_doc'};
            my $has_doc = scalar @{ $return_type->{'docs'} };
            my $return_colspan = $has_doc ? $colspan - 1 : $colspan;

            push @html => qq{<tr $tr_style>};
            push @html => $has_doc ? $self->make_cell_with_border(nowrap => 0, colspan => $return_colspan, text => $return_type->{'type'})
                                   : $self->make_cell_without_border(nowrap => 0, colspan => $return_colspan, text => $return_type->{'type'})
                                   ;
            push @html => $self->make_cell_without_border(nowrap => 0, text => join '<br />' => @{ $return_type->{'docs'} });
            push @html => '</tr>';
        }
    }
    if(scalar @html) {
        unshift @html => '<!-- -->', qq{<table $table_style>};
        push @html => '</table>';
    }

    my $content = sprintf qs{
        =begin %s

            <p>%s</p>

            %s

        =end %s
    }, $self->for, $method_doc // '', join ("\n" => @html), $self->for;

    return $content;
}

sub get_colspan {
    my $self = shift;
    my $params = shift;

    return (any { defined $_->{'docs'} && scalar @{ $_->{'docs'} } } @$params) ? (any { ref $_->{'docs'} eq 'HASH' } @$params) ? 6
                                                                               :                                                 5
           :                                                                                                                     4
           ;
}

sub param_trait_text {
    my $self = shift;
    my $param = shift;

    my @traits = grep { $_ ne 'doc' && $_ ne 'optional' } @{ $self->param_trait_list($param) };

    return undef if !scalar @traits;
    return join ', ' => map { $_ eq 'slurpy' ? $_ : sprintf '<a href="https://metacpan.org/pod/Kavorka/TraitFor/Parameter/%s">$_</a>', $_ } @traits;
}

sub param_trait_list {
    my $self = shift;
    my $param = shift;

    my $trait_list = [ uniq sort map { keys %{ $_ } } @{ $param->{'traits'} } ];

    return $trait_list;

}

sub param_default_text {
    my $self = shift;
    my $param = shift;

    return q{<span style="color: #999;">no default</span>} if !defined $param->{'default'};
    return $self->parse_pod(sprintf q(default C<%s { }>), $param->{'default_when'}) if ref $param->{'default'} eq 'HASH' && scalar keys %{ $param->{'default'} } == 0;
    return $self->parse_pod(sprintf q(default C<%s hashref>), $param->{'default_when'}) if ref $param->{'default'} eq 'HASH';

    return $self->parse_pod(sprintf q(default C<%s [ ]>), $param->{'default_when'}) if ref $param->{'default'} eq 'ARRAY' && scalar @{ $param->{'default'} } == 0;
    return $self->parse_pod(sprintf q(default C<%s arrayref>), $param->{'default_when'}) if ref $param->{'default'} eq 'ARRAY';

    return $self->parse_pod(sprintf q{default C<%s coderef>}, $param->{'default_when'}) if ref $param->{'default'} eq 'CODE';
    return $self->parse_pod(sprintf q{default C<%s %s>}, $param->{'default_when'}, $param->{'default'} eq '' ? "''" : $param->{'default'});
}

sub make_cell_without_border {
    my $self = shift;
    my($text, $nowrap, $colspan) = $self->fix_cell_args(@_);
    $text = defined $text ? $text : '';

    my $style = qq{style="padding: 3px 6px; vertical-align: top; $nowrap border-bottom: 1px solid #eee;"};
    my @colspans = (qq{    <td $style>&#160;</td>}) x $colspan;

    return (qq{    <td $style>$text</td>}, @colspans);
}
sub make_cell_with_border {
    my $self = shift;

    my($text, $nowrap, $colspan) = $self->fix_cell_args(@_);
    my $padding = defined $text ? ' padding: 3px 6px;' : '';
    $text = defined $text ? $text : '';

    my $style = qq{style="vertical-align: top; border-right: 1px solid #eee;$nowrap $padding border-bottom: 1px solid #eee;"};
    my @colspans = (qq{    <td $style>&#160;</td>}) x $colspan;

    return (qq{    <td $style>$text</td>}, @colspans);
}

sub fix_cell_args {
    my $self = shift;
    my %args = @_;

    my $text = $args{'text'};
    my $nowrap = !$args{'nowrap'} ? '' : ' white-space: nowrap;';
    my $colspan = !exists $args{'colspan'} ? 0 : $args{'colspan'} - 1; # Since we add cells *after* the current one.

    return ($text, $nowrap, $colspan);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Splint::MethodRenderer::HtmlDefault - Default html method renderer

=head1 VERSION

Version 0.1202, released 2020-12-26.

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
