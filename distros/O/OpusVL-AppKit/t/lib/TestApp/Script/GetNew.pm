
package TestApp::Script::GetNew;

use Moose;
use namespace::autoclean;

with 'Catalyst::ScriptRole';

sub run 
{
    my $self = shift;
    my $app = $self->application_name;
    Class::MOP::load_class($app);
    return $app->new;
}

__PACKAGE__->meta->make_immutable;
