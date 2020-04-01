package ExampleApp::Plugin::MyEngine;
use Mojo::Base 'Mojolicious::Plugin::Notifications::Engine';
use Mojo::ByteStream 'b';
use Mojo::Util qw/xml_escape quote/;
use File::Spec;
use File::Basename;

# Notification method
sub notifications {
  my ($self, $c, $notify_array) = @_;

  return '' unless @$notify_array;

  # Start JavaScript snippet
  my $js .= qq{<script>//<![CDATA[\n};
  $js .= "var notifications=[];\n";

  # Add notifications
  foreach (@$notify_array) {
    $js .= 'notifications.push([' . quote($_->[-1]);
    $js .= ',' . quote($_->[0]);
    $js .= "]);\n";

  };

  return b($js . "//]]>\n</script>\n");
};


1;
