package Pcore::Util::Src::Filter::html;

use Pcore -class, -res;
use Pcore::Util::Text qw[trim];
use Pcore::Util::Src::Filter::js;
use Pcore::Util::Src::Filter::css;

with qw[Pcore::Util::Src::Filter];

sub decompress ($self) {
    return res 200 if !length $self->{data}->$*;

    return res 200 if $self->has_kolon;

    my $temp = P->file1->tempfile;

    P->file->write_bin( $temp, $self->{data} );

    my $proc = P->sys->run_proc( qq[html-beautify --quiet --indent-scripts separate --replace "$temp"], win32_create_no_window => 1 )->wait;

    $self->{data}->$* = P->file->read_bin($temp);    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    return res 200;
}

sub compress ($self) {
    return res 200 if !length $self->{data}->$*;

    return res 200 if $self->has_kolon;

    # compress js
    my @script = split m[(<script[^>]*>)(.*?)(</script[^>]*>)]smi, $self->{data}->$*;

    for my $i ( 0 .. $#script ) {
        if ( $script[$i] =~ m[\A</script]sm && $script[ $i - 1 ] ) {
            Pcore::Util::Src::Filter::js->new( { data => \$script[ $i - 1 ] } )->compress;

            trim $script[ $i - 1 ];
        }
    }

    $self->{data}->$* = join $EMPTY, @script;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    # compress css
    my @css = split m[(<style[^>]*>)(.*?)(</style[^>]*>)]smi, $self->{data}->$*;

    for my $i ( 0 .. $#css ) {
        if ( $css[$i] =~ m[\A</style]sm && $css[ $i - 1 ] ) {
            Pcore::Util::Src::Filter::css->new( { data => \$css[ $i - 1 ] } )->compress;
        }
    }

    $self->{data}->$* = join $EMPTY, @css;       ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    require HTML::Packer;

    eval { $self->{data}->$* = HTML::Packer->init->minify( $self->{data}, { remove_comments => 0, remove_newlines => 1, html5 => 1 } ) };    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    return res 200;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 57                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::html

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
