use strict;
use warnings;

use Test::More tests => 20;
use Path::Tiny qw(path);
use Test::Fatal qw( exception );
use FindBin;

sub nofatal {
  my ( $message, $sub ) = @_;
  my $e = exception { $sub->() };
  return is( $e, undef, "no exceptions: $message" );
}

my $corpus_dir =
  path($FindBin::Bin)->parent->parent->child('corpus')->child('Changelog');

flow_control: {
  last unless nofatal 'require Path::IsDev::Object' => sub {
    require Path::IsDev::Object;
  };
  my $instance;
  last unless nofatal 'instance = Path::IsDev::Object->new()' => sub {
    $instance = Path::IsDev::Object->new();
  };
  last unless nofatal 'instance->set()' => sub {
    is( $instance->set(), 'Basic', 'instance->set() == Basic' );
  };
  last unless nofatal 'instance->set_prefix()' => sub {
    is( $instance->set_prefix, 'Path::IsDev::HeuristicSet', 'instance->set_prefix() == Path::IsDev::HeuristicSet' );
  };
  last unless nofatal 'instance->set_module()' => sub {
    is( $instance->set_module, 'Path::IsDev::HeuristicSet::Basic', 'instance->set_module() == Path::IsDev::HeuristicSet::Basic' );
  };
  last unless nofatal 'instance->loaded_set_module()' => sub {
    is(
      $instance->set_module,
      'Path::IsDev::HeuristicSet::Basic',
      'instance->loaded_set_module() == Path::IsDev::HeuristicSet::Basic'
    );
  };
  last unless nofatal 'instance->matches($path_isdev_source)' => sub {
    my $computed_root = path($FindBin::Bin)->parent->parent;
    diag( '$path_isdev_source = ' . $computed_root );
    my $result = $instance->matches($computed_root);
    ok( defined $result, 'instance->matches($path_isdev_source) is defined' );
  };
  last unless nofatal 'instance->matches($corpus_Changes_dir)' => sub {
    diag( '$corpus_Changes_dir = ' . $corpus_dir );
    my $result = $instance->matches($corpus_dir);
    ok( defined $result, 'instance->matches($corpus_Changes_dir) is defined' );
  };
  last unless nofatal 'instance->matches($corpus_Changes_dir/../)' => sub {
    diag( '$corpus_Changes_dir/../ = ' . $corpus_dir->parent );
    my $result = $instance->matches( $corpus_dir->parent );
    ok( !defined $result, 'instance->matches($corpus_Changes_dir/../) is not defined' );
  };
  last unless nofatal 'instance->_instance_id' => sub {
    my $result = $instance->_instance_id;
    ok( defined $result, 'instance->_instance_id is defined' );
  };
  last unless nofatal 'instance->_debug(testing)' => sub {
    my $result = $instance->_debug('testing');
    pass("_debug(testing) OK ");
  };
}
