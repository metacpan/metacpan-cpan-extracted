package TestAS2;

use strict;
use warnings;
use autodie;

use Cwd            qw(abs_path);
use Data::Dumper   qw();
use File::Basename qw(basename dirname);
use File::Path     qw(make_path remove_tree);

use Plack::Test;

my $dir = dirname(dirname(abs_path(__FILE__)));

sub start {
    my ($server, $type) = @_;

    $Plack::Test::Impl = $type if $type;

    my $app = require "$dir/$server/$server.psgi";

    my $psgi = Plack::Test->create($app);

    return $psgi;
}

sub slurp_file {
    my $file = shift;

    local $/ = undef;
    open my $fh, '<', $file;
    my $contents = scalar(<$fh>);
    close $fh;

    return $contents;
}

sub configure {
    my ($server, $partnership, $vars) = @_;

    my $partnership_dir = "$dir/$server/partnerships/$partnership";

    make_path($partnership_dir, {
        mode => oct(700),
    });

    my @files = glob("$dir/$server/*.template");
    foreach my $file (@files) {
        my $template = slurp_file($file);

        # Apply dynamic content
        my $content = $template;
        foreach my $v (keys %$vars) {
            $content=~ s/\{\{$v\}\}/$vars->{$v}/g;
        }

        # Save to new file under partnerships/$partnership
        (my $filename = basename($file)) =~ s/[.]template$//;

        my $partnership_file = "$partnership_dir/$filename";
        open my $to_fh, '>', $partnership_file;
        chmod 0600, $partnership_file;
        print $to_fh $content;
        close $to_fh;
    }
}

sub tear_down {
    my ($server) = @_;

    my $partnerships_dir = "$dir/$server/partnerships";
    my $files_dir        = "$dir/$server/files";

    return remove_tree($partnerships_dir, $files_dir);
}

1;
