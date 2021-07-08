package Mojolicious::Command::Author::generate::obrazi;
use feature ':5.26';
use Mojo::Base Mojolicious::Command => -signatures;
use Mojo::File 'path';
use Mojo::Util qw(url_escape punycode_decode punycode_encode getopt encode decode dumper);
use Mojo::Collection 'c';
use Text::CSV_XS qw( csv );
use Imager;

my $_formats  = join '|', 'jpg', keys %Imager::formats;
my $FILETYPES = qr/(?:$_formats)$/i;
my sub _U {'UTF-8'}
has description => 'Generate a gallery from a directory structure with images';

# our own log, used instead of 'say'.
has log => sub {
  Mojo::Log->new(format => sub { "[$$] [$_[1]] " . join(' ', @_[2 .. $#_]) . $/ });
};

has usage             => sub { shift->extract_usage };
has from_dir          => sub { path('./')->to_abs };
has files_per_subproc => sub {
  my $all = scalar @{$_[0]->matrix} > 1 ? grep { $_->[1] =~ $FILETYPES } @{$_[0]->matrix} : 100;
  return int($all / $_[0]->subprocs_num) + 1;
};
has csv_filename  => 'index.csv';
has subprocs_num  => 4;
has template_file => '';
has to_dir        => sub { $_[0]->app->home->child('public') };

# Default titles and descriptions
has defaults => sub { {
  author               => 'Марио Беров',
  category_title       => 'Заглавие на категорията',
  category_description => 'Описание на категорията',
  image_title          => 'Заглавие на изображението',
  image_description    => 'Описание на изображението'
    . $/
    . ' Материали, размери,какво, защо - според каквото мислиш, че е важно.',
} };

# An empty Imager instance on which the read() method will be called for every
# image we work with.
has imager => sub { Imager->new };

my @header = qw(category path title description author image thumbnail);

# images to be resized
has matrix => sub { c([@header]) };

# resized images
has _processed => sub { c() };

# '1000x1000'
sub max {
  if ($_[1]) {
    $_[0]->{max} = $_[1] && return $_[0] if ref $_[1];
    ($_[0]->{max}{width}, $_[0]->{max}{height}) = $_[1] =~ /(\d+)x(\d+)/;
    return $_[0];
  }
  return $_[0]->{max} //= {width => 1000, height => 1000};
}

# '100x100'
sub thumbs {
  if ($_[1]) {
    $_[0]->{thumbs} = $_[1] && return $_[0] if ref $_[1];
    ($_[0]->{thumbs}{width}, $_[0]->{thumbs}{height}) = $_[1] =~ /(\d+)x(\d+)/;
    return $_[0];
  }
  return $_[0]->{thumbs} //= {width => 100, height => 100};
}

sub run ($self, @args) {
  getopt \@args,
    'f|from=s'     => \(my $from_dir     = $self->from_dir),
    'to=s'         => \(my $to_dir       = $self->to_dir),
    'x|max=s'      => \(my $max          = $self->max),
    's|thumbs=s'   => \(my $thumbs       = $self->thumbs),
    'i|index=s'    => \(my $csv_filename = $self->csv_filename),
    't|template=s' => \(my $template     = $self->template_file),
    ;
  if ($template ne $self->template_file and not -f $template) {
    Carp::croak("Template $template does not exist. " . "Please provide an existing template file.");
  }
  $self->template_file($template) if $template;
  $self->from_dir(path($from_dir)->to_abs)->to_dir(path($to_dir)->to_abs)->max($max)->thumbs($thumbs)
    ->csv_filename($csv_filename);
  $self->_do_csv->_resize_and_copy_to_dir->_do_html;
  return;
}

# Calculates the resized image dimensions according to the C<$self-E<gt>max>
# and C<$self-E<gt>thumbs> gallery contraints. Accepts the utf8 decoded path
# and the raw path to the file to be worked on. Returns two empty strings if
# there is error reading the image and warns about the error. Returns filenames
# for the resized image and the thumbnail image.
sub calculate_max_and_thumbs ($self, $path, $raw_path) {
  state $imager = $self->imager;
  my $log = $self->log;
  my $img;
  my $image = [$raw_path->to_array->[-1] =~ /^(.+?)\.(.\w+)$/];
  $log->info('Inspecting image ', $path);

  my $max        = $self->max;
  my $thumbs     = $self->thumbs;
  my %size       = %$max;
  my %thumb_size = %$thumbs;
  my $fh         = $raw_path->open();
  unless ($fh->binmode) {
    $log->warn(" !!! Skipping $path.  Error: " . $!);
    return ('', '');
  }
  if (not eval { $img = $imager->read(fh => $fh) }) {
    $log->warn(" !!! Skipping $path. Image error: " . $imager->errstr());
    return ('', '');
  }
  else {
    $image->[0] = decode _U, $image->[0];
    %size       = (width => $img->getwidth, height => $img->getheight);
    %thumb_size = %size;
    if ($size{width} > $max->{width} || $size{height} > $max->{height}) {
      @size{qw(x_scale y_scale width height)}
        = $img->scale_calculate(xpixels => $max->{width}, ypixels => $max->{height}, type => 'min');
    }

    if ($thumb_size{width} > $thumbs->{width} || $thumb_size{height} > $thumbs->{height}) {
      @thumb_size{qw(x_scale y_scale width height)}
        = $img->scale_calculate(xpixels => $thumbs->{width}, ypixels => $thumbs->{height}, type => 'min');
    }
  }

  return (
    punycode_encode($image->[0]) . "_$size{width}x$size{height}.$image->[1]",
    punycode_encode($image->[0]) . "_$thumb_size{width}x$thumb_size{height}.$image->[1]"
  );
}

# Reads the `from_dir` and dumps a csv file named after the from_dir folder.
# The file contains a table with paths and default titles and descriptions for
# the pictures.  This file can be given to the painter to add titles and
# descriptions for the pictures using an application like LibreOffice Calc or
# M$ Excel.
sub _do_csv ($self, $root = $self->from_dir) {
  my $csv_filepath = decode _U, $root->child($self->csv_filename);
  my $log = $self->log;
  if (-f $csv_filepath) {
    $log->info("$csv_filepath already exists.$/"
        . "\tIf you want to refresh it, please remove it.$/"
        . "\tContinuing with resizing and copying files...$/");
    return $self;
  }
  my $category = '';
  my $defaults = $self->defaults;
  my $matrix   = $self->matrix;
  $root->list_tree({dir => 1})->sort->each(
    sub ($e, $num) {
      $self->_make_matrix_row($root, $e, \$category, $defaults, $matrix, $log);
    }
  );
  csv(in => $matrix->to_array, enc => _U, out => \my $data, binary => 1, sep_char => ",");
  path($csv_filepath)->spurt($data);

  return $self;
}

sub _make_matrix_row ($self, $root, $raw_path, $category, $defaults, $matrix, $log) {
  my $path = decode(_U, $_->to_string =~ s|$root/||r);
  if (-d $raw_path) {
    $log->info("Inspecting category $path");
    $$category = decode(_U, $_->to_array->[-1]);
    push @$matrix,
      [
      $$category, $path,
      "$defaults->{category_title} – $$category",
      $defaults->{category_description},
      $defaults->{author}, '', '',
      ];
  }
  elsif (-f $raw_path) {
    if ($_ !~ $FILETYPES) {
      $log->warn("Skipping unsupported file $path…");
      return;
    }

    # for images without category - which are in the $root folder
    $$category = '' unless $path =~ /$$category/;
    push @$matrix,
      [
      $$category, $path,
      "$defaults->{image_title} – " . path($path)->basename,
      $defaults->{image_description},
      $defaults->{author}, $self->calculate_max_and_thumbs($path, $raw_path)
      ];
  }
}

# Scales and resizes images to maximum width and height and generates thumbnails.
sub _resize_and_copy_to_dir($self) {
  my $matrix = $self->matrix;
  my $csv_filepath = decode _U, $self->from_dir->child($self->csv_filename);
  if (@$matrix == 1) {

    # read the CSV file from disk to get calculated dimensions
    $matrix = c @{csv(in => $csv_filepath, enc => _U, binary => 1, sep_char => ",")};
    $self->matrix($matrix);
  }
  my @files = grep { $_->[1] =~ $FILETYPES } @{$_[0]->matrix};
  my @subprocs;
  my $chunk_size = $self->files_per_subproc;
  while (my @chunk = splice @files, 0, $chunk_size) {
    push @subprocs, $self->_process_chunk_of_files(\@chunk);
  }

#  foreach my $s (@subprocs) {
#
#    # Start event loop if necessary
#    $s->ioloop->start unless $s->ioloop->is_running;
#  }

  foreach my $s (@subprocs) {

    # Wait for the subprocess to finish
    $s->wait;
  }
  $self->log->info('All subprocesses finished.');

  my $copied = path($csv_filepath)->copy_to($self->to_dir);
  $self->log->info("$csv_filepath copied to $copied");
  return $self;
}

sub _process_chunk_of_files ($self, $files = []) {
  my $log      = $self->log;
  my $from_dir = $self->from_dir;
  my $to_dir   = $self->to_dir;
  my $imager   = $self->imager;
  Mojo::IOLoop->subprocess->run_p(sub($sub) {
    my $processed = [];
    for my $row (@$files) {
      my $raw_path = $from_dir->child(encode _U, $row->[1]);

      # Check for calculated dimensions and calculate them if missing.
      if (!$row->[-2] || !$row->[-1]) {
        ($row->[-2], $row->[-1]) = $self->calculate_max_and_thumbs($row->[1], $raw_path);
      }
      my $to_path    = $to_dir->child($row->[1])->dirname;
      my $sized_path = $to_path->child($row->[-2])->to_string;
      my $thumb_path = $to_path->child($row->[-1])->to_string;
      if (-s $sized_path && -s $thumb_path) {
        $log->info("$row->[-2] and $row->[-1] were already produced. Skipping ...");
        push @$processed, $row;
        next;
      }
      $log->info("Producing $row->[-2] and $row->[-1] from $row->[1] ...");
      my (%sized, %thumb);
      @sized{qw(xpixels ypixels)} = $row->[-2] =~ /_(\d+)x(\d+)\./;
      @thumb{qw(xpixels ypixels)} = $row->[-1] =~ /_(\d+)x(\d+)\./;
      my $img;
      if (not eval { $img = $imager->read(file => $raw_path) }) {
        $log->warn(" !!! Skipping $row->[1]. Image error: " . $imager->errstr());
        next;
      }
      unless (eval { $to_path->make_path({mode => 0711}); 1 }) {
        $log->warn("!!! Skipping $row->[1]. Error: $@");
        next;
      }
      my $maxi = $img->scale(%sized);
      $maxi->settag(name => 'i_xres', value => 96);
      $maxi->settag(name => 'i_yres', value => 96);
      unless ($maxi->write(file => $sized_path)) {
        $log->warn("!!! Cannot write image $sized_path!\nError:" . $maxi->errstr);
      }
      else {
        $log->info("Written $sized_path.");
      }
      my $thumbi = $img->scale(%thumb);
      $thumbi->settag(name => 'i_xres', value => 96);
      $thumbi->settag(name => 'i_yres', value => 96);
      unless ($thumbi->write(file => $thumb_path)) {
        $log->warn("!!! Cannot write image $thumb_path!\nError:" . $thumbi->errstr);
      }
      else {
        $log->info("Written $thumb_path.");
      }
      push @$processed, $row;
    }
    return $$, $processed;
  })->then(
    sub ($pid, $processed) {

      # Executed in the parent process where we can collect the results and write the
      # new csv file, which can be saved in the $to_dir.
      # TODO: think if this is needed or we can just copy the initially produced
      # csv file to $to_dir.
      $log->info("PID $pid processed " . (scalar @$processed) . ' files!');
      push @{$self->_processed}, @$processed;

      #for my $row(@$processed) {
      #  my $to_path = $to_dir->child($row->[1])->dirname;
      #  $log->info($to_path->child($row->[-2]));
      #  $log->info($to_path->child($row->[-1]));
      #}
    }
  )->catch(sub ($err) {
    $log->warn("Subprocess error: $err") if $err;
  });

}

sub _do_html($self) {
  state $app = $self->app;
  my $categories    = $self->matrix->grep(sub { !$_->[-1] && !$_->[-2] && $_->[1] =~ /$_->[0]$/ });
  my $processed     = $self->_processed;
  my $template_file = $self->template_file;
  my $vars          = {
    generator  => __PACKAGE__,
    categories => $categories,
    processed  => $processed,
    app        => $app,
    thumbs     => $self->thumbs
  };
  if ($template_file) {

    my $html = Mojo::Template->new($self->template)->name($template_file)->render_file($template_file => $vars);
    $self->to_dir->child(path($template_file)->basename =~ s/\.ep$//r)->spurt(encode _U, $html);
  }
  else {
    my $tpl = 'obrazi.html';
    $self->write_file($self->to_dir->child($tpl), encode _U, $self->render_data($tpl => $vars));
  }

  return;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::obrazi - Обраꙁи for your site – a
gallery generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate obrazi [OPTIONS]

    ./myapp.pl generate obrazi --from --to
    mojo generate obrazi --from ~/Pictures/summer-2021 \
        --to /opt/myapp/public/summer-2021

    mojo generate obrazi --from ~/Pictures/summer-2021 \
        --to /opt/myapp/public/albums/summer-2021 -x 800x600 -s 96x96

  Options:
    -h, --help       Show this summary of available options
    -f, --from       Root of directory structure from which the images
                     will be taken. Defaults to ./.
        --to         Root directory where the gallery will be put. Defaults to ./.
    -x, --max        Maximal image dimesnions in pixels in format 'widthxheight'.
                     Defaults to 1000x1000.
    -s, --thumbs     Thumbnails maximal dimensions. Defaults to 100x100 pixels.
    -i, --index      Name of the CSV index file to be generated or read in the
                     --from directory.
    -t, --template   Path to template file. Defaults to embedded template
                     obrazi.html.ep.

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::obrazi> generates a gallery from a
directory structure, containing images. The produced gallery is a static html
file which content can be easily taken, modified, and embedded into a page in
any site.

In addition the command generates a csv file describing the images. This file
can be edited. Titles and descriptions can be added for each image and then the
command can be run again to regenerate the gallery with the new titles and
descriptions. This file can be further used by a helper —
L<Mojolicious::Plugin::Obrazi/obrazi> to produce and embed the HTML for the
galery into a L<Mojolicious> application. Please note that the helper is not
yet implemented.

The word B<обраꙁъ>(singular) means L<face, image, picture, symbol, example,
template, etc.|https://histdict.uni-sofia.bg/dictionary/show/d_05616>
in OCS/OS/OBG language. The name of the plugin is the plural variant in
nominative case (обраꙁи).

=head1 WORKFLOW

1. Images' owner and producer gives the direcory (probably zipped) to the
command runner (a human yet).

2. The runner runs the command as shown in the SYNOPSIS.

3. The runner gives back the produced csv file to the images' producer. Fixes
problems with ICC profiles etc. Notifies the producer for eventual naming
convetions, possible problems. The producer fills in the description and titles
in the comfort of L<LibreOffice
Calc|https://www.libreoffice.org/discover/calc/> or MS Excel and returns the
file to the command-runner. This may take some time.

4. The runner runs again the command with the new csv file, reviews the
produced file. Takes the HTML and puts it in a page on the Web.

5. The images' owner/producer enjoys the gallery, prise him/herself with it or
goes back to the runner to report problems.

6. DONE or go to some of the previous steps.

=head1 FEATURES

Recursively traverses subdirectories and scales images (four at a time) to
given width and height and produces thumbnails for those images. Thumbnail
sizes can also be set.

Produces an index CSV file which can be edited to add titles and descriptions
for the images.

Produces an HTML file with fully functional lightbox-like gallery, implemented
only using jQuery  and CSS – no plugins. Left/right keyboard buttons navigation
to next and previous image.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::obrazi> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 csv_filename

    my $filename = $self->csv_filename; # index.csv
    my $обраꙁи = $self->csv_filename('gallery.csv');

The name of the CSV file which will be created in L</from_dir>. This file,
after being edited and after the images are processed, will be copied together
with the images to L</to_dir>. Defaults to C<index.csv>. Can be passed on the
command-line via the C<--index> argument.

=head2 defaults

    my $defaults_hashref = $обраꙁи->defaults;
    $обраꙁи->defaults->{category_title} = 'Def. Cat. title';
    $обраꙁи->defaults->{category_description} = 'Def. Cat. description.';
    $обраꙁи->defaults->{image_title} = 'Def. Image Title';
    $обраꙁи->defaults->{image_description} = 'Def. Image description.';
    $обраꙁи->defaults->{author} = 'John Smith';

These values go to the folowing columns in the produced CSV file. C<title,
description, author>. They are supposed to be replaced by editing the produced
file. TODO: Allow these to be passed on the command line via an argument C<--defaults>.

=head2 description

  my $description = $обраꙁи->description;
  $self       = $обраꙁи->description('Foo');

Short description of this command, used for the application's command list.

=head2 files_per_subproc

    my $files_num = $обраꙁи->files_per_subproc;
    $self         = $обраꙁи->files_per_subproc(10);

Number of files to be processed by one subprocess. Defaults to
C<int($number_of_images/$self-E<gt>subprocs_num) +1>. The last chunk of files is
the remainder — usually smaller than the previous chunks.

=head2 from_dir

    $self = $обраꙁи->from_dir(path('./'));
    my $root_folder_abs_path = $обраꙁи->from_dir;

Holds a L<Mojo::File> instance - absolute path to the directory from which the
pictures will be taken. This is where the CSV file describing the directory
structure will be generated too. The value is taken from the commandline
argument C<--from_dir>. Defaults to C<./> — current directory — where the
command is executed.

=head2 imager

    my $img = $обраꙁи->imager->read(file=>'path/to/image.jpg')
        || die $обраꙁи->imager->errstr;

    my $self = $обраꙁи->imager(Imager->new);

An L<Imager> instance.

=head2 log

    my $log = $self->log;
    my $self = $self->log(Mojo::Log->new)

A L<Mojo::Log> instance. It is not the same as C<$self-E<gt>app-E<gt>log>. Used
to output info, warnings and errors in the terminal or the application log.

=head2 matrix

    my $matrix = $self->matrix;

    # add an image
    push @$matrix,
      [
      $category,               $path,
      $defaults->{image_title}, $defaults->{image_description},
      $defaults->{author},      $self->calculate_max_and_thumbs($path, $raw_path)
      ];

    # add a category
    push @$matrix, [
        $category, $path, "$defaults->{category_title} – $category",
        $defaults->{category_description}, $defaults->{author}, '', ''
    ];

    $matrix->each(sub{...});


    csv(in => $matrix->to_array, enc => 'UTF-8', out => \my $data, binary => 1, sep_char => ",");
    path($csv_filepath)->spurt($data);

A L<Mojo::Collection> instance. First row contains the headers. This matrix is
filled in while recursively searching in the L</from_dir> for images. Then it
is dumped into the index CSV file.

=head2 max

    my $max_sizes = $self->max; #{width => 1000, height => 1000}
    $self = $self->max(width => 1000, height => 1000);
    $self = $self->max('1000x1000');

A hash reference with keys C<width> and C<height>. Defaults to C<{width =>
1000, height => 1000}>. Can be changed via the command line argument C<--max>.

=head2 subprocs_num

    $self->subprocs_num; #4
    $self = $self->subprocs_num(5);

Integer, used to split the number of files found into equal chunks, each of
which will be processed in a separate subprocess in parallel. Defaults to 4.
See also L</files_per_subproc>.

=head2 template_file

    my $self = $self->template_file('path/to/template.html.ep');
    my $tpl  = $self->template_file;

Path to template file to be used for generating the HTML for the gallery.
Defaults to embedded template obrazi.html.ep. Can be passed as argument on the
command-line via C<--template>.

=head2 thumbs

    my $thumbs_sizes = $self->thumbs; #{width => 100, height => 100}
    $self = $self->thumbs(width => 100, height => 100);
    $self = $self->thumbs('1000x1000');

A hash reference with keys C<width> and C<height>. Defaults to C<{width =>
100, height => 100}>. Can be changed via the command line argument
C<--thumbs>.

=head2 to_dir

    $self->to_dir # path($app/public)
    $self = $self->to_dir(path('/some/folder'));

A L<Mojo::File> instance. Directory, where the folder with the processed images
will be put. Defaults to the C<public> forlder of the current application.
Can be changed via the command line argument C<--to_dir>. It is recommended to
pass this value unless all your images are into one root folder. The L</to_dir>
directory is the root of your images' galery.

=head2 usage

  my $usage = $обраꙁи->usage;
  $self = $обраꙁи->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::obrazi> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 calculate_max_and_thumbs

    #   img_1000x1000.jpg, img_100x100.jpg
    my ($img_filename, $thumb_filename) = $self->calculate_max_and_thumbs($decoded_path, $raw_path);

Calculates the resized image dimensions according to the C<$self-E<gt>max>
and C<$self-E<gt>thumbs> gallery constraints. Accepts the utf8 decoded path
and the raw path to the file to be worked on. Returns two empty strings if
there is error reading the image and warns about the error. Returns filenames
for the resized image and the thumbnail image. See also
L<Imager::Transformations/scale_calculate()>.

=head2 run

  $makefile->run(@ARGV);

Run this command.

=head2 TEMPLATES

L<Mojolicious::Command::Author::generate::obrazi> contains an embedded template
C<obrazi.html.ep>. TODO: Make the template inflatable.

=head1 DEMOS

Here is a hopefully growing list of URLs of galleries produced with this
software.

L<Творби на Марио Беров|https://слово.бг/хѫдожьство/mario_berov.bg.html> — a
gallery, presenting works of the Bulgarian Orthodox icon painter Mario Berov.

=head1 SEE ALSO

L<Imager>, L<Text::CSV_XS>
L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>,

L<jQuery – used for implementing the example embedded template|https://jquery.com/>,

L<Chota (A micro (~3kb) CSS framework) – also used for the example implementation|https://jenil.github.io/chota/>.

=cut

__DATA__

@@ obrazi.html
% use Mojo::File qw(path);
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="<%= $generator %>" />
        <title>Обраꙁи</title>
        <script
			  src="https://code.jquery.com/jquery-3.6.0.min.js"
			  integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4="
			  crossorigin="anonymous"></script>
        <link rel="stylesheet" href="https://unpkg.com/chota@latest">
        <style>
            section .card {
                background-position: center;
                background-repeat: no-repeat;
                max-width: <%= $thumbs->{width} + 15 %>px;
                height: <%= $thumbs->{width} + 15 %>px;
                overflow: hidden; /* Hide scrollbars */
                cursor: pointer;
                /* filter: blur(3px);
                -webkit-filter: blur(3px); */
            }
            section .card .image {
                width: 100% !important;
                height: 100% !important;
                background-position: center;
                background-repeat: no-repeat;
                background-size: contain;
                background-color: rgba(11, 11, 11, 0.9);
                color: #fff;
                text-shadow: 2px 2px 4px #000;
                position: fixed;
                box-sizing: border-box;
                left: 0;
                top: 0;
                display: none;
                z-index: 1024;
                cursor: default;
            }
            section .card .image h4 {
                margin-left: 0;
            }
            section .card .image h3.category {
                position: absolute;
                top: 0;
                right:0;
                padding: 1em;
            }
            section .card .image .meta {
                position: absolute;
                bottom: 0;
                left:0;
                padding: 1em;
            }
            .image .prev, .image .next {
		position: relative;
		top: 0;
		padding-top: calc(100vh / 2 - 6rem / 2);
                font-size: 6rem;
		width: 10vw;
		height: 100%;
		border-radius: 10px;
		cursor:pointer;
		transition: background-color .5s;
            }
	    .image .prev:hover, .image .next:hover {
                background-color: rgba(55, 55, 55, 0.9);
	    }
            section[class^="idx"] {
                display: none;
            }
            h2, section.level2 {
                margin-left:2rem;
            }
            h3, section.level3 {
                margin-left:4rem;
            }
            h4, section.level4 {
                margin-left:6rem;
            }
            h2.button, h3.button, h4.button {
                display: block;
                text-align: left;
            }
        </style>
    </head>
    <body>
        <h1>Обраꙁи</h1>
        <section tabindex="0" class="obrazi">
% my $cols     = int(12/2); #6
% my $idx     = 0;
% my $img_idx = 1;
% for my $cat(['','',''], @$categories) {
%    my $images  = $processed->map(sub {my $img = shift; $cat->[0] eq $img->[0] ? $img : (); });
%    next unless @$images;
%    my $level = $cat->[1] =~ m|(/)|g;
%    $level += 1; $idx++;
% if($cat->[2]) {
        <h<%= $level %> class="primary button" data-index="<%= $idx %>"><%= $cat->[2] %></h<%= $level %>>
% }
<section tabindex="<%= $idx %>" class="idx<%= $idx %> level<%= $level %>">
<%= $app->t('p', $cat->[3]) if $cat->[3] %>
%    while(my @row = splice @$images, 0, $cols) {
    <div class="row">
    %   for my $img(@row) { $img_idx++;
        <div class="col card"
            data-index="<%= $img_idx %>"
            title="<%= $img->[2] %>"
            style="background-image :url('<%= path($img->[1])->dirname->child($img->[-1])%>')">
            <div class="image" id="<%= $img_idx %>"
                style="background-image: url('<%= path($img->[1])->dirname->child($img->[-2]) %>')">
                    <div data-index="<%= $img_idx %>" class="prev pull-left text-left text-light">⏴</div>
                    <div data-index="<%= $img_idx %>" class="next pull-right text-right text-light">⏵</div>
		<h3 class="category text-right text-light"><%= $cat->[2] %></h3>
                <div class="meta">
                    <h4><%= $img->[2] %></h4>
                    <p><%= $img->[3] %></p>
                </div>
            </div>
        </div>
    % }
    </div>
% } # end of while
</section>
% } # end for @$categories
        </section><!-- end section class="obrazi"-->
<script>

// Clicking on a category title shows/hides the category's <section> element.
$('h1,h2,h3').click(function(e) {
    e.stopPropagation();
    let idx = $(e.target).data('index');
    $('section.idx' + idx).toggle('slow');
})

/*
    Clicking on a thumbnail opens a full-sized image in a 100%x100% screen-sized
    overlay box. Sets a more visible border on the thumbnail to remind the user
    where he/she was.
*/
$('section .card').click(function(e){
    e.stopPropagation();
    let self = $(e.target);
    let id = self.data('index');
    $('#' + id).toggle('slow');
    $('section .card').css({border:"0px"});
    self.css({border: "1px solid #333"});
});

/*
    Clicking anywhere on the full-sized image box toggles the visibility of the
    box. Effectively hiding it.
*/
$('section .card .image').click(function(e) {
    e.stopPropagation();
    $(e.target).toggle('slow');
});

/*
    To be bound to the keydown event, the sections need to have the attribute
    tabindex, set to a meaningful sequence.
    This event is handled for every <section>. It handles the right/left and
    up/down keypresses. When the corresponding key is pressed, the image box is
    replaced with the respectively previous or next image.
*/
$('section.obrazi,section[class^="level"]').keydown(function(e) {
    // e.preventDefault();
    e.stopPropagation();
    $('section .card').css({border:"0px"});
    // close the currently visible image...
    let img = $('section .card .image:visible');
    if(img.get(0) === undefined) return;
    if(e.key === 'Escape'){
        img.hide();
        return;
    }
    let id = img.attr('id');
    re_prev = /^Arrow(Left|Up)$/;
    re_next = /^Arrow(Right|Down)$/;
    // ... and open
    if(e.key.match(re_prev) ){
        id--;
    }
    else if(e.key.match(re_next) ){
        id++;
    }
    $('#' + id).toggle('slow');
    $('#' + id).parent().css({border: "1px solid #333"});
    img.toggle(900);
});

/*
    Pressing the right and left buttons in the image closes the image and opens the
    previous and next image.
*/
$('.image .prev, .image .next').click(function(e) {
    e.stopPropagation();
    let self = $(e.target);
    let img = self.parent();
    let id = img.attr('id');
    if(self.hasClass('next')) {
        id++;
    }
    else {
        id--;
    }
    $('#' + id).toggle('slow');
    $('#' + id).parent().css({border: "1px solid #333"});
    img.toggle(900);
});

</script>
    </body>
</html>
