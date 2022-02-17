package Test2::Tools::LicenseRegistry;

my $CLASS = __PACKAGE__;

use strict;
use warnings;

use Regexp::Pattern::License;

use base 'Exporter';
our @EXPORT = qw(license_org_metadata);

my %RE = %Regexp::Pattern::License::RE;

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

sub license_org_metadata
{
	my ( %opts, @args );
	for (@_) {
		next unless defined;
		if    ( !ref )          { push @args, $_ }
		elsif ( ref eq 'HASH' ) { @opts{ keys %$_ } = values %$_ }
		else                    { die "Bad ref: $_"; }
	}
	my ($org) = @args;

	my %names;
	for my $key ( keys %RE ) {
		next
			unless grep {
			/^(?:name|caption|summary)\.alt\.org\.$org(?:\.|\z)/
				and not /\.version\./
			}
			keys %{ $RE{$key} };

		my $date_but_1 = $opts{date};
		$date_but_1 = 1
			if defined $opts{date} and $opts{date} == 0;
		my @names     = get_org_props( $key, 'name',    $org, $opts{date} );
		my @captions  = get_org_props( $key, 'caption', $org, $date_but_1 );
		my @summaries = get_org_props( $key, 'summary', $org, $date_but_1 );
		my $name      = shift @names;

		if ($name) {
			for ( @names, @captions, @summaries ) {
				$names{$_} = $name;
			}
		}
	}

	return \%names;
}

sub get_org_props
{
	my ( $key, $prop, $org, $date ) = @_;
	my ( @main, @extra, $skipcount );

	for ( keys %{ $RE{$key} } ) {
		/$re_prop_attrs/;
		next unless $+{prop} and $+{prop} eq $prop;
		next unless $+{org}  and $+{org} eq $org;
		next if $+{version};
		if ( $+{since_date} ) {
			if ( defined $date and 1 < $date and $date < $+{since_date} ) {
				$skipcount++ unless $+{other};
				next;
			}
		}
		if ( $+{until_date} ) {
			if ( not defined $date or $+{until_date} <= $date ) {
				$skipcount++ unless $+{other};
				next;
			}
		}
		elsif ( defined $date and $date == 0 ) {
			$skipcount++ unless $+{other};
			next;
		}

		if ( $+{other} ) {
			push @extra, $RE{$key}{$_};
		}
		else {
			push @main, $RE{$key}{$_};
		}
	}
	die "More than one main $prop tied to $org for $key: ", join '; ', @main
		if @main > 1;
	if ( not @main and not $skipcount ) {
		if ( exists $RE{$key}{$prop} ) {
			push @main, $RE{$key}{$prop};
		}
		elsif ( $prop eq 'name' ) {
			push @main, $key;
		}
	}

	return @main, @extra;
}

1;
