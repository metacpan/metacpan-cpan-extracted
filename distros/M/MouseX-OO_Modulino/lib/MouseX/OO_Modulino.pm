#!/usr/bin/env perl
package MouseX::OO_Modulino;
use MouseX::OO_Modulino::MOP4Import -as_base;

our $VERSION = '0.02';

use Carp ();
use Module::Runtime ();

use File::Basename ();
use open ();

use Encode ();
use Data::Dumper ();

use JSON::MaybeXS ();
use constant USING_CPANEL_JSON_XS => JSON::MaybeXS::JSON()->isa("Cpanel::JSON::XS");

#========================================

has output => (is => 'rw', default => 'jsonl');

has binary => (is => 'rw', default => 0);
has scalar => (is => 'rw', default => 0);
has quiet => (is => 'rw', default => 0);
has undef_as => (is => 'rw', default => 'null');
has no_exit_code => (is => 'rw', default => 0);

#========================================

sub cli_run {
  my ($class, $arglist, $opt_alias) = @_;

  {
    my $modFn = Module::Runtime::module_notional_filename($class);
    $INC{$modFn} //= 1;
  }

  my $self = $class->new($class->cli_parse_opts($arglist, undef, $opt_alias));

  unless (@$arglist) {
    # Invoke help command if no arguments are given.
    $self->cmd_help;
    return;
  }

  my $cmd = shift @$arglist;
  if (my $sub = $self->can("cmd_$cmd")) {
    # Invoke official command.

    $self->cli_precmd($cmd);

    $sub->($self, @$arglist);
  }
  elsif ($self->can($cmd)) {
    # Invoke unofficial internal methods. Development aid.

    $self->cli_invoke($cmd, @$arglist);

  }
  else {
    # Last resort. You can implement your own subcommand interpretations here.

    $self->cli_unknown_subcommand($cmd, $arglist);
  }
}

sub cli_unknown_subcommand {
  my ($self, $cmd, $arglist) = @_;

  $self->cmd_help("Error: No such subcommand '$cmd'\n");
}

sub cli_invoke {
  my ($self, $method, @args) = @_;

  my $no_exit_code = $self->can('no_exit_code') && $self->no_exit_code;

  $self->cli_precmd($method);

  my $sub = $self->can($method)
    or Carp::croak "No such method: $method";

  my $list = $self->cli_invoke_sub($sub, $self, @args);

  unless ($no_exit_code) {
    $self->cli_exit_for_result($list);
  }
}

sub cli_invoke_sub {
  my ($self, $sub, $receiver, @args) = @_;

  my @res;
  if ($self->scalar) {
    $res[0] = $sub->($receiver, @args);
    $self->cli_output($res[0]) if not $self->quiet and $res[0];
  } else {
    @res = $sub->($receiver, @args);
    $self->cli_output(\@res) if not $self->quiet and @res;
  }

  \@res;
}

sub cli_output {
  my ($self, $item) = @_;

  my $format = $self->output // "jsonl";

  my $emitter = $self->can("cli_write_fh_as_$format")
    or Carp::croak "No such output format: $format";

  if ($self->scalar) {
    $emitter->($self, \*STDOUT, $item);
  } else {
    $emitter->($self, \*STDOUT, $_) for @$item;
  }
}

*cli_write_fh_as_json = *cli_write_fh_as_jsonl; *cli_write_fh_as_json = *cli_write_fh_as_jsonl;
sub cli_write_fh_as_jsonl {
  my ($self, $outFH, $item) = @_;
  print $outFH (
    ref $item ? $self->cli_encode_json($item) : $item // $self->undef_as
  ), "\n";
}

sub cli_encode_json {
  my ($self, $obj) = @_;
  my $json = $self->cli_encode_json_as_bytes($obj);
  Encode::_utf8_on($json) unless $self->binary;
  $json;
}

sub cli_encode_json_as_bytes {
  my ($self, $obj) = @_;
  $self->cli_json->encode($obj);
}

sub cli_write_fh_as_dump {
  my ($self, $outFH, $item) = @_;
  print $outFH $self->cli_encode_dump($item), "\n";
}

sub cli_exit_for_result {
  my ($self, $list) = @_;

  exit($self->cli_examine_result($list) ? 0 : 1);
}

sub cli_examine_result {
  my ($self, $list) = @_;
  if ($self->scalar) {
    $list->[0];
  } else {
    @$list;
  }
}

sub cmd_help {
  my $self = shift;
  my $pack = ref $self || $self;

  # Invoke precmd (mainly for binmode handling)
  $self->cli_precmd();

  my @msg = (join("\n", @_, <<END));
Usage: @{[File::Basename::basename($0)]} [--opt=value].. <Command | Method> ARGS...
END

  my @cmds = $self->cli_describe_commands;
  my @opts = $self->cli_describe_options;

  push @msg, "\nCommands:\n", @cmds if @cmds;

  push @msg, "\n" if @cmds && @opts;

  push @msg, "\nOptions:\n",  @opts if @opts;

  $! = 0; $? = 0;
  die join("", @msg);
}

sub cli_describe_commands {
  my ($self) = @_;
  my $meta = $self->meta;
  map {
    my $subName = $_;
    (my $name = $subName) =~ s/^cmd_//;
    my $rawAtts = $meta->get_method($subName)->attributes;
    my $attsDict = $self->cli_parse_attributes(@$rawAtts);
    "  $name" . (defined $attsDict->{Doc} ? "  -- $attsDict->{Doc}" : "");
  } sort grep {/^cmd_/} $meta->get_method_list;
}

sub cli_parse_attributes {
  my ($self, @atts) = @_;
  my $atts = +{};
  foreach my $attDesc (@atts) {
    my ($name, $value) = $attDesc =~ m{^([^\(]+)([\(].*)?\z}
      or Carp::croak "Can't parse attribute $attDesc";
    $value =~ s/^\(|\)\z//g if defined $value;
    $atts->{$name} = $value // 1;
  }
  $atts;
}

sub cli_describe_options {
  my ($self) = @_;
  my $meta = $self->meta;
  my $maxLen = 0;
  my @spec = map {
    my $att = $_;
    if ($att->associated_class == $meta) {
      my $doc = $att->{documentation};
      my $name = $att->name;
      $maxLen = length($name) > $maxLen ? length($name): $maxLen;
      [$name, $doc];
    } else {
      ()
    }
  } $meta->get_all_attributes;
  map {
    my ($name, $doc) = @$_;
    sprintf "  --%-${maxLen}s  %s\n", $name, $doc // ""
  } @spec;
}

sub cli_precmd {
  my ($self) = @_;
  #
  # cli_precmd() may be called from $class->cmd_help.
  #
  unless (ref $self and $self->can("binary") and $self->binary) {
    'open'->import(qw/:locale :std/);
  }
}

sub cli_parse_opts {
  my ($class, $list, $result, $alias) = @_;
  my $wantarray = wantarray;
  unless (defined $result) {
    $result = $wantarray ? [] : {};
  }
  while (@$list and defined $list->[0] and my ($n, $v) = $list->[0] =~ m{
    ^--$
    | ^(?:--? ([\w:\-\.]+) (?: =(.*))?)$
  }xs) {
    shift @$list;
    last unless defined $n;
    $n = $alias->{$n} if $alias and $alias->{$n};
    $v = 1 unless defined $v;
    if (ref $result eq 'HASH') {
      $result->{$n} = $class->cli_decode_argument($v);
    } else {
      push @$result, $n, $class->cli_decode_argument($v);
    }
  }

  $_ = $class->cli_decode_argument($_) for @$list;

  $wantarray && ref $result ne 'HASH' ? @$result : $result;
}

sub cli_decode_argument {
  if ($_[1] =~ /^(?:\[.*?\]|\{.*?\})\z/s) {
    my $copy = $_[1];
    Encode::_utf8_off($copy) if Encode::is_utf8($copy);
    $_[0]->cli_json->utf8->relaxed->decode($copy);
  }
  elsif (not Encode::is_utf8($_[1]) and $_[1] =~ /\P{ASCII}/) {
    Encode::decode(utf8 => $_[1]);
  }
  else {
    $_[1];
  }
}

sub cli_json {
  JSON::MaybeXS::JSON()->new;
}

__PACKAGE__->cli_run(\@ARGV) unless caller;

1;
