package Mojar::Config::Ini;
use Mojar::Config -base;

our $VERSION = 0.031;
# Adapted from Mojolicious::Plugin::Config (3.57)

use Carp 'croak';
use Mojo::Util 'decode';

sub parse {
  my ($self, $content_ref, %param) = @_;
  $param{sections} //= ':all';
  croak 'Unrecognised sections spec'
    unless ref $param{sections} eq 'ARRAY'
        or $param{sections} eq ':all' or $param{sections} eq ':ignore';

  return {} unless $$content_ref;

  my $config = {};
  my $section = '_';
  while ($$content_ref =~ /^(.*)$/gm) {
    $_ = $1;
    next unless /\S/;  # blank line
    next if /^\s*#/;  # comment line
    $section = $1, $config->{$section} = {}, next
      if /^\s*\[([^\]]+)\]/;  # section header
    if (/^\s*([\w-]+)\s+=\s+(\S.*?)\s*$/) {
      if ($param{sections} eq ':ignore') {
        $config->{$1} = $2;
      }
      else {
        $config->{$section}{$1} = $2;
      }
    }
    else {
      croak qq{Failed to parse configuration line ($_)} if !$config && $@;
    }
  }

  if (ref $param{sections} eq 'ARRAY') {
    my $cfg = {};
    %$cfg = (%$cfg, %{$config->{$_} // {}}) for @{$param{sections}};
    return $cfg;
  }
  return $config;
}

1;
__END__

=head1 NAME

Mojar::Config::Ini - Ini-style configuration utility for standalone code

=head1 SYNOPSIS

  use Mojar::Config::Ini;
  my $config = Mojar::Config::Ini->load('cfg/defaults.ini');
  say $config->{redis}{ip};

=head1 DESCRIPTION

A simple configuration file reader for a configuration written as an ini file.
Although fairly primitive (essentially everything is a line-bounded string) it
is a widespread format.

=head1 USAGE

  # cfg/defaults.ini
  debug = 0
  # Comment
  # Records without section are treated as section "_"
  expiration = 36000
  confession = very basic format, but widely used
  secrets = "where,wild,things,roam"
  port = 8000

  [redis]
  ip = 192.168.1.1
  port = 6379

Each line is read separately.  Whitespace following the (first) "=" is ignored,
as is any whitespace at the end of the line.  In the case of duplicates, later
records overwrite earlier records.

=head1 METHODS

=head2 load

  $hashref = Mojar::Config->load('path/to/file.cnf');
  $hashref = Mojar::Config->load('path/to/file.cnf', log => $log);

Loads an ini-style configuration from the given file path.  In normal usage,
this is the only method required.  The result is a plain (unblessed) hashref.

=head2 parse

  $content = 'testing = 4';
  $config = Mojar::Config::Ini->parse(\$content, sections => ':ignore');
  say $config->{testing};

Does the actual parsing of the configuration, being passed a ref to the
configuration text.

=head1 PARAMETERS

Both the C<load> and C<parse> methods accept a C<sections> parameter.

=head2 sections

Specifies how to handle sections within the configuration file.  Records with no
section are treated as if given the section C<_>.  The default is C<:all> which
loads each section into its individual hash key.

  ->load('cfg/defaults.ini', sections => ':all');  # load configuration
  # The config hashref has two keys, with constituent keys below those
  # ->{_}{debug} is 0
  # ->{redis}{port} is 6379

A section spec of ':ignore' loads each record into a unified configuration, as
if the section headings were omitted.  Beware any duplicates, later records
overwrite earlier records.

  ->load('cfg/defaults.ini', sections => ':ignore');  # load configuration
  # The config hashref has seven keys in a flat structure
  # ->{debug} is 0
  # ->{port} is 6379

A section spec of an arrayref of section names loads each record into a unified
configuration, absorbing the sections in the order specified.

  ->load('cfg/defaults.ini', sections => [qw(redis _)]);  # load configuration
  # The config hashref has seven keys in a flat structure
  # ->{debug} is 0
  # ->{port} is 8000

Whenever practical, order your configuration file sections starting with the
most general (eg 'client') and ending with the most specific (eg 'mysqldump').
That leads to a more intuitive order when loading sections; you load your
selected sections in the same order.

=head1 DEBUGGING

Both methods accept a Mojar::Log/Mojo::Log object in their parameters.  If
passed a debug-level logger, some debugging statements become available.

  my $log = Mojar::Log->new(level => 'debug', path => '/tmp/stuff.log');
  my $config = Mojar::Config->new->load('/etc/stuff.conf', log => $log);

=head1 RATIONALE

There are many modules for tackling these files, but although the format is
simple, how it should be handled is not.  The key motivator for this module is
the C<sections> parameter and its application to MySQL configuration/credentials
files.  If your software is functioning as a mysql-client, it should load from
my.cnf using C<sections => [qw(client mysql)]>, and similarly when it loads from
a .cnf credentials file.  You can add custom sections to such files, so you
could end up using, for example, C<sections => [qw(client datafeed)]>.

=head1 SEE ALSO

L<Mojar::Config>, L<Mojolicious::Plugin::Config>.
