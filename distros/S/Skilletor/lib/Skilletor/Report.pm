package Skilletor::Report;
# ABSTRACT: The reports of sync, check and status – their shape, their text, their exit codes (spec §8)

use strict;
use warnings;
use utf8;

use Exporter qw( import );
use Skilletor::Lock qw( parse_lock_key );

our $VERSION = '0.001';

our @EXPORT_OK = qw(
  ACTIVATION empty_scope_report display_safe backend_label conflict_hint has_changes has_notable
  report_text status_text check_text exit_code
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
  return ( defined $harness && $HARNESS_ACTIVATION{$harness} ) // ACTIVATION->{ $it->{type} };
}

sub empty_scope_report {
  my ( $scope ) = @_;
  return {
    scope => $scope, added => [], updated => [], removed => [], unchanged => [], skipped => [], conflicts => [], overwritten => [],
    warnings => [], trustRequests => [],
  };
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
  return ( defined $r->{error} || grep { _is_notable($_) } @{ $r->{scopes} } ) ? 1 : 0;
}

sub _settings_hint {
  my ( $u ) = @_;
  my @what;
  push @what, 'enables '.join( ', ', @{ $u->{enabled} } ) if @{ $u->{enabled} };
  push @what, 'declares marketplace'.( @{ $u->{declared} } > 1 ? 's' : '' ).' '.join( ', ', @{ $u->{declared} } ) if @{ $u->{declared} };
  return $u->{path}.' updated ('.join( '; ', @what ).') — commit it';
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
    push @lines, '  '.$_.' updated — commit it' for @{ $s->{gitignoreUpdated} // [] };
    push @lines, '  '._settings_hint( $s->{settingsUpdated} ) if $s->{settingsUpdated};
    push @lines, '  warning: '.$_ for @{ $s->{warnings} };
  }
  push @lines, 'skilletor: warning: '.$_ for @{ $r->{warnings} // [] };
  push @lines, 'skilletor: note: '.$_    for @{ $r->{notes}    // [] };
  return join "\n", map { display_safe($_) } @lines;
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

version 0.001

=head1 SYNOPSIS

  use Skilletor::Report qw( report_text exit_code );

  my $report = $sk->sync;
  print report_text($report) || 'skilletor: up to date', "\n";
  exit exit_code( sync => $report );

=head1 DESCRIPTION

The reference's C<report.ts> (spec §8), and the text C<skilletor status> and
C<skilletor check> print (C<cli.ts>). The reports themselves are plain data –
what C<skilletor sync --json>, C<check --json> and C<status --json> print –
built by L<Skilletor::Engine>; this module words them for a person or a model's
context, line for line as the CLI does: the same marks, the same activation
hints (a skill is active at once, an agent or rule after C</reload-plugins>),
every line passed through L</display_safe>.

=head2 report_text

The sync report's text; empty when no scope has anything to say (the CLI then
prints C<skilletor: up to date>).

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
