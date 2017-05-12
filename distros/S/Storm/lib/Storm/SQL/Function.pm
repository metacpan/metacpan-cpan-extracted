package Storm::SQL::Function;
{
  $Storm::SQL::Function::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use MooseX::Types::Moose qw( ArrayRef Str );

use Storm::SQL::Parameter;
use Storm::SQL::Placeholder;

has 'function' => (
    is => 'rw',
    isa => Str,
    required => 1,
);

has '_args' => (
    is      => 'ro'      ,
    isa     => ArrayRef,
    default => sub { [] },
);

sub BUILDARGS
{
    my $class = shift;
    my $name = shift;
    my @args = @_;
    
    return {
        function => $name,
        _args   => \@args,
    };
    
}

sub sql {
    my ( $self ) = @_;
    my $sql = '';
    $sql .= uc $self->function;
    $sql .= '(';
    $sql .= join  ", ", map { $_->sql } @{$self->_args};
    $sql .= ')';
    return $sql;
}

sub bind_params {
    my ( $self ) = @_;
    return
        ( map { $_->bind_params() }
          grep { $_->can('bind_params') }
          @{$self->_args}
        );
}



no Moose;
__PACKAGE__->meta()->make_immutable();
1;
