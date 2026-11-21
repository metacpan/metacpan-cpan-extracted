package Skilletor::Report;
# ABSTRACT: The reports of sync, check and status – their shape, their text, their exit codes (spec §8)

use strict;
use warnings;
use utf8;

use Exporter qw( import );
use Skilletor::Briefing qw( briefing_warning );
use Skilletor::JSON qw( js_ordered js_stringify );
use Skilletor::Lock qw( parse_lock_key );

our $VERSION = '0.008000';

our @EXPORT_OK = qw(
  ACTIVATION empty_scope_report display_safe backend_label conflict_hint has_changes has_notable
  report_json report_text report_hook status_text check_text exit_code
);

# Per item type: when Claude Code sees an item a sync installed (spec §12).
use constant ACTIVATION => {
  skill => 'active now',
  agent => 'active after /reload-plugins or restart',
  rule  => 'active after /reload-plugins or restart',
};

my %HARNESS_ACTIVATION = ( codex => 'active from the next Codex session', hermes => 'active from the next Hermes session' );

sub _activation_of {
  my ( $it ) = @_;
  my $harness = parse_lock_key( $it->{key} )->{harness};
  return ( defined $harness ? $HARNESS_ACTIVATION{$harness} : undef ) // ACTIVATION->{ $it->{type} };
}

# A string's truthiness in JavaScript: set and not empty ("0" counts).
sub _truthy { defined $_[0] && length $_[0] }

sub empty_scope_report {
  my ( $scope ) = @_;
  return js_ordered(
    scope => $scope, added => [], updated => [], removed => [], unchanged => [], skipped => [], conflicts => [], overwritten => [],
    warnings => [], trustRequests => [],
  );
}

my %C0 = ( "\b" => '\\b', "\f" => '\\f', "\n" => '\\n', "\r" => '\\r' );

# One display line safe for a terminal and a model's context: control characters but tab, the
# bidi controls, the line and paragraph separators, the zero-width space, word joiner and BOM
# escaped the JSON way.
sub display_safe {
  my ( $line ) = @_;
  $line =~ s{((?!\t)[\p{Cc}\p{Bidi_Control}\x{200B}\x{2028}\x{2029}\x{2060}\x{FEFF}])}{
    my $c = $1;
    ord($c) < 0x20 ? ( $C0{$c} // sprintf( '\\u%04x', ord $c ) ) : sprintf( '\\u%04x', ord $c );
  }ge;
  return $line;
}

sub backend_label {
  my ( $b ) = @_;
  return $b->{kind}.' '.$b->{url};
}

sub conflict_hint {
  my ( $c ) = @_;
  return 'is not a file (move or remove it yourself; --force leaves it)' if $c->{notFile};
  return 'already exists (use --force to '.( $c->{replace} ? 'replace it' : 'adopt' ).')';
}

sub has_changes {
  my ( $r ) = @_;
  return ( grep { @{ $_->{added} } || @{ $_->{updated} } || @{ $_->{removed} } } @{ $r->{scopes} } ) ? 1 : 0;
}

sub _is_notable {
  my ( $s ) = @_;
  return ( @{ $s->{added} } || @{ $s->{updated} } || @{ $s->{removed} } || @{ $s->{conflicts} } || @{ $s->{overwritten} }
      || @{ $s->{warnings} } || @{ $s->{trustRequests} } || @{ $s->{gitignoreUpdated} // [] } || $s->{settingsUpdated} ) ? 1 : 0;
}

sub has_notable {
  my ( $r ) = @_;
  return ( _truthy( $r->{error} ) || grep { _is_notable($_) } @{ $r->{scopes} } ) ? 1 : 0;
}

sub _commit_hint { $_[0].' updated — commit it' }

sub _settings_hint {
  my ( $u ) = @_;
  my @what;
  push @what, 'enables '.join( ', ', @{ $u->{enabled} } ) if @{ $u->{enabled} };
  push @what, 'declares marketplace'.( @{ $u->{declared} } > 1 ? 's' : '' ).' '.join( ', ', @{ $u->{declared} } ) if @{ $u->{declared} };
  return $u->{path}.' updated ('.join( '; ', @what ).') — commit it';
}

# A report as `--json` prints it: JSON.stringify(report, null, 2), each line display-safe (the
# CLI's printText); no final newline.
sub report_json {
  my ( $r ) = @_;
  return join "\n", map { display_safe($_) } split /\n/, js_stringify( $r, 2 ), -1;
}

# The sync report as the CLI prints it; empty when there is nothing to say.
sub report_text {
  my ( $r ) = @_;
  return display_safe( 'skilletor: config error, nothing changed — '.$r->{error} ) if defined $r->{error};
  my @lines;
  for my $s ( @{ $r->{scopes} } ) {
    # Skips are informational: shown here, but not notable.
    next if !_is_notable($s) && !@{ $s->{skipped} };
    my %skipped = map { ( $_->{key} => 1 ) } @{ $s->{skipped} };
    push @lines, 'skilletor: '.$s->{scope}.' scope';
    push @lines, '  + '.$_->{key}.' ('._activation_of($_).')' for @{ $s->{added} };
    push @lines, '  ~ '.$_->{key}.' ('._activation_of($_).')' for @{ $s->{updated} };
    push @lines, '  - '.$_->{key}.' ('.( $skipped{ $_->{key} } ? 'removed: renders empty' : 'removed' ).')' for @{ $s->{removed} };
    my %removed = map { ( $_->{key} => 1 ) } @{ $s->{removed} };
    push @lines, '  · '.$_->{key}.' skipped (renders empty)' for grep { !$removed{ $_->{key} } } @{ $s->{skipped} };
    push @lines, '  overwrote local change: '.$_->{path} for @{ $s->{overwritten} };
    push @lines, '  conflict: '.$_->{path}.' '.conflict_hint($_) for @{ $s->{conflicts} };
    push @lines, '  trust: source "'.$_->{name}.'" ('.backend_label($_).') — run: skilletor trust '.$_->{name} for @{ $s->{trustRequests} };
    push @lines, '  '._commit_hint($_) for @{ $s->{gitignoreUpdated} // [] };
    push @lines, '  '._settings_hint( $s->{settingsUpdated} ) if $s->{settingsUpdated};
    push @lines, '  warning: '.$_ for @{ $s->{warnings} };
  }
  push @lines, 'skilletor: warning: '.$_ for @{ $r->{warnings} // [] };
  push @lines, 'skilletor: note: '.$_    for @{ $r->{notes}    // [] };
  return join "\n", map { display_safe($_) } @lines;
}

# The report without its briefing warnings – and without the settings warnings of a scope whose
# settings file this run left as it was: the hooks show them only in a run that changed something.
sub _without_repeats {
  my ( $r ) = @_;
  my $out = js_ordered( map { ( $_ => $r->{$_} ) } keys %$r );
  $out->{scopes} = [
    map {
      my $s = $_;
      my @settings = $s->{settingsUpdated} ? () : @{ $s->{settingsSkipped} // [] };
      my @briefing = @{ $s->{briefingMissing} // [] };
      if ( !@briefing && !@settings ) { $s }
      else {
        my %lines = map { ( $_ => 1 ) } ( map { briefing_warning( parse_lock_key( $_->{key} )->{name}, $_->{harness}, $_->{missing} ) } @briefing ),
          @settings;
        my $rest = js_ordered( map { ( $_ => $s->{$_} ) } grep { $_ ne 'briefingMissing' } keys %$s );
        $rest->{warnings} = [ grep { !$lines{$_} } @{ $s->{warnings} } ];
        $rest;
      }
    } @{ $r->{scopes} }
  ];
  return $out;
}

# The hooks' output of a sync report: a one-line systemMessage and a terse additionalContext,
# every line display-safe; a config error alone, as one line. Nothing to say: an empty hash.
sub report_hook {
  my ( $report ) = @_;
  return js_ordered( systemMessage => display_safe( 'skilletor: '.$report->{error} ) ) if _truthy( $report->{error} );
  my $r = has_changes($report) ? $report : _without_repeats($report);
  return js_ordered() unless has_notable($r);
  my ( @changed, @gitignores );
  my ( $warnings, $removed ) = ( 0, 0 );
  for my $s ( @{ $r->{scopes} } ) {
    push @changed, @{ $s->{added} }, @{ $s->{updated} };
    $warnings += @{ $s->{warnings} } + @{ $s->{conflicts} } + @{ $s->{trustRequests} } + @{ $s->{overwritten} };
    $removed  += @{ $s->{removed} };
    push @gitignores, @{ $s->{gitignoreUpdated} // [] }, ( $s->{settingsUpdated} ? $s->{settingsUpdated}{path} : () );
  }

  my @parts;
  push @parts, scalar(@changed).' item(s) updated' if @changed;
  push @parts, $removed.' removed'                 if $removed;
  push @parts, $warnings.' warning(s)'             if $warnings;
  push @parts, join( ', ', @gitignores ).' updated — commit '.( @gitignores > 1 ? 'them' : 'it' ) if @gitignores;
  my $out = js_ordered( systemMessage => display_safe( 'skilletor: '.( @parts ? join( ', ', @parts ) : 'changes applied' ) ) );

  my @ctx;
  if (@changed) {
    push @ctx, 'skilletor synced items:';
    for my $it (@changed) {
      # Claude Code's items are unmarked; another harness's are named.
      my $harness = parse_lock_key( $it->{key} )->{harness};
      my $mark = defined $harness && $harness ne 'claude' ? ' ('.$harness.')' : '';
      push @ctx, '- '.$it->{type}.' '.$it->{name}.'@'.$it->{source}.$mark.': '._activation_of($it);
    }
  }
  # One line per counted warning; the scope says which `.claude` a path is relative to.
  for my $s ( @{ $r->{scopes} } ) {
    push @ctx, '- overwrote local change in '.$s->{scope}.' scope: '.$_->{path} for @{ $s->{overwritten} };
    push @ctx, '- conflict in '.$s->{scope}.' scope: '.$_->{path}.' '.conflict_hint($_) for @{ $s->{conflicts} };
    push @ctx, '- untrusted source '.$_->{name}.' ('.backend_label($_).'); run: skilletor trust '.$_->{name} for @{ $s->{trustRequests} };
    push @ctx, '- '._commit_hint($_) for @{ $s->{gitignoreUpdated} // [] };
    push @ctx, '- '._settings_hint( $s->{settingsUpdated} ) if $s->{settingsUpdated};
    push @ctx, '- warning: '.$_ for @{ $s->{warnings} };
  }
  $out->{additionalContext} = join "\n", map { display_safe($_) } @ctx if @ctx;
  return $out;
}

# The status report as `skilletor status` prints it.
sub status_text {
  my ( $r ) = @_;
  return display_safe( 'skilletor: config error — '.$r->{error} ) if defined $r->{error};
  my @lines;
  for my $s ( @{ $r->{scopes} } ) {
    my @t = @{ $s->{targets} };
    my $claude_only = @t == 1 && $t[0] eq 'claude';
    push @lines, $claude_only ? $s->{scope}.' scope:' : $s->{scope}.' scope ('.( @t ? join( ', ', @t ) : 'no targets' ).'):';
    for my $d ( @{ $s->{declared} } ) {
      my $mark = $d->{installed} ? '✓' : $d->{skipped} ? '-' : '·';
      my $note = ( $d->{skipped} ? ' (skipped: renders empty)' : '' ).( $d->{partial} ? ' (partial: the last sync stopped midway)' : '' )
        .( $d->{briefingMissing} ? ' (briefing skills not installed: '.join( ', ', @{ $d->{briefingMissing} } ).')' : '' );
      push @lines, '  '.$mark.' '.$d->{key}.' @'.$d->{source}.( defined $d->{via} ? ' via '.$d->{via} : '' ).$note;
    }
    for my $w ( @{ $s->{wildcards} } ) {
      ( my $pattern = substr( $w->{entry}, 0, rindex( $w->{entry}, '@' ) ) ) =~ s/\A[a-z]+://;
      push @lines, '  * '.$w->{type}.'s/'.$pattern.' @'.$w->{source}.' ('.$w->{installed}.' installed)';
    }
    push @lines, '  * bundle:'.$_->{name}.'@'.$_->{source}.' ('.$_->{installed}.' installed)' for @{ $s->{bundles} };
    push @lines, '  ? '.$_.' (in lock, not declared)' for @{ $s->{orphans} };
    push @lines, '  trust: '.$_->{name}.' ('.backend_label($_).')' for @{ $s->{trustRequests} };
  }
  push @lines, 'project scope: none (the project directory is the home directory)' if $r->{projectIsHome};
  push @lines, 'warning: '.$_ for @{ $r->{warnings} // [] };
  return join "\n", map { display_safe($_) } @lines;
}

# The check verdict as `skilletor check` prints it.
sub check_text {
  my ( $r ) = @_;
  return display_safe( 'skilletor: '.$r->{error} ) if defined $r->{error};
  return $r->{changed} ? 'changed' : 'up to date';
}

# The CLI's exit code for a report: 2 on an error; `check` 1 when a sync is due; else 0.
sub exit_code {
  my ( $op, $r ) = @_;
  return 2 if defined $r->{error};
  return ( $op eq 'check' && $r->{changed} ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Report - The reports of sync, check and status – their shape, their text, their exit codes (spec §8)

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Report qw( report_text exit_code );

  my $report = $sk->sync;
  print report_text($report) || 'skilletor: up to date', "\n";
  exit exit_code( sync => $report );

=head1 DESCRIPTION

The reference's C<report.ts> (spec §8), and the text C<skilletor status> and
C<skilletor check> print (C<cli.ts>). The reports themselves are plain data,
built by L<Skilletor::Engine> with their keys in the reference's order;
L</report_json> writes them as C<skilletor sync --json>, C<check --json> and
C<status --json> print them. The other functions word them for a person or a
model's context, line for line as the CLI does: the same marks, the same
activation hints (a skill is active at once, an agent or rule after
C</reload-plugins>), every line passed through L</display_safe>.

=head2 report_json

  print report_json( $sk->sync ), "\n";

A sync, check or status report as the CLI's C<--json> prints it, byte for
byte: C<JSON.stringify(report, null, 2)> (L<Skilletor::JSON/js_stringify>),
keys in their order, every line through L</display_safe>, without the final
newline. The escapes are JSON's own, so the text parses back to the same
values.

=head2 report_text

The sync report's text; empty when no scope has anything to say (the CLI then
prints C<skilletor: up to date>).

=head2 report_hook

  my $h = report_hook( $sk->sync );   # { systemMessage => …, additionalContext => … }

What the hooks make of a sync report (the reference's C<reportHook>): a
one-line C<systemMessage> counting the items updated, removed, the warnings
and the files to commit, and an C<additionalContext> with one line per synced
item (its activation hint; an item of another harness than Claude Code names
it) and per counted warning, each line through L</display_safe>. A report with
an C<error> gives that line alone; one with nothing to say an empty hash. A run
that added, updated or removed nothing leaves out what it would say in every
session: an agent's missing briefing skills, and the settings warnings of a
scope whose C<.claude/settings.json> it did not update. The report itself is
not changed.

=head2 status_text

=head2 check_text

C<changed> or C<up to date>.

=head2 exit_code

  exit_code( sync | check | status => $report );

The CLI's exit code: 2 for a report with an C<error>, 1 for a C<check> that
found a reason to sync, else 0.

=head2 display_safe

One line with every control character but tab, every bidi control, the line
and paragraph separators, the zero-width space, word joiner and BOM escaped
the JSON way (C<\n>, C<\u001b>, C<‮>): a name or a message from a config
or a source cannot move the cursor, recolour or reorder what is shown.

=head2 empty_scope_report

  empty_scope_report('user');

=head2 conflict_hint

The text after a conflict's path: C<already exists (use --force to adopt)>.

=head2 backend_label

C<git https://…>, C<local /path>.

=head2 has_changes

True when a sync added, updated or removed an item.

=head2 has_notable

True when a sync report has anything a hook would show.

=head2 ACTIVATION

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
