use strict;
use warnings;

use Test::More tests => 29;
use Path::Tiny qw(path);
use Test::Fatal qw( exception );
use FindBin;

sub nofatal {
  my ( $message, $sub ) = @_;
  my $e = exception { $sub->() };
  return is( $e, undef, "no exceptions: $message" );
}

our $level = 0;

sub my_subtest {
  note( ( '    ' x $level ) . '{' . ' subtest: ' . $_[0] );
  { local $level = $level + 1; $_[1]->() };
  note( ( '    ' x $level ) . '}' );
}

my $corpus_dir =
  path($FindBin::Bin)->parent->parent->child('corpus')->child('Changelog');

my_subtest 'corpus/Changelog' => sub {
  return unless nofatal 'require Path::IsDev::Object' => sub {
    require Path::IsDev::Object;
  };
  my $instance;
  return unless nofatal 'instance = Path::IsDev::Object->new()' => sub {
    $instance = Path::IsDev::Object->new();
  };
  return unless nofatal 'instance->set()' => sub {
    is( $instance->set(), 'Basic', 'instance->set() == Basic' );
  };
  return unless nofatal 'instance->set_prefix()' => sub {
    is( $instance->set_prefix, 'Path::IsDev::HeuristicSet', 'instance->set_prefix() == Path::IsDev::HeuristicSet' );
  };
  return unless nofatal 'instance->set_module()' => sub {
    is( $instance->set_module, 'Path::IsDev::HeuristicSet::Basic', 'instance->set_module() == Path::IsDev::HeuristicSet::Basic' );
  };
  return unless nofatal 'instance->loaded_set_module()' => sub {
    is(
      $instance->set_module,
      'Path::IsDev::HeuristicSet::Basic',
      'instance->loaded_set_module() == Path::IsDev::HeuristicSet::Basic'
    );
  };
  return unless nofatal 'instance->_matches($path_isdev_source)' => sub {
    my $computed_root = path($FindBin::Bin)->parent->parent;
    my $result        = $instance->_matches($computed_root);
    ok( defined $result->result, 'instance->_matches($path_isdev_source)->result is defined' );
    my_subtest "result_object" => sub {
      return unless nofatal 'result->path' => sub {
        my $path = $result->path;
        ok( defined $path, '->path is defined' );
        ok( ref $path,     '->path is a ref' );
      };
      return unless nofatal 'result->result' => sub {
        my $result = $result->result;
        ok( defined $result, '->result is defined' );
      };
      return unless nofatal 'result->reasons' => sub {
        my $reasons = $result->reasons;
        ok( defined $reasons, '->reasons is defined' );
        ok( ref $reasons,     '->reasons is a ref' );
        is( ref $reasons, 'ARRAY', '->reasons is ARRAY' );
      };
    };
  };
  return unless nofatal 'instance->matches($corpus_Changes_dir)' => sub {
    my $result = $instance->matches($corpus_dir);
    ok( defined $result, 'instance->matches($corpus_Changes_dir) is defined' );
  };
  return unless nofatal 'instance->matches($corpus_Changes_dir/../)' => sub {
    my $result = $instance->matches( $corpus_dir->parent );
    ok( !defined $result, 'instance->matches($corpus_Changes_dir/../) is not defined' );
  };
  return unless nofatal 'instance->_instance_id' => sub {
    my $result = $instance->_instance_id;
    ok( defined $result, 'instance->_instance_id is defined' );
  };
  return unless nofatal 'instance->_debug(testing)' => sub {
    my $result = $instance->_debug('testing');
    pass("_debug(testing) OK ");
  };
};
