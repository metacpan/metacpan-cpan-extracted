package Mojolicious::Plugin::Config::Structured::Command::config_dump 3.01;
use v5.26;
use warnings;

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Config::Structured::Command::config_dump - dump a Config::Structured configuration to text

=head1 SYNOPSIS

  Dump a Config::Structured configuration to text
  Usage: <APP> config-dump [--verbose] [--depth n] [--path str] [--reveal-sensitive]

  Options:
    --verbose             display all node metadata instead of just the value
    --depth n             truncate/ignore nodes below depth n (relative to real root, not --path)
    --path str            display only config nodes from str down
    --reveal-sensitive    do not obscure sensitive values in output

=head1 DESCRIPTION

C<config_dump> is a utility for displaying a L<Config::Structured> config that 
has been loaded into Mojolicious as formatted text

In its default mode, it displays each node name and the associated value. With
the L<--verbose|/verbose> flag, though, all node metadata is output, including
description, examples, notes, and where the configured value came from.

=head1 OPTIONS

=head2 verbose

Display complete node metadata instead of just node names and values. All 
supported L<Config::Structured> node metadata keys and values are included.

=head2 path
 
Begin the output at the specified configuration path, ignoring configuration
nodes above/outside that point

=head2 depth

End the output at the specified configuration depth (relative to the original 
root node -- does not regard L<--path|/path>), ignoring configuration nodes
below that point

=head2 reveal-sensitive

By default, configured values for any nodes marked C<sensitive> are obscured and
replaced by a string of asterisks. Use this option to show the actual values for
these nodes

=cut

use Mojo::Base 'Mojolicious::Command';
use Getopt::Long qw(GetOptionsFromArray);

use JSON         qw(encode_json);
use List::Util   qw(max);
use Scalar::Util qw(looks_like_number);
use Syntax::Keyword::Try;
use Term::ANSIColor;

use experimental qw(signatures);

has description => 'Display Config::Structured configuration';
has usage       => sub ($self) {$self->extract_usage};

my sub resolve_path($conf, $path) {
  my @path = split(q{/}, $path);
  shift(@path);
  my $node_name = pop(@path);
  return $conf unless ($node_name);
  try {
    $conf = $conf->$_ foreach (@path);
    return ($conf, $node_name) if ($conf->get_node($node_name));
  } catch ($e) {
  }
  die("'$path' is not a valid configuration path\n");
}

my sub stringify_value($value) {
  return 'undef' unless (defined($value));
  return encode_json($value) if (ref($value));
  return $value              if (looks_like_number($value));
  return qq{"$value"};
}

my sub is_branch($node) {
  return eval {$node->isa('Config::Structured::Node')}    # pre-5.32 safe "isa" check
}

my sub dump_node($conf, %params) {
  my ($name, $allow_sensitive, $depth, $max_depth) = @params{qw(node sensitive depth max_depth)};
  $depth //= 0;
  my $at_limit = defined($max_depth) && $depth >= $max_depth;
  my $indent   = '  ' x $depth;

  if (defined($name)) {
    say stringify_value($conf->$name($allow_sensitive)) and return unless (is_branch($conf->$name));
    $conf = $conf->$name;
  }

  my $m = (max map {length} ($conf->get_node->{leaves}->@*, $conf->get_node->{branches}->@*)) // 0;
  foreach (sort($conf->get_node->{leaves}->@*)) {
    printf("%s%-${m}s%s%s\n", $indent, $_, ' => ', stringify_value($conf->$_($allow_sensitive)));
  }
  foreach (sort($conf->get_node->{branches}->@*)) {
    printf("%s%-${m}s%s%s\n", $indent, $_, ' =>', $at_limit ? ' {...}' : '');
    __SUB__->($conf->$_, max_depth => $max_depth, depth => $depth + 1, sensitive => $allow_sensitive) unless ($at_limit);
  }
}

my sub fv($label, $value = '') {
  printf("  %-12s%s\n", $label . ':', $value);
}

my sub dump_node_verbose($conf, %params) {
  my ($name, $allow_sensitive, $depth, $max_depth) = @params{qw(node sensitive depth max_depth)};
  $depth //= 0;
  my $at_limit = defined($max_depth) && $depth >= $max_depth;

  if (!defined($name)) {
    return if (defined($max_depth) && $max_depth < $depth);
    __SUB__->($conf, sensitive => $allow_sensitive, depth => $depth + 1, max_depth => $max_depth, node => $_)
      foreach (sort $conf->get_node->{leaves}->@*);
    __SUB__->($conf->$_, sensitive => $allow_sensitive, depth => $depth + 1, max_depth => $max_depth)
      foreach (sort $conf->get_node->{branches}->@*);
  } elsif (is_branch($conf->$name)) {
    __SUB__->($conf->$name, sensitive => $allow_sensitive, depth => $depth + 1, max_depth => $max_depth);
  } else {
    my $node = $conf->get_node($name, $allow_sensitive);
    my @fmt;
    push(@fmt, qw(red)) if (!defined($node->{value}));
    push(@fmt, qw(italic)) unless ($node->{overridden});
    @fmt = qw(reset) unless (@fmt);

    say colored([qw(clear)], $node->{path});
    say "  " . colored([qw(faint)], $node->{description}) if ($node->{description});
    if ($node->{notes}) {
      my @lines = split("\n", $node->{notes});
      say colored([qw(faint)], '  | ') . colored([qw(faint italic)], $_) foreach (@lines);
    }
    fv('Type',      $node->{isa});
    fv('Sensitive', colored([qw(green)],     'Y'))                               if ($node->{sensitive});
    fv('URL',       colored([qw(underline)], $node->{url}))                      if ($node->{url});
    fv('Default',   colored([qw(italic)],    stringify_value($node->{default}))) if ($node->{default});
    fv('Ref<' . ucfirst($node->{reference}->{source}) . '>', $node->{reference}->{ref}) if ($node->{reference});
    fv('Value',                                              colored([@fmt], stringify_value($node->{value})));
    if ($node->{examples}) {
      fv('Examples');
      say "    " . stringify_value($_) foreach (ref($node->{examples}) eq 'ARRAY') ? $node->{examples}->@* : ($node->{examples});
    }
    say "";
  }
}

sub run ($self, @args) {
  my ($dump_node, $depth, $path, $sensitive) = (\&dump_node, undef, '/', 0);
  GetOptionsFromArray(
    \@args,
    'verbose'          => sub($n, $v) {$dump_node = \&dump_node_verbose},
    'depth=i'          => sub($n, $v) {$depth     = $v - 1},
    'path=s'           => \$path,
    'reveal-sensitive' => \$sensitive,
  );
  my ($conf, $node_name) = resolve_path($self->app->conf, $path);
  $dump_node->($conf, node => $node_name, max_depth => $depth, sensitive => $sensitive);
}

=pod

=head1 EXAMPLES

Standard:

    /app$ script/myapp config-dump
    secrets => "************"
    db      =>
      dsn       => "dbi:mysql:host=mydb;port=3306;database=myapp_dev"
      pass      => "************"
      user      => "myapp_user"
      migration =>
        directory => "/schema"
        pass      => "************"
        registry  => "sqitch_myapp_dev"
        user      => "sqitch"

At path:

    /app$ script/myapp config-dump --path /db/migration
    directory => "/schema"
    pass      => "************"
    registry  => "sqitch_myapp_dev"
    user      => "sqitch"

With depth limit:

    /app$ script/myapp config-dump --path /db --depth 1
    dsn       => "dbi:mysql:host=mydb;port=3306;database=myapp_dev"
    pass      => "************"
    user      => "myapp_user"
    migration => {...}

Without sensitive obscurement:

    /app$ script/myapp config-dump --path /db --depth 1 --reveal-sensitive
    dsn       => "dbi:mysql:host=mydb;port=3306;database=myapp_dev"
    pass      => "&xyus7#^kP**6Eeo9Yht6fU"
    user      => "devapps"
    migration => {...}

Verbose:

    /app$ script/myapp config-dump --verbose
    /secrets
      private key to encrypt session data with
      Type:       ArrayRef[Str]
      Sensitive:  Y
      Default:    ["not-very-secret"]
      Value:      "************"

    /db/dsn
      Data Source Name for the database connection
      Type:       Str
      URL:        https://en.wikipedia.org/wiki/Data_source_name
      Default:    "dbi:mysql:host=localhost;port=3306;database=myapp"
      Value:      "dbi:mysql:host=mydb;port=3306;database=myapp_dev"

    /db/pass
      database connection password
      | Often passed as a file or ENV for security
      Type:       Str
      Sensitive:  Y
      Ref<File>:  /run/secrets/app_db_password
      Value:      "************"

    /db/user
      database connection username
      Type:       Str
      Default:    "app_user"
      Value:      "myapp_user"

    /db/migration/directory
      location of schema migration files
      Type:       Str
      Default:    "/schema"
      Value:      "/schema"

    /db/migration/pass
      database connection password for migrations
      | Often passed as a file or ENV for security
      Type:       Str
      Sensitive:  Y
      Ref<File>:  /run/secrets/sqitch_password
      Value:      "************"
    ...

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
