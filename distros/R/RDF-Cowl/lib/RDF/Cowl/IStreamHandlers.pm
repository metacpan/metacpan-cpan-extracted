package RDF::Cowl::IStreamHandlers;
# ABSTRACT: Ontology input stream handlers
$RDF::Cowl::IStreamHandlers::VERSION = '1.0.0';
# CowlIStreamHandlers
use strict;
use warnings;
use feature qw(state);
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::Platypus::Record;
use Scalar::Util qw(refaddr);
use Class::Method::Modifiers qw(around after);
use Types::Common qw(Optional CodeRef);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;

our %_INSIDE_OUT;

my $CALLBACK_INFO = {
	iri     => { element => '_iri'    , arg => 'CowlIRI'        },
	version => { element => '_version', arg => 'CowlIRI'        },
	import  => { element => '_import' , arg => 'CowlIRI'        },
	annot   => { element => '_annot'  , arg => 'CowlAnnotation' },
	axiom   => { element => '_axiom'  , arg => 'CowlAnyAxiom'   },
};

# (opaque, CowlIRI)->cowl_ret
$ffi->type( '(opaque, opaque)->int', 'cowl_istream_handlers_iri_closure_t' );

# (opaque, CowlIRI)->cowl_ret
$ffi->type( '(opaque, opaque)->int', 'cowl_istream_handlers_version_closure_t' );

# (opaque, CowlIRI)->cowl_ret
$ffi->type( '(opaque, opaque)->int', 'cowl_istream_handlers_import_closure_t' );

# (opaque, CowlAnnotation)->cowl_ret
$ffi->type( '(opaque, opaque)->int', 'cowl_istream_handlers_annot_closure_t' );

# (opaque, CowlAnyAxiom)->cowl_ret
$ffi->type( '(opaque, opaque)->int', 'cowl_istream_handlers_axiom_closure_t' );

record_layout_1($ffi,
	# void *ctx;
	opaque => '_ctx',

	# cowl_istream_handlers_iri_closure_t
	# cowl_ret (*iri)(void *ctx, CowlIRI *iri);
	opaque => '_iri',

	# cowl_istream_handlers_version_closure_t
	# cowl_ret (*version)(void *ctx, CowlIRI *version);
	opaque => '_version',

	# cowl_istream_handlers_import_closure_t
	# cowl_ret (*import)(void *ctx, CowlIRI *import);
	opaque => '_import',

	# cowl_istream_handlers_annot_closure_t
	# cowl_ret (*annot)(void *ctx, CowlAnnotation *annot);
	opaque => '_annot',

	# cowl_istream_handlers_axiom_closure_t
	# cowl_ret (*axiom)(void *ctx, CowlAnyAxiom *axiom);
	opaque => '_axiom',
);
$ffi->type('record(RDF::Cowl::IStreamHandlers)', 'CowlIStreamHandlers');

around new => sub {
	my $orig  = shift;
	my $class = shift;
	my $ret = $orig->($class);

	state $signature = signature (
		named => [
			map {
				$_ => Optional[CodeRef]
			} keys %$CALLBACK_INFO,
		],
	);

	my ( $args ) = $signature->(@_);

	for my $callback_name (keys %$CALLBACK_INFO) {
		if( defined( my $cb = $args->$callback_name ) ) {
			my $info = $CALLBACK_INFO->{$callback_name};
			my $element = $info->{element};
			my $closure = $ffi->closure(sub {
				my ($ctx, $object) = @_;
				return $ffi->cast(
					'cowl_ret' => 'int',
					$cb->(
						$ffi->cast( 'opaque' => $info->{arg}, $object )->_REBLESS,
					)
				);
			});
			$closure->sticky;
			$_INSIDE_OUT{refaddr $ret}{closure}{$callback_name} = $closure;
			$ret->$element(
				$ffi->cast( "cowl_istream_handlers_${callback_name}_closure_t" => 'opaque', $closure )
			);
		}
	}

	return $ret;
};

after DESTROY => sub {
	my ($self) = @_;
	return unless $self;
	return unless exists $_INSIDE_OUT{refaddr $self};
	my $closures = $_INSIDE_OUT{refaddr $self}{closure};
	for my $callback_name ( keys %$closures ) {
		$closures->{$callback_name}->unstick;
	}
	delete $_INSIDE_OUT{ refaddr $self };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::IStreamHandlers - Ontology input stream handlers

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
