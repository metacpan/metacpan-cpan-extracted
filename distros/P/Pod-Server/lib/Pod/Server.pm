package Pod::Server;
use strict;
use warnings;
use Squatting;
use File::Which;
our $VERSION = '1.14';
$| = 1;

my $vim = which('vim');

our %CONFIG = (
  background_color          => '#112',
  foreground_color          => 'wheat',
  pre_background_color      => '#000',
  pre_foreground_color      => '#ccd',
  code_foreground_color     => '#fff',
  a_foreground_color        => '#fc4',
  a_hover_foreground_color  => '#fe8',
  font_size                 => '10pt',
  sidebar                   => 'right',
  first                     => 'Squatting',
  title                     => '#',
  tree                      => [],
  vim                       => $vim,
  vim_comment               => '#0cf',
  vim_constant              => '#0fc',
  vim_identifier            => '#0aa',
  vim_statement             => '#fc2',
  vim_preproc               => '#8fc',
  vim_type                  => '#2e8b57',
  vim_special               => '#6a5acd',
  vim_underlined            => '#fff',
  vim_error_bg              => '#f00',
  vim_error_fg              => '#fff',
  vim_todo_bg               => '#fc2',
  vim_todo_fg               => '#222',
);

sub init {
  my $app = shift;
  Pod::Server::Controllers::scan();
  my $have_vim = eval { require Text::VimColor };
  if (not $have_vim) {
    $CONFIG{vim} = undef;
  }
  $app->next::method;
}

package Pod::Server::Controllers;
use strict;
use warnings;
use File::Basename;
use File::Find;
use File::Which;
use Config;
use aliased 'Pod::Simple::Search';
use aliased 'Squatting::H';

# skip files we've already seen
my %already_seen;

# figure out where all(?) our pod is located
# (loosely based on zsh's _perl_basepods and _perl_modules)
our %perl_basepods;

our %perl_programs;
our @perl_programs;

our %perl_modules;
our @perl_modules;
sub scan {
  no warnings;
  warn "scanning for POD...\n";

  if ($Config{man1ext} ne "1") {
    %perl_programs = map {
      my ($file, $path, $suffix) = fileparse($_, qr/\.$Config{man1ext}.*$/);
      $already_seen{$_} = 1;
      ("$file" => which($file) || $_);
    } ( 
      glob("$Config{installman1dir}/*.$Config{man1ext}*"),
      glob("$Config{installsiteman1dir}/*.$Config{man1ext}*"),
      glob("$Config{installvendorman1dir}/*.$Config{man1ext}*")
    );
  }

  my $search = Search->new;
  $search->limit_glob('*');
  $search->progress(H->new({
    reach => sub {
      print ".";
    },
    done => sub {
      print "\n";
    },
  }));

  my $survey;
  if (scalar(@{$CONFIG{tree}})) {
    $search->inc(0);
    $survey = $search->survey(@{$CONFIG{tree}});
  }
  else {
    $survey = $search->survey;
  }

  for (keys %$survey) {
    my $key = $_;
    $key =~ s/::/\//g;
    $perl_modules{$key} = $survey->{$_};
  }
  @perl_modules  = sort keys %perl_modules;
  @perl_programs = sort keys %perl_programs;
}
%already_seen = ();

# *.pod takes precedence over *.pm
sub pod_for {
  for ($_[0]) {
    return $_ if /\.pod$/;
    my $pod = $_;
    $pod =~ s/\.pm$/\.pod/;
    if (-e $pod) {
      return $pod;
    }
    return $_;
  }
}

# *.pm takes precedence over *.pod
sub code_for {
  for ($_[0]) {
    return $_ if /\.pm$/;
    my $pm = $_;
    $pm =~ s/\.pod$/\.pm/;
    if (-e $pm) {
      return $pm;
    }
    return $_;
  }
}

# cat out a file
sub cat {
  my $file = shift;
  open(CAT, $file) || return;
  return join('', <CAT>);
}

our @C = (

  C(
    Home => [ '/' ],
    get  => sub {
      my ($self) = @_;
      $self->v->{title} = $Pod::Server::CONFIG{title};
      if (defined $self->input->{base}) {
        $self->v->{base} = 'pod';
      }
      $self->render('home');
    }
  ),

  C(
    Frames => [ '/@frames' ],
    get    => sub {
      my ($self) = @_;
      $self->v->{title} = $Pod::Server::CONFIG{title};
      $self->render('_frames');
    }
  ),

  C(
    Rescan => [ '/@rescan' ],
    get => sub {
      my ($self) = @_;
      $Pod::Server::Views::HOME = undef;
      %already_seen  = ();
      %perl_basepods = ();
      %perl_programs = ();
      @perl_programs = ();
      %perl_modules  = ();
      @perl_modules  = ();
      scan();
      "OK";
    }
  ),

  C(
    Source => [ '/@source/(.*)' ],
    get => sub {
      my ($self, $module) = @_;
      my $v = $self->v;
      my $pm = $module; $pm =~ s{/}{::}g;
      my $pm_file;
      $v->{path} = [ split('/', $module) ];
      $v->{title} = "$Pod::Server::CONFIG{title} - $pm";
      if (exists $perl_modules{$module}) {
        $v->{file} = code_for $perl_modules{$module};
        if ($Pod::Server::CONFIG{vim}) {
          my $vim    = Text::VimColor->new(file => $v->{file});
          $v->{code} = $vim->html;
        } else {
          $v->{code} = cat $v->{file};
        }
        $self->render('source');
      } elsif (exists $perl_basepods{$module}) {
        $v->{file} = code_for $perl_basepods{$module};
        if ($Pod::Server::CONFIG{vim}) {
          my $vim    = Text::VimColor->new(file => $v->{file});
          $v->{code} = $vim->html
        } else {
          $v->{code} = cat $v->{file};
        }
        $self->render('source');
      } elsif (exists $perl_programs{$module}) {
        $v->{file} = $perl_programs{$module};
        if ($Pod::Server::CONFIG{vim}) {
          my $vim    = Text::VimColor->new(file => $v->{file});
          $v->{code} = $vim->html
        } else {
          $v->{code} = cat $v->{file};
        }
        $self->render('source');
      } else {
        $self->render('pod_not_found');
      }
    }
  ),

  # The job of this controller is to take $module
  # and find the file that contains the POD for it.
  # Then it asks the view to turn the POD into HTML.
  C(
    Pod => [ '/(.*)' ],
    get => sub {
      my ($self, $module) = @_;
      my $v        = $self->v;
      my $pm       = $module; $pm =~ s{/}{::}g;
      $v->{path}   = [ split('/', $module) ];
      $v->{module} = $module;
      $v->{pm}     = $pm;
      if (exists $perl_modules{$module}) {
        $v->{pod_file} = pod_for $perl_modules{$module};
        $v->{title} = "$Pod::Server::CONFIG{title} - $pm";
        $self->render('pod');
      } elsif (exists $perl_basepods{$module}) {
        $v->{pod_file} = pod_for $perl_basepods{$module};
        $v->{title} = "$Pod::Server::CONFIG{title} - $pm";
        $self->render('pod');
      } elsif (exists $perl_programs{$module}) {
        $v->{pod_file} = $perl_programs{$module};
        $v->{title} = "$Pod::Server::CONFIG{title} - $pm";
        $self->render('pod');
      } else {
        $v->{title} = "$Pod::Server::CONFIG{title} - $pm";
        $self->render('pod_not_found');
      }
    }
  ),

);

package Pod::Server::Views;
use strict;
use warnings;
use Data::Dump 'pp';
use HTML::AsSubs;
use Pod::Simple;
use Pod::Simple::HTML;
$Pod::Simple::HTML::Perldoc_URL_Prefix = '/';

# the ~literal pseudo-element -- don't entity escape this content
sub x {
  HTML::Element->new('~literal', text => $_[0])
}

our $JS;
our $HOME;
our $C = \%Pod::Server::CONFIG;

our @V = (
  V(
    'html',

    layout => sub {
      my ($self, $v, @content) = @_;
      html(
        head(
          title($v->{title}),
          style(x($self->_css)),
          (
            $v->{base} 
              ? base({ target => $v->{base} })
              : ()
          ),
        ),
        body(
          div({ id => 'menu' },
            a({ href => R('Home')}, "Home"), ($self->_breadcrumbs($v))
          ),
          div({ id => 'pod' }, @content),
        ),
      )->as_HTML;
    },

    _breadcrumbs => sub {
      my ($self, $v) = @_;
      my @breadcrumb;
      my @path;
      for (@{$v->{path}}) {
        push @path, $_;
        push @breadcrumb, a({ href => R('Pod', join('/', @path)) }, " > $_ ");
      }
      @breadcrumb;
    },

    _css => sub {qq|
      body {
        background: $C->{background_color};
        color: $C->{foreground_color};
        font-family: 'Trebuchet MS', sans-serif;
        font-size: $C->{font_size};
      }
      h1, h2, h3, h4 {
        margin-left: -1em;
        margin-bottom: 4px;
      }
      dl {
        margin: 0;
        padding: 0;
      }
      dt {
        margin: 1em 0 1em 1em;
      }
      dd {
        margin: -0.75em 0 0 2em;
        padding: 0;
      }
      em {
        padding: 0.25em;
        font-weight: bold;
      }
      pre {
        font-size: 9pt;
        font-family: "DejaVu Sans Mono", "Bitstream Vera Sans Mono", monospace;
        background: $C->{pre_background_color};
        color: $C->{pre_foreground_color};
      }
      code {
        font-size: 9pt;
        font-weight: bold;
        color: $C->{code_foreground_color};
      }
      a {
        color: $C->{a_foreground_color};
        text-decoration: none;
      }
      a:hover {
        color: $C->{a_hover_foreground_color};
      }
      div#menu {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        background: #000;
        color: #fff;
        opacity: 0.75;
      }
      ul#list {
        margin-left: -6em;
        list-style: none;
      }
      div#pod {
        width: 580px;
        margin: 2em 4em 2em 4em;
      }
      div#pod pre {
        padding: 0.5em;
        border: 1px solid #444;
        border-radius: 7px;
      }
      div#pod h1 {
        font-size: 24pt;
        border-bottom: 2px solid $C->{a_hover_foreground_color};
      }
      div#pod p {
        margin: 0.75em 0 1em 0;
        line-height: 1.4em;
      }
    |},

    home => sub {
      my ($self, $v) = @_;
      $HOME ||= div(
        a({ href => R('Home'),   target => '_top' }, "no frames"),
        em(" | "),
        a({ href => R('Frames'), target => '_top' }, "frames"),
        ul({ id => 'list' },
          li(em(">> Modules <<")),
          (
            map {
              my $pm = $_;
              $pm =~ s{/}{::}g;
              li(
                a({ href => R('Pod', $_) }, $pm )
              )
            } (sort @perl_modules)
          ),
          li(em(">> Executables <<")),
          (
            map {
              li(
                a({ href => R('Pod', $_) }, $_ )
              )
            } (sort @perl_programs),
          )
        )
      );
    },

    _frames => sub {
      my ($self, $v) = @_;
      html(
        head(
          title($v->{title})
        ),
        ($C->{sidebar} eq "right" 
          ?
          frameset({ cols => '*,340' },
            frame({ name => 'pod',  src => R('Pod', $C->{first}) }),
            frame({ name => 'list', src => R('Home', { base => 'pod' }) }),
          )
          :
          frameset({ cols => '340,*' },
            frame({ name => 'list', src => R('Home', { base => 'pod' }) }),
            frame({ name => 'pod',  src => R('Pod', $C->{first}) }),
          )
        ),
      )->as_HTML;
    },

    pod => sub {
      my ($self, $v) = @_;
      my $out;
      my $pod = Pod::Simple::HTML->new;
      $pod->index(1);
      $pod->output_string(\$out);
      $pod->parse_file($v->{pod_file});
      $out =~ s/^.*<!-- start doc -->//s;
      $out =~ s/<!-- end doc -->.*$//s;
      $out =~ s/^(.*%3A%3A.*)$/my $x = $1; ($x =~ m{indexItem}) ? 1 : $x =~ s{%3A%3A}{\/}g; $x/gme;
      (
        x($out), 
        $self->_possibilities($v),
        $self->_source($v),
      );
    },

    pod_not_found => sub {
      my ($self, $v) = @_;
      div(
        p("POD for $v->{pm} not found."),
        $self->_possibilities($v)
      )
    },

    _possibilities => sub {
      my ($self, $v) = @_;
      my @possibilities = grep { /^$v->{module}/ } @perl_modules;
      @possibilities    = grep { /^$v->{module}/ } @perl_programs if(not(@possibilities));
      my $colon = sub { my $x = shift; $x =~ s{/}{::}g; $x };
      hr,
      ul(
        map {
          li(
            a({ href => R('Pod', $_) }, $colon->($_))
          )
        } @possibilities
      );
    },

    _source => sub {
      my ($self, $v) = @_;
      hr,
      h4(a({ href => R('Source', $v->{module} )}, 
        "Source Code for " . 
        Pod::Server::Controllers::code_for($v->{pod_file}) 
      ));
    },

    _vim_syntax_css => sub {qq|
      .synComment    { color: $C->{vim_comment} }
      .synConstant   { color: $C->{vim_constant} }
      .synIdentifier { color: $C->{vim_identifier} }
      .synStatement  { color: $C->{vim_statement}  ; font-weight: bold; }
      .synPreProc    { color: $C->{vim_preproc} }
      .synType       { color: $C->{vim_type}       ; font-weight: bold; }
      .synSpecial    { color: $C->{vim_special} }
      .synUnderlined { color: $C->{vim_underlined} ; text-decoration: underline; }
      .synError      { color: $C->{vim_error_fg}   ; background: $C->{vim_error_bg}; }
      .synTodo       { color: $C->{vim_todo_fg}    ; background: $C->{vim_todo_bg};  }
    |},

    source => sub {
      my ($self, $v) = @_;
      style("div#pod { width: auto; }"), 
      ($C->{vim}
        ?
        ( style(x($self->_vim_syntax_css)), 
          pre(x($v->{code})) )
        :
        ( pre($v->{code}) )
      )
    },

  )
);

1;

__END__

=head1 NAME

Pod::Server - a web server for locally installed perl documentation

=head1 SYNOPSIS

Usage for the pod_server script:

  pod_server [OPTION]...

Examples:

  pod_server --help

  pod_server -bg '#301'

Then, in your browser, visit:

  http://localhost:8088/

How to start up a Continuity-based server manually (via code):

  use Pod::Server 'On::Continuity';
  Pod::Server->init;
  Pod::Server->continue(port => 8088);

How to embed Pod::Server into a Catalyst app:

  use Pod::Server 'On::Catalyst';
  Pod::Server->init;
  Pod::Server->relocate('/pod');
  $Pod::Simple::HTML::Perldoc_URL_Prefix = '/pod/';
  sub pod : Local { Pod::Server->catalyze($_[1]) }

=head1 DESCRIPTION

In the Ruby world, there is a utility called C<gem_server> which starts up a
little web server that serves documentation for all the locally installed
RubyGems.  When I was coding in Ruby, I found it really useful to know what
gems I had installed and how to use their various APIs.

B<"Why didn't Perl have anything like this?">

Well, apparently it did.  If I had searched through CPAN, I might have found
L<Pod::Webserver> which does the same thing this module does.  After more
searching, I might have discovered L<Pod::POM::Web>.  And then just recently,
L<Pod::Browser> was uploaded to CPAN.  (It's getting kinda crowded here.)

However, I didn't know any of this at the time, so I ended up writing this
module.  At first, its only purpose was to serve as an example L<Squatting>
app, but it felt useful enough to spin off into its own perl module
distribution.

I have no regrets about duplicating effort or reinventing the wheel, because
Pod::Server has a lot of nice little features that aid usability and readability.
It is also quite configurable.  To see all the options run any of the following:

  pod_server -h

  squatting Pod::Server --show-config

  squatting Pod::Server --show-config | perltidy -i 4


=head1 API

=head2 Home

=head3 get

=head2 Rescan

=head3 get

=head2 Frames

=head3 get

=head2 Source

=head3 get

=head2 Pod

=head3 get


=head1 SEE ALSO

L<Squatting>, L<Continuity>, L<Pod::Webserver>, L<Pod::POM::Web>,
L<Pod::Browser>

=head2 Pod::Server Source Code

The source code is available at:

L<http://github.com/beppu/pod-server/tree/master>

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 John BEPPU E<lt>beppu@cpan.orgE<gt>.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
