use v5.26;
use warnings;
package PlackX::Framework::Role::TemplateEngine {
  use Role::Tiny;
  requires qw(new process);
}

1;
