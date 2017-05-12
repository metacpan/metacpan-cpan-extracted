package Template::Plugin::MobileJPPictogram;

use strict;
use warnings;
use 5.0080008;
our $VERSION = '0.06';

require Template::Plugin;
use base qw(Template::Plugin);

use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Charnames;

sub new {
    my ( $self, $context, @args ) = @_;
    $context->define_filter( 'pictogram_charname', \&_charname, 1 );
    $context->define_filter( 'pictogram_unicode',  \&_unicode,  1 );
    return $self;
}

sub _charname {
    my ( $ctx, $unicode ) = @_;
    die "unicode string missing for pictogram_charname" unless $unicode;

    sub {
        local $_ = shift;

        s{(\p{InMobileJPPictograms})}{
            my $name = Encode::JP::Mobile::Charnames::unicode2name(unpack 'U*', $1);
            sprintf $unicode, $name;
        }ge;

        $_;
    };
}

sub _unicode {
    my ( $ctx, $unicode ) = @_;
    die "unicode string missing for pictogram_unicode" unless $unicode;

    sub {
        local $_ = shift;

        s{(\p{InMobileJPPictograms})}{
            sprintf $unicode, unpack 'U*', $1;
        }ge;

        $_;
    };
}

1;
__END__

=for stopwords aaaatttt dotottto gmail pictogram pictograms Unicode charnames

=head1 NAME

Template::Plugin::MobileJPPictogram - Japanese mobile phone's pictogram operator

=head1 SYNOPSIS

  # controller
  my $tt = Template->new;
  $tt->process('foo.tt', {body => "\x{E001}"});

  # foo.tt
  [% USE MobileJPPictogram %]
  [% body | pictogram_charname('***%s***') %]
  [% body | pictogram_unicode('<img src="/img/pictogram/%X.gif" />') %]

  # output
  ***男の子***
  <img src="/img/pictogram/E001.gif" />

=head1 DESCRIPTION

Template::Plugin::MobileJPPictogram is Japanese mobile phone's pictogram operator.

=head1 FILTERS

=head2 pictogram_charname

format with charnames.

    [% body | pictogram_charname('***%s***') %]

=head2 pictogram_unicode

format with Unicode.

    [% body | pictogram_unicode('<img src="/img/pictogram/%X.gif" />') %]

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom aaaatttt@ gmail dotottto commmmmE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

