use strictures 1;
package Mojito::Auth;
{
  $Mojito::Auth::VERSION = '0.24';
}
use Mojito::Auth::Mongo;
use Mojito::Auth::Deep;
use Mojito::Auth::Elasticsearch;
use Moo;

=head1 Name

Mojito::Auth - authentication delegator class

=cut

has 'auth' => (
    is => 'ro',
    lazy => 1,
    writer => '_set_auth',
    handles =>  [ qw( digest_authen_cb _secret get_user add_user remove_user username realm password clear_db_name db_name) ],
);

sub BUILD {
    my ($self, $constructor_args_href) = @_;
   
    # Determine the document store backend from the configuration
    my $doc_storage = ucfirst lc $constructor_args_href->{config}->{document_storage};
    my $delegatee = __PACKAGE__ . '::' . $doc_storage;
    $self->_set_auth($delegatee->new($constructor_args_href));
}

1
