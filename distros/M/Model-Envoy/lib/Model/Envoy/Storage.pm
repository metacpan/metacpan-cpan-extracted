package Model::Envoy::Storage;

our $VERSION = '0.1.0';

use Moose;

has 'model' => (
    is => 'rw',
    does => 'Model::Envoy',
    required => 1,
    weak_ref => 1,
);

sub configure {
    my ( $class, $conf ) = @_;

    $conf->{_configured} = 1;
}

sub build {

    return undef;
}

=head1 Storage Plugins

Model::Envoy provides the ability to persist objects via any number of services via plugins. These plugins
are referenced in Model::Envoy's role parameters, and dispatched to as needed.

=head3 Declaration & Configuration

    with 'Model::Envoy' => { storage => {
        'DBIC' => {
            schema => sub {
                ... connect to database here ...
            }
        }
    } };

Any configuration information you need passed into your plugin should be part of the hashref attached to the plugin
key in the role parameters.

=head2 Instantiation

When C<Model::Envoy> creates an instance of your plugin to track a model object via new(), it will pass in the configuration
information and a reference to the model object to track.

=head2 Required Methods

=head3 C<save>

save the data from the model object this instance is tracking to your persistence service.

=head3 C<delete>

delete the data from the model object this instance is tracking from your persistence service.

=head3 C<fetch(%params)>

This method is expected to take some parameters and return a single Model::Envoy based object in response.  Typically this will be an id the plugin
uses to look up a record, but it could be multiple parameters depending on the needs of the plugin.

=head3 C<list(%params)>

This method is expected to take some search parameters and return an arrayref of zero or more Model::Envoy based objects in response.

=head2 Optional Methods

=head3 C<configure($self, $conf)>

When your models first need to connect to storage, they will call C<configure>
on your storage plugin to give it a chance to perform setup that will be needed
by all of your instance objects (a database handle, for example).

=over

=item $self - the plugin's class

=item $conf - the hashref of configuration information specified in Model::Envoy's role parameters

=back

If you implement this method, you should set the key C<_configured> in the $conf hashref to a true
value to tell C<Model::Envoy> that configuration was successful.

=head3 C<build($class, $model_class, $object, [$no_rel] )>

If your plugin knows how to take a particular kind of object (say, a database record class) and turn it into a matching Model::Envoy based object,
it should implement this method.

=over

=item $class - the plugin's class

=item $model_class - the C<Model::Envoy> based class we're trying to make

=item $object - the raw datastructure you'll be trying to turn into the requested $model_class

=item $no_rel - an optional boolean to indicate whether to walk the relationship tree of the $object to create more C<Model::Envoy> based objects (to limit recursion).

=back

=cut

1;