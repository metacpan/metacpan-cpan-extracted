package Reaction::InterfaceModel::ObjectClass;

use Reaction::ClassExporter;
use Reaction::Class;

use Reaction::InterfaceModel::Object;

use namespace::clean -except => [ qw(meta) ];
override default_base => sub { ('Reaction::InterfaceModel::Object') };
override exports_for_package => sub {
  my ($self, $package) = @_;
  return (super(),
          domain_model => sub {
            $package->meta->add_domain_model(@_);
          },
         );
};
__PACKAGE__->meta->make_immutable;


1;

__END__;


=head1 NAME

Reaction::InterfaceModel::ObjectClass

=cut
