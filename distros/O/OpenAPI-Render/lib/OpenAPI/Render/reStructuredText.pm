package OpenAPI::Render::reStructuredText;

use strict;
use warnings;

our $VERSION = '0.1.0'; # VERSION

use Text::ASCIITable;

use parent qw(OpenAPI::Render);

sub header
{
    my( $self ) = @_;
    return _h( $self->{api}{info}{title} . ' v' .
               $self->{api}{info}{version},
               '=' );
}

sub path_header
{
    my( $self, $path ) = @_;

    my $text = _h( $path, '-' );
    my @url_parameters;
    if( $self->{api}{paths}{$path}{parameters} ) {
        @url_parameters = grep { $_->{in} eq 'path' }
                               @{$self->{api}{paths}{$path}{parameters}};
    }
    if( @url_parameters ) {
        $text .= _h( 'URL parameters', '+' );
        $self->_start_table( 'Name', 'Description', 'Format', 'Example' );
        foreach (@url_parameters) {
            $self->{table}->addRow( $_->{name},
                                    $_->{description},
                                    $_->{format},
                                    $_->{example} );
        }
        $text .= $self->parameters_footer;
    }

    return $text;
}

sub operation_header
{
    my( $self, $path, $operation ) = @_;
    return _h( uc( $operation ) .
               ( $self->{api}{paths}{$path}{$operation}{description}
                    ? ': ' . $self->{api}{paths}{$path}{$operation}{description} : '' ),
               '+' );
}

sub parameters_header
{
    my( $self ) = @_;
    $self->_start_table( 'Name', 'Description', 'Mandatory?', 'Format', 'Example' );
    return _h( 'Parameters', '~' );
}

sub parameter
{
    my( $self, $parameter ) = @_;
    return '' if $parameter->{in} eq 'path'; # should be already handled

    my $table = $self->{table};
    $table->addRow( $parameter->{name},
                    $parameter->{description},
                    $parameter->{required} ? 'yes' : 'no',
                    $parameter->{schema}{type},
                    $parameter->{example} );
    return '';
}

sub parameters_footer
{
    my( $self ) = @_;
    return $self->{table}->draw( [ '+', '+', '-', '+' ],
                                 [ '|', '|', '|' ],
                                 [ '+', '+', '=', '+' ],
                                 [ '|', '|', '|' ],
                                 [ '+', '+', '-', '+' ] ) . "\n";
}

sub responses_header
{
    my( $self ) = @_;
    $self->_start_table( 'HTTP code', 'Description' );
    return _h( 'Responses', '~' );
}

sub response
{
    my( $self, $code, $response ) = @_;
    my $table = $self->{table};
    $table->addRow( $code, $response->{description} );
    return '';
}

sub responses_footer { &parameters_footer }

sub _h
{
    my( $text, $symbol ) = @_;
    $symbol = '-' unless $symbol;
    return $text . "\n" . ( $symbol x length $text ) . "\n\n";
}

sub _start_table
{
    my( $self, @columns ) = @_;
    $self->{table} = Text::ASCIITable->new;
    $self->{table}->setOptions( 'drawRowLine', 1 );
    $self->{table}->setCols( @columns );
}

1;
