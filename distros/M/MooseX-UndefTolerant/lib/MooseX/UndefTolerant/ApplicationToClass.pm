package MooseX::UndefTolerant::ApplicationToClass;

our $VERSION = '0.21';

use Moose::Role;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my ($role, $class) = @_;

    $class = Moose::Util::MetaRole::apply_metaroles(
        for             => $class,
        class_metaroles => {
            class => [ 'MooseX::UndefTolerant::Class' ],
        }
    );

    $self->$orig( $role, $class );
};

no Moose::Role;

1;
