package Razor2::Preproc::deHTML_comment;

sub new {

    my $class = shift;
    return bless {}, $class;

}

sub isit {

    my ( $self, $text ) = @_;
    my $isit = 0;
    my ( $hdr, $body ) = split /\n\r*\n/, $$text, 2;

    return 0 unless $body;

    $isit = $body =~ /(?:<HTML>|<BODY|<FONT|<A HREF)/ism;
    return $isit if $isit;

    $isit = $hdr =~ m"^Content-Type: text/html"ism;
    return $isit;

}

sub doit {

    my ( $self, $text ) = @_;
    my ( $hdr, $body ) = split /\n\r*\n/, $$text, 2;

    $body =~ s/<!--.*?-->//gs;

    $$text = "$hdr\n\n$body";

}

1;

