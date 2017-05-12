package TestX::CatalystX::ExtensionB::Controller::ExtensionB;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'Extension Bee',
    appkit_icon                 => 'static/images/flagB.jpg',
    appkit_myclass              => 'TestX::CatalystX::ExtensionB',
);


sub auto 
    :Private
{
    my ($self, $c) = @_;

    #$c->stash->{current_model}  = 'BookDB::Author';
}


=head2 home
    bascially the index path for this controller.
=cut
sub home
    :Path
    :Args(0)
    :NavigationHome
    :NavigationName('ExtensionB Home')
{
    my ($self, $c) = @_;
    $c->stash->{template} = 'extensiona.tt';
}


=head2 formpage 
    Testing not only the loading of a FormFu config file but also if that config
    can access a model and pull data from it.
=cut
sub formpage
    :Local
    :Args(0)
    :NavigationName('Form Page')
    :AppKitForm
{
    my ($self, $c) = @_;

    # stash all books..
    my $rs = $c->model('BookDB::Book')->search;
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @books = $rs->all;
    $c->stash->{books} = \@books;

    # draw the form page...
    $c->stash->{template} = 'formpage.tt';
}


__END__
