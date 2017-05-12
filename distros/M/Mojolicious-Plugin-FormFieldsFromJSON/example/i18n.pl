#!/usr/bin/perl

use Mojolicious::Lite;

use File::Basename;
use File::Spec;

app->plugin( 'I18N' => { namespace => 'I18N' } );
app->plugin( 'I18NUtils' );
app->plugin( 'FormFieldsFromJSON' => {
  dir                => File::Spec->catdir( app->home, 'fields' ),
  template           => '<%= $label %>: <%= $field %>',
  translate_labels   => 1,
  translation_method => sub { shift->l( @_ ) },
});

any '/' => sub {
    my $self = shift;

    $self->languages( $self->param('lang') || 'de' );

    my %data = (
        price => {
            data => {
                map{
                    $_ => $self->currency( $_, $self->param('lang') || 'en', 'EUR' )
                }qw(1.00 1.50 2.00 2.50 3.00 3.50)
            },
        },
    );

    $self->render( 'index', default_data => \%data );
};

app->start;

__DATA__
@@ index.html.ep
%= form_fields( 'price', %{$default_data} )
