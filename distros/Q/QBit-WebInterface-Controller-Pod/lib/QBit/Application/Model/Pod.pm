package QBit::Application::Model::Pod;
$QBit::Application::Model::Pod::VERSION = '0.004';
use qbit;

use base qw(QBit::Application::Model);

use Pod::Checker;

# Ugly hack to disable checking internal links
no warnings 'redefine';
no strict 'refs';
*{'Pod::Checker::hyperlink'} = sub { };

sub clear_path {
    my ($path) = @_;

    $path =~ s/[\/\\]{2}/\//g;

    return $path;
}

sub folder_has_pod {
    my ($folder) = @_;

    my @files = <$folder/*>;
    chomp(@files);

    foreach my $file (@files) {
        return TRUE if -d $file && folder_has_pod($file) || $file =~ /\.(?:pm|pod)$/ && -f $file;
    }

    return FALSE;
}

sub check_pod {
    my ($file) = @_;

    open(F, ">", '/dev/null');
    return podchecker($file, \*F, -warnings => 0);
}

sub get_folder_info {
    my ($base_paths, $path) = @_;

    my %res = ();
    foreach my $base_path (@$base_paths) {
        my $folder = clear_path("${base_path}${path}");

        my @files = <$folder/*>;
        chomp(@files);

        foreach my $file (@files) {
            my $filename = $file;
            $filename = $1 if $filename =~ /([^\\\/]+)$/;

            next if exists($res{$filename});

            if (-d $file) {
                $res{$filename} = {type => 1, name => $filename} if folder_has_pod($file);
                next;
            }

            if ($file =~ /\.(?:pm|pod)/ && -f $file) {
                my $pod_chk = check_pod($file);

                unless ($pod_chk) {
                    $res{$filename} = {type => 2, name => $filename};
                } else {
                    if ($pod_chk == -1) {
                        $res{$filename} = {type => 3, name => $filename};
                    } else {
                        $res{$filename} = {type => 4, name => $filename};
                    }
                }
            }
        }
    }

    return [values(%res)];
}

sub pod_errors {
    my ($file) = @_;

    my $data = '';
    open(F, ">", \$data);
    my $err_cnt = podchecker($file, \*F, -warnings => 0);
    close(F);

    return $err_cnt ? $data : undef;
}

sub get_pod {
    my ($file) = @_;

    my $pod_errors = pod_errors($file);
    if ($pod_errors) {
        $pod_errors =~ s/\n/<br>/g;
        return $pod_errors;
    }

    my $text = '<a name="___top"><h1>Index</h1></a>';
    my $pod  = QBit::Application::Model::Pod::HTML->new();
    $pod->bare_output(TRUE);
    $pod->index(TRUE);
    $pod->output_string(\$text);
    $pod->parse_file($file);

    return $text;
}

sub show_pod {
    my ($self, $base_paths, $path, %opts) = @_;

    $base_paths ||= ['/'];
    $base_paths = [$base_paths] if ref($base_paths) ne 'ARRAY';

    $path = "/$path" unless $path =~ /^[\\\/]/;
    $path =~ s/\.\.//g;

    foreach my $base_path (@$base_paths) {
        my $file = clear_path("${base_path}${path}");

        next unless -e $file;

        return {type => 1, data => get_folder_info($base_paths, $path), path => clear_path($path)} if -d $file;

        if (-f $file) {
            my $name = clear_path($path);
            my $fname = $1 if $name =~ /([^\\\/]+?)$/;
            $name =~ s/^[\\\/]+//;
            $name =~ s/[\\\/]/::/g;
            $name =~ s/\.pm$//;
            $path =~ s/[^\\\/]+$//;
            return {type => 2, data => get_pod($file), path => clear_path($path), name => $name, fname => $fname};
        }
    }
}

package QBit::Application::Model::Pod::HTML;
$QBit::Application::Model::Pod::HTML::VERSION = '0.004';
use qbit;

use base qw(Pod::Simple::HTML);

sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;

    my $url = '';

    if (defined($to) && length($to)) {
        my ($path, $file) = ('', '');
        ($path, $file) = ($1, $2) if $to =~ /^(.*?)(?:\:\:)?([\w\d_]+)$/;
        $path =~ s/::/\//g;
        $path = uri_escape($path);
        $file = uri_escape($file);

        $url .= "?path=/$path&file=$file.pm";
    }

    if (defined($section) && length($section)) {
        $url .= "#$section";
    }

    return $url;
}

1;
