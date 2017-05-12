use strict;
use warnings;

use File::Path;
use Module::Build;
use Test::More tests => 5;

use Spoon;

my $spoon = Spoon->new;
my $hub = $spoon->load_hub( { template_class => 'Spoon::Template::Mason' } );

ok( $hub, 'made new hub' );
is( $hub->config->template_class, 'Spoon::Template::Mason',
    ' template class is Spoon::Template::Mason as' );

my $template = $hub->template;

my ($path) = @{ $template->path };

mkpath( $path, 0755 );
Module::Build->current->add_to_cleanup($path);

my $file = "$path/foo.html";
open my $fh, '>', $file
    or die "Cannot write to $file";

print $fh <<'EOF' or die "Cannot write to $file";
This is being rendered!

foo is <% $foo %>
bar is <% $bar %>

<%args>
$foo => 'yadda'
$bar
</%args>
EOF

close $fh
    or die "Cannot write to $file";

my $output = $template->render( 'foo.html', bar => 30 );

like( $output, qr/This is being rendered!/, 'check render output - 1' );
like( $output, qr/foo is yadda/, 'check render output - 2' );
like( $output, qr/bar is 30/, 'check render output - 3' );
