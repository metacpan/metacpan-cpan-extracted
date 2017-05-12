package Reaction::Role::Parameterized;

use MooseX::Role::Parameterized ();
use Reaction::ClassExporter;
use Reaction::Class;
use Moose::Meta::Class;

use namespace::clean -except => [ qw(meta) ];

override exports_for_package => sub {
  my ($self, $package) = @_;
  my %exports = $self->SUPER::exports_for_package($package);
  delete $exports{class};
  return %exports;
};

override default_base => sub { () };

override exporter_for_package => sub {
    my ($self) = @_;
    my ($import) = Moose::Exporter->build_import_methods(
        also        => ['MooseX::Role::Parameterized'],
        with_caller => ['role'],
    );
    $import;
};

override next_import => sub { };

sub role (&) {
    my $caller = shift;
    my ($code) = @_;
    &MooseX::Role::Parameterized::role($caller, sub {
        my ($p, %args) = @_;
        $args{operating_on} = Moose::Util::MetaRole::apply_metaroles(
            for            => $args{operating_on}->name,
            role_metaroles => {
                applied_attribute => ['Reaction::Role::Meta::Attribute'],
            },
        ) if Moose->VERSION >= 1.9900;
        $code->($p, %args);
    });
}

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::Role

=head1 DESCRIPTION

=head1 SEE ALSO

L<Moose::Role>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
