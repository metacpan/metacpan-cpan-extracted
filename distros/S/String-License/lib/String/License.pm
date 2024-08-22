use v5.20;
use utf8;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Feature::Compat::Class 0.07;

=head1 NAME

String::License - detect source code license statements in a text string

=head1 VERSION

Version v0.0.11

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

package String::License v0.0.11;

use Carp         qw(croak);
use Log::Any     ();
use Scalar::Util qw(blessed);
use List::Util   qw(uniq);
use Array::IntSpan;
use Regexp::Pattern::License 3.4.0;
use Regexp::Pattern 0.2.12;
use String::License::Naming::Custom;
use String::License::Naming::SPDX;

use namespace::clean;

class Tag {
	field $name : param;
	field $desc : param;
	field $begin : param;
	field $end : param;

	method data () { return lc __CLASS__, $name, $desc, $begin, $end }
}

class Exception : isa(Tag) {;}

class Flaw : isa(Tag) {;}

class Licensing {
	field $name : param;
	field $desc : param;

	method data () { return lc __CLASS__, $name, $desc }
}

class Fulltext : isa(Tag) {;}

class Grant : isa(Tag) {;}

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

field $string : param = undef;

=item naming => OBJ

A L<String::License::Naming> object,
used to define license naming conventions.

By default uses L<String::License::Naming::SPDX>.

Since instantiation of naming schemes is expensive,
there can be a significant speed boost
in passing a pre-initialized naming object
when processing multiple strings.

=cut

field $naming : param = undef;

field $license = '';
field $expr    = '';

field $coverage;
field @loose_licensing;
field %fulltext;
field %grant;

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

	$coverage = Array::IntSpan->new();
}

=head1 METHODS

=over

=cut

method note ( $name, $begin = undef, $end = undef )
{
	my $obj;

	if ( ref($name) ) {
		$obj = $name;
		( undef, $name, undef, $begin, $end ) = $obj->data;
	}

	$log->tracef(
		'noted %s: %d-%d "%s"',
		$name, $begin, $end,
		substr( $string, $begin, $end - $begin )
	);

	return $obj
		if $obj;

	return [ $begin, $end ];
}

method tag ($obj)
{
	my ( $type, $name, $desc, $begin, $end ) = $obj->data;

	if ( $type eq 'licensing' ) {
		push @loose_licensing, [ $type, $name, $desc ];
	}
	else {
		$coverage->set_range( $begin, $end, [ $type, $name, $desc ] );
		$log->tracef(
			'tagged %s: %s: %d-%d',
			$type, $desc, $begin, $end
		);
	}

	return $obj;
}

method contains_tag ( $begin, $end )
{
	return defined( $coverage->get_range( $begin, $end )->get_element(0) );
}

method get_tags ()
{
	my ( @thing, %set );

	@thing = $coverage->get_range_list;
	$set{grant}{ $_->[1] } = $_ for @loose_licensing;
	for my $i ( 0 .. $#thing ) {
		my ( $begin, $end, $thing, $type, $key );

		( $begin, $end, $thing ) = $coverage->get_element($i);
		$type = $thing->[0];

		# TODO: drop fallback when all flaws have shortname
		$key = $thing->[1] || $thing->[2];

		next unless $type =~ /^[a-z]/;

		$set{$type}{$key} = $thing;
	}

	return (
		[ values %{ $set{fulltexts} }, values %{ $set{grant} } ],
		[ values %{ $set{exception} } ],
		[ values %{ $set{flaw} } ],
	);
}

method string ()
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

method best_value ( $hashref, @props )
{
	my $value;

	PROPERTY:
	for my $prop (@props) {
		for my $org ( $naming->list_schemes ) {
			for ( keys %$hashref ) {
				/$re_prop_attrs/;
				next
					if not defined $+{prop}
					or $+{prop} ne $prop
					or not defined $+{org}
					or $+{org} ne $org
					or defined $+{version}
					or defined $+{other}
					or defined $+{until_date};

				$value = $hashref->{$_};
				last PROPERTY;
			}
		}
		$value ||= $hashref->{$prop};
	}

	return $value;
}

method name_and_desc ($id)
{
	my ( $ref, %result );

	$ref = $Regexp::Pattern::License::RE{$id};
	$result{name} = $self->best_value( $ref, 'name' ) || $id;
	$result{desc}
		= $self->best_value( $ref, 'caption' ) || $ref->{name} || $id;

	return \%result;
}

my $license_contains_license_re
	= qr/^license:contains:license:([a-z][a-z0-9_]*)/;
my $type_re
	= qr/^type:([a-z][a-z0-9_]*)(?::([a-z][a-z0-9_]*))?(?::([a-z][a-z0-9_]*))?/;

our %RE;
my (%L, @EXCEPTIONS, @LICENSES, @NAMES, @USAGE, @SINGLEVERSION, @VERSIONED,
	@UNVERSIONED, @COMBO, @GROUP
);

method init_licensepatterns ()
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
			capture => 'named',
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

	my @license_containers;
	for my $key ( grep {/^[a-z]/} keys %Regexp::Pattern::License::RE ) {
		my $val = $Regexp::Pattern::License::RE{$key};

		( $L{name}{$key}, $L{caption}{$key} )
			= @{ $self->name_and_desc($key) }{ 'name', 'desc' };
		for ( @{ $val->{tags} } ) {
			if (/$license_contains_license_re/) {
				$L{contained_licenses}{$key}{$1} = undef;
				push @license_containers, $key;
			}
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
	for my $container (@license_containers) {
		for my $contained ( keys %{ $L{contained_licenses}{$container} } ) {
			if ( exists $L{contained_licenses}->{$contained} ) {
				$L{contained_licenses}{$container}{$_} = undef
					for keys %{ $L{contained_licenses}{$contained} };
			}
		}
	}

	# list by amount of contained licenses (fewest first),
	# then key length (longest first), then alphabetically
	@LICENSES = sort {
		keys %{ $L{contained_licenses}{$b} } <=>
			keys %{ $L{contained_licenses}{$a} }
			|| length($b) <=> length($a)
			|| $a cmp $b
		}
		map {/^LICENSE_(.*)/} keys %RE;

	# list by key length (longest first), then alphabetically
	@NAMES = sort { length($b) <=> length($a) || $a cmp $b }
		map {/^NAME_(.*)/} keys %RE;

	# list alphabetically
	@EXCEPTIONS = sort map {/^EXCEPTION_(.*)/} keys %RE;

	@USAGE = grep { exists $L{type}{usage}{$_} } @LICENSES;
	@SINGLEVERSION
		= grep { exists $L{type}{singleversion}{$_} } @LICENSES;
	@VERSIONED = grep { exists $L{type}{versioned}{$_} } @LICENSES;
	@UNVERSIONED
		= grep { exists $L{type}{unversioned}{$_} } @LICENSES;
	@COMBO = grep { exists $L{type}{combo}{$_} } @LICENSES;
	@GROUP = grep { exists $L{type}{group}{$_} } @LICENSES;

	# FIXME: drop when perl doesn't mysteriously  freak out over it
	$L{re_trait}{any_of} = '';

	#<<<  do not let perltidy touch this (keep long regex on one line)
	$L{multi_1} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_any_of}(?:[^.]|\.\S)*$RE{LOCAL_NAME_lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{multi_2} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_any_of}(?:[^.]|\.\S)*$RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{lgpl_5} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_NAME_lgpl}(?:$RE{LOCAL_TRAIT_by_fsf})?$RE{LOCAL_TRAIT_KEEP_version}(?:,? ?$RE{LOCAL_TRAIT_or_at_option} $RE{LOCAL_TRAIT_KEEP_version})?/i;
	$L{gpl_7} = qr/either $RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?(?: \((?:the )?"?GPL"?\))?, or $RE{LOCAL_NAME_lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{apache_1} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{apache_2} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?P<version_bsd>[ -](\d)-clause)?\b/i;
	$L{apache_4} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $RE{LOCAL_NAME_mit}\b/i;
	$L{fsful} = qr/This (\w+)(?: (?:file|script))? is free software; $RE{LOCAL_TRAIT_fsf_unlimited}/i;
	$L{fsfullr} = qr/This (\w+)(?: (?:file|script))?  is free software; $RE{LOCAL_TRAIT_fsf_unlimited_retention}/i;
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

my $id2patterns_re = qr/(.*)(?:_(\d+(?:\.\d+)*)(_or_later)?)?/;

method resolve ()
{
	$self->init_licensepatterns;

	my @spdx_gplver;

	my @agpl = qw(agpl agpl_1 agpl_2 agpl_3);
	my @gpl  = qw(gpl gpl_1 gpl_2 gpl_3);
	my @lgpl = qw(lgpl lgpl_2 lgpl_2_1 lgpl_3);

	my %match;

	my $patterns2id = sub ( $stem, $version = undef ) {
		return $stem
			unless ($version);
		$version =~ tr/./_/;
		$version =~ s/_0$//g;
		return "${stem}_$version";
	};
	my $id2patterns = sub ($id) {
		return $id =~ /$id2patterns_re/;
	};
	my $gen_license = sub (
		$id, $v = undef, $later = undef, $id2 = undef, $v2 = undef,
		$later2 = undef
		)
	{
		my ( @spdx, $name, $desc, $name2, $desc2, $legacy, $expr );

		$name = $L{name}{$id}    || $id;
		$desc = $L{caption}{$id} || $id;
		if ($v) {
			push @spdx, $later ? "$name-$v+" : "$name-$v";
			$v .= ' or later' if ($later);
		}
		else {
			push @spdx, $name;
		}
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
		$legacy = join(
			' ',
			$desc,
			$v     ? "(v$v)"     : (),
			$desc2 ? "or $desc2" : (),
			$v2    ? "(v$v2)"    : (),
		);
		$expr = join( ' or ', sort @spdx );
		$self->tag(
			Licensing->new(
				name => $expr,
				desc => $L{caption}{$legacy} || $legacy,
			)
		);
	};

	# fulltext
	$log->trace('scan for license fulltext');
	my %pos_license;
	for my $id (@LICENSES) {
		next unless ( $RE{"LICENSE_$id"} );
		while ( $string =~ /$RE{"LICENSE_$id"}/g ) {
			$pos_license{ $-[0] }{obj}{$id} = $self->note(
				Fulltext->new(
					%{ $self->name_and_desc($id) },
					begin => $-[0], end => $+[0]
				)
			);
			$pos_license{ $-[0] }{end}{$id} = $+[0];
		}
	}
	for my $trait ( keys %{ $L{TRAITS_exception_prefix} } ) {
		next unless ( $string =~ /$RE{"TRAIT_$trait"}/ );
		while ( $string =~ /$RE{"TRAIT_$trait"}/g ) {
			next if $self->contains_tag( $-[0], $+[0] );
			$self->note( $trait, $-[0], $+[0] );
		}
	}
	for my $pos ( sort { $a <=> $b } keys %pos_license ) {

		# pick longest or most specific among matched license fulltexts
		my ($longest)
			= sort { $b <=> $a } values %{ $pos_license{$pos}{end} };
		my @licenses = grep {
			exists $pos_license{$pos}{end}{$_}
				and $pos_license{$pos}{end}{$_} eq $longest
		} @LICENSES;
		my $id = $licenses[0];
		next
			if not $id
			or $self->contains_tag( $pos, $pos_license{$pos}{end}{$id} );
		$fulltext{$id} = $self->tag( $pos_license{$pos}{obj}{$id} );
	}

	# grant, stepwise
	my @prefixes;
	$log->trace('scan stepwise for license grant');
	for my $trait ( keys %{ $L{TRAITS_grant_prefix} } ) {
		while ( $string =~ /$RE{"TRAIT_$trait"}/g ) {
			next if $self->contains_tag( $-[0], $+[0] );
			push @prefixes, $self->note( $trait, $-[0], $+[0] );
		}
	}
	LICENSED_UNDER:
	for my $licensed_under ( sort { $a->[1] <=> $b->[1] } @prefixes ) {
		my $pos = $licensed_under->[1];

		# possible grant names
		my @grant_types = (
			@COMBO,
			@UNVERSIONED,
			@VERSIONED,
			@SINGLEVERSION,
			@USAGE,
		);

		# optional grant version
		my ( $version, $suffix );

		# scan for prepended version
		substr( $string, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
		if ( defined $+{version_number} ) {
			$self->note( 'version',        $pos + $-[0], $pos + $+[0] );
			$self->note( 'version_number', $pos + $-[1], $pos + $+[1] );
			$version = $+{version_number};
			if ( defined $+{version_later} ) {
				$self->note( 'version_later', $pos + $-[2], $pos + $+[2] );
				$suffix = '_or_later';
			}
			if ( defined $+{version_only} ) {
				$self->note( 'version_only', $pos + $-[4], $pos + $+[4] );
				$suffix = '_only';
			}
			if ( defined $+{version_of} ) {
				$self->note( 'version_of', $pos + $-[5], $pos + $+[5] );
				$pos += $+[0];
				@grant_types = @VERSIONED;
			}
			else {
				$version = '';
			}
		}

		# scan for name
		for my $id (@NAMES) {
			if ( substr( $string, $pos ) =~ $RE{"NAME_$id"} ) {
				$match{$id}{name}{ $pos + $-[0] }
					= $self->note( "name($id)", $pos + $-[0], $pos + $+[0] );
			}
		}

		# pick longest matched license name
		# TODO: include all of most specific type when more are longest
		my @names = sort {
			$match{$a}{name}{$pos}->[1] <=> $match{$b}{name}{$pos}->[1]
			}
			grep {
					$match{$_}
				and $match{$_}{name}
				and $match{$_}{name}{$pos}
			} @grant_types;
		my $name = $names[-1];
		if (    $name
			and $match{$name}{name}{$pos}
			and !$self->contains_tag( $pos, $match{$name}{name}{$pos}->[1] )
			and ( !$skip_stepwise or $L_grant_atomic_incomplete{$name} ) )
		{
			my $pos_end = $pos = $match{$name}{name}{$pos}->[1];

			# may include version
			if ( !$version and grep { $_ eq $name } @VERSIONED ) {
				substr( $string, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
				if ( defined $+{version_number} ) {
					$self->note(
						'version',
						$pos + $-[0], $pos + $+[0]
					);
					$self->note(
						'version_number',
						$pos + $-[1], $pos + $+[1]
					);
					$version = $+{version_number};
					if ( $+{version_later} ) {
						$self->note(
							'version_later',
							$pos + $-[2], $pos + $+[2]
						);
						$suffix = '_or_later';
					}
					if ( defined $+{version_only} ) {
						$self->note(
							'version_only',
							$pos + $-[4], $pos + $+[4]
						);
						$suffix = '_only';
					}
					$pos_end = $pos + $+[0];
				}
			}
			elsif ( !$version and grep { $_ eq $name } @SINGLEVERSION ) {
				substr( $string, $pos )
					=~ $RE{ANCHORLEFT_NAMED_version_later};
				if ( defined $+{version_later} ) {
					$self->note(
						'version_later',
						$pos + $-[1], $pos + $+[1]
					);
					$suffix  = '_or_later';
					$pos_end = $pos + $+[0];
				}
			}
			if ($version) {
				$version =~ tr/./_/;
				$version =~ s/(?:_0)+$//;
				$name .= "_$version";
			}
			if ($suffix) {
				my $latername = "$name$suffix";
				$grant{$latername} = $self->note(
					Grant->new(
						%{ $self->name_and_desc($latername) },
						begin => $licensed_under->[0], end => $pos_end
					)
				);
				next LICENSED_UNDER if grep { $grant{$_} } @NAMES;
			}
			$grant{$name} = $self->note(
				Grant->new(
					%{ $self->name_and_desc($name) },
					begin => $licensed_under->[0], end => $pos_end
				)
			);
		}
	}

	# GNU oddities
	if ( grep { $match{$_}{name} } @agpl, @gpl, @lgpl ) {
		$log->trace('scan for GNU oddities');

		# address in AGPL/GPL/LGPL
		while ( $string =~ /$RE{TRAIT_addr_fsf}/g ) {
			for my $id (
				qw(addr_fsf_franklin_steet addr_fsf_mass addr_fsf_temple))
			{
				if ( defined $+{$id} ) {
					$self->tag(
						Flaw->new(
							%{ $self->name_and_desc($id) },
							begin => $-[0], end => $+[0]
						)
					);
				}
			}
		}
	}

	# exceptions
	# TODO: conditionally limit to AGPL/GPL/LGPL
	for my $id (@EXCEPTIONS) {
		if ( $string =~ $RE{"EXCEPTION_$id"} ) {
			$self->tag(
				Exception->new(
					%{ $self->name_and_desc($id) },
					begin => $-[0], end => $+[0]
				)
			);
		}
	}

	# oddities
	$log->trace('scan for oddities');

	# generated file
	if ( $string =~ $RE{TRAIT_generated} ) {
		$self->tag(
			Flaw->new(
				%{ $self->name_and_desc('generated') },
				begin => $-[0], end => $+[0]
			)
		);
	}

	# multi-licensing
	my @multilicenses;

	# LGPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @lgpl ) {
		$log->trace('scan for LGPL dual-license grant');
		if ( $string =~ $L{multi_1} ) {
			$self->note( 'grant(multi#1)', $-[0], $+[0] );
			push @multilicenses, 'lgpl', $1, $2;
		}
	}

	# GPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @gpl ) {
		$log->trace('scan for GPL dual-license grant');
		if ( $string =~ $L{multi_2} ) {
			$self->note( 'grant(multi#2)', $-[0], $+[0] );
			push @multilicenses, 'gpl', $1, $2;
		}
	}

	$gen_license->(@multilicenses) if (@multilicenses);

	# LGPL
	for ( grep { $match{$_}{name} } @lgpl ) {
		$log->trace('scan for LGPL fulltext/grant');

		# LGPL, dual versions last
		if ( $string =~ $L{lgpl_5} ) {

			# TODO: simplify, and require Regexp::Pattern::License v3.11.0
			my $v2 = $+{version_number_2} // $-{version_number}[1] || next;

			$self->tag(
				Grant->new(
					name  => "LGPL-$+{version_number} or LGPL-$v2",
					desc  => "LGPL (v$+{version_number} or v$v2)",
					begin => $-[0], end => $+[0],
				)
			);
			$match{ 'lgpl_' . $+{version_number} =~ tr/./_/r }{custom} = 1;
			$match{ 'lgpl_' . $v2                =~ tr/./_/r }{custom} = 1;
			$match{lgpl}{custom} = 1;
		}
	}

	# GPL or LGPL
	if ( grep { $match{$_}{name} } @gpl ) {
		$log->trace('scan for GPL or LGPL dual-license grant');
		if ( $string =~ $L{gpl_7} ) {
			$self->note( "grant(gpl#7)", $-[0], $+[0] );
			$gen_license->(
				'gpl',  $-{version_number}[0], $-{version_later}[0],
				'lgpl', $-{version_number}[1], $-{version_later}[1],
			);
			$match{gpl}{custom}  = 1;
			$match{lgpl}{custom} = 1;
		}
	}

	# Apache dual-licensed with GPL/BSD/MIT
	if ( $match{apache}{name} ) {
		$log->trace('scan for Apache license grant');
		for ($string) {
			if ( $string =~ $L{apache_1} ) {
				$self->note( 'grant(apache#1)', $-[0], $+[0] );
				$gen_license->(
					'apache', $-{version_number}[0], $-{version_later}[0],
					'gpl',    $-{version_number}[1], $-{version_later}[1],
				);
				$match{ $patterns2id->( 'apache', $-{version_number}[0] ) }
					{custom} = 1;
				next;
			}
			if ( $string =~ $L{apache_2} ) {
				$self->note( 'grant(apache#2)', $-[0], $+[0] );
				$gen_license->(
					'apache', $+{version_number}, $+{version_later},
					$+{version_bsd} ? "bsd_$+{version_bsd}_clause" : ''
				);
				$match{ $patterns2id->( 'apache', $+{version_number} ) }
					{custom} = 1;
				next;
			}
			if ( $string =~ $L{apache_4} ) {
				$self->note( 'grant(apache#4)', $-[0], $+[0] );
				$gen_license->(
					'apache', $+{version_number}, $+{version_later},
					'mit',
				);
				$match{ $patterns2id->( 'apache', $+{version_number} ) }
					{custom} = 1;
				next;
			}
		}
	}

	# FSFUL
	# FIXME: add test covering this pattern
	$log->trace('scan for FSFUL fulltext');
	if (   !$fulltext{fsful}
		and $string =~ $L{fsful} )
	{
		$self->tag(
			Fulltext->new(
				name  => "FSFUL~$1",
				desc  => "FSF Unlimited ($1 derivation)",
				begin => $-[0], end => $+[0],
			)
		);
		$match{fsful}{custom} = 1;
	}

	# FSFULLR
	# FIXME: add test covering this pattern
	$log->trace('scan for FSFULLR fulltext');
	if (   !$fulltext{fsfullr}
		and $string =~ $L{fsfullr} )
	{
		$self->tag(
			Fulltext->new(
				name  => "FSFULLR~$1",
				desc  => "FSF Unlimited (with Retention, $1 derivation)",
				begin => $-[0], end => $+[0],
			)
		);
		$match{fsfullr}{custom} = 1;
	}

	# usage
	$log->trace('scan atomic for singleversion usage license grant');
	for my $id (@USAGE) {
		next if ( $match{$id}{custom} );
		if (    !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic )
			and $string =~ $RE{"GRANT_$id"} )
		{
			if ( $self->contains_tag( $-[0], $+[0] ) ) {
				$log->tracef( 'skip grant in covered range: %s', $id );
			}
			else {
				$grant{$id} = $self->tag(
					Grant->new(
						%{ $self->name_and_desc($id) },
						begin => $-[0], end => $+[0]
					)
				);
			}
		}

		if ( $grant{$id} ) {
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
	for my $id (@SINGLEVERSION) {
		if (    !$fulltext{$id}
			and !$grant{$id}
			and !$match{$id}{custom}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic )
			and $string =~ $RE{"GRANT_$id"} )
		{
			if ( $self->contains_tag( $-[0], $+[0] ) ) {
				$log->tracef( 'skip grant in covered range: %s', $id );
			}
			else {
				$grant{$id} = $self->tag(
					Grant->new(
						%{ $self->name_and_desc($id) },
						begin => $-[0], end => $+[0]
					)
				);
			}
		}

		if ( $fulltext{$id} or $grant{$id} ) {
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
	for my $id (@VERSIONED) {
		next
			if $match{$id}{custom}
			or ( $fulltext{rpsl_1} and grep { $id eq $_ } qw(mpl python) )
			or $fulltext{$id};
		if (    !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic )
			and $RE{"GRANT_$id"}
			and $string =~ $RE{"GRANT_$id"} )
		{
			if ( $self->contains_tag( $-[0], $+[0] ) ) {
				$log->tracef( 'skip grant in covered range: %s', $id );
			}
			else {
				$grant{$id} = $self->tag(
					Grant->new(
						%{ $self->name_and_desc($id) },
						begin => $-[0], end => $+[0]
					)
				);
			}
		}
		if ( $grant{$id} ) {
			$gen_license->($id);
		}
	}

	# other
	# TODO: add @GROUP
	$log->trace('scan atomic for misc fulltext/grant');
	for my $id ( @UNVERSIONED, @COMBO ) {
		next
			if (not $fulltext{$id}
			and not $grant{$id}
			and not $L_grant_stepwise_incomplete{$id}
			and not $force_atomic )
			or ( $fulltext{caldera}        and $id eq 'bsd' )
			or ( $fulltext{cube}           and $id eq 'zlib' )
			or ( $fulltext{dsdp}           and $id eq 'ntp' )
			or ( $fulltext{mit_cmu}        and $id eq 'ntp_disclaimer' )
			or ( $fulltext{ntp_disclaimer} and $id eq 'ntp' );

		if (    !$fulltext{$id}
			and !$grant{$id}
			and $string =~ $RE{"GRANT_$id"} )
		{
			if ( $self->contains_tag( $-[0], $+[0] ) ) {
				$log->tracef( 'skip grant in covered range: %s', $id );
			}
			else {
				$grant{$id} = $self->tag(
					Grant->new(
						%{ $self->name_and_desc($id) },
						begin => $-[0], end => $+[0]
					)
				);
			}
		}
		if ( $fulltext{$id} or $grant{$id} ) {
			$gen_license->($id);
		}
	}

	# Expressions and exceptions contain DEP-5 or SPDX identifiers;
	# flaws contain non-SPDX notes.
	my ( $licenses, $exceptions, $flaws ) = $self->get_tags;

	my @expressions = map { $_->[1] } @$licenses;
	my @license     = map { $_->[2] } @$licenses;
	$expr    = join( ' and/or ', sort @expressions );
	$license = join( ' and/or ', sort @license );
	$expr    ||= 'UNKNOWN';
	$license ||= 'UNKNOWN';

	if (@$exceptions) {
		$expr = "($expr)"
			if ( @expressions > 1 );
		$expr .= ' with ' . join(
			'_AND_',
			sort map { $_->[1] } @$exceptions
		) . ' exception';
	}
	if (@$flaws) {
		$license .= ' [' . join(
			', ',
			sort map { $_->[2] } @$flaws
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

method as_text ()
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
