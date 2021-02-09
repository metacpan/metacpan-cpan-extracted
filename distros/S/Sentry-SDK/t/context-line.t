use Mojo::Base -base;

use Mojo::Util 'dumper';
use Sentry::SourceFileRegistry::ContextLine;
use Test::Spec;

my $Source_code = q{line1
line2
line3
line4
line5
line6
line7
line8
line9
};

describe 'Sentry::SourceFileRegistry::ContextLine' => sub {
  my $context;

  before each => sub {
    $context = Sentry::SourceFileRegistry::ContextLine->new(
      content    => $Source_code,
      line_count => 2
    );
  };

  it '_get_lower_bound' => sub {
    is_deeply($context->_get_lower_bound(-1),  []);
    is_deeply($context->_get_lower_bound(0),   []);
    is_deeply($context->_get_lower_bound(1),   []);
    is_deeply($context->_get_lower_bound(2),   [qw(line1)]);
    is_deeply($context->_get_lower_bound(3),   [qw(line1 line2)]);
    is_deeply($context->_get_lower_bound(4),   [qw(line2 line3)]);
    is_deeply($context->_get_lower_bound(666), []);
  };

  it '_get_upper_bound' => sub {
    is_deeply($context->_get_upper_bound(-1),  []);
    is_deeply($context->_get_upper_bound(1),   [qw(line2 line3)]);
    is_deeply($context->_get_upper_bound(7),   [qw(line8 line9)]);
    is_deeply($context->_get_upper_bound(8),   [qw(line9)]);
    is_deeply($context->_get_upper_bound(666), []);
  };

  it 'get' => sub {
    is_deeply(
      $context->get(5),
      {
        pre_context  => [qw(line3 line4)],
        context_line => 'line5',
        post_context => [qw(line6 line7)],
      }
    );
  };
};

runtests;
