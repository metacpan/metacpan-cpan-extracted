package Pcore::Util::Src::Filter::html;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];
use Pcore::Util::Src::Filter::js;
use Pcore::Util::Src::Filter::css;

with qw[Pcore::Util::Src::Filter];

sub decompress ($self) {
    return $SRC_OK if $self->has_kolon;

    my $res = $self->filter_prettier( parser => 'html' );

    return $res;
}

sub compress ($self) {
    return $SRC_OK if $self->has_kolon;

    # compress js
    my @script = split m[(<script[^>]*>)(.*?)(</script[^>]*>)]smi, $self->{data};

    for my $i ( 0 .. $#script ) {
        if ( $script[$i] =~ m/\A<script/sm && $script[ $i + 1 ] ) {
            my $res = Pcore::Util::Src::Filter::js->compress( \$script[ $i + 1 ] );

            return $res if !$res;
        }
    }

    $self->{data} = join $EMPTY, @script;

    # compress css
    my @css = split m[(<style[^>]*>)(.*?)(</style[^>]*>)]smi, $self->{data};

    for my $i ( 0 .. $#css ) {
        if ( $css[$i] =~ m/\A<style/sm && $css[ $i + 1 ] ) {
            my $res = Pcore::Util::Src::Filter::css->compress( \$css[ $i + 1 ] );

            return $res if !$res;
        }
    }

    $self->{data} = join $EMPTY, @css;

    my $res = $self->filter_html_packer;

    return $res;
}

sub filter_html_packer ($self) {
    state $packer = do {
        require HTML::Packer;

        HTML::Packer->init;
    };

    $packer->minify( \$self->{data}, { remove_comments => 0, remove_newlines => 1, html5 => 1 } );

    return $SRC_OK;
}

1;
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
