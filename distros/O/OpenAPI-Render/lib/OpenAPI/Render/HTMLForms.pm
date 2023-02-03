package OpenAPI::Render::HTMLForms;

use strict;
use warnings;

# ABSTRACT: Generate HTML forms for OpenAPI specifications.
our $VERSION = '0.3.0'; # VERSION

use OpenAPI::Render;
use parent OpenAPI::Render::;

use CGI qw( -nosticky -utf8 h1 h2 h3 p input filefield popup_menu legend submit start_div end_div start_fieldset end_fieldset start_form end_form start_html end_html );
use List::Util qw( any );

sub header
{
    my( $self ) = @_;

    my %start_html_options = (
        -title => $self->api->{info}{title} . ' v' .
                  $self->api->{info}{version},
    );

    if( any { $_->{in} eq 'path' } $self->parameters ) {
        $start_html_options{-script} =
'

function replace_url_parameters( form ) {
    var url = form.getAttribute( "action" );
    var inputs = form.getElementsByTagName( "input" );
    for( var i = 0; i < inputs.length; i++ ) {
        var data_in_path = inputs[i].getAttribute( "data-in-path" );
        if( data_in_path ) {
            url = url.replace( "{" + inputs[i].name + "}", inputs[i].value );
            inputs[i].disabled = "disabled";
        }
    }
    form.setAttribute( "action", url );
}

'
    }

    return start_html( %start_html_options );
}

sub footer
{
    return end_html;
}

sub path_header
{
    my( $self, $path ) = @_;
    return h1( $path );
}

sub operation_header
{
    my( $self, $path, $operation ) = @_;
    return start_form( -action => $self->{base_url} . $path,
                       -method => $operation ) .
           start_fieldset .
           legend( uc( $operation ) .
                   ( $self->api->{paths}{$path}{$operation}{description}
                        ? ': ' . $self->api->{paths}{$path}{$operation}{description} : '' ) );
}

sub operation_footer
{
    my( $self, $path, $operation ) = @_;

    my %submit_options;
    if( $operation eq 'get' || $operation eq 'post' ) {
        if( any { $_->{in} eq 'path' } $self->parameters( $path, $operation ) ) {
            $submit_options{-onclick} = 'replace_url_parameters( this.form )';
        }
    } else {
        $submit_options{-name} =
            sprintf 'Submit Query (cannot be handled for %s)',
                    uc $operation;
        $submit_options{-disabled} = 'disabled';
    }

    return submit( %submit_options ) . end_fieldset . end_form;
}

sub parameter
{
    my( $self, $parameter ) = @_;
    my @parameter;
    return @parameter if $parameter->{'x-is-pattern'};

    push @parameter,
         h3( $parameter->{name} ),
         $parameter->{description} ? p( $parameter->{description} ) : ();
    if( $parameter->{schema} && $parameter->{schema}{enum} ) {
        my @values = @{$parameter->{schema}{enum}};
        if( !$parameter->{required} ) {
            unshift @values, '';
        }
        push @parameter,
             popup_menu( -name => $parameter->{name},
                         -values => \@values,
                         ($parameter->{in} eq 'path'
                            ? ( '-data-in-path' => 1 ) : ()) );
    } elsif( ($parameter->{schema}{type} &&
              $parameter->{schema}{type} eq 'object') ||
             ($parameter->{schema}{format} &&
              $parameter->{schema}{format} eq 'binary') ) {
        push @parameter,
             filefield( -name => $parameter->{name} );
    } else {
        push @parameter,
             input( { -type => 'text',
                      -name => $parameter->{name},
                      ($parameter->{in} eq 'path'
                        ? ( '-data-in-path' => 1 ) : ()),
                      (exists $parameter->{example}
                        ? ( -placeholder => $parameter->{example} )
                        : ()),
                      ($parameter->{in} eq 'path' || $parameter->{required}
                        ? ( -required => 'required' ) : ()) } );
    }
    return @parameter;
}

1;
