package MyIntegration;
use Mojo::Base 'Sentry::Integration::Base', -signatures;

use Sentry::Util 'around';
use Try::Tiny;

sub setup_once ($self, $add_global_event_processor, $get_current_hub) {

  around(
    'MyLib',
    foo2 => sub ($orig, @args) {
      my $hub = $get_current_hub->();

      $hub->add_breadcrumb({ message => 'Breadcrumb aus MyIntegration (2)' });

      my $parent = $hub->get_scope()->get_span;

      my $span = $parent->start_child({
        name => 'foo2', description => 'calling foo2', });

      my $return_value;

      try {
        $return_value = $orig->(@args);
      } catch {
        $span->finish();
        die $_;
      };

      return $return_value;
    }
  );
}

1;
