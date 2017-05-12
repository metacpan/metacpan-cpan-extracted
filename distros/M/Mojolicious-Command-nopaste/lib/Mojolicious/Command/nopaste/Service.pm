package Mojolicious::Command::nopaste::Service;
use Mojo::Base 'Mojolicious::Command';

use Mojo::UserAgent;
use Mojo::Util qw/decode monkey_patch/;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case); # no_auto_abbrev

our $USAGE = <<END;
USAGE:

  $0 command SERVICE [OPTIONS] [FILES]

OPTIONS:
  Note that not all options are relevant for all services.

  --channel, -c       The channel for the service's pastebot or to post via Mojo::IRC
                          e.g. perl, #perl, irc://irc.perl.org:6667/perl
  --copy, -x          Copy the resulting URL to the clipboard (requires Clipboard.pm)
  --description, -d   Description or title of the nopaste
  --name, -n          Your name or nick, used for the pastebin and/or IRC
  --language, -l      Language for syntax highlighting, defaults to 'perl'
  --open, -o          Open a browser to the url (requires Browser::Open)
  --paste, -p         Read contents from clipboard (requires Clipboard.pm)
  --private, -P       Mark the paste as private (note: silently ignored if not relevant for service)
  --token, -t         A file containing an access token, or else the token string itself
  --update, -u        Update a paste of a given id

END

has usage => sub {
  my $self = shift; 
  my $usage = $USAGE;
  if (my $add = $self->service_usage) {
    $usage .= "\n$add";
  }
  return $usage;
};

has [qw/channel name desc service_usage token update/];
has [qw/copy open private irc_handled/] => 0;
has clip => sub { 
  die "Clipboard module not available. Do you need to install it?\n"
    unless eval 'use Clipboard; 1';
  monkey_patch 'Clipboard::Xclip',
    copy  => \&_xclip_copy,
    paste => \&_xclip_paste;
  return 'Clipboard';
};
has files    => sub { [] };
has language => 'perl';
has text     => sub { shift->slurp };
has ua       => sub { Mojo::UserAgent->new->max_redirects(10) };

sub run {
  my ($self, @args) = @_;
  GetOptionsFromArray( \@args,
    'channel|c=s'     => sub { $self->channel($_[1])           },
    'copy|x'          => sub { $self->copy($_[1])              },
    'description|d=s' => sub { $self->desc($_[1])              },
    'name|n=s'        => sub { $self->name($_[1])              },
    'language|l=s'    => sub { $self->language($_[1])          },
    'open|o'          => sub { $self->open($_[1])              },
    'paste|p'         => sub { $self->text($self->clip->paste) },
    'private|P'       => sub { $self->private($_[1])           },
    'token|t=s'       => sub { $self->add_token($_[1])         },
    'update|u=s'      => sub { $self->update($_[1])            },
  );
  $self->files(\@args);
  my $url = $self->paste or return;
  say $url;
  $self->clip->copy($url) if $self->copy;
  if ($self->open) {
    die "Browser::Open module not available. Do you need to install it?\n"
      unless eval { require Browser::Open; 1 };
    Browser::Open::open_browser($url);
  }
  if ($self->channel and not $self->irc_handled) {
    $self->post_to_irc($url);
  }
}

sub add_token {
  my ($self, $token) = @_;
  if (-e $token) {
    $token = $self->slurp($token);
  }
  chomp $token;
  $self->token($token);
}

sub paste { die 'Not implemented' }

sub slurp { 
  my ($self, @files) = @_;
  @files = @{ $self->files } unless @files;

  my $content = do {
    local $/;
    local @ARGV = @files;
    decode 'UTF-8', <>;
  };

  # Remove trailing newline as some sites won't do it for us
  chomp $content;
  return $content;
}

sub post_to_irc {
  my ($self, $paste) = @_;
  die "This service requires Mojo::IRC to post to IRC, but it is not available. Do you need to install it?\n"
    unless eval { require Mojo::IRC; 1 };
  require Mojo::IOLoop;
  require Mojo::URL;

  my $url = Mojo::URL->new($self->channel);
  my $chan = $url->fragment || $url->path->[-1];
  die "Could not parse IRC channel\n" unless $chan;
  my $server = $url->host_port || 'irc.perl.org:6667';
  my $irc = Mojo::IRC->new(server => $server, nick => 'MojoNoPaste', user => 'MojoNoPaste');
  $irc->register_default_event_handlers;

  my $name = $self->name || 'someone';

  my $err;
  my $catch = sub { $err = $_[1]; Mojo::IOLoop->stop };
  $irc->on(error     => $catch);
  $irc->on(irc_error => $catch);

  $irc->on(irc_join => sub {
    my ($irc, $message) = @_;
    my $chan = $message->{params}[0];
    my $delay = Mojo::IOLoop->delay(
      sub { $irc->write( privmsg => $chan, ":$name pasted $paste", shift->begin ) },
      sub { $irc->disconnect( shift->begin ) },
      sub { Mojo::IOLoop->stop }, 
    );
    $delay->on(error => $catch);
  });

  $irc->connect(sub{
    my ($irc, $err) = @_;
    die $err if $err;
    say 'Connected to IRC';
    $irc->write(join => "#$chan");
  });

  Mojo::IOLoop->start;
  
  die $err if $err;
}

sub _xclip_copy {
  my ($self, $input) = @_;
  eval { $self->copy_to_selection($_, $input) } for $self->all_selections();
}

sub _xclip_paste {
  my $self = shift;
  my $data;
  for my $sel ($self->all_selections) {
    $data = eval { $self->paste_from_selection($sel) };
    last if $data;
  }
  return decode 'UTF-8', $data || '';
}

1;

