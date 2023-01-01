use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Fatal;

use Pod::Elemental;
use Pod::Elemental::Transformer::List;

my $pod5 = Pod::Elemental::Transformer::Pod5->new;
my $list = Pod::Elemental::Transformer::List->new;

subtest "we ignore pod regions without the right name" => sub {
  my $pod = <<'END_POD';
=for :not_a_list
* foo
* bar
* baz
END_POD

  my $doc = Pod::Elemental->read_string($pod);
  $list->transform_node( $doc );

  eq_or_diff($doc->as_pod_string, "=pod\n\n$pod=cut\n", 'pod string');
};

subtest "undef input" => sub {
  my $error = exception { my $node = $list->transform_node( undef ); };
  like(
    $error,
    qr/undefined/,
    'we die on undefined input'
  );
};

subtest "non-pod region" => sub {
  my $pod = <<'END_POD';
=for list
* Missing
* a
* colon
* before
* list
END_POD

  my $doc = Pod::Elemental->read_string($pod);

  my $error = exception {
    $pod5->transform_node($doc);
    $list->transform_node($doc);
  };

  like(
    $error,
    qr/list regions must be pod/,
    'list regions must be pod'
  );
};

done_testing;
