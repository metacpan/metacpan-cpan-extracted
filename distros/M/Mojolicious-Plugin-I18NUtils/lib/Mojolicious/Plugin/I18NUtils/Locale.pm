package Mojolicious::Plugin::I18NUtils::Locale;

# ABSTRACT: class that represents a locale string

use Mojo::Base qw(-base);

our $VERSION = 0.01;

has 'locale' => 'en';
has 'lang'   => '';
has 'script' => '';
has 'region' => '';
has 'ext'    => '';

sub new {
    my $self = shift->SUPER::new(@_);

    if ( @_ && @_ % 2 == 0 ) {
       my %attrs = @_;
       $self->locale( $attrs{locale} );
    }

    $self->_split_locale(); 

    $self;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;

    my @infos  = split //, (split /::/, $AUTOLOAD)[-1];
    my %attrs  = qw/l lang s script r region e ext/;
    my @wanted = map{ my $attr = $attrs{$_}; ( $attr && $self->$attr() ) ? $self->$attr() : () }@infos;

    @wanted = ('') if !@wanted;

    return join '-', @wanted;
}

sub _split_locale {
    my ($self) = @_;
 
    my $locale = $self->locale;
 
    $locale = lc $locale;
    $locale =~ tr{_}{-};
 
    my ($lang, $script, $region, $ext) = $locale =~ m{ ^
              ( [a-z]{2,3}          )     # language
        (?: - ( [a-z]{4}            ) )?  # script
        (?: - ( [a-z]{2} | [0-9]{3} ) )?  # country or region
        (?: - ( u- .+               ) )?  # extension
            -?                            # trailing separator
    $ }xi;
 
    $script = ucfirst $script if $script;
    $region = uc      $region if $region;
 
    $self->lang( $lang );
    $self->script( $script );
    $self->region( $region );
    $self->ext( $ext );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::I18NUtils::Locale - class that represents a locale string

=head1 VERSION

version 0.20

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
