package Skilletor::ClaudeSettings;
# ABSTRACT: The plugin requirement in a project's committed .claude/settings.json (spec §6.8, k140)

use strict;
use warnings;
use utf8;

use Errno ();
use Exporter qw( import );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed );
use Skilletor::FSUtil qw( encode_text node_fs_error path_join read_text same_path );
use Skilletor::JSON qw( js_ordered js_parse js_sort_keys js_stringify js_type );

our $VERSION = '0.001';

our @EXPORT_OK = qw( plan_claude_settings skilletor_marketplace not_declarable OFFICIAL_MARKETPLACE );

use constant OFFICIAL_MARKETPLACE => 'claude-plugins-official';
use constant PLUGIN               => 'skilletor';

sub _is_object { js_type( $_[0] ) eq 'object' }

# A JSON object file, or undef (missing, unreadable, not JSON, not an object).
sub _read_object {
  my ( $path ) = @_;
  my $v = eval { js_parse( read_text($path) ) };
  return _is_object($v) ? $v : undef;
}

# `name@marketplace` → its parts; undef for a key of another form.
sub _plugin_key {
  my ( $key ) = @_;
  my $at = rindex $key, '@';
  return undef if $at <= 0 || $at == length($key) - 1;
  return { name => substr( $key, 0, $at ), marketplace => substr( $key, $at + 1 ) };
}

sub _str { js_type( $_[0] ) eq 'string' ? $_[0] : undef }

# skilletor's installs from installed_plugins.json (a list per key; an older file's single
# object is read as a list of one).
sub _skilletor_installs {
  my ( $claude_dir ) = @_;
  my $file = _read_object( path_join( $claude_dir, 'plugins', 'installed_plugins.json' ) );
  my $plugins = $file ? $file->{plugins} : undef;
  return () unless _is_object($plugins);
  my @out;
  for my $key ( keys %$plugins ) {
    my $k = _plugin_key($key);
    next unless $k && $k->{name} eq PLUGIN;
    my $value = $plugins->{$key};
    for my $e ( js_type($value) eq 'array' ? @$value : ($value) ) {
      next unless _is_object($e);
      push @out, { marketplace => $k->{marketplace}, map { ( $_ => _str( $e->{$_} ) ) } qw( scope installPath projectPath ) };
    }
  }
  return @out;
}

sub _unique {
  my %seen;
  return grep { !$seen{$_}++ } map { $_->{marketplace} } @_;
}

# The marketplace skilletor is installed from, for this project: the install the running plugin
# is, else the one marketplace of the user's install and this project's.
sub skilletor_marketplace {
  my ( $claude_dir, $project_dir, $plugin_root ) = @_;
  my @installs = _skilletor_installs($claude_dir);
  if ( defined $plugin_root && length $plugin_root ) {
    my @running = _unique( grep { defined $_->{installPath} && same_path( $_->{installPath}, $plugin_root ) } @installs );
    return { name => $running[0] } if @running == 1;
  }
  my @here = _unique(
    grep {
      ( defined $_->{scope} && $_->{scope} eq 'user' ) || ( defined $_->{projectPath} && same_path( $_->{projectPath}, $project_dir ) )
    } @installs
  );
  return { name => $here[0] } if @here == 1;
  return @here > 1 ? { ambiguous => [ js_sort_keys(@here) ] } : {};
}

sub _is_remote_git {
  my ( $url ) = @_;
  return ( $url =~ m{\A(?:https?|ssh|git)://}i || $url =~ m{\A[\w.-]+\@[\w.-]+:(?!//)}a ) ? 1 : 0;
}

# Why a marketplace source must not go into a committed file, or undef when it may.
sub not_declarable {
  my ( $source ) = @_;
  return 'no readable source' unless _is_object($source);
  my $kind = js_type( $source->{source} ) eq 'string' ? $source->{source} : 'unknown';
  return undef if $kind eq 'github' && js_type( $source->{repo} ) eq 'string' && length $source->{repo};
  return undef if $kind eq 'git' && js_type( $source->{url} ) eq 'string' && _is_remote_git( $source->{url} );
  return undef if $kind eq 'url' && js_type( $source->{url} ) eq 'string' && $source->{url} =~ m{\Ahttps?://}i;
  return 'a git source on a local path' if $kind eq 'git';
  return 'a '.$kind.' source';
}

# The text layout of an existing file: its indent, line ending and final newline.
sub _layout_of {
  my ( $text ) = @_;
  my $indent = ( $text =~ /^([ \t]+)"/m && length($1) <= 10 ) ? $1 : '  ';
  return ( $indent, ( index( $text, "\r\n" ) >= 0 ? "\r\n" : "\n" ), ( $text =~ /\n\z/ ? 1 : 0 ) );
}

sub _message {
  my ( $err ) = @_;
  return $err->message if blessed $err && $err->can('message');
  return "$err" =~ s/ at \S+ line \d+\.?\n?\z//r;
}

# Plan the additions; reads the settings file and Claude Code's plugin state only.
sub plan_claude_settings {
  my ( %a ) = @_;
  my $plan = { enabled => [], declared => [], warnings => [] };
  my $leave = sub {
    push @{ $plan->{warnings} }, $a{label}.' '.$_[0].'; plugin requirement not written';
    return $plan;
  };
  my $bytes = encode_text( $a{file} );
  my $text;
  if ( my @st = lstat $bytes ) {
    return $leave->('is a symbolic link') if -l _;
    return $leave->('is not a file') unless -f _;
    if ( open my $fh, '<:raw', $bytes ) {
      close $fh;
      $text = read_text( $a{file} );
    }
    else {
      return $leave->( 'cannot be read ('.node_fs_error( 0 + $!, 'open', $a{file} ).')' );
    }
  }
  elsif ( !$!{ENOENT} ) {
    return $leave->( 'cannot be read ('.node_fs_error( 0 + $!, 'lstat', $a{file} ).')' );
  }
  my $settings = js_ordered();
  if ( defined $text ) {
    my $parsed;
    return $leave->( 'is not valid JSON ('._message($@).')' ) unless eval { $parsed = js_parse($text); 1 };
    return $leave->('is not a JSON object') unless _is_object($parsed);
    $settings = $parsed;
  }
  for my $key (qw( enabledPlugins extraKnownMarketplaces )) {
    return $leave->( 'has an "'.$key.'" that is not an object' ) if exists $settings->{$key} && !_is_object( $settings->{$key} );
  }
  my $enabled  = $settings->{enabledPlugins}         // js_ordered();
  my $declared = $settings->{extraKnownMarketplaces} // js_ordered();
  my $known = _read_object( path_join( $a{claude_dir}, 'plugins', 'known_marketplaces.json' ) ) // {};
  my $source_of = sub { _is_object( $known->{ $_[0] } ) ? $known->{ $_[0] }{source} : undef };
  my $needs = 'a committed file takes a github, git or url source';

  # skilletor itself – unless the file names it already, from any marketplace, on or off.
  unless ( grep { my $k = _plugin_key($_); $k && $k->{name} eq PLUGIN } keys %$enabled ) {
    my $own = skilletor_marketplace( $a{claude_dir}, $a{project_dir}, $a{plugin_root} );
    if ( $own->{ambiguous} ) {
      push @{ $plan->{warnings} }, 'skilletor is installed from several marketplaces ('.join( ', ', @{ $own->{ambiguous} } ).'); '
        .$a{label}.' does not get it – enable the one teammates should use';
    }
    elsif ( defined $own->{name} ) {
      my $m   = $own->{name};
      my $why = ( $m eq OFFICIAL_MARKETPLACE || exists $declared->{$m} ) ? undef
        : !exists $known->{$m} ? q{no entry in Claude Code's known marketplaces}
        : not_declarable( $source_of->($m) );
      if ( defined $why ) {
        push @{ $plan->{warnings} }, 'skilletor\'s marketplace "'.$m.'" has '.$why.' on this machine; '.$a{label}
          .' does not get skilletor@'.$m.' ('.$needs.')';
      }
      else {
        push @{ $plan->{enabled} }, PLUGIN.'@'.$m;
      }
    }
  }

  # Every marketplace an entry that is not switched off needs, in the order of the entries.
  my @additions;
  my @wanted = ( ( grep { my $on = $enabled->{$_}; !( js_type($on) eq 'boolean' && !$on ) } keys %$enabled ), @{ $plan->{enabled} } );
  my %seen;
  for my $key (@wanted) {
    my $k = _plugin_key($key) or next;
    my $m = $k->{marketplace};
    next if $seen{$m}++;
    next if $m eq OFFICIAL_MARKETPLACE || exists $declared->{$m};
    my $users = join ', ', grep { my $x = _plugin_key($_); $x && $x->{marketplace} eq $m } @wanted;
    unless ( exists $known->{$m} ) {
      push @{ $plan->{warnings} }, 'marketplace "'.$m.'" ('.$users.') is not known to Claude Code on this machine; not declared in '.$a{label};
      next;
    }
    if ( defined( my $why = not_declarable( $source_of->($m) ) ) ) {
      push @{ $plan->{warnings} }, 'marketplace "'.$m.'" ('.$users.') has '.$why.' on this machine; not declared in '.$a{label}.' ('.$needs.')';
      next;
    }
    push @additions, [ $m, js_ordered( source => $source_of->($m) ) ];
    push @{ $plan->{declared} }, $m;
  }
  return $plan unless @{ $plan->{enabled} } || @additions;

  # Add only: every key stays where it was, new ones go last.
  my $next = js_ordered( map { ( $_ => $settings->{$_} ) } keys %$settings );
  if ( @{ $plan->{enabled} } ) {
    my $e = js_ordered( map { ( $_ => $enabled->{$_} ) } keys %$enabled );
    $e->{$_} = JSON::MaybeXS::true() for @{ $plan->{enabled} };
    $next->{enabledPlugins} = $e;
  }
  if (@additions) {
    my $d = js_ordered( map { ( $_ => $declared->{$_} ) } keys %$declared );
    $d->{ $_->[0] } = $_->[1] for @additions;
    $next->{extraKnownMarketplaces} = $d;
  }
  my ( $indent, $eol, $final ) = defined $text ? _layout_of($text) : ( '  ', "\n", 1 );
  my $body = js_stringify( $next, $indent );
  $body = join $eol, split /\n/, $body, -1 if $eol ne "\n";
  $plan->{next} = $body.( $final ? $eol : '' );
  return $plan;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::ClaudeSettings - The plugin requirement in a project's committed .claude/settings.json (spec §6.8, k140)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::ClaudeSettings qw( plan_claude_settings );

  my $plan = plan_claude_settings(
    file        => "$project/.claude/settings.json",
    label       => '.claude/settings.json',
    project_dir => $project,
    claude_dir  => $claude_dir,   # CLAUDE_CONFIG_DIR, else "$home/.claude"
    plugin_root => $ENV{CLAUDE_PLUGIN_ROOT},
  );
  # { next => $text?, enabled => [ 'skilletor@getty' ], declared => [ 'getty' ], warnings => [ ... ] }

=head1 DESCRIPTION

The reference's C<claudesettings.ts> (spec §6.8, k140): a project that uses
skilletor enables C<< skilletor@<marketplace> >> in its committed
C<.claude/settings.json> and declares every marketplace an C<enabledPlugins>
entry of the file needs, so a fresh checkout gets Claude Code's offer to
install the plugins. Add-only: no existing key changes, a C<false> stays, new
keys go last, the file keeps its indent, line endings and final newline. The
marketplace and its source are read – never written – from Claude Code's
plugin state under C<< <claude_dir>/plugins >> (Claude Code's config dir); a source that only means
something on this machine (a directory, a file, a git repository on a local
path) never goes into a committed file, a warning says so. Never throws.

=head2 plan_claude_settings

The additions: C<next> (the new file text, absent when nothing is added),
C<enabled> and C<declared> (what was added) and C<warnings> (what could not
be, one line each).

=head2 skilletor_marketplace

  skilletor_marketplace( $claude_dir, $project_dir, $plugin_root );   # { name } or { ambiguous => [...] } or {}

=head2 not_declarable

Why a marketplace source must not go into a committed file, or undef.

=head2 OFFICIAL_MARKETPLACE

C<claude-plugins-official>: known everywhere, never declared.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
