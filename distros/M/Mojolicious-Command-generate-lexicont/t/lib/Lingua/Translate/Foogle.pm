package Lingua::Translate::Foogle;
use utf8;
use Encode qw/decode/;
use Carp;

sub new {

    my($class, %args) = @_;

    my $self = bless {
        src               => $args{src},
        dest              => $args{dest},
    }, $class;

    $self;
}

sub translate{
    my $self = shift;
    my $text = shift;
    $text = decode("utf-8", $text);
    if ($self->{src} eq 'ja'){
        if ($text eq "日本語"){
            if ($self->{dest} eq 'en'){
                return "Japanese";
            }
            if ($self->{dest} eq 'es'){
                return "japonés";
            }
            if ($self->{dest} eq 'zh'){
                return "日本";
            }
        }
        if ($text eq "英語"){
            if ($self->{dest} eq 'en'){
                return "English";
            }
            if ($self->{dest} eq 'es'){
                return "idioma en Inglés";
            }
            if ($self->{dest} eq 'zh'){
                return "英语";
            }
        }
    }
    elsif($self->{src} eq 'en'){
        if ($text eq "Japanese"){
            if ($self->{dest} eq 'ja'){
                return "日本語";
            }
            if ($self->{dest} eq 'es'){
                return "japonés";
            }
            if ($self->{dest} eq 'zh'){
                return "日本";
            }
        }
        if ($text eq "English"){
            if ($self->{dest} eq 'ja'){
                return "英語";
            }
            if ($self->{dest} eq 'es'){
                return "idioma en Inglés";
            }
            if ($self->{dest} eq 'zh'){
                return "英语";
            }
        }
    }
    elsif($self->{src} eq 'es'){
        if ($text eq "japonés"){
            if ($self->{dest} eq 'ja'){
                return "日本語";
            }
            if ($self->{dest} eq 'en'){
                return "Japanese";
            }
            if ($self->{dest} eq 'zh'){
                return "日本";
            }
        }
        if ($text eq "idioma en Inglés"){
            if ($self->{dest} eq 'ja'){
                return "英語";
            }
            if ($self->{dest} eq 'en'){
                return "English";
            }
            if ($self->{dest} eq 'zh'){
                return "英语";
            }
        }
    }
    elsif($self->{src} eq 'zh'){
        if ($text eq "日本"){
            if ($self->{dest} eq 'ja'){
                return "日本語";
            }
            if ($self->{dest} eq 'en'){
                return "Japanese";
            }
            if ($self->{dest} eq 'es'){
                return "japonés";
            }
        }
        if ($text eq "英语"){
            if ($self->{dest} eq 'ja'){
                return "英語";
            }
            if ($self->{dest} eq 'en'){
                return "English";
            }
            if ($self->{dest} eq 'es'){
                return "idioma en Inglés";
            }
        }
    }
    croak("Cannot translate $self->{src} to $self->{dest}");
}

1;