package Storm::SQL::Fragment::Where::SubgroupStart;
{
  $Storm::SQL::Fragment::Where::SubgroupStart::VERSION = '0.240';
}
use Moose;



sub sql { return '(' };



no Moose;
__PACKAGE__->meta()->make_immutable();