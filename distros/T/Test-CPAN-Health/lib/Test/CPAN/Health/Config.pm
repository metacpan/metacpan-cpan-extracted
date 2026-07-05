package Test::CPAN::Health::Config;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

our $VERSION = '0.1.0';

# Recognised configuration file names, in preference order.
Readonly::Array my @CONFIG_NAMES => qw(
	.cpan-health.ini
	.cpan-health.conf
	cpan-health.ini
	cpan-health.conf
);

# Valid scalar boolean / numeric option keys.
Readonly::Hash my %SCALAR_KEYS => map { $_ => 1 } qw(
	no_network no_cover min_score severity
);

# Valid list option keys (comma-separated in the file).
Readonly::Hash my %LIST_KEYS => map { $_ => 1 } qw(
	skip ignore_abandoned
);

=head1 NAME

Test::CPAN::Health::Config - Read per-project configuration for cpan-health

=head1 SYNOPSIS

    use Test::CPAN::Health::Config;

    my $cfg = Test::CPAN::Health::Config->new(path => '/path/to/dist');

    # Returns the merged configuration (file values override defaults)
    my %opts = $cfg->as_hash;

    # Individual accessors
    print $cfg->min_score;                     # integer or undef
    print join(', ', @{ $cfg->skip });         # arrayref
    print join(', ', @{ $cfg->ignore_abandoned }); # arrayref

=head1 DESCRIPTION

Reads an optional C<.cpan-health.ini> (or C<cpan-health.conf>) file from a
distribution's root directory.  The file uses a simple C<key = value> format;
comma-separated values are supported for list options.

If no configuration file is found, all accessors return C<undef> (scalars)
or C<[]> (lists), and the caller falls back to its own defaults.

Supported options:

  no_network       = 0|1
  no_cover         = 0|1
  min_score        = 0..100
  severity         = 1..5
  skip             = check_id1, check_id2, ...
  ignore_abandoned = Module::Name1, Module::Name2, ...

=head1 LIMITATIONS

=over 4

=item * Sections (C<[section]>) are not supported; all keys live at the top level.

=item * Unknown keys produce a C<carp> warning and are ignored.

=item * Only the first matching config file in the preference order is read.

=back

=cut

=head2 new

=head3 PURPOSE

Construct a Config object, locating and parsing any config file found under
the given distribution path.

=head3 API SPECIFICATION

=head4 INPUT

  path  string  required  Absolute path to the distribution root

=head4 OUTPUT

Blessed Config object.

=head3 MESSAGES

  Code  | Severity | Message                         | Resolution
  ------+----------+---------------------------------+--------------
  CFG01 | WARNING  | Unknown config key '<key>'      | Remove the key
  CFG02 | WARNING  | Config parse error in <file>    | Fix the file syntax

=head3 FORMAL SPECIFICATION

  Pre:  path is a readable directory
  Post: self._data contains merged key/value from file (or empty if no file)

=head3 SIDE EFFECTS

Reads at most one file from disk.

=head3 USAGE EXAMPLE

    my $cfg = Test::CPAN::Health::Config->new(path => $dist->path);
    my $min = $cfg->min_score // 0;

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			path => { type => 'string', optional => 1, default => '.' },
		},
		input => \%args,
	) };

	my $self = bless {
		_path => $args{path},
		_data => {},
		_file => undef,
	}, $class;

	$self->_load;

	return $self;
}

=head2 as_hash

=head3 PURPOSE

Return all parsed configuration options as a flat hash.  Suitable for
merging with CLI-supplied options.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Hash with keys: C<no_network>, C<no_cover>, C<min_score>, C<severity>,
C<skip> (arrayref), C<ignore_abandoned> (arrayref).  Only keys that were
explicitly set in the config file are present.

=head3 MESSAGES

  (none)

=head3 FORMAL SPECIFICATION

  Post: result is a hashref subset of (SCALAR_KEYS union LIST_KEYS)

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my %cfg = $config->as_hash;
    my $effective_min = $cfg{min_score} // $cli_min_score // 0;

=cut

sub as_hash { my ($self) = @_; return %{ $self->{_data} } }

=head2 file

Returns the path of the config file that was loaded, or C<undef> if none was found.

=cut

sub file { my ($self) = @_; return $self->{_file} }

=head2 no_network

Returns the C<no_network> setting or C<undef>.

=cut

sub no_network { my ($self) = @_; return $self->{_data}{no_network} }

=head2 no_cover

Returns the C<no_cover> setting or C<undef>.

=cut

sub no_cover { my ($self) = @_; return $self->{_data}{no_cover} }

=head2 min_score

Returns the C<min_score> setting or C<undef>.

=cut

sub min_score { my ($self) = @_; return $self->{_data}{min_score} }

=head2 severity

Returns the C<severity> setting or C<undef>.

=cut

sub severity { my ($self) = @_; return $self->{_data}{severity} }

=head2 skip

Returns the C<skip> arrayref or C<[]>.

=cut

sub skip { my ($self) = @_; return $self->{_data}{skip} // [] }

=head2 ignore_abandoned

Returns the C<ignore_abandoned> arrayref or C<[]>.

=cut

sub ignore_abandoned { my ($self) = @_; return $self->{_data}{ignore_abandoned} // [] }

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _split_list {
	my ($val) = @_;
	my @raw   = split / , /x, $val;
	my @items;
	for my $item (@raw) {
		$item =~ s/ ^ \s+ | \s+ $ //gx;
		push @items, $item if length $item;
	}
	return \@items;
}

sub _load {
	my ($self) = @_;

	my $cfg_file;
	for my $name (@CONFIG_NAMES) {
		my $candidate = File::Spec->catfile($self->{_path}, $name);
		if (-f $candidate) {
			$cfg_file = $candidate;
			last;
		}
	}

	return unless defined $cfg_file;

	$self->{_file} = $cfg_file;

	open my $fh, '<', $cfg_file;
	my @lines = <$fh>;
	close $fh;

	for my $line (@lines) {
		chomp $line;
		next if _skip_line($line);
		$self->_parse_line($line, $cfg_file);
	}

	return;
}

sub _skip_line {
	my ($line) = @_;
	return 1 if $line =~ / ^ \s* [#;] /x;
	return 1 if $line =~ / ^ \s*      $ /x;
	return 1 if $line =~ / ^ \s* \[   /x;
	return 0;
}

sub _parse_line {
	my ($self, $line, $cfg_file) = @_;

	if ($line =~ / ^ \s* ( [\w]+ ) \s* = \s* (.*?) \s* $ /x) {
		my ($key, $val) = ($1, $2);
		if ($SCALAR_KEYS{$key}) {
			$self->{_data}{$key} = $val + 0;
		} elsif ($LIST_KEYS{$key}) {
			$self->{_data}{$key} = _split_list($val);
		} else {
			carp "Unknown config key '$key' in $cfg_file";
		}
	} else {
		carp "Config parse error in $cfg_file: unrecognised line: $line";
	}

	return;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
