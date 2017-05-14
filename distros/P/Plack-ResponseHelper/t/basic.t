use Test::More;
use Test::Exception;

use Plack::ResponseHelper;

dies_ok {
    respond abc => 'abc';
} 'unknown type';

done_testing;
