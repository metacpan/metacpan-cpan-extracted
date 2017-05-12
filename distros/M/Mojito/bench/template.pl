use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use 5.010;
use Mojito::Template::Zoom;
my $zoom = Mojito::Template::Zoom->new;

my $count = $ARGV[0] || 10;

my $edit = '<section>hey</section>';
my $view = '<h1>Sweet Home Alabama</h1>';

# page fixture if needed:
# http://10.0.0.2:5000/page/4d50e8092d4a8a4019000000/edit

my $result = cmpthese(
    $count,
    {
        'tmpl' => sub {
            #$zoom->template_z->to_html;
            $zoom->replace_edit_page($edit,$view);
        },
#        'divide'  => sub { 1.3 / 2.7 },
#        'conquer' => sub {
#            sub {
#                sub { my $goodness = rand }
#              }
#        },
    }
);