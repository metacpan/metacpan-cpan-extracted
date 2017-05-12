package Rhetoric;
use 5.010_0;
use common::sense;
use aliased 'Squatting::H';
use Squatting;
use Try::Tiny;

use Rhetoric::Helpers ':all';
use Rhetoric::Widgets;
use Rhetoric::Meta;

our $VERSION = '0.06';

# global config for our blogging app
our %CONFIG = (
  'base'                => '.',                   # config directory - metadata, menus, widgets, pages
  'user'                => undef,                 # used for rhetoric.al accounts but otherwise optional
  'time_format'         => '%b %e, %Y %I:%M%P',
  'archive_format'      => '%B %Y',               # TODO - use this!
  'posts_per_page'      => 8,

  'theme'               => 'BrownStone',          # Rhetoric::Theme::____
  'theme.base'          => './share/theme',

  'login'               => 'admin',
  'password'            => 'admin',

  'storage'             => 'File',                # Rhetoric::Storage::____
  'storage.file.path'   => '.',
  # TODO
  'storage.couchdb.url'    => undef,              # URL for CouchDB database
  # TODO
  'storage.mysql.connect'  => undef,              # connect string suitable for DBI->connect
  'storage.mysql.user'     => undef,
  'storage.mysql.password' => undef,

  # just for continuity
  docroot => 'share',
);

sub continue {
  my $app = shift;
  $app->next::method(
    docroot => $CONFIG{'docroot'}, 
    staticp => sub { $_[0]->url =~ m/\.(jpg|jpeg|gif|png|css|ico|js|swf)$/ },
    @_
  );
}

# service() is run on every request (just like in Camping).
sub service {
  my ($class, $c, @args) = @_;
  $c->view = $c->state->{theme} // $CONFIG{theme};
  my $v = $c->v;
  my $s = $c->env->{storage} = storage($CONFIG{storage});
  H->bless($v);
  H->bless($c->input);
  H->bless($c->env);
  $v->{title}        = $s->meta('title');
  $v->{subtitle}     = $s->meta('subtitle');
  $v->{copy}         = $s->meta('copy');
  $v->{menu}         = $s->menu;
  $v->{request_path} = $c->env->{REQUEST_PATH};
  $v->{time_format}  = $CONFIG{time_format};
  $v->{hostname}     = $CONFIG{hostname} // $c->env->{HTTP_HOST};
  $v->{state}        = $c->state; # XXX - Should Squatting be doing this automatically?

  # hack to help rh-export
  if ($c->state->{mock_request}) {
    # the RIGHT THING(tm) would be to change how we store menu information.
    # I suppose I need to support perl expressions in there instead of
    # just strings.
    # FIXME
    for my $menu (@{$v->{menu}}) {
      my $href = $menu->url;
      if (($href !~ qr{^https?:}) && ($href !~ qr{\.html$}) && ($href ne '/')) {
        $href .= ".html";
        $menu->url($href);
      }
    }
  }

  if (exists $CONFIG{relocated}) {
    for (@{ $v->menu }) {
      $_->url($CONFIG{relocated} . $_->url);
    }
    $v->{relocated} = $CONFIG{relocated};
  }
  for my $position ($s->widgets->positions) {
    $v->{widgets}{$position} = [ $s->widgets->content_for($position, $c, @args) ];
  }
  $class->next::method($c, @args);
}

# initialize app
sub init {
  my ($class) = @_;

  # TODO - Make absolutely sure the Page controller is at $C[-1].
  if ($Rhetoric::Controllers::C[-1]->name ne 'Page') {
    # find index of Page controller
    # splice it out
    # push it back on to the end
  }

  # view initialization
  Rhetoric::Views::init();

  $class->next::method();
}

# Return an object that handles the storage for blog data based on
# what $CONFIG{storage} dictates.
sub storage {
  no strict 'refs';
  my $impl    = shift;
  my $path    = "Rhetoric/Storage/$impl.pm";
  my $package = "Rhetoric::Storage::$impl";
  require($path); # let it die if it fails.

  # the stuff that's ALWAYS in the filesystem (besides widgets)
  # menus and pages might get split out later
  my $meta = $Rhetoric::Meta::meta;

  # where posts and comments are stored
  my $storage = ${"${package}::storage"};
  $storage->init(\%CONFIG);

  # widgets
  my $widgets = $Rhetoric::Widgets::widgets;
  $widgets->init(\%CONFIG);

  my $blog = H->new({
    base    => $CONFIG{base},
    widgets => $widgets,
    %$meta,
    %$storage,
  });
}

#_____________________________________________________________________________
package Rhetoric::Controllers;
use common::sense;
use aliased 'Squatting::H';
use Method::Signatures::Simple;
use Rhetoric::Helpers ':all';
use Data::Dump 'pp';
use MIME::Base64;
use Ouch;
use Try::Tiny;

sub authorized {
  my $self = shift;
  return undef unless defined $self->env->{HTTP_AUTHORIZATION};
  my $auth = $self->env->{HTTP_AUTHORIZATION};
  $auth =~ s/Basic\s*//;
  warn $auth;
  my $login_pass =  encode_base64("$CONFIG{login}:$CONFIG{password}", '');
  warn $login_pass;
  if ($auth eq $login_pass) {
    return 1;
  } else {
    return 0;
  }
}

our @C = (

  C(
    Home => [ '/', '/page/(\d+)' ],
    get => method($page) {
      my $v       = $self->v;
      my $storage = $self->env->storage;
      $page //= 1;
      ($v->{posts}, $v->{pager}) = $storage->posts($CONFIG{posts_per_page}, $page);
      $self->render('index');
    },
  ),

  C(
    Feed => [ '/feed' ],
    get => method {
      my $v = $self->v;
      my $storage = $self->env->storage;
      ($v->{posts}, $v->{pager}) = $storage->posts($CONFIG{posts_per_page}, 1);
      $self->render('index', 'AtomFeed');
    },
  ),

  C(
    Post => [ '/(\d+)/(\d+)/([\w-]+)' ],
    get => method($year, $month, $slug) {
      my $v          = $self->v;
      my $storage    = $self->env->storage;
      $v->{post}     = $storage->post($year, $month, $slug);
      $v->{comments} = $storage->comments($v->{post});
      $self->render('post');
    },
    post => method($year, $month, $slug) {
      my $v       = $self->v;
      my $storage = $self->env->storage;
      my $post    = $v->{post} = $storage->post($year, $month, $slug);
      # XXX - modify post and redirect
    }
  ),

  # XXX - replace with Rhetoric::Admin->squat('/admin')
  C(
    NewPost => [ '/admin' ],
    get => method {
      if (authorized($self)) {
        $self->render('new_post');
      } else {
        $self->status = 401;
        $self->headers->{'WWW-Authenticate'} = 'Basic realm="Secret"';
        "auth yourself";
      }
    },
    post => method {
      if (authorized($self)) {
        my $storage = $self->env->storage;
        my $input   = $self->input;
        try {
          $storage->new_post({
            title  => $input->title,
            body   => $input->body,
            format => $input->format,
          });
        }
        catch {
          if (kiss('InvalidPost', $_)) {
            $self->state->{errors} = $_->data;
          }
          else {
          }
        };
        $self->redirect(R('NewPost'));
      } else {
        $self->redirect(R('Home'));
      }
    },
  ),

  C(
    NewComment => [ '/comment' ],
    post => method {
      my $input   = $self->input;
      my $year    = $input->year;
      my $month   = $input->month;
      my $slug    = $input->slug;
      my $name    = $input->name;
      my $email   = $input->email;
      my $url     = $input->url;
      my $body    = $input->body;
      my $format  = $input->format // 'pod';
      my $storage = $self->env->storage;
      my $state   = $self->state;
      warn pp $state;

      $state->{name}    = $name;
      $state->{email}   = $email;
      $state->{url}     = $url;

      my $result;
      try {
        $result = $storage->new_comment($year, $month, $slug, {
          name   => $name,
          email  => $email,
          url    => $url,
          body   => $body,
          format => $format,
        });
      }
      catch {
        if (kiss('InvalidComment'),  $_) {
          $self->state->{errors} = $_->data;
        }
        else {
          warn $_;
        }
      };
      $self->redirect(R('Post', $year, $month, $slug));
    }
  ),

  C(
    Category => [ '/category/([\w-]+)' ],
    get => method($category) {
      my $v       = $self->v;
      my $storage = $self->env->storage;
      ($v->{posts}, $v->{pager}) = $storage->category_posts($category);
      $self->render('index');
    }
  ),

  C(
    Archive => [ '/archive/(\d+)/(\d+)' ],
    get => method($year, $month) {
      my $v       = $self->v;
      my $storage = $self->env->storage;
      ($v->{posts}, $v->{pager}) = $storage->archive_posts($year, $month);
      $self->render('index');
    }
  ),

  C(
    Env => [ '/env' ],
    get => method {
      use Data::Dump 'pp';
      $self->headers->{'Content-Type'} = 'text/plain';
      return pp($self->env);
    }
  ),

  C(
    Theme => [ '/t', '/t/(.*)' ],
    get => method($name) {
      if ($name) {
        $self->state->{theme} = $name;
      }
      return $self->env->{HTTP_HOST} . " => " . 
        ($self->state->{theme} // $CONFIG{theme}) . "\n";
    }
  ),

  # Everything else that's not static is a page to be rendered through the view.
  # This controller has to be last!
  C(
    Page => [ '/(.*)' ],
    get => method($path) {
      if ($path =~ /\.\./) {
        $self->status = 404;
        return "GTFO";
      }
      my $v = $self->v;
      $self->render($path);
    }
  ),

);

#_____________________________________________________________________________
package Rhetoric::Views;
use common::sense;
use Method::Signatures::Simple;
use Template;
use XML::Atom::Feed;
use XML::Atom::Entry;
use Module::Find;

*CONFIG = \%Rhetoric::CONFIG;

# Someday, there may be too many themes for the call to usesub to be practical.
# That would be a good problem to have.
our @themes = usesub('Rhetoric::Theme');

our @V = (

  (map { $_->view } @themes),

  V(
    'AtomFeed',

    _atom_id => method($post) {
      my $hostname = $CONFIG{hostname};
      sprintf('tag:%s,%d-%02d-%02d:%s',
        $hostname,
        $post->year, $post->month, $post->day,
        R('Post', $post->year, $post->month, $post->slug)
      );
    },

    _link => method($post) {
      my $link     = XML::Atom::Link->new();
      my $hostname = $CONFIG{hostname};
      $link->type('text/html');
      $link->rel('alternate');
      $link->href(sprintf(
        'http://%s%s',
        $hostname,
        R('Post', $post->year, $post->month, $post->slug)
      ));
      $link;
    },

    index => method($v) {
      my $feed     = XML::Atom::Feed->new();
      my $hostname = $CONFIG{hostname};
      my $since    = $CONFIG{since};
      $feed->id(sprintf('tag:%s,%d:feed-id', $hostname, $since));
      for my $post (@{ $v->posts }) {
        my $entry = XML::Atom::Entry->new();
        $entry->id($self->_atom_id($post));
        $entry->add_link($self->_link($post));
        $entry->title($post->title);
        $entry->content($post->body);
        $feed->add_entry($entry);
      }
      $feed->as_xml;
    }

  ),

);

sub init {
  my $i = 0;
  for my $name (@themes) {
    $name =~ s/^.*::(\w*)$/$1/;
    $V[$i]->_init([ "$CONFIG{'base'}/pages", "$CONFIG{'theme.base'}/$name" ]);
    $i++;
  }
}

1;

=head1 NAME

Rhetoric - a simple blogging system for perl

=head1 SYNOPSIS

Setting up a blog

  mkdir -p /var/www/myblog.org
  cd /var/www/myblog.org
  rh init

Running the blog

  plackup rhetoric.psgi

=head1 DESCRIPTION

Rhetoric is a simple CPAN-friendly blogging system for Perl.

It's simple because...

It's CPAN-friendly because:

=over 4

=item * You can install it from CPAN and setup a blog in minutes.

=item * Themes can also be installed from CPAN.

=back

=head1 API

=head2 Home

/

/page/(\d+)

=head3 get


=head2 Post

/(\d+)/(\d+)/(\w+)

=head3 get



=head2 NewPost

/post

=head3 get

=head3 post



=head2 Comment

/comment

=head3 post



=head2 Category

/category/(\w+)

=head3 get



=head2 Archive

/archive/(\d+)/(\d+)

=head3 get



=head2 Page

/(.*)

=head3 get



=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>


=head1 COPYRIGHT

MIT

=cut
