use 5.014;
use File::Temp;
use FindBin qw($Bin);
use File::Compare qw(compare);
use File::Spec;
use Test::Most;
use Mojo::UserAgent::Mockable::Serializer;

my $serializer = Mojo::UserAgent::Mockable::Serializer->new;
my $file = qq{$Bin/../files/sample resume.docx};

package TestApp {
    use Mojolicious::Lite;

    get '/download' => sub {
        my $c = shift;

        my ( $dir, $filename ) = ( File::Spec->splitpath($file) )[ 1 .. 2 ];
        push @{ $c->app->static->paths }, $dir;
        $c->res->headers->content_disposition('attachment; filename=sample_resume.docx');
        $c->reply->static($filename);
    };
};

my $action = sub {
    my $c = shift;

    my ($dir, $filename) = (File::Spec->splitpath($file))[1..2];
    push @{$c->app->static->paths}, $dir; 
    $c->res->headers->content_disposition('attachment; filename=sample_resume.docx');
    $c->reply->static($filename);
};

my $app = TestApp::app;
my $ua = $app->ua;
my $tx = $ua->get('/download');
my $serialized = $serializer->serialize($tx);
$tx = undef;
$app = undef;

my $dir = File::Temp->newdir;
my $download = qq{$dir/sample_resume.docx};

my ($tx2) = $serializer->deserialize($serialized);
$tx2->res->content->asset->move_to($download);

is compare($download, $file), 0, 'Binary files copied properly';
done_testing;
