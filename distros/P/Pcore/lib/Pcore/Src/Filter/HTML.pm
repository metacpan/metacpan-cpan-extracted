package Pcore::Src::Filter::HTML;

use Pcore -class;
use Pcore::Util::Text qw[trim];
use Pcore::Src::Filter::JS;
use Pcore::Src::Filter::CSS;

with qw[Pcore::Src::Filter];

sub decompress ($self) {
    return 0 if !length $self->buffer->$*;

    return 0 if $self->has_kolon;

    my $html_beautify_args = $self->dist_cfg->{HTML_BEAUTIFY} || $self->src_cfg->{HTML_BEAUTIFY};

    my $temp = P->file->tempfile;

    syswrite $temp, $self->buffer->$* or die;

    my $proc = P->sys->run_proc1( qq[html-beautify $html_beautify_args --replace "$temp"], win32_create_no_window => 1 )->wait;

    $self->buffer->$* = P->file->read_bin( $temp->path )->$*;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    return 0;
}

sub compress ($self) {
    return 0 if !length $self->buffer->$*;

    return 0 if $self->has_kolon;

    # compress js
    my @script = split m[(<script[^>]*>)(.*?)(</script[^>]*>)]smi, $self->buffer->$*;

    for my $i ( 0 .. $#script ) {
        if ( $script[$i] =~ m[\A</script]sm && $script[ $i - 1 ] ) {
            Pcore::Src::Filter::JS->new( { file => $self->file, buffer => \$script[ $i - 1 ] } )->compress;

            trim $script[ $i - 1 ];
        }
    }

    $self->buffer->$* = join q[], @script;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    # compress css
    my @css = split m[(<style[^>]*>)(.*?)(</style[^>]*>)]smi, $self->buffer->$*;

    for my $i ( 0 .. $#css ) {
        if ( $css[$i] =~ m[\A</style]sm && $css[ $i - 1 ] ) {
            Pcore::Src::Filter::CSS->new( { file => $self->file, buffer => \$css[ $i - 1 ] } )->compress;
        }
    }

    $self->buffer->$* = join q[], @css;       ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    my $html_packer_minify_args = $self->dist_cfg->{HTML_PACKER_MINIFY} || $self->src_cfg->{HTML_PACKER_MINIFY};

    state $init = !!require HTML::Packer;

    eval {
        $self->buffer->$* = HTML::Packer->init->minify( $self->buffer, $html_packer_minify_args );    ## no critic qw[Variables::RequireLocalizedPunctuationVars]
    };

    return 0;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 61                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Src::Filter::HTML

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
