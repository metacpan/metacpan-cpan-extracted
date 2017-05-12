package Rhetoric::Storage::File;
use common::sense;
use aliased 'Squatting::H';

use Data::Dump 'pp';
use DateTime;
use Cwd;
use File::Copy;
use File::Basename;
use File::Find::Rule;
use File::Path::Tiny;
use File::ShareDir ':ALL';
use IO::All;
use Method::Signatures::Simple;
use Ouch;

use Rhetoric::Helpers ':all';

# shortcuts for File::Path::Tiny
*mk = *File::Path::Tiny::mk;

our $storage = H->new({

  init => method($config) {
    $self->root($config->{'storage.file.path'});
    $self->archive_format($config->{'archive_format'});
    $self;
  },

  install => method {
    my $root = $self->root;
    mk("$root/posts");
    mk("$root/categories");
    mk("$root/categories/Perl");

    my $share = File::ShareDir::dist_dir('Rhetoric');

    # TODO - Don't use system()

    # TODO - Move this to Rhetoric::Meta
    mk("$root/menu");
    system("cp '$share/menu/'* '$root/menu'");

    # TODO - Move this to Rhetoric::Meta
    mk("$root/pages");
    system("cp '$share/pages/'* '$root/pages'");

    # TODO - Move this to Rhetoric::Meta
    #mk("$root/widgets");
    system("rsync -a '$share/widgets/' '$root/widgets/'");
    my $cwd = getcwd;
    chdir "$root/widgets/sidebar";
    symlink("init.pl",       "00_init.pl");
    symlink("search.pl",     "01_search.pl");
    symlink("content.pl",    "02_about.pl");
    symlink("categories.pl", "03_categories.pl");
    symlink("archives.pl",   "04_archives.pl");
    symlink("cleanup.pl",    "99_cleanup.pl");
    chdir $cwd;

    # TODO - Move this to Rhetoric::Meta
    $self->meta(title    => "Rhetoric")                                              unless (-e "$root/title");
    $self->meta(subtitle => "Simple Blogging for Perl")                              unless (-e "$root/subtitle");
    $self->meta('copy'   => "COPYRIGHT (C) 2011 SOMESITE.COM.  ALL RIGHTS RESERVED") unless (-e "$root/copy");
    return 1;
  },

  meta => method($k, $v) {
    my $root = $self->root;
    if (defined($v)) {
      wl("$root/$k", "$v");
    } else {
      $v = rl("$root/$k");
    }
    return $v;
  },

  new_post => method($post) {
    ref($post) eq 'HASH' && H->bless($post);
    my ($title, $body, $format, $schedule);
    $title  = $post->title;
    $body   = $post->body;
    $format = $post->format || 'pod';
    my ($Y, $M, $D, $h, $m, $s);
    if ($schedule) {
      # FIXME - use $post->posted_on instead of $schedule
      ($Y, $M, $D, $h, $m, $s) = split('/', $schedule);
    } else {
      ($Y, $M, $D, $h, $m, $s) = now();
    }
    my $dt   = DateTime->new(
      year   => $Y,
      month  => $M,
      day    => $D,
      hour   => $h,
      minute => $m,
      second => $s,
    );
    my $root = $self->root;
    my $post_path = sprintf("$root/posts/%d/%02d/%02d/%02d/%02d/%02d", $Y, $M, $D, $h, $m, $s);
    mk($post_path);
    wl("$post_path/title",  $title);
    wl("$post_path/slug",   slug($title));
    wl("$post_path/body",   $body);
    wl("$post_path/format", $format);
    $post->slug(slug($title));
    $post->format($format);
    $post->year($Y);
    $post->month($M);
    $post->posted_on($dt);
    $post->author($ENV{USER});
    return $post;
  },

  # fetch a post
  post => method($y, $m, $slug) {
    my $root = $self->root;
    my $partial_post_path = "$root/posts/$y/$m";
    my @files = File::Find::Rule
      ->file()
      ->name('slug')
      ->in($partial_post_path);
    my ($file) = grep { my $test_slug = rl($_); $test_slug eq $slug } @files;
    if ($file) {
      my $post_path = dirname($file);
      my $title  = rl("$post_path/title");
      my $format = rl("$post_path/format");
      chomp($format);
      my $body   = $F->$format(io("$post_path/body")->all);
      my @s = split('/', $post_path);
      my ($Y, $M, $D, $h, $m, $s) = @s[-6 .. -1];
      my $posted_on = DateTime->new(year => $Y, month => $M, day => $D, hour => $h, minute => $m, second => $s);
      my $post = H->new({
        title     => $title,
        slug      => $slug,
        body      => $body,
        format    => $format,
        posted_on => $posted_on,
        year      => $Y,
        month     => $M,
        day       => $D,
        hour      => $h,
        minute    => $m,
        second    => $s,
        author    => ($Rhetoric::CONFIG{user} // file_owner("$post_path/title")),
      });
      my @comment_files = glob("$post_path/comments/*");
      my $comment_count = scalar(@comment_files);
      $post->comment_count($comment_count);
      return $post;
    } else {
      return undef;
    }
  },

  # FIXME - This implementation is not efficient,
  # FIXME   because it scans the entire post history every time.
  posts => method($count, $page) {
    my $root = $self->root;
    my @all_posts = reverse sort (
      File::Find::Rule
        ->file()
        ->name('slug')
        ->in("$root/posts")
    );
    $count = (@all_posts < $count) ? scalar(@all_posts) : $count;
    my $pager = Data::Page->new(
      scalar(@all_posts),   # total # of posts
      $count,               # posts per page
      $page                 # current page
    );
    my @p = $pager->splice(\@all_posts);
    my @posts = map {
      my @d = (split('/', $_))[-7 .. -1]; # d for directory
      my $slug = rl($_);
      my ($y, $m) = ($d[0], $d[1]);
      $self->post($y, $m, $slug);
    } @p;
    return (\@posts, $pager);
  },

  categories => method {
    my $root = $self->root;
    my $category_path = "$root/categories";
    my @c = sort (
      map { basename($_) }
      File::Find::Rule
        ->directory()
        ->mindepth(1)
        ->maxdepth(1)
        ->in($category_path)
    );
  },

  # TODO - list of category posts
  category_posts => method($category) {
    ([], undef);
  },

  #
  archives => method {
    my $root = $self->root;
    my $post_path = "$root/posts";
    my @d = reverse sort (
      File::Find::Rule
        ->directory()
        ->mindepth(2)
        ->maxdepth(2)
        ->in($post_path)
    );
    my @ad = map {
      my $path = $_;
      $path =~ s/^$post_path\///;
      my ($year, $month) = split('/', $path);
      my $name = DateTime
        ->new(year => $year, month => $month)
        ->strftime($self->archive_format);
      my $archive = H->new({
        year  => $year,
        month => $month,
        name  => $name,
      });
    } @d;
    @ad;
  },

  # 
  archive_posts => method($y, $m) {
    my $root = $self->root;
    my @all_posts = reverse sort (
      File::Find::Rule
        ->file()
        ->name('slug')
        ->in("$root/posts/$y/$m")
    );
    my @posts = map {
      my @d = (split('/', $_))[-7 .. -1]; # d for directory
      my $slug = rl($_);
      my ($y, $m) = ($d[0], $d[1]);
      $self->post($y, $m, $slug);
    } @all_posts;
    (\@posts, undef);
  },

  #
  comments => method($post) {
    my $root = $self->root;
    my $post_path = sprintf('%s/posts/%s/%s/%s/%s/%s/%s',
      $root,
      $post->year, $post->month,  $post->day,
      $post->hour, $post->minute, $post->second,
    );
    my @comment_files = sort glob("$post_path/comments/*");
    my @comments = map {
      my ($name,$email,$url,@body) = io($_)->slurp;
      chomp($name, $email, $url);
      my $body = join('', @body);
      H->new({
        name  => $name,
        email => $email,
        url   => $url,
        body  => $body,
      });
    } @comment_files;
    \@comments;
  },

  #
  new_comment => method($year, $month, $slug, $comment) {
    ref($comment) eq 'HASH' && H->bless($comment);
    my @errors;
    push @errors, ['name']  if (not $comment->name);
    push @errors, ['email'] if (not $comment->email);
    push @errors, ['body']  if (not $comment->body);
    if (@errors) {
      ouch('InvalidComment', \@errors);
    }

    my $post = $self->post($year, $month, $slug);
    my $root = $self->root;
    my $post_path = sprintf('%s/posts/%s/%s/%s/%s/%s/%s',
      $root,
      $post->year, $post->month,  $post->day,
      $post->hour, $post->minute, $post->second,
    );
    warn("$post_path/comments");
    mk("$post_path/comments");
    my @comment_files = sort glob("$post_path/comments/*");
    my $index = '001';
    if (@comment_files) {
      warn "previous comments existed";
      my $last = (split('/', $comment_files[-1]))[-1];
      $last =~ s/^0*//;
      warn "last is $last";
      $index = sprintf('%03d', $last + 1);
    }
    warn $index;
    my $format = $comment->format || 'pod';
    my $body   = $F->$format($comment->body);
    io("$post_path/comments/$index") <  $comment->name  . "\n";
    io("$post_path/comments/$index") << $comment->email . "\n";
    io("$post_path/comments/$index") << $comment->url   . "\n";
    io("$post_path/comments/$index") << $body           . "\n";
    $comment->success(1);
    $comment;
  },

  # XXX - this needs to take TT or perl expressions
  menu => method($menu) {
    my $root = $self->root;
    my $menu_path = "$root/menu";
    if (defined($menu)) {
      my $i = 1;
      for (@$menu) {
        my $name = $_->name;
        my $url  = $_->url;
        io(sprintf("$menu_path/%02d_%s", $i, $menu)) < $url;
        $i++;
      }
    } else {
      my @menu_files = sort glob("$menu_path/*");
      $menu = [ map {
        my $filename = $_;
        my $url      = rl($filename);
        my ($name)   = fileparse($filename);
        chomp($url);
        $name        =~ s/^\d*_//;
        H->new({ name => $name, url => $url });
      } @menu_files ];
    }
    return $menu;
  },
});

1;

__END__

=head1 NAME

Rhetoric::Storage::File - filesystem-based storage for Rhetoric blog data

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 API

=head2 Package Variables

=head3 $storage

=head2 Methods for $storage

=head3 $storage->init

=head3 $storage->meta($key, $value)

=head3 $storage->new_post($post)

=head3 $storage->post($year, $month, $slug)

=head3 $storage->posts($count, $after)

=head3 $storage->categories

=head3 $storage->category_posts

=head3 $storage->archives

=head3 $storage->archive_posts($year, $month)

=head3 $storage->comments($post)

=head3 $storage->new_comment($year, $month, $slug, $comment)

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
