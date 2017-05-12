package Template::Jade::Helpers;
use strict;
use warnings FATAL => 'all';

use feature ':5.12';

use HTML::Escape;

use Sub::Exporter -setup => {
	exports => [qw(
		gen_doctype
		printf_inline_sub
		gen_open_tag          gen_close_tag
		START_SUB  END_SUB
		is_self_closing
	)]
};


sub is_self_closing ($) {
	# source: http://www.w3.org/html/wg/drafts/html/master/syntax.html#void-elements
	state $SELF_CLOSING =  {map { $_, undef } qw(
		area      base  br     col     embed
		hr        img   input  keygen  link
		menuitem  meta  param  source  track
		wbr
	)};
	return exists $SELF_CLOSING->{$_[0]};
}

sub printf_inline_sub ($) {
	my $escape = shift;
	my $sub = 
		( $escape ? 'HTML::Escape::escape_html(' : '' )
		. q{
			sub {
				my $ret = eval{%s};
				die "Template::Jade [$@]" if $@;
				$ret;
			}->()
		}
		. ( $escape ? ');' :';' )
	;
	$sub =~ tr/\n//d;
	$sub;

};

sub gen_doctype {
	my ( $doctype ) = shift;

	state $doctypes = {
		'xml'            => '<?xml version="1.0" encoding="utf-8" ?>'
		, 'html'         => '<!DOCTYPE html>'
		, 'transitional' => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
		, 'strict'       => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
		, 'frameset'     => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'
		, '1.1'          => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
		, 'basic'        => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">'
		, 'mobile'       => '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">'
	};

	return $doctypes->{ $doctype };
}

sub gen_close_tag ($) {
	my $jade_tag = shift;
	die "Undefined jade tag sent to gen_close_tag"
		unless defined $jade_tag;
	$jade_tag =~ m/^( [.#]? [a-zA-Z_0-9]+ )/x;
	if ( $1 =~ qr/^[.#]/ ) {
		return '</div>';
	}
	elsif ( ! is_self_closing($1) ) {
		return "</" . lc $1 . '>';
	}
}

sub gen_open_tag ($) {
	my $jade_tag = shift;
	die "Undefined jade tag sent to gen_open_tag"
		unless defined $jade_tag;
	$jade_tag =~ m/^([a-zA-Z0-9_.#-]+) (?:\( ([^)]+ )\))?/x;

	my $tag = lc $1;

	my %attrs;
	my $literal;
	
	if ( $2 ) {
		for ( split /\s*,\s*/, $2 ) {
			my ( $k, $v ) = split /\s*=\s*/, $_, 2;
			$v =~ m/^(["']?) (\\?+.*)? \1/x;
			$literal = $1;
			push @{$attrs{lc $k}}, {
				literal => !!$1
				, value => $2
			};
		}
	}

	while ( $tag =~ s/([.#])([^\.\#]+)// ) {
		if ( $1 eq '.' ) {
			push @{$attrs{class}}, { literal => 1, value => $2 };
		}
		elsif ( $1 eq '#' ) {
			if ( defined $attrs{id} ) {
				die "Only one id attributed permited\n";
			}
			else {
				push @{$attrs{id}}, { literal => 1, value => $2 };
			}
		}
	
		if ( $tag eq '' ) {
			$tag = 'div';
		}
	}

	my $html = "<$tag";
	while ( my ($k, $arr) = each %attrs ) {
		my @attr;
		foreach my $v ( @$arr ) {
			if ( $v->{literal} ) {
				push @attr, quotemeta $v->{value};
			}
			else {
				push @attr, sprintf( q{$TEMPLATE{%s}}, quotemeta $v->{value} );
			}
		}
		$html .= sprintf( qq{ %s=\\"%s\\"}, $k, (join ' ', @attr) );
	}
	
	$html .= '>';

	return "$html";
}

use constant START_SUB => <<'EOF';
sub {
	use strict;
	my %TEMPLATE = %{$_[0]->{template}//{}};
	my %META     = %{$_[0]->{meta}//{}};
	undef @_;
EOF

use constant END_SUB => "\n};\n";

1;
