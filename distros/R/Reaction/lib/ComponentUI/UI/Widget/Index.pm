package ComponentUI::UI::Widget::Index;

use Reaction::UI::WidgetClass;
use namespace::clean -except => [ qw(meta) ];

after fragment widget {
  $_{viewport}->ctx->log->debug('widget');
  arg message_to_layout => $_{layout_message};
};

__PACKAGE__->meta->make_immutable;

1;

__END__
