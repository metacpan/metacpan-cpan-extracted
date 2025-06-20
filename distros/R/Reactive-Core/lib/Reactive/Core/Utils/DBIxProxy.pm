package Reactive::Core::Utils::DBIxProxy;

use warnings;
use strict;

use Moo;
use namespace::clean;

use Scalar::Util 'blessed';

use Types::Standard qw/Int Str HashRef Bool InstanceOf Maybe/;

has _model       => (is => 'lazy', predicate => 1, isa => Str);
has _id          => (is => 'lazy', predicate => 1, isa => Int|Str);
has _summary     => (is => 'lazy', clearer   => 1, isa => HashRef);
has _instance    => (is => 'lazy', predicate => 1, isa => Maybe[InstanceOf['DBIx::Class::Core']]);
has _schema      => (is => 'lazy', predicate => 1, isa => InstanceOf['DBIx::Class::Schema']);


=head2 dbic_schema($model)

=cut
sub dbic_schema { die '`*Reactive::Core::Utils::DBIxProxy::dbic_schema` must be overridden for DBIx coercions to work correctly' }

sub _build__schema {
    my $self = shift;
    if ($self->_has_instance) {
        return $self->_instance->result_source->schema;
    }

    return dbic_schema($self->_model);
}

sub _resultset {
    my $self = shift;
    return unless $self->_schema->resultset($self->_model);
}

sub _build__instance {
    my $self = shift;

    return unless $self->_has_model && $self->_has_id;

    printf "Attempting to load instance %s : %s\n", $self->_model, $self->_id;

    return $self->_resultset->find($self->_id);
}

sub _build__model {
    my $self = shift;

    if ($self->_has_instance) {
        return blessed $self->_instance;
    }
    # TODO: should probably throw some kind of exception here
    return;
}

sub _build__id {
    my $self = shift;

    if ($self->_has_instance) {
        return $self->_instance->id;
    }
    # TODO: should probably throw some kind of exception here
    return;
}

sub _build__summary {
    my $self = shift;

    if ($self->_has_instance) {
        if ($self->_instance->can('short_summary')) {
            return $self->_instance->short_summary;
        }
    }

    return {};
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $method = $AUTOLOAD;
    my @args = @_;

    $method =~ s/.*:://;

    printf "Autoload called for %s->%s\n", blessed $self // $self, $method;

    if ($method =~ /^_/ || $method =~ /^[A-Z_]*$/) {
        printf "Dont allow private or all caps subs\n";
        return;
    }

    if ($method eq 'id') {
        return $self->_id;
    }

    if (!@args && exists $self->_summary->{$method}) {
        return $self->_summary->{$method};
    }

    $self->_clear_summary;

    return $self->_instance->$method(@args);
}


1;
