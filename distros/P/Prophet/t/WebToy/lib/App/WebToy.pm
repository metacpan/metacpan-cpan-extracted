package App::WebToy;
use Any::Moose;
use App::WebToy::Model::WikiPage;
extends 'Prophet::App';

sub set_db_defaults {
    my $self = shift;
    $self->SUPER::set_db_defaults(@_);
    my $record = App::WebToy::Model::WikiPage->new( app_handle => $self );
    $record->create( props => { title => 'TitleOfPage', content => 'Body!' } );

}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

