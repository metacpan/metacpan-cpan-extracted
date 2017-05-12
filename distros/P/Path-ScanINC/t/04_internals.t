use strict;
use warnings;

use Test::More 0.98;
use FindBin;

use lib "$FindBin::Bin/lib";

use winfail;

use_ok('Path::ScanINC');

=begin comment

subtest __try => sub {
  will_win 'exceptions not fatal to caller';
  t { Path::ScanINC::__try( sub { die 'not a problem' } ) };
};

subtest __catch => sub {
  will_win 'exceptions not fatal to caller';

  my $caught;

  t { Path::ScanINC::__try( sub { die 'not a problem' }, Path::ScanINC::__catch( sub { $caught = $_ } ) ) };

  like( $caught, qr/^\Qnot a problem\E/, 'Catch still works' );

};

subtest __blessed => sub {
  will_win 'blessed loads ok';

  my $object = bless( {}, 'foo' );
  my $gotbless;

  t { $gotbless = Path::ScanINC::__blessed($object) };

  is( $gotbless, 'foo', '__blessed resolves ok' );
};

subtest __reftype => sub {
  will_win 'reftype loads ok';

  my $gotreftype;

  t { $gotreftype = Path::ScanINC::__reftype( [] ) };

  is( $gotreftype, 'ARRAY', '__reftype resolves ok' );

};

=end comment

=cut

subtest __pp => sub {
  will_win 'pp loads ok';

  my $gotdump;

  t { $gotdump = Path::ScanINC::__pp( [] ) };

  is( $gotdump, '[]', '__pp resolves ok' );
};

=begin comment

subtest __croak => sub {

  will_fail 'croak loads ok ';

  t { Path::ScanINC::__croak("its ok") };
};

=end comment

=cut

subtest __croakf => sub {
  will_fail 'basic croakf';
  t { Path::ScanINC::__croakf('test') };
};

done_testing;

