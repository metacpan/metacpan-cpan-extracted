package Lingua::Translate::BingWrapper;
use utf8;
use Encode qw/decode/;
use Carp;

sub new {

    my($class, %args) = @_;

    require "Lingua/Translate/Bing.pm";

    my $self = bless {
        src               => $args{src},
        dest              => $args{dest},
        parent            => Lingua::Translate::Bing->new(
          client_id => $args{client_id}, 
          client_secret => $args{client_secret}),
    }, $class;

    $self;

}

sub translate{
    my $self = shift;
    my $text = shift;
    
    return $self->{parent}->translate($text, $self->{dest}, $self->{src});
}

1;