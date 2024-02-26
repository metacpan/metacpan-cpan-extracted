#!/usr/bin/env perl
# PODNAME: process-api.pl
# ABSTRACT: Generates Perl and POD for Cowl

use strict;
use warnings;

use FindBin; ## no critic Community::DiscouragedModules
use lib "$FindBin::Bin/../lib";

BEGIN {
	$RDF::Cowl::no_gen = 1;
}

use feature qw(say postderef);
use Syntax::Construct qw(heredoc-indent);
use Function::Parameters;

package Cowl_API::C::DocComment {
	use Moo;
	use Sub::HandlesVia;
	use MooX::ShortHas;
	use feature qw(state);

	ro comment => ( default => '' );

	lazy text => method() {
		my $txt = $self->comment;
		$txt =~ s{\A\Q/**\E\n}{}sm;
		$txt =~ s{\n\s+\Q*/\E\z}{}sm;
		$txt =~ s{^\ \*(\ |$)}{}gm;
		$txt;
	};

	lazy header => method() {
		( $self->text =~ /\A([^.]+.)\s*$/ms )[0];
	};
}

package Cowl_API::C::Fdecl {
	use Moo;
	use Sub::HandlesVia;
	use MooX::ShortHas;
	use feature qw(state);
	use List::SomeUtils qw(lastidx);
	use PerlX::Maybe qw(maybe);

	use constant GLOBAL_CLASS => '__GLOBAL__';

	ro data => ();

	use overload '""' => \&to_string;

	lazy comment => method() {
		Cowl_API::C::DocComment->new( maybe comment => $self->data->{comment} );
	};
	method memberof()      { $self->data->{extract}{memberof} // GLOBAL_CLASS }
	method function_name() { $self->data->{extract}{fname} }

	method library() {
		lc( (split '_', $self->data->{visibility})[0] );
	}

	method visibility() {
		state $V_MAP = {
			COWL_INLINE => 'inline',
			COWL_PUBLIC => 'public',
			ULIB_INLINE => 'inline',
			ULIB_PUBLIC => 'public',
		};
		if( exists $V_MAP->{ $self->data->{visibility} } ) {
			return $V_MAP->{ $self->data->{visibility} };
		}
		die "Unknown visibility";
	}

	lazy doc_params => method() {
		[ $self->comment->text =~ /^\@param\s+.*?$/gm ];
	};

	lazy params_optional_bool => method() {
		[ map { !! ($_ =~ /\Q[optional]\E/) } $self->doc_params->@* ];
	};

	method args() {
		my $args = $self->data->{extract}{args};
		my @optional = $self->params_optional_bool->@*;
		my $last_nonoptional = lastidx { ! $_ } @optional;
		return [ map {
			my $idx = $_;
			my %arg = %{ $args->[$idx] };
			unless( exists $arg{void} ) {
				$arg{type} =~ s/\s*$//g;
				$arg{optional} = $optional[$idx];
				$arg{tail_optional} = $optional[$idx] && $idx > $last_nonoptional;
			}
			\%arg;
		} 0..@$args-1 ];
	}

	method return_type() {
		return ( map {
			my $type = $_;

			$type =~ s/\s*$//g;

			my ($comment_for_retainment) = $self->comment->text =~ /(
				(?: ^\@return \s+? (?: \[ [^\[\]]+? \] \s+? )? Retained \b)
				|
				(?: \QReturns a retained\E \b)
				|
				(?: \Qis retained\E \b)
			)/xm;
			my ($comment_for_null_on_error) = $self->comment->text =~ /(
				^ \@return .* \Qor NULL on error\E
			)/xm;
			{
				type => $type,

				retained   => !! do {
					$comment_for_retainment
				},
				unretained => !! do {
					# type is a pointer to CowlObject
					$type =~ /^Cowl.*\*/
					&&
					# but not a *Vocab const pointer (points to static variable)
					$type !~ /\QVocab const *\E/
					&&
					! $comment_for_retainment
				},
				retained_reason => $comment_for_retainment,

				null_on_error => defined $comment_for_null_on_error,
				null_on_error_reason => $comment_for_retainment,

				is_cowlanystar => !! do {
					$type =~ /^CowlAny.*\*/
				},
			};
		} $self->data->{extract}{return} )[0];
	}

	method to_string(@) {
		$self->data->{extract}{fname};
	}
}

package Cowl_API::C::Struct {
	use Moo;
	use Sub::HandlesVia;
	use MooX::ShortHas;
	use Regexp::Common qw /balanced/;

	ro data => ();

	use overload '""' => \&to_string;

	method struct()       { $self->data->{extract}{struct} }

	lazy abstract_text => method() {
		my $text = $self->data->{extract}{header};
		$text =~ s{\n}{ }sg; # fold
		$text =~ s{\.\z}{}; # remove period at end
		$text =~ s/$RE{balanced}{-parens=>'[]'}/substr($1,1,-1)/ge;
		$text =~ s/#Cowl/RDF::Cowl::/g;
		$text;
	};

	method to_string(@) {
		$self->struct;
	}
}

package Cowl_API::Translate {
	use feature qw(state);
	use Mu;
	use Path::Tiny;
	use B qw(perlstring);
	use Template;
	use Template::Toolkit::Simple ();
	use List::Util qw(all);
	use Module::Runtime qw(module_notional_filename);
	use boolean;

	use RDF::Cowl::Lib;

	use Object::Util magic => 0;

	ro 'process' => (
		handles => [qw(lib_path)],
	);

	lazy tt => method() {
		my $template = Template->new({
			INCLUDE_PATH => path($FindBin::Bin, 'tt'),
		});
	};

	lazy lib_gen_dir => method() {
		$self->lib_path->child(qw(RDF Cowl Lib Gen))
			->$_tap( 'mkdir' );
	};

	lazy bundle_gen_dir => method() {
		$self->lib_path->parent->child(qw(ffi))
			->$_tap( 'mkdir' );
	};

	method generate( $extract ) {
		$self->tt->process( 'Types.pm.tt',
			$self->types_vars( $extract ),
			$self->lib_gen_dir->child('Types.pm')->openw_utf8
		) || warn $self->tt->error;

		$self->lib_gen_dir->child(qw(Enum))->mkdir;
		$self->tt->process( 'Enum_OT.pm.tt',
			$self->object_type_vars( $extract ),
			$self->lib_gen_dir->child('Enum', 'ObjectType.pm')->openw_utf8
		) || warn $self->tt->error;

		$self->lib_gen_dir->child(qw(Class))->mkdir;
		for my $class (keys $extract->fdecl_data_group_by->%*) {
			next if !$ENV{RDF_COWL_GEN_GLOBAL} && $class eq Cowl_API::C::Fdecl->GLOBAL_CLASS;
			my $suffix = $self->_c2p_type_suffix( $class );
			my $class_vars = $self->class_vars( $extract, $class );
			$self->tt->process( 'Class.pm.tt',
				$class_vars,
				$self->lib_gen_dir->child(qw(Class), "$suffix.pm")->openw_utf8
			) || warn $self->tt->error;

			$self->tt->process( 'Class.pod.tt',
				$class_vars,
				$self->lib_gen_dir->child(qw(Class), "$suffix.pod")->openw_utf8
			) || warn $self->tt->error;

			$self->tt->process( 'Class.c.tt',
				$class_vars,
				$self->bundle_gen_dir->child("class-$suffix.gen.c")->openw_utf8
			) || warn $self->tt->error;
		}
	}

	method object_type_vars( $extract ) {
		my $data = $extract->object_type_data;

		my @names = map { $_->{enum} } $data->@*;
		my @types = map { $self->_c2p_type_to_package( $_->{type} ) } $data->@*;

		return +{
			names => \@names,
			types => \@types,
		};
	}

	method object_tree( $extract ) {
		my $struct_data = $extract->struct_data;

		my @tree_data;
		for my $s (@$struct_data) {
			next unless $s->struct =~ /^Cowl/;
			my $info;
			$info->{class} = my $perl_class = $self->_c2p_type_to_package($s->struct);
			my $perl_class_file = $self->lib_path->child( module_notional_filename($perl_class) );
			$info->{path} = $perl_class_file->relative( $self->lib_path->parent );

			my $perl_class_code = $perl_class_file->slurp_utf8;

			chomp(my $abstract_cmt = <<~EOF);
			# ABSTRACT: @{[ $s->abstract_text ]}
			EOF

			chomp(my $class_cmt = <<~EOF);
			# @{[ $s->struct ]}
			EOF

			for my $cmt ($abstract_cmt, $class_cmt) {
				push $info->{code}->@*, $cmt unless $perl_class_code =~ /^\Q@{[ $cmt ]}\E$/m;
			}

			if( exists $s->data->{extract}{extends} ) {
				# keep original order: more specific to less specific
				my @perl_parents = map { $self->_c2p_type_to_package($_) } $s->data->{extract}{extends}->@*;
				my $c;
				if( @perl_parents > 1 ) {
					chomp($c = <<~EOF);
					use parent qw(@{[ join " ", @perl_parents ]});
					EOF

				} else {
					chomp($c = <<~EOF);
					use parent '$perl_parents[0]';
					EOF
				}
				# Check for exact text:
				# $perl_class_code =~ /^\Q@{[ $c ]}\E$/m &&
				push $info->{code}->@*, $c unless all { $perl_class->isa( $_ ) } @perl_parents
			}

			$self->tt->process( 'object-tree.tt',
				$info
			) || warn $self->tt->error;

			push @tree_data, $info;
		}

		for my $info (@tree_data) {
		}
	}

	method _c2p_type_suffix($type) {
		die "Type $type does not begin with Cowl"
			unless my $suffix = $type =~ s/^Cowl//r;
		return $suffix;
	}

	method _c2p_type_to_package( $type ) {
		"RDF::Cowl::@{[ $self->_c2p_type_suffix($type) ]}";
	}

	method base_vars() {
		return +{
			perlstring => sub { return B::perlstring(@_) },
		};
	}

	method _c2p_type_to_ffi_type( $c_type ) {
		state $type_map = {
			'char const *' => 'string',
			'char *'       => 'string',
			'FILE *'       => 'FILE',
		};
		$c_type =~ s/\QUVec(CowlObjectPtr)\E/UVec_CowlObjectPtr/;
		$c_type =~ s/\QUHash(CowlObjectTable)\E/UHash_CowlObjectTable/;
		die "Undefined type" unless defined $c_type;
		state $ffi = RDF::Cowl::Lib->ffi;
		if( $c_type =~ /^(?<obj_ffi_type>(Cowl|U)\w+)(\s+const)?\Q *\E$/ ) {
			return $+{'obj_ffi_type'};
		}
		my $clean_type = $c_type =~ s/\s+$//r;
		if( exists $type_map->{$clean_type} ) {
			$type_map->{$clean_type}
		} elsif( eval { $ffi->type_meta( $clean_type ); 1 } ) {
			return $clean_type;
		} else {
			die "Unknown type $clean_type";
		}
	}

	method cowl_object_types($extract) {
		grep { ! /[ ]/ } map { s/\Q *\E$//r } grep { ! /\(/ && /Cowl/ && /\Q *\E$/ } $extract->types->@*;
	}

	method types_vars( $extract ) {
		state $ffi = RDF::Cowl::Lib->ffi;
		my $vars = $self->base_vars;
		$vars->{types}->@* = map {
			# Check if already defined.
			eval { $ffi->type_meta($_); 1 }
			? ()
			: +{
				typename => "object(@{[ $self->_c2p_type_to_package($_) ]})",
				alias    => $_,
			}
		}
		sort $self->cowl_object_types( $extract );

		$vars;
	}

	method class_vars( $extract, $class ) {
		state $prefix_underscore_static = {
			'CowlObject' => 'cowl',
		};
		state $ffi_type_to_type_tiny_static = {
			'string' => 'Str',
			'size_t' => 'PositiveOrZeroInt',
			'char'   => 'StrMatch[qr{\A.\z}]',
			'FILE'   => 'InstanceOf["FFI::C::File"]',
			'bool'   => 'BoolLike|InstanceOf["boolean"]',
		};
		my $vars = $self->base_vars;
		my $prefix_underscore = $prefix_underscore_static->{$class}
			// lc join "_", $self->split_camelcase($class)->@*;
		$vars->{class} = $class;
		$vars->{class_suffix} = $self->_c2p_type_suffix( $class );
		$vars->{library} = $class =~ /^Cowl/ ? 'cowl' : 'ulib';
		$vars->{bindings}->@* = map {
			my $fdecl = $_;
			my $incomplete = false;
			use DDP; p $fdecl;
			my $prefix_drop = $fdecl->function_name =~ s/\Q$prefix_underscore\E_//r;

			my $manual = exists RDF::Cowl::Lib->ffi->_attached_functions->{$fdecl->function_name}
				|| exists RDF::Cowl::Lib->ffi->_attached_functions->{ "COWL_WRAP_" . $fdecl->function_name};

			my $perl_func_name =
				# is main constructor ?
				$fdecl->function_name eq $prefix_underscore
				? ( $fdecl->library eq 'cowl'
					? 'new'
					: '_new'
				)
				: $class eq 'UVec_CowlObjectPtr'
				? ( $fdecl->function_name =~ /\Auvec_CowlObjectPtr\z/
					? ( do { $incomplete = true; "new" } ) # allocates on stack
					: ( $fdecl->function_name =~ /\Auvec_(.*)_CowlObjectPtr\z/ )[0]
				)
				: $class eq 'UHash_CowlObjectTable'
				? ( $fdecl->function_name =~ /\Au(h(?:ash|map|set))_CowlObjectTable\z/
					? ( do { $incomplete = true; "new_$1" } ) # allocates on stack
					: ( $fdecl->function_name =~ /\Au(h(?:ash|map|set)_.*)_CowlObjectTable\z/ )[0]
				)
				: $prefix_drop;

			my $binding = +{
				manual         => $manual,
				visibility     => $fdecl->visibility,
				c_func_name    => $fdecl->function_name,
				perl_func_name => $perl_func_name,
			};
			$binding->{args}->@* =
					map {

						if( exists $_->{void} ) {
							()
						} else {
							my $ffi_type;

							# Skip this type found in ustream.h for now.
							if( $_->{type} eq 'size_t *' ) {
								$incomplete = true;
							}

							eval { $ffi_type = $self->_c2p_type_to_ffi_type($_->{type}); 1; }
								or do {
									$incomplete = true;
									$ffi_type = $_->{type};
								};

							my $type_tiny_type = $ffi_type_to_type_tiny_static->{$ffi_type} // ucfirst($ffi_type);
							if( $_->{optional} ) {
								$type_tiny_type = "Maybe[ $type_tiny_type ]";
							}
							{
								ffi_type => $ffi_type,
								c_type   => $_->{type},
								type_tiny => {
									type => $type_tiny_type,
								},
								id       => $_->{param},
								meta    => $_,
							}
						}
					} $fdecl->args->@*;
			$binding->{return_type} = do {
				my $ffi_type;
				my $rt = $fdecl->return_type;
				eval { $ffi_type = $self->_c2p_type_to_ffi_type($rt->{type}); 1; } or do {
					$incomplete = true;
					$ffi_type = $rt->{type};
				};

				{
					ffi_type => $ffi_type,
					c_type   => $rt->{type},
					meta    => $rt,
				};
			};

			# If first arg does not match class
			$binding->{is_class_method} =
				$vars->{class_suffix}
				&& $binding->{args}->@* > 0
					&& $binding->{args}->[0]{ffi_type} !~ /Cowl(?:Any)?@{[ $vars->{class_suffix} ne 'Object' ? $vars->{class_suffix} : '' ]}/;

			$binding->{is_constructor} =
				$vars->{class_suffix}
				&& (
					$binding->{is_class_method}
					|| $binding->{args}->@* == 0
				) && $binding->{return_type}->{ffi_type} eq qq/Cowl@{[ $vars->{class_suffix} ]}/;

			$binding->{incomplete} = $incomplete;

			$binding->{comment} = $fdecl->comment->text
				=~ s{\Q, or NULL on error.\E$}{. Throws exception on error.}gmr
				=~ s{^\s*\@public \@memberof.*$}{}gmr
				=~ s{^\s*\@note You are responsible for releasing the returned object\.$}{}gmr
				=~ s{^\s*\@note The returned .* is retained, so you are responsible for releasing it\.$}{}gmr
				=~ s{\n+\z}{}gsr
				;

			$binding;
		} $extract->fdecl_data_group_by->{$class}->@*;

		$vars;

	}

=head2 split_camelcase

This does camel case word splitting with exceptions for:

=over 2

=item * C<CowlIStream>

=item * C<CowlOStream>

=item * C<CowlNAry*>

=back

=cut
	method split_camelcase($ident) {
		return [ $ident =~ /U(?:String|[IO]Stream|Time|Version)|[IO]Stream|NAry|[A-Z](?:[A-Z]+|[a-z]*)(?=$|[A-Z])/g ];
	}
}

package Cowl_API::Extract {
	use Mu;
	use experimental qw(refaliasing);
	no warnings qw(experimental::refaliasing);
	use boolean;
	use RDF::Cowl::Lib;
	use Module::Load qw(load);

	use Path::Tiny;
	use File::Find::Rule;
	use Regexp::Common qw/comment list/;

	use Sort::Key::Multi qw(iikeysort);
	use List::Util qw(uniq first);
	use List::SomeUtils qw(firstidx part);
	use List::Util::groupby qw(hgroupby);
	use Data::DPath qw(dpath);
	use PerlX::Maybe qw(provided_deref);
	use Capture::Tiny qw(capture_stdout);

	ro [ qw(root_path lib_path) ];

	lazy api_path => method() {
		$self->root_path->child(qw(include));
	};

	lazy header_paths => method() {
		[ map { path($_) } File::Find::Rule->file
			->name('*.h')
			->in( $self->api_path ) ];
	};

	lazy header_order => method() {
		my @order = (
			qr{/cowl_},
			qr{/u},
			qr{.*},
		);
		\@order;
	};

	lazy sorted_header_paths => method() {
		my @order = $self->header_order->@*;
		my @sorted = iikeysort {
				my $item = $_;
				my $first = firstidx { $item =~ $_ } @order;
				($first, length $_);
			} $self->header_paths->@*;
		\@sorted;
	};

	lazy fdecl_re => method() {
		my $re = qr{
			(?>
				(?<comment>
					$RE{comment}{C}
				)
				\n*+
			)??
			(?<fdecl>
				^
				(?:
					(?<visibility>(?:COWL|ULIB)_PUBLIC) [^;]+ ;
					|
					(?<visibility>(?:COWL|ULIB)_INLINE) [^\{]+ \{
				)
			)
		}xm;
	};

	lazy c_type_re => sub {
		my $type_re = qr{
			  \QUHash(CowlObjectTable) const *\E
			| \QUHash(CowlObjectTable) *\E
			| \QUVec(CowlObjectPtr) const *\E
			| \QUVec(CowlObjectPtr) *\E
			| \QCowlAny * const *\E
			| long\s+long
			| (?: \w+ (\s+ const)? \s* [*]+ \s*)
			| (?: \w+ \s+)
		}xm;
	};

	lazy fdecl_data => method() {
		my $re = $self->fdecl_re;
		my $all_data = $self->_process_re($re);

		my $type_re = $self->c_type_re;
		my $arg_re = qr{
				(?<type> $type_re) \s* (?<param> \w+ (\s*\[\])? )
			| (?<void> void )
			| (?<vargs> \Q...\E )
		}xm;
		my $c_func_re = qr{
			\A

			(?:(?:COWL|ULIB)_(?:PUBLIC|INLINE))

			\s+

			(?:
				(?<return>
					$type_re
				)
			)
			\s*
			(?:
				(?<fname>
					\w+
				)
			)
			\s*
			(?:
				\(
				\s*

				(?<fargs>
					(?: $arg_re \s*,\s*)*? $arg_re
				)
				\s*
				\)
			)?
		}xm;

		my %skip_func = map { $_ => 1 }
			# function pointer args
			qw(
				uistream
				uostream
			),
			# function pointer args for generated code
			qw(
				uhset_pi_CowlObjectTable
				uhmap_pi_CowlObjectTable
			),
			# optional: ifdef COWL_ENTITY_IDS
			qw(
				cowl_entity_get_id
				cowl_entity_with_id
			),
			# NOTE: Unimplemented in upstream source!
			# Thus not compiled in the library.
			qw(
				cowl_obj_prop_exp_get_prop
				cowl_ontology_iterate_disjoint_classes
			)
			;

		for my $data (@$all_data) {
			if( $data->{fdecl} =~ /^extern/m ) {
				warn "Skipping extern: @{[ $data->{fdecl} =~ y/\n/ /r ]}";
				next;
			}
			my ($func_name) = $data->{fdecl} =~ m/ \A [^(]*? (\w+) \s* \( (?!\s*\*) /xs;
			die "Could not extract function name from $data->{fdecl}" unless $func_name;

			$data->{extract}{func_name} = $func_name;

			next if exists $skip_func{$func_name};
			if( $data->{fdecl} =~ $c_func_re ) {
				my %matches = ( %+ );
				if( not defined $matches{fargs} ) {
					die "Could not find args for $func_name";
				}

				if( $data->{fdecl} !~ /^(UHash|UVec)\(/m ) {
					warn "Function name does not match: '$func_name' vs '$+{fname}'"
						unless $func_name eq $matches{fname};
				}

				$data->{extract}{fdecl_clean}  = $data->{fdecl} =~ s/\s*[;\{]\Z//sgr;
				$data->{extract}{fname}  = $matches{fname};
				$data->{extract}{return} = $matches{return} =~ s/\n//gr;
				$data->{extract}{fargs}  = $matches{fargs};
				$data->{extract}{args}   = [
					map {
						$_ =~ $arg_re;
						+{ %+ };
					} split /\s*,\s*/, $matches{fargs}
				];

				if( defined $data->{comment} ) {
					my @memberof = $data->{comment} =~ /\@public\s+\@memberof\s+(\w+)/msg;
					die "Function @{[ $data->{extract}{func_name} ]}: unexpected number of matches" if @memberof > 1;
					if( @memberof ) {
						$data->{extract}{memberof} = $memberof[0];
						$data->{extract}{global} = false;
					} else {
						$data->{extract}{global} = true;
					}
				} else {
					if( exists $data->{file} ) {
						warn "Function @{[ $data->{extract}{func_name} ]}: is undocumented";
					} else {
						$data->{extract}{memberof} = do {
							my $m;
							for ($data->{extract}{fname}) {
								if( /\Auvec_(.*_)?CowlObjectPtr\z/ ) {
									$m = 'UVec_CowlObjectPtr';
								} elsif( /\Auh(ash|map|set)_(.*_)?CowlObjectTable\z/ ) {
									$m = 'UHash_CowlObjectTable'
								}
							}
							$m;
						};
						$data->{extract}{global} = false;
					}
				}
			} else {
				die "Could not parse: @{[ $data->{fdecl} ]}";
			}
		}

		[ map { Cowl_API::C::Fdecl->new(data => $_) } @$all_data ];
	};

	lazy struct_data => method() {
		my $re = qr/
			(?<comment>
				$RE{comment}{C}
			)
		/xm;
		my $all_data = $self->_process_re($re);

		for my $data (@$all_data) {
			next unless $data->{comment} =~ /\@struct/;

			my $doc = Cowl_API::C::DocComment->new( comment => $data->{comment} );
			$data->{extract}{text} = $doc->text;

			die "Decomment failed" unless $data->{extract}{text} =~ /^\@struct/m;

			for \my %e ($data->{extract}) {
				($e{struct}) = $e{text} =~ /^\@struct\s+(\w+)/m;
				# multiple @extends
				$e{extends} = [ $e{text} =~ /^\@extends\s+(\w+)/gm ];
				delete $e{extends} unless $e{extends}->@*;

				$e{header} = $doc->header;
			}
		}

		[ map { defined $_->{extract} ? Cowl_API::C::Struct->new(data => $_) : () } @$all_data ];
	};

	lazy _param_types_code => method() {
		my $header = path($FindBin::Bin, 'tt', 'param_type.h.tt');
		my ($stdout) = capture_stdout {
			system( qw(cpp), Alien::Cowl->cflags, $header );
		};
		for ($stdout) {
			# keep from marker to end
			s/\A.*?(^\Q# 1 "START"\E)/$1/ms;
			# remove preprocessor lines
			s/^#.*//mg;

			# add new lines after
			s/[;}]/$&\n/g;

			# update scope
			s/^ COWL_PUBLIC/ULIB_PUBLIC/mg;
			s/^ static inline/ULIB_INLINE/mg;

			# update types
			s/_Bool/bool/mg;
			s/\QCowlAny * *\E/CowlAny **/g;
			s/\QCowlAny * const *\E/CowlAny * const * /g;
		}
		$stdout;
	};

	lazy object_type_data => method() {
		my $object_types_h = $self->api_path->child('cowl_object_type.h');
		my $start = '/// @name Base types';
		my $end   = '/// @name Markers';
		my $enum_data = ( $object_types_h->slurp_utf8 =~ m{
			\Q$start\E
			( .*? )
			\Q$end\E
		}xs )[0];

		my $enum_qr = qr{
			^ \s+ ///\s+(?<type>Cowl\w+) \s+ - \s+ .*? $
			\n+
			^ \s+ (?<enum>COWL_OT_\w+) (?:\s*?=\s*?0)? , $
		}xm;
		my $map = $self->_process_text( $enum_qr, $enum_data );

		return $map;
	};

	method _process_text($re, $txt, $file = undef) {
		my @data;
		while( $txt =~ /$re/g ) {
			push @data, {
				%+,
				provided_deref( ref $file eq 'Path::Tiny',
					sub { file => $file->relative($self->root_path) } ),
				pos  => pos($txt),
			};
		}
		return \@data;
	}

	method _process_re($re) {
		my @data;
		my @input = (
			$self->sorted_header_paths->@*,
			$self->_param_types_code
		);
		for my $file (@input) {
			my $txt = ref $file eq 'Path::Tiny'
				? $file->slurp_utf8
				: $file;
			push @data, $self->_process_text($re, $txt, $file )->@*;
		}
		\@data;
	}

	lazy types => method() {
		my $data = $self->fdecl_data;
		my %types;
		$types{$_} = 1 for map { s/const\s+\*$/*/r } dpath('//type')->match($data);
		$types{$_} = 1 for map { s/const\s+\*$/*/r } dpath('//return')->match($data);
		[ keys %types ]; 
	};


	lazy fdecl_data_group_by => method() {
		+{ hgroupby { $_->memberof } $self->fdecl_data->@* };
	};

	sub BUILD {
		Moo::Role->apply_roles_to_object(
			RDF::Cowl::Lib->ffi
			=> qw(AttachedFunctionTrackable));
		load 'RDF::Cowl';
	}
}

package Cowl_API::Process {
	use Mu;
	use CLI::Osprey;

	use Alien::Cowl;
	use Types::Path::Tiny qw/Path/;

	option 'root_path' => (
		is => 'ro',
		format => 's',
		doc => 'Root for Cowl',
		default => sub {
			Alien::Cowl->dist_dir;
		},
		isa => Path,
		coerce => 1,
	);

	option 'lib_path' => (
		is => 'ro',
		format => 's',
		doc => 'Root for lib',
		default => "$FindBin::Bin/../lib",
		isa => Path,
		coerce => 1,
	);

	lazy extract => method() {
		Cowl_API::Extract->new(
			map { $_ => $self->$_ } qw(root_path lib_path)
		)
	};

	lazy translate => method() { Cowl_API::Translate->new( process => $self ); };

	method run() {
		$self->extract;
		require Carp::REPL; Carp::REPL->import('repl'); repl();#DEBUG
	}

	subcommand generate => method() {
		$self->translate->generate( $self->extract );
	};

	subcommand 'object-tree' => method() {
		$self->translate->object_tree( $self->extract );
	};
}

package AttachedFunctionTrackable {
	use Mu::Role;
	use Sub::Uplevel qw(uplevel);
	use Hook::LexWrap;

	ro _attached_functions => ( default => sub { {} } );

	around attach => sub {
	    my ($orig, $self, $name) = @_;
	    my $real_name;
	    wrap 'FFI::Platypus::DL::dlsym',
		post => sub { $real_name = $_[1] if $_[-1] };
	    my $ret = uplevel 3, $orig, @_[1..$#_];
	    return $ret unless defined $real_name;
	    push $self->_attached_functions->{$real_name}->@*, {
		    c        => $real_name,
		    package  => (caller(2))[0],
		    perl     => ref($name) ? $name->[1] : $name,
		    args     => $_[3],
		    return   => $_[4],
	    };
	    $ret;
	}
}


Cowl_API::Process->new_with_options->run;
