use Feature::Compat::Class 0.04;

use v5.12;
use utf8;
use warnings;

=head1 NAME

String::License - detect source code license statements in a text string

=head1 VERSION

Version v0.0.5

=head1 SYNOPSIS

    use String::License;
    use String::License::Naming::Custom;

    my $string = 'Licensed under same terms as Perl itself';

    my $expressed  = String::License->new( string => $string );
    my $expression = $expressed->as_text;  # => "Perl"

    my $desc        = String::License::Naming::Custom->new;
    my $described   = String::License->new( string => $string, naming => $desc );
    my $description = $described->as_text;  # => "The Perl 5 License"

=head1 DESCRIPTION

L<String::License> identifies license statements in a string
and serializes them in a normalized format.

=cut

package String::License v0.0.5;

use Carp            qw(croak);
use Log::Any        ();
use Scalar::Util    qw(blessed);
use List::SomeUtils qw(nsort_by uniq);
use Array::IntSpan;
use Regexp::Pattern::License 3.4.0;
use Regexp::Pattern 0.2.12;
use String::License::Naming::Custom;
use String::License::Naming::SPDX;

use namespace::clean;

class Trait {
	field $log;
	field $name :param;
	field $begin :param;
	field $end :param;
	field $file :param;

	ADJUST {
		$log = Log::Any->get_logger;

		$log->tracef(
			'located trait: %s: %d-%d "%s"',
			$name, $begin, $end,
			$file ? substr( $file->string, $begin, $end - $begin ) : '',
		);
	}

	method name { return $name }
	method begin { return $begin }
	method end { return $end }
	method file { return $file }
}

class Exception {
	field $log;
	field $id :param;
	field $begin :param;
	field $end :param;
	field $file :param;

	ADJUST {
		$log = Log::Any->get_logger;

		$log->tracef(
			'detected exception: %s: %d-%d',
			$id->{caption}, $begin, $end
		);
	}

	method id { return $id }
	method begin { return $begin }
	method end { return $end }
	method file { return $file }
}

class Flaw {
	field $log;
	field $id :param;
	field $begin :param;
	field $end :param;
	field $file :param;

	ADJUST {
		$log = Log::Any->get_logger;

		$log->tracef(
			'detected flaw: %s: %d-%d',
			$id->{caption}, $begin, $end
		);
	}

	method id { return $id }
	method begin { return $begin }
	method end { return $end }
	method file { return $file }
}

class Licensing {
	field $log;
	field $name :param;

	ADJUST {
		$log = Log::Any->get_logger;

		$log->debugf(
			'collected some licensing: %s',
			$name
		);
	}

	method name { return $name }
}

class Fulltext {
	field $log;
	field $name :param;
	field $begin :param;
	field $end :param;
	field $file :param;
	field $traits :param = undef;

	ADJUST {
		$log = Log::Any->get_logger;

		$log->debugf(
			'collected fulltext: %s: %d-%d',
			$name, $begin, $end
		);
	}

	method name { return $name }
	method begin { return $begin }
	method end { return $end }
	method file { return $file }
	method traits { return $traits }
}

class Grant {
	field $log;
	field $name :param;
	field $begin :param;
	field $end :param;
	field $file :param;
	field $traits :param = undef;

	ADJUST {
		$log = Log::Any->get_logger;

		$log->debugf(
			'collected grant: %s: %d-%d "%s"',
			$name, $begin, $end,
			$file ? substr( $file->string, $begin, $end - $begin ) : '',
		);
	}

	method name { return $name }
	method begin { return $begin }
	method end { return $end }
	method file { return $file }
	method traits { return $file }
}

class String::License;

# try enable RE2 engine
eval { require re::engine::RE2 };
my @OPT_RE2 = $@ ? () : ( engine => 'RE2' );

field $log;

=head1 CONSTRUCTOR

=over

=item new

    my $licensed = String::License->new( string => 'Licensed under GPLv2' );

Accepts named arguments,
and constructs and returns a String::License object.

The following options are recognized:

=over

=item string => STRING

The scalar string to parse for licensing information.

=cut

field $string :param = undef;

=item naming => OBJ

A L<String::License::Naming> object,
used to define license naming conventions.

By default uses L<String::License::Naming::SPDX>.

Since instantiation of naming schemes is expensive,
there can be a significant speed boost
in passing a pre-initialized naming object
when processing multiple strings.

=cut

field $naming :param = undef;

field $license = '';
field $expr = '';

=back

=back

=cut

ADJUST {
	$log = Log::Any->get_logger;

	if ( defined $naming ) {
		croak $log->fatal(
			'parameter "naming" must be a String::License::Naming object')
			unless defined blessed($naming)
			and $naming->isa('String::License::Naming');
	}
	else {
		$naming = String::License::Naming::SPDX->new;
	}
}

=head1 METHODS

=over

=cut

method string
{
	return $string;
}

my $any           = '[A-Za-z_][A-Za-z0-9_]*';
my $str           = '[A-Za-z][A-Za-z0-9_]*';
my $re_prop_attrs = qr/
	\A(?'prop'$str)\.alt(?:
		\.org\.(?'org'$str)|
		\.version\.(?'version'$str)|
		\.since\.date_(?'since_date'\d{8})|
		\.until\.date_(?'until_date'\d{8})|
		\.synth\.$any|
		(?'other'\.$any)
	)*\z/x;

method best_value
{
	my ( $hashref, @props ) = @_;
	my $value;

	PROPERTY:
	for my $prop (@props) {
		for my $org ( $naming->list_schemes ) {
			for ( keys %$hashref ) {
				/$re_prop_attrs/;
				next unless $+{prop} and $+{prop} eq $prop;
				next unless $+{org}  and $+{org} eq $org;
				next if $+{version};
				next if $+{other};
				next if $+{until_date};

				$value = $hashref->{$_};
				last PROPERTY;
			}
		}
		$value ||= $hashref->{$prop};
	}

	return $value;
}

my $type_re
	= qr/^type:([a-z][a-z0-9_]*)(?::([a-z][a-z0-9_]*))?(?::([a-z][a-z0-9_]*))?/;

our %RE;
my ( %L, @RE_EXCEPTION, @RE_LICENSE, @RE_NAME );

method init_licensepatterns
{
	# reuse if already resolved
	return %L if exists $L{re_trait};

	Regexp::Pattern->import(
		're',
		'License::*' => (
			@OPT_RE2,
			subject             => 'trait',
			-prefix             => 'EXCEPTION_',
			-has_tag_matching   => '^type:trait:exception(?:\z|:)',
			-lacks_tag_matching => '^type:trait:exception:prefix(?:\z|:)',
		),
		'License::*' => (
			@OPT_RE2,
			capture             => 'named',
			subject             => 'trait',
			-prefix             => 'TRAIT_',
			-has_tag_matching   => '^type:trait(?:\z|:)',
			-lacks_tag_matching => '^type:trait:exception(?!:prefix)(?:\z|:)',
		),
		'License::version' => (
			@OPT_RE2,
			capture    => 'named',
			subject    => 'trait',
			anchorleft => 1,
			-prefix    => 'ANCHORLEFT_NAMED_',
		),
		'License::version_later' => (
			@OPT_RE2,
			capture    => 'named',
			subject    => 'trait',
			anchorleft => 1,
			-prefix    => 'ANCHORLEFT_NAMED_',
		),
		'License::any_of' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::by_fsf' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::fsf_unlimited' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::fsf_unlimited_retention' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::licensed_under' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::or_at_option' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::version' => (
			capture => 'numbered',
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_KEEP_',
		),
		'License::version_numberstring' => (
			capture => 'numbered',
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_KEEP_',
		),
		'License::apache' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::gpl' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::lgpl' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::mit' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::*' => (
			@OPT_RE2,
			subject             => 'name',
			-prefix             => 'NAME_',
			anchorleft          => 1,
			-lacks_tag_matching => '^type:trait(?:\z|:)',
		),
		'License::*' => (
			@OPT_RE2,
			subject             => 'grant',
			-prefix             => 'GRANT_',
			-lacks_tag_matching => '^type:trait(?:\z|:)',
		),
		'License::*' => (
			@OPT_RE2,
			subject             => 'license',
			-prefix             => 'LICENSE_',
			-lacks_tag_matching => '^type:trait(?:\z|:)',
		),
	);

	@RE_EXCEPTION = sort map /^EXCEPTION_(.*)/, keys(%RE);
	@RE_LICENSE   = sort map /^LICENSE_(.*)/,   keys(%RE);
	@RE_NAME      = sort map /^NAME_(.*)/,      keys(%RE);

	foreach my $key ( grep {/^[a-z]/} keys(%Regexp::Pattern::License::RE) ) {
		my $val = $Regexp::Pattern::License::RE{$key};
		$L{name}{$key} = $self->best_value( $val, 'name' ) || $key;
		$L{caption}{$key}
			= $self->best_value( $val, 'caption' ) || $val->{name} || $key;
		foreach ( @{ $val->{tags} } ) {
			/$type_re/ or next;
			$L{type}{$1}{$key} = 1;
			if ( $2 and $1 eq 'singleversion' ) {
				$L{series}{$key} = $2;
			}
			if ( $2 and $1 eq 'usage' ) {
				$L{usage}{$key} = $2;
			}

			# TODO: simplify, and require Regexp::Pattern::License v3.9.0
			if ( $3 and $1 eq 'trait' ) {
				if ( substr( $key, 0, 14 ) eq 'except_prefix_' ) {
					$L{TRAITS_exception_prefix}{$key} = undef;
				}
				else {
					$L{"TRAITS_$2_$3"}{$key} = undef;
				}
			}
		}
	}

	# FIXME: drop when perl doesn't mysteriously  freak out over it
	foreach (qw(any_of)) {
		$L{re_trait}{$_} = '';
	}

	#<<<  do not let perltidy touch this (keep long regex on one line)
	$L{multi_1} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_any_of}(?:[^.]|\.\S)*$RE{LOCAL_NAME_lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{multi_2} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_any_of}(?:[^.]|\.\S)*$RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{lgpl_5} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_NAME_lgpl}(?:$RE{LOCAL_TRAIT_by_fsf})?[,;:]?(?: either)? ?$RE{LOCAL_TRAIT_KEEP_version_numberstring},? $RE{LOCAL_TRAIT_or_at_option} $RE{LOCAL_TRAIT_KEEP_version_numberstring}/i;
	$L{gpl_7} = qr/either $RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?(?: \((?:the )?"?GPL"?\))?, or $RE{LOCAL_NAME_lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{bsd_1} = qr/THIS SOFTWARE IS PROVIDED (?:BY (?:\S+ ){1,15})?AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY/;
	$L{apache_1} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{apache_2} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?:[ -](\d)-clause)?\b/i;
	$L{apache_4} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $RE{LOCAL_NAME_mit}\b/i;
	$L{fsful} = qr/This (\w+)(?: (?:file|script))? is free software; $RE{LOCAL_TRAIT_fsf_unlimited}/i;
	$L{fsfullr} = qr/This (\w+)(?: (?:file|script))?  is free software; $RE{LOCAL_TRAIT_fsf_unlimited_retention}/i;
	$L{trailing_space} = qr/\s+$/;
	$L{LEFTANCHOR_version_of} = qr/^ of /;
	#>>>
}

# license objects where atomic scan must always be applied
my %L_grant_stepwise_incomplete = (

	# usage

	# singleversion
	apache_2 => 1,

	# versioned
	gpl  => 1,
	lgpl => 1,

	# other
	mit_new       => 1,    # misdetects ambiguous "MIT X11" grant
	public_domain => 1,
);

# license objects where stepwise scan cannot be skipped
my %L_grant_atomic_incomplete = (
	afl_1_1    => 1,
	afl_1_2    => 1,
	afl_2      => 1,
	afl_2_1    => 1,
	afl_3      => 1,
	apache_1_1 => 1,
	artistic_1 => 1,
	artistic_2 => 1,
	bsl_1      => 1,
	cc_by_2_5  => 1,
	cc_by_sa   => 1,
	cpl_1      => 1,
	mpl        => 1,
	mpl_1      => 1,
	mpl_1_1    => 1,
	mpl_2      => 1,
	openssl    => 1,
	postgresql => 1,
	zpl_2_1    => 1,
);

# scan for grants first stepwise and if not found then also atomic
# flip either of these flags to test stepwise/atomic pattern coverage
my $skip_stepwise = 0;
my $force_atomic  = 0;

my $contains_bsd2_re = qr/^license:contains:license:bsd_2_clause/;
my @L_contains_bsd   = grep {
	$Regexp::Pattern::License::RE{$_}{tags}
		and grep /$contains_bsd2_re/,
		@{ $Regexp::Pattern::License::RE{$_}{tags} }
} keys(%Regexp::Pattern::License::RE);

my $id2patterns_re = qr/(.*)(?:_(\d+(?:\.\d+)*)(_or_later)?)?/;

method resolve
{
	$self->init_licensepatterns;

	my @L_type_usage         = sort keys %{ $L{type}{usage} };
	my @L_type_singleversion = sort keys %{ $L{type}{singleversion} };
	my @L_type_versioned     = sort keys %{ $L{type}{versioned} };
	my @L_type_unversioned   = sort keys %{ $L{type}{unversioned} };
	my @L_type_combo         = sort keys %{ $L{type}{combo} };
	my @L_type_group         = sort keys %{ $L{type}{group} };

	my @spdx_gplver;

	my @agpl = qw(agpl agpl_1 agpl_2 agpl_3);
	my @gpl  = qw(gpl gpl_1 gpl_2 gpl_3);
	my @lgpl = qw(lgpl lgpl_2 lgpl_2_1 lgpl_3);

	my $coverage = Array::IntSpan->new();
	my %match;
	my ( %grant, %license );

   # @clues, @expressions, and @exceptions contains DEP-5 or SPDX identifiers,
   # and @flaws contains non-SPDX notes.
	my ( @clues, @expressions, @exceptions, @flaws );

	my $patterns2id = sub {
		my ( $id, $ver ) = @_;
		return $id
			unless ($ver);
		$_ = $ver;
		s/\.0$//g;
		s/\./_/g;
		return "${id}_$_";
	};
	my $id2patterns = sub {
		return $_[0] =~ /$id2patterns_re/;
	};
	my $gen_license = sub {
		my ( $id, $v, $later, $id2, $v2, $later2 ) = @_;
		my @spdx;
		my $name = $L{name}{$id}    || $id;
		my $desc = $L{caption}{$id} || $id;
		if ($v) {
			push @spdx, $later ? "$name-$v+" : "$name-$v";
			$v .= ' or later' if ($later);
		}
		else {
			push @spdx, $name;
		}
		my ( $name2, $desc2 );
		if ($id2) {
			$name2 = $L{name}{$id2}    || $id2;
			$desc2 = $L{caption}{$id2} || $id2;
			if ($v2) {
				push @spdx, $later2 ? "$name2-$v2+" : "$name2-$v2";
				$v2 .= ' or later' if ($later2);
			}
			else {
				push @spdx, $name2;
			}
		}
		my $legacy = join(
			' ',
			$desc,
			$v     ? "(v$v)"     : (),
			$desc2 ? "or $desc2" : (),
			$v2    ? "(v$v2)"    : (),
		);
		my $expr = join( ' or ', sort @spdx );
		push @expressions, Licensing->new( name => $expr );
		$license = join( ' ', $L{caption}{$legacy} || $legacy, $license );
	};

	# fulltext
	$log->trace('scan for license fulltext');
	my %pos_license;
	foreach my $id (@RE_LICENSE) {
		next unless ( $RE{"LICENSE_$id"} );
		while ( $string =~ /$RE{"LICENSE_$id"}/g ) {
			$pos_license{ $-[0] }{$id} = Trait->new(
				name  => "license($id)",
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
		}
	}

	foreach my $trait ( keys %{ $L{TRAITS_exception_prefix} } ) {

		next unless ( $string =~ /$RE{"TRAIT_$trait"}/ );
		while ( $string =~ /$RE{"TRAIT_$trait"}/g ) {
			next
				if (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				);
			push @clues,
				Trait->new(
				name  => $trait,
				begin => $-[0],
				end   => $+[0],
				file  => $self,
				);
		}
	}
	foreach my $pos ( sort { $a <=> $b } keys %pos_license ) {

		# pick longest or most specific among matched license fulltexts
		my @licenses = nsort_by { $pos_license{$pos}{$_}->end }
		grep { $pos_license{$pos}{$_} ? $pos_license{$pos}{$_}->end : () } (
			@L_type_group,
			@L_type_combo,
			@L_type_unversioned,
			@L_type_versioned,
			@L_type_singleversion,
			@L_type_usage,
		);
		my $license = pop @licenses;
		next unless ($license);
		next
			if defined(
			$coverage->get_range( $pos, $pos_license{$pos}{$license}->end )
				->get_element(0) );
		$coverage->set_range(
			$pos_license{$pos}{$license}->begin,
			$pos_license{$pos}{$license}->end,
			$pos_license{$pos}{$license}
		);
		$license{$license} = 1;
	}

	# grant, stepwise
	$log->trace('scan stepwise for license grant');
	foreach my $trait ( keys %{ $L{TRAITS_grant_prefix} } ) {

		while ( $string =~ /$RE{"TRAIT_$trait"}/g ) {
			next
				if (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				);
			push @clues,
				Trait->new(
				name  => $trait,
				begin => $-[0],
				end   => $+[0],
				file  => $self,
				);
		}
	}
	LICENSED_UNDER:
	foreach my $licensed_under (
		sort { $a->end <=> $b->end }
		grep { exists $L{TRAITS_grant_prefix}{ $_->name } } @clues
		)
	{
		my $pos = $licensed_under->end;

		# possible grant names
		my @grant_types = (
			@L_type_combo,
			@L_type_unversioned,
			@L_type_versioned,
			@L_type_singleversion,
			@L_type_usage,
		);

		# optional grant version
		my ( $version, $later );

		# scan for prepended version
		substr( $string, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
		if ( $+{version_number} ) {
			push @clues,
				Trait->new(
				name  => 'version',
				begin => $pos + $-[0],
				end   => $pos + $+[0],
				file  => $self,
				);
			$version = $+{version_number};
			if ( $+{version_later} ) {
				push @clues,
					Trait->new(
					name  => 'or_later',
					begin => $pos + $-[2],
					end   => $pos + $+[2],
					file  => $self,
					);
				$later = $+{version_later};
			}
			if (
				substr( $string, $pos + $+[0] ) =~ $L{LEFTANCHOR_version_of} )
			{
				push @clues,
					Trait->new(
					name  => 'version_of',
					begin => $pos + $-[0],
					end   => $pos + $+[0],
					file  => $self,
					);
				$pos += $+[0];
				@grant_types = @L_type_versioned;
			}
			else {
				$version = '';
			}
		}

		# scan for name
		foreach my $id (@RE_NAME) {
			if ( substr( $string, $pos ) =~ $RE{"NAME_$id"} ) {
				$match{$id}{name}{ $pos + $-[0] } = Trait->new(
					name  => "name($id)",
					begin => $pos + $-[0],
					end   => $pos + $+[0],
					file  => $self,
				);
			}
		}

		# pick longest matched license name
		# TODO: include all of most specific type when more are longest
		my @names = nsort_by { $match{$_}{name}{$pos}->end }
		grep { $match{$_} and $match{$_}{name} and $match{$_}{name}{$pos} }
			@grant_types;
		my $name = pop @names;
		if (    $name
			and $match{$name}{name}{$pos}
			and !defined(
				$coverage->get_range( $pos, $match{$name}{name}{$pos}->end )
					->get_element(0)
			)
			and ( !$skip_stepwise or $L_grant_atomic_incomplete{$name} )
			)
		{
			my $pos_end = $pos = $match{$name}{name}{$pos}->end;

			# may include version
			if ( !$version and grep { $_ eq $name } @L_type_versioned ) {
				substr( $string, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
				if ( $+{version_number} ) {
					push @clues, Trait->new(
						name  => 'version',
						begin => $pos + $-[0],
						end   => $pos + $+[0],
						file  => $self,
					);
					$version = $+{version_number};
					$pos_end = $pos + $+[1];
					if ( $+{version_later} ) {
						push @clues, Trait->new(
							name  => 'or_later',
							begin => $pos + $-[2],
							end   => $pos + $+[2],
							file  => $self,
						);
						$later   = $+{version_later};
						$pos_end = $pos + $+[2];
					}
				}
			}
			elsif ( !$version and grep { $_ eq $name } @L_type_singleversion )
			{
				substr( $string, $pos )
					=~ $RE{ANCHORLEFT_NAMED_version_later};
				if ( $+{version_later} ) {
					push @clues, Trait->new(
						name  => 'or_later',
						begin => $pos + $-[1],
						end   => $pos + $+[1],
						file  => $self,
					);
					$later   = $+{version_later};
					$pos_end = $pos + $+[1];
				}
			}
			if ($version) {
				$version =~ s/(?:\.0)+$//;
				$version =~ s/\./_/g;
				$name .= "_$version";
			}
			if ($later) {
				my $latername = "${name}_or_later";
				push @clues, Trait->new(
					name  => $latername,
					begin => $licensed_under->begin,
					end   => $pos_end,
					file  => $self,
				);
				$grant{$latername} = $clues[-1];
				next LICENSED_UNDER if grep { $grant{$_} } @RE_NAME;
			}
			$grant{$name} = Trait->new(
				name  => "grant($name)",
				begin => $licensed_under->begin,
				end   => $pos_end,
				file  => $self,
			);
			push @clues, $grant{$name};
		}
	}

	# GNU oddities
	if ( grep { $match{$_}{name} } @agpl, @gpl, @lgpl ) {
		$log->trace('scan for GNU oddities');

		# address in AGPL/GPL/LGPL
		while ( $string =~ /$RE{TRAIT_addr_fsf}/g ) {
			foreach (
				qw(addr_fsf_franklin_steet addr_fsf_mass addr_fsf_temple))
			{
				if ( defined $+{$_} ) {
					push @flaws, Flaw->new(
						id    => $Regexp::Pattern::License::RE{$_},
						begin => $-[0],
						end   => $+[0],
						file  => $self,
					);
				}
			}
		}
	}

	# exceptions
	# TODO: conditionally limit to AGPL/GPL/LGPL
	foreach (@RE_EXCEPTION) {
		if ( $string =~ $RE{"EXCEPTION_$_"} ) {
			my $exception = Exception->new(
				id    => $Regexp::Pattern::License::RE{$_},
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$coverage->set_range( $-[0], $+[0], $exception );
			push @exceptions, $exception;
		}
	}

	# oddities
	$log->trace('scan for oddities');

	# generated file
	if ( $string =~ $RE{TRAIT_generated} ) {
		push @flaws, Flaw->new(
			id    => $Regexp::Pattern::License::RE{generated},
			begin => $-[0],
			end   => $+[0],
			file  => $self,
		);
	}

	# multi-licensing
	my @multilicenses;

	# LGPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @lgpl ) {
		$log->trace('scan for LGPL dual-license grant');
		if ( $string =~ $L{multi_1} ) {
			my $meta = Trait->new(
				name  => 'grant(multi#1)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$log->tracef(
				'detected custom pattern multi#1: %s %s %s: %s',
				'lgpl', $1, $2, $-[0]
			);
			push @multilicenses, 'lgpl', $1, $2;
		}
	}

	# GPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @gpl ) {
		$log->trace('scan for GPL dual-license grant');
		if ( $string =~ $L{multi_2} ) {
			$log->tracef(
				'detected custom pattern multi#2: %s %s %s: %s',
				'gpl', $1, $2, $-[0]
			);
			push @multilicenses, 'gpl', $1, $2;
		}
	}

	$gen_license->(@multilicenses) if (@multilicenses);

	# LGPL
	if ( grep { $match{$_}{name} } @lgpl ) {
		$log->trace('scan for LGPL fulltext/grant');

		# LGPL, dual versions last
		if ( $string =~ $L{lgpl_5} ) {
			my $grant = Trait->new(
				name  => 'grant(lgpl#5)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$license = "LGPL (v$1 or v$2) $license";
			my $expr = "LGPL-$1 or LGPL-$2";
			push @expressions,
				Grant->new(
				name  => $expr,
				begin => $grant->begin,
				end   => $grant->end,
				file  => $grant->file,
				);
			$match{ 'lgpl_' . $1 =~ tr/./_/r }{custom} = 1;
			$match{ 'lgpl_' . $2 =~ tr/./_/r }{custom} = 1;
			$match{lgpl}{custom} = 1;
		}
	}

	# GPL or LGPL
	if ( grep { $match{$_}{name} } @gpl ) {
		$log->trace('scan for GPL or LGPL dual-license grant');
		if ( $string =~ $L{gpl_7} ) {
			my $grant = Trait->new(
				name  => "grant(gpl#7)",
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$gen_license->( 'gpl', $1, $2, 'lgpl', $3, $4 );
			$match{gpl}{custom}  = 1;
			$match{lgpl}{custom} = 1;
		}
	}

	# BSD
	if ( grep { $match{$_}{name} } @L_contains_bsd
		and $string =~ $L{bsd_1} )
	{
		$log->trace('scan for BSD fulltext');
		my $grant = Trait->new(
			name  => 'license(bsd#1)',
			begin => $-[0],
			end   => $+[0],
			file  => $self,
		);
		for ($string) {
			next if ( $license{bsd_4_clause} );
			if ( $string =~ $RE{TRAIT_clause_advertising} ) {
				my $grant = Trait->new(
					name  => 'clause_advertising',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->('bsd_4_clause');
				next;
			}
			next if ( $license{bsd_3_clause} );
			if ( $string =~ $RE{TRAIT_clause_non_endorsement} ) {
				my $grant = Trait->new(
					name  => 'clause_non_endorsement',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->('bsd_3_clause');
				next;
			}
			next if ( $license{bsd_2_clause} );
			if ( $string =~ $RE{TRAIT_clause_reproduction} ) {
				next
					if (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					);
				my $grant = Trait->new(
					name  => 'clause_reproduction',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->('bsd_2_clause');
				next;
			}
			$gen_license->('bsd');
		}
	}

	# Apache dual-licensed with GPL/BSD/MIT
	if ( $match{apache}{name} ) {
		$log->trace('scan for Apache license grant');
		for ($string) {
			if ( $string =~ $L{apache_1} ) {
				my $grant = Trait->new(
					name  => 'grant(apache#1)',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->( 'apache', $1, $2, 'gpl', $3, $4 );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
				next;
			}
			if ( $string =~ $L{apache_2} ) {
				my $grant = Trait->new(
					name  => 'grant(apache#2)',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->(
					'apache', $1, $2,
					$3 ? "bsd_${3}_clause" : ''
				);
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
				next;
			}
			if ( $string =~ $L{apache_4} ) {
				my $grant = Trait->new(
					name  => 'grant(apache#4)',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->( 'apache', $1, $2, 'mit', $3, $4 );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
				next;
			}
		}
	}

	# FSFUL
	# FIXME: add test covering this pattern
	$log->trace('scan for FSFUL fulltext');
	if ( not $license{fsful} ) {
		if ( $string =~ $L{fsful} ) {
			my $grant = Trait->new(
				name  => 'grant(fsful#1)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$license = "FSF Unlimited ($1 derivation) $license";
			my $expr = "FSFUL~$1";
			push @expressions,
				Fulltext->new(
				name  => $expr,
				begin => $grant->begin,
				end   => $grant->end,
				file  => $grant->file,
				);
			$match{fsful}{custom} = 1;
		}
	}

	# FSFULLR
	# FIXME: add test covering this pattern
	$log->trace('scan for FSFULLR fulltext');
	if ( not $license{fsfullr} ) {
		if ( $string =~ $L{fsfullr} ) {
			my $grant = Trait->new(
				name  => 'grant(fsfullr#1)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$license
				= "FSF Unlimited (with Retention, $1 derivation) $license";
			my $expr = "FSFULLR~$1";
			push @expressions,
				Fulltext->new(
				name  => $expr,
				begin => $grant->begin,
				end   => $grant->end,
				file  => $grant->file,
				);
			$match{fsfullr}{custom} = 1;
		}
	}

	# usage
	$log->trace('scan atomic for singleversion usage license grant');
	foreach my $id (@L_type_usage) {
		next if ( $match{$id}{custom} );
		if ( !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $string =~ $RE{"GRANT_$id"} ) {
				my $grant = Trait->new(
					name  => "grant($id)",
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				unless (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					)
				{
					$grant{$id} = Grant->new(
						name  => $id,
						begin => $grant->begin,
						end   => $grant->end,
						file  => $grant->file,
					);
				}
			}
		}

		if ( $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			);
			$gen_license->( $id2patterns->($id) );

			# skip singleversion and unversioned equivalents
			if ( $L{usage}{$id} ) {
				$log->tracef( 'flagged license object: %s', $id );
				$match{ $L{usage}{$id} }{custom} = 1;
				if ( $L{series}{ $L{usage}{$id} } ) {
					$log->tracef(
						'flagged license object: %s',
						$L{usage}{$id}
					);
					$match{ $L{series}{ $L{usage}{$id} } }{custom} = 1;
				}
			}
		}
	}

	# singleversion
	$log->trace('scan atomic for singleversion license grant');
	foreach my $id (@L_type_singleversion) {
		if (    !$license{$id}
			and !$grant{$id}
			and !$match{$id}{custom}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $string =~ $RE{"GRANT_$id"} ) {
				my $grant = Trait->new(
					name  => "grant($id)",
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				unless (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					)
				{
					$grant{$id} = Grant->new(
						name  => $id,
						begin => $grant->begin,
						end   => $grant->end,
						file  => $grant->file,
					);
				}
			}
		}

		if ( $license{$id} or $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			) if $grant{$id};
			$gen_license->( $id2patterns->($id) )
				unless ( $match{$id}{custom} );

			# skip unversioned equivalent
			if ( $L{series}{$id} ) {
				$log->tracef( 'flagged license object: %s', $id );
				$match{ $L{series}{$id} }{custom} = 1;
			}
		}
	}

	# versioned
	$log->trace('scan atomic for versioned license grant');
	foreach my $id (@L_type_versioned) {
		next if ( $match{$id}{custom} );

		# skip name part of another name detected as grant
		# TODO: use less brittle method than name of clue
		next
			if ( $id eq 'cc_by'
			and grep { $_->name eq 'grant(cc_by_sa_3)' } @clues );

		# skip embedded or referenced licenses
		next if ( $license{rpsl_1} and grep { $id eq $_ } qw(mpl python) );

		next if ( $license{$id} );
		if ( !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $RE{"GRANT_$id"} ) {
				if ( $string =~ $RE{"GRANT_$id"} ) {
					my $grant = Trait->new(
						name  => "grant($id)",
						begin => $-[0],
						end   => $+[0],
						file  => $self,
					);
					unless (
						defined(
							$coverage->get_range( $-[0], $+[0] )
								->get_element(0)
						)
						)
					{
						$grant{$id} = Grant->new(
							name  => $id,
							begin => $grant->begin,
							end   => $grant->end,
							file  => $grant->file,
						);
					}
				}
			}
		}

		if ( $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			);
			$gen_license->($id);
		}
	}

	# other
	# TODO: add @L_type_group
	$log->trace('scan atomic for misc fulltext/grant');
	foreach my $id ( @L_type_unversioned, @L_type_combo ) {
		next if ( !$license{$id} and $match{$id}{custom} );

		next
			unless ( $license{$id}
			or $grant{$id}
			or $L_grant_stepwise_incomplete{$id}
			or $force_atomic );

		# skip embedded or referenced licenses
		next if ( $license{caldera}        and $id eq 'bsd' );
		next if ( $license{cube}           and $id eq 'zlib' );
		next if ( $license{dsdp}           and $id eq 'ntp' );
		next if ( $license{mit_cmu}        and $id eq 'ntp_disclaimer' );
		next if ( $license{ntp_disclaimer} and $id eq 'ntp' );

		if (    !$license{$id}
			and !$grant{$id}
			and $string =~ $RE{"GRANT_$id"} )
		{
			my $grant = Trait->new(
				name  => "grant($id)",
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			unless (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				)
			{
				$grant{$id} = Grant->new(
					name  => $id,
					begin => $grant->begin,
					end   => $grant->end,
					file  => $grant->file,
				);
			}
		}
		if ( $license{$id} or $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			) if $grant{$id};
			$gen_license->($id);
		}
	}

	$license =~ s/$L{trailing_space}//;
	$expr = join( ' and/or ', sort map { $_->name } @expressions );
	$expr    ||= 'UNKNOWN';
	$license ||= 'UNKNOWN';
	if (@exceptions) {
		$expr = "($expr)"
			if ( @expressions > 1 );
		$expr .= ' with ' . join(
			'_AND_',
			sort map { $self->best_value( $_->id, 'name' ) } @exceptions
		) . ' exception';
	}
	if (@flaws) {
		$license .= ' [' . join(
			', ',
			sort map { $self->best_value( $_->id, qw(caption name) ) } @flaws
		) . ']';
	}
	$log->infof( 'resolved license expression: %s', $expr );

	return $self;
}

=item as_text

Returns identified licensing patterns as a string,
either structured as SPDX License Expressions,
or with scheme-less naming as a short description.

=cut

method as_text
{
	if ( $naming->list_schemes ) {
		$self->resolve
			unless $expr;

		return $expr;
	}

	$self->resolve
		unless $license;

	return $license;
}

=back

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

This program is based on the script "licensecheck" from the KDE SDK,
originally introduced by Stefan Westerfeld C<< <stefan@space.twc.de> >>.

  Copyright © 2007, 2008 Adam D. Barratt

  Copyright © 2016-2023 Jonas Smedegaard

  Copyright © 2017-2022 Purism SPC

This program is free software:
you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License
as published by the Free Software Foundation,
either version 3, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY;
without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy
of the GNU Affero General Public License along with this program.
If not, see <https://www.gnu.org/licenses/>.

=cut

1;
