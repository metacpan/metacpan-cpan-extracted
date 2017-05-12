package Storm::Role::Query;
{
  $Storm::Role::Query::VERSION = '0.240';
}
use Moose::Role;

use Storm::Types qw( Storm );
use MooseX::Types::Moose qw( ClassName );

has 'orm' => (
    is  => 'ro',
    isa => Storm,
    required => 1,
);

has 'class' => (
    is  => 'ro',
    isa => ClassName,
    required => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    
    # parse arguments
    if (@_ >= 2 ) {
        return $class->$orig( orm => shift, class => shift, @_ );
    }
    # otherwise pass upwords to deal with
    else {
        return $class->$orig( @_ );
    }
};

sub dbh  {
    $_[0]->orm->source->dbh;
}

no Moose::Role;
1;
