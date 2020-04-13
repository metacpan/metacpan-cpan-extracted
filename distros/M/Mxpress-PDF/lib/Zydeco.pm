use 5.014;
use strict;
use warnings;
use B ();
use Carp ();
use Import::Into ();
use MooX::Press 0.048 ();
use MooX::Press::Keywords ();
use Syntax::Keyword::Try ();
use feature ();

package Zydeco;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.508';

use Keyword::Simple ();
use PPR;
use B::Hooks::EndOfScope;
use Exporter::Shiny our @EXPORT = qw( version authority overload );
use Devel::StrictMode qw(STRICT);

BEGIN {
	package Zydeco::_Gather;
	my %gather;
	my %stack;
	sub _already {
		my ($me, $caller) = @_;
		!!$gather{$me}{$caller};
	}
	sub import {
		my ($me, $action, $caller) = (shift, shift, scalar caller);
		if ($action eq -gather) {
			while (@_) {
				my ($k, $v) = splice @_, 0, 2;
				if (my ($kind,$pkg) = ($k =~ /^(class|role|class_generator|role_generator):(.+)$/)) {
					if ( my @stack = @{ $stack{$me}{$caller}||[] } ) {
						pop @stack if $stack[-1] eq $pkg;
						if (@stack) {
							$v->{_stack} = \@stack;
							$kind = '_defer_'.$kind;
						}
					}
					push @{ $gather{$me}{$caller}{$kind}||=[] }, $pkg, $v;
				}
				else {
					$gather{$me}{$caller}{$k} = $v;
				}
			}
		}
		elsif ($action eq -go) {
			if ($gather{$me}{$caller}{'_defer_role'}) {
				require Carp;
				Carp::croak('Nested roles are not supported');
			}
			if ($gather{$me}{$caller}{'_defer_role_generator'}) {
				require Carp;
				Carp::croak('Nested role generators are not supported');
			}
			if ($gather{$me}{$caller}{'_defer_class_generator'}) {
				$me->_undefer_class_generators($gather{$me}{$caller}{'class_generator'}||=[], delete $gather{$me}{$caller}{'_defer_class_generator'});
			}
			if ($gather{$me}{$caller}{'_defer_class'}) {
				$me->_undefer_classes($gather{$me}{$caller}{'class'}, delete $gather{$me}{$caller}{'_defer_class'});
			}
			
			if ($gather{$me}{$caller}{debug}) {
				require Data::Dumper;
				warn Data::Dumper::Dumper($gather{$me}{$caller});
			}
			
			delete $stack{$me}{$caller};
			@_ = ('MooX::Press' => delete $gather{$me}{$caller});
			goto \&MooX::Press::import;
		}
		elsif ($action eq -parent) {
			push @{ $stack{$me}{$caller}||=[] }, $_[0];
		}
		elsif ($action eq -unparent) {
			pop @{ $stack{$me}{$caller} };
		}
		else {
			die;
		}
	}
	sub _undefer_classes {
		my ($me, $classes, $d) = @_;
		my %class_hash = @{$classes||[]};
		my @deferred;
		my $max_depth = 0;
		while (@$d) {
			my ($class, $spec) = splice(@$d, 0, 2);
			$spec->{_class_name} = $class;
			$spec->{_depth}      = @{ $spec->{_stack} };
			push @deferred, $spec;
			$max_depth = $spec->{_depth} if $spec->{_depth} > $max_depth;
		}
		DEPTH: for my $depth (1 .. $max_depth) {
			SPEC: for my $spec (@deferred) {
				next SPEC unless $spec->{_depth} == $depth;
				my $parent_key = join('|', @{$spec->{_stack}});
				my $my_key     = join('|', @{$spec->{_stack}}, $spec->{_class_name});
				if (not $class_hash{$parent_key}) {
					require Carp;
					Carp::croak(sprintf(
						'%s is nested in %s but %s is not a class',
						$spec->{_class_name},
						$spec->{_stack}[-1],
						$spec->{_stack}[-1],
					));
				}
				push @{ $class_hash{$parent_key}{subclass} ||=[] }, $spec->{_class_name}, $spec;
				$class_hash{$my_key} = $spec;
			}
		}
		for my $spec (@deferred) {
			delete $spec->{_stack};
			delete $spec->{_class_name};
			delete $spec->{_depth};
		}
	}
	sub _undefer_class_generators {
		my ($me, $classes, $d) = @_;
		while (@$d) {
			my ($class, $spec) = splice(@$d, 0, 2);
			my $extends = $spec->{_stack}[-1];
			my $next = delete($spec->{code});
			$spec->{code} = sub {
				my $got = $next->(@_);
				$got->{extends} ||= [$extends];
				$got;
			};
			delete $spec->{_stack};
			push @$classes, $class, $spec;
		}
	}

	$INC{'Zydeco/_Gather.pm'} = __FILE__;
};

#
# GRAMMAR
#

our $GRAMMAR = qr{
	(?(DEFINE)
	
		(?<PerlKeyword>
		
			(?: include         (?&MxpIncludeSyntax)   )|
			(?: class           (?&MxpClassSyntax)     )|
			(?: abstract        (?&MxpAbstractSyntax)  )|
			(?: role            (?&MxpRoleSyntax)      )|
			(?: interface       (?&MxpRoleSyntax)      )|
			(?: toolkit         (?&MxpToolkitSyntax)   )|
			(?: begin           (?&MxpHookSyntax)      )|
			(?: end             (?&MxpHookSyntax)      )|
			(?: after_apply     (?&MxpHookSyntax)      )|
			(?: before_apply    (?&MxpHookSyntax)      )|
			(?: type_name       (?&MxpTypeNameSyntax)  )|
			(?: extends         (?&MxpExtendsSyntax)   )|
			(?: with            (?&MxpWithSyntax)      )|
			(?: requires        (?&MxpWithSyntax)      )|
			(?: has             (?&MxpHasSyntax)       )|
			(?: constant        (?&MxpConstantSyntax)  )|
			(?: coerce          (?&MxpCoerceSyntax)    )|
			(?: method          (?&MxpMethodSyntax)    )|
			(?: factory         (?&MxpFactorySyntax)   )|
			(?: factory         (?&MxpFactoryViaSyntax))|
			(?: before          (?&MxpModifierSyntax)  )|
			(?: after           (?&MxpModifierSyntax)  )|
			(?: around          (?&MxpModifierSyntax)  )|
			(?: multi           (?&MxpMultiSyntax)     )|
			(?: try             (?&TrySyntax)          )
		)#</PerlKeyword>
		
		(?<MxpSimpleIdentifier>
		
			(?&PerlIdentifier)|(?&PerlBlock)
		)#</MxpSimpleIdentifier>
		
		(?<MxpSimpleIdentifiers>
		
			(?&MxpSimpleIdentifier)
			(?:
				(?&PerlOWS)
				,
				(?&PerlOWS)
				(?&MxpSimpleIdentifier)
			)*
		)#</MxpSimpleIdentifiers>
		
		(?<MxpDecoratedIdentifier>
			
			(?: \+ )?                                     # CAPTURE:plus
			(?: \* | \$ )?                                # CAPTURE:asterisk
			(?: (?&MxpSimpleIdentifier) )                 # CAPTURE:name
			(?: \! | \? )?                                # CAPTURE:postfix
		)#</MxpDecoratedIdentifier>
		
		(?<MxpDecoratedIdentifierSolo>
			(?: (?&MxpDecoratedIdentifier) )   # deliberately non-capturing
		)#</MxpDecoratedIdentifierSolo>
		
		(?<MxpDecoratedIdentifiers>
		
			(?&MxpDecoratedIdentifier)
			(?:
				(?&PerlOWS)
				,
				(?&PerlOWS)
				(?&MxpDecoratedIdentifier)
			)*
		)#</MxpDecoratedIdentifiers>
		
		(?<MxpSimpleTypeSpec>
		
			~?(?&PerlBareword)(?&PerlAnonymousArray)?
		)#</MxpSimpleTypeSpec>
		
		(?<MxpTypeSpec>
		
			(?&MxpSimpleTypeSpec)
			(?:
				\s*\&\s*
				(?&MxpSimpleTypeSpec)
			)*
			(?:
				\s*\|\s*
				(?&MxpSimpleTypeSpec)
				(?:
					\s*\&\s*
					(?&MxpSimpleTypeSpec)
				)*
			)*
		)#</MxpTypeSpec>
		
		(?<MxpExtendedTypeSpec>
		
			(?&MxpTypeSpec)|(?&PerlBlock)
		)#</MxpExtendedTypeSpec>
		
		(?<MxpSignatureElement>
		
			(?&PerlOWS)
			(?: (?&MxpExtendedTypeSpec))?                 # CAPTURE:type
			(?&PerlOWS)
			(?:                                           # CAPTURE:name
				(?&PerlVariable) | (\*(?&PerlIdentifier))
			)
			(?:                                           # CAPTURE:postamble
				\? | ((?&PerlOWS)=(?&PerlOWS)(?&PerlTerm))
			)?
		)#</MxpSignatureElement>
		
		(?<MxpSignatureList>
			
			(?&MxpSignatureElement)
			(?:
				(?&PerlOWS)
				,
				(?&PerlOWS)
				(?&MxpSignatureElement)
			)*
		)#</MxpSignatureList>
		
		(?<MxpAttribute>
		
			:
			[^\W0-9]\w*
			(?:
				[(]
					[^\)]+
				[)]
			)?
		)#</MxpAttribute>
		
		(?<MxpRoleList>
		
			(?&PerlOWS)
			(?:
				(?&PerlBlock) | (?&PerlQualifiedIdentifier)
			)
			(?:
				(?:\s*\?) | (?: (?&PerlOWS)(?&PerlList))
			)?
			(?:
				(?&PerlOWS)
				,
				(?&PerlOWS)
				(?:
					(?&PerlBlock) | (?&PerlQualifiedIdentifier)
				)
				(?:
					(?:\s*\?) | (?: (?&PerlOWS)(?&PerlList))
				)?
			)*
		)#</MxpRoleList>
		
		(?<MxpCompactRoleList>
		
			(?&PerlOWS)
			(?:
				(?&PerlQualifiedIdentifier)
			)
			(?:
				(?:\s*\?) | (?: (?&PerlOWS)(?&PerlList))
			)?
			(?:
				(?&PerlOWS)
				,
				(?&PerlOWS)
				(?:
					(?&PerlQualifiedIdentifier)
				)
				(?:
					(?:\s*\?) | (?: (?&PerlOWS)(?&PerlList))
				)?
			)*
		)#</MxpCompactRoleList>
		
		(?<MxpIncludeSyntax>
		
			(?&PerlOWS)
			(?: (?&PerlQualifiedIdentifier) )?            # CAPTURE:name
			(?&PerlOWS)
		)#</MxpIncludeSyntax>
		
		(?<MxpClassSyntax>
		
			(?&PerlOWS)
			(?: [+] )?                                    # CAPTURE:plus
			(?: (?&PerlQualifiedIdentifier) )?            # CAPTURE:name
			(?&PerlOWS)
			(?:
				(?: (?&PerlVersionNumber) )                # CAPTURE:version
				(?&PerlOWS)
			)?
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?:
				extends
				(?&PerlOWS)
				(?: (?&MxpCompactRoleList) )               # CAPTURE:compact_extends
				(?&PerlOWS)
			)?
			(?:
				with
				(?&PerlOWS)
				(?: (?&MxpCompactRoleList) )               # CAPTURE:compact_with
				(?&PerlOWS)
			)?
			(?: (?&PerlBlock) )?                          # CAPTURE:block
			(?&PerlOWS)
		)#</MxpClassSyntax>
		
		(?<MxpAbstractSyntax>
			
			(?&PerlOWS)
			class
			(?&PerlOWS)
			(?: [+] )?                                    # CAPTURE:plus
			(?: (?&PerlQualifiedIdentifier) )?            # CAPTURE:name
			(?&PerlOWS)
			(?:
				(?: (?&PerlVersionNumber) )                # CAPTURE:version
				(?&PerlOWS)
			)?
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?:
				extends
				(?&PerlOWS)
				(?: (?&MxpCompactRoleList) )               # CAPTURE:compact_extends
				(?&PerlOWS)
			)?
			(?:
				with
				(?&PerlOWS)
				(?: (?&MxpCompactRoleList) )               # CAPTURE:compact_with
				(?&PerlOWS)
			)?
			(?: (?&PerlBlock) )?                          # CAPTURE:block
			(?&PerlOWS)
		)#</MxpAbstractSyntax>
		
		(?<MxpRoleSyntax>
		
			(?&PerlOWS)
			(?: (?&PerlQualifiedIdentifier) )?            # CAPTURE:name
			(?&PerlOWS)
			(?:
				(?: (?&PerlVersionNumber) )                # CAPTURE:version
				(?&PerlOWS)
			)?
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?:
				with
				(?&PerlOWS)
				(?: (?&MxpCompactRoleList) )               # CAPTURE:compact_with
				(?&PerlOWS)
			)?
			(?: (?&PerlBlock) )?                          # CAPTURE:block
			(?&PerlOWS)
		)#</MxpRoleSyntax>
		
		(?<MxpHookSyntax>
		
			(?&PerlOWS)
			(?: (?&PerlBlock) )                           # CAPTURE:hook
			(?&PerlOWS)
		)#</MxpHookSyntax>
		
		(?<MxpTypeNameSyntax>
		
			(?&PerlOWS)
			(?: (?&PerlIdentifier) )                      # CAPTURE:name
			(?&PerlOWS)
		)#</MxpTypeNameSyntax>
		
		(?<MxpToolkitSyntax>
		
			(?&PerlOWS)
			(?: (?&PerlIdentifier) )                      # CAPTURE:name
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:imports
						(?: (?&PerlQualifiedIdentifier)|(?&PerlComma)|(?&PerlOWS) )*
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
		)#</MxpToolkitSyntax>
		
		(?<MxpExtendsSyntax>
		
			(?&PerlOWS)
			(?:                                           # CAPTURE:list
				(?&MxpRoleList)
			)
			(?&PerlOWS)
		)#</MxpExtendsSyntax>
		
		(?<MxpWithSyntax>
		
			(?&PerlOWS)
			(?:                                           # CAPTURE:list
				(?&MxpRoleList)
			)
			(?&PerlOWS)
		)#</MxpWithSyntax>
		
		(?<MxpRequiresSyntax>
		
			(?&PerlOWS)
			(?: (?&MxpSimpleIdentifier) )                 # CAPTURE:name
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
		)#</MxpRequiresSyntax>
		
		(?<MxpHasSyntax>
		
			(?&PerlOWS)
			(?: (?&MxpDecoratedIdentifiers) )             # CAPTURE:name
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?: (?&PerlList) )                      # CAPTURE:spec
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?:
				[=]
				(?&PerlOWS)
				(?: (?&PerlAssignment) )                   # CAPTURE:default
			)?
			(?&PerlOWS)
		)#</MxpHasSyntax>
		
		(?<MxpConstantSyntax>
		
			(?&PerlOWS)
			(?: (?&PerlIdentifier) )                      # CAPTURE:name
			(?&PerlOWS)
			=
			(?&PerlOWS)
			(?: (?&PerlExpression) )                      # CAPTURE:expr
			(?&PerlOWS)
		)#</MxpConstantSyntax>
		
		(?<MxpMethodSyntax>
		
			(?&PerlOWS)
			(?: \$? (?&MxpSimpleIdentifier) )?            # CAPTURE:name
			(?&PerlOWS)
			(?: ( (?&MxpAttribute) (?&PerlOWS) )+ )?      # CAPTURE:attributes
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?: (?&PerlBlock) )                           # CAPTURE:code
			(?&PerlOWS)
		)#</MxpMethodSyntax>
		
		(?<MxpMultiSyntax>
		
			(?&PerlOWS)
			method
			(?&PerlOWS)
			(?: (?&MxpSimpleIdentifier) )                 # CAPTURE:name
			(?&PerlOWS)
			(?: ( (?&MxpAttribute) (?&PerlOWS) )+ )?      # CAPTURE:attributes
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?: (?&PerlBlock) )                           # CAPTURE:code
			(?&PerlOWS)
		)#</MxpMultiSyntax>
		
		(?<MxpModifierSyntax>
		
			(?&PerlOWS)
			(?: (?&MxpSimpleIdentifiers) )                # CAPTURE:name
			(?&PerlOWS)
			(?: ( (?&MxpAttribute) (?&PerlOWS) )+ )?      # CAPTURE:attributes
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?: (?&PerlBlock) )                           # CAPTURE:code
			(?&PerlOWS)
		)#</MxpModifierSyntax>
		
		# Easier to provide two separate patterns for `factory`
		
		(?<MxpFactorySyntax>
		
			(?&PerlOWS)
			(?: (?&MxpSimpleIdentifier) )                 # CAPTURE:name
			(?&PerlOWS)
			(?: ( (?&MxpAttribute) (?&PerlOWS) )+ )?      # CAPTURE:attributes
			(?&PerlOWS)
			(?:
				[(]
					(?&PerlOWS)
					(?:                                     # CAPTURE:sig
						(?&MxpSignatureList)?
					)
					(?&PerlOWS)
				[)]
			)?
			(?&PerlOWS)
			(?: (?&PerlBlock) )                           # CAPTURE:code
			(?&PerlOWS)
		)#</MxpFactorySyntax>
		
		(?<MxpFactoryViaSyntax>
		
			(?&PerlOWS)
			(?: (?&MxpSimpleIdentifier) )                 # CAPTURE:name
			(?&PerlOWS)
			(?:
				(: via )
				(?:                                        # CAPTURE:via
					(?&PerlBlock)|(?&PerlIdentifier)|(?&PerlString)
				)
			)?
			(?&PerlOWS)
		)#</MxpFactoryViaSyntax>
		
		(?<MxpCoerceSyntax>
		
			(?&PerlOWS)
			(?: from )?
			(?&PerlOWS)
			(?:                                           # CAPTURE:from
				(?&MxpExtendedTypeSpec)
			)
			(?&PerlOWS)
			(?: via )
			(?&PerlOWS)
			(?:                                           # CAPTURE:via
				(?&PerlBlock)|(?&PerlIdentifier)|(?&PerlString)
			)
			(?&PerlOWS)
			(?: (?&PerlBlock) )                           # CAPTURE:code
			(?&PerlOWS)
		)#</MxpCoerceSyntax>
		
		# try/catch/finally is implemented by another module
		# but we need to be able to grok it to be able to parse
		# blocks
		#
		(?<TrySyntax>
		
			(?&PerlOWS)
			(?: do )?
			(?&PerlOWS)
			(?&PerlBlock)
			(?:
				(?&PerlOWS)
				catch
				(?&PerlOWS)
				(?&PerlBlock)
			)?
			(?:
				(?&PerlOWS)
				finally
				(?&PerlOWS)
				(?&PerlBlock)
			)?
			(?&PerlOWS)
		)#</TrySyntax>
		
	)
	$PPR::GRAMMAR
}xso;

my %_fetch_re_cache;
sub _fetch_re {
	my $key = "@_";
	my $name = shift;
	my %opts = @_;
	
	$opts{anchor} ||= '';
	
	$_fetch_re_cache{$key} ||= do {
		"$GRAMMAR" =~ m{<$name>(.+)</$name>}s or die "could not fetch re for $name";
		(my $re = $1) =~ s/\)\#$//;
		my @lines = split /\n/, $re;
		for (@lines) {
			if (my ($named_capture) = /# CAPTURE:(\w+)/) {
				s/\(\?\:/\(\?<$named_capture>/;
			}
		}
		$re = join "\n", @lines;
		$opts{anchor} eq 'start' ? qr/ ^ $re $GRAMMAR   /xs :
		$opts{anchor} eq 'end'   ? qr/   $re $GRAMMAR $ /xs :
		$opts{anchor} eq 'both'  ? qr/ ^ $re $GRAMMAR $ /xs : qr/ $re $GRAMMAR /xs
	}
}

#
# HELPERS
#

sub _handle_signature_list {
	my $me = shift;
	my $sig = $_[0];
	my $seen_named = 0;
	my $seen_pos   = 0;
	my @parsed;
	
	return (
		0,
		'',
		'[]',
		'',
	) if !$sig;
	
	while ($sig) {
		$sig =~ s/^\s+//xs;
		last if !$sig;
		
		push @parsed, {};
		
		if ($sig =~ /^((?&PerlBlock)) $GRAMMAR/xso) {
			my $type = $1;
			$parsed[-1]{type}          = $type;
			$parsed[-1]{type_is_block} = 1;
			$sig =~ s/^\Q$type//xs;
			$sig =~ s/^((?&PerlOWS)) $GRAMMAR//xso;
		}
		elsif ($sig =~ /^((?&MxpTypeSpec)) $GRAMMAR/xso) {
			my $type = $1;
			$parsed[-1]{type}          = $type;
			$parsed[-1]{type_is_block} = 0;
			$sig =~ s/^\Q$type//xs;
			$sig =~ s/^((?&PerlOWS)) $GRAMMAR//xso;
		}
		else {
			$parsed[-1]{type} = 'Any';
			$parsed[-1]{type_is_block} = 0;
		}
		
		if ($sig =~ /^\*((?&PerlIdentifier)) $GRAMMAR/xso) {
			my $name = $1;
			$parsed[-1]{name}       = $name;
			$parsed[-1]{named}      = 1;
			$parsed[-1]{positional} = 0;
			++$seen_named;
			$sig =~ s/^\*\Q$name//xs;
			$sig =~ s/^((?&PerlOWS)) $GRAMMAR//xso;
		}
		elsif ($sig =~ /^((?&PerlVariable)) $GRAMMAR/xso) {
			my $name = $1;
			$parsed[-1]{name}       = $name;
			$parsed[-1]{named}      = 0;
			$parsed[-1]{positional} = 1;
			++$seen_pos;
			$sig =~ s/^\Q$name//xs;
			$sig =~ s/^((?&PerlOWS)) $GRAMMAR//xs;
		}
		
		if ($sig =~ /^\?/) {
			$parsed[-1]{optional} = 1;
			$sig =~ s/^\?((?&PerlOWS)) $GRAMMAR//xso;
		}
		elsif ($sig =~ /^=((?&PerlOWS))((?&PerlTerm)) $GRAMMAR/xso) {
			my ($ws, $default) = ($1, $2);
			$parsed[-1]{default} = $default;
			$sig =~ s/^=\Q$ws$default//xs;
			$sig =~ s/^((?&PerlOWS)) $GRAMMAR//xso;
		}
		
		if ($sig) {
			$sig =~ /^,/ or die "WEIRD SIGNATURE??? $sig";
			$sig =~ s/^,//;
		}
	}
	
	my @signature_var_list;
	my $type_params_stuff = '[';
	
	my (@head, @tail);
	if ($seen_named and $seen_pos) {
		while (@parsed and $parsed[0]{positional}) {
			push @head, shift @parsed;
		}
		while (@parsed and $parsed[-1]{positional}) {
			unshift @tail, pop @parsed;
		}
		if (grep $_->{positional}, @parsed) {
			require Carp;
			Carp::croak("Signature contains an unexpected mixture of positional and named parameters");
		}
		for my $p (@head, @tail) {
			my $is_optional = $p->{optional};
			$is_optional ||= ($p->{type} =~ /^Optional/s);
			if ($is_optional) {
				require Carp;
				Carp::croak("Cannot have optional positional parameter $p->{name} in signature with named parameters");
			}
			elsif ($p->{default}) {
				require Carp;
				Carp::croak("Cannot have positional parameter $p->{name} with default in signature with named parameters");
			}
			elsif ($p->{name} =~ /^[\@\%]/) {
				require Carp;
				Carp::croak("Cannot have slurpy parameter $p->{name} in signature with named parameters");
			}
		}
	}
	
	require B;

	my $extra = '';
	my $count = @parsed;
	while (my $p = shift @parsed) {
		$type_params_stuff .= B::perlstring($p->{name}) . ',' if $seen_named;
		if ($p->{name} =~ /^[\@\%]/) {
			die "Cannot have slurpy in non-final position" if @parsed;
			$extra .= sprintf(
				'my (%s) = (@_==%d ? %s{$_[-1]} : ());',
				$p->{name},
				$count,
				substr($p->{name}, 0, 1),
			);
			$p->{slurpy} = 1;
			if ($p->{type} eq 'Any') {
				$p->{type} = substr($p->{name}, 0, 1) eq '%' ? 'HashRef' : 'ArrayRef';
			}
		}
		else {
			push @signature_var_list, $p->{name};
		}
		
		if ($p->{type_is_block}) {
			$type_params_stuff .= sprintf('scalar(do %s)', $p->{type}) . ',';
		}
		else {
			$type_params_stuff .= B::perlstring($p->{type}) . ',';
		}
		if (exists $p->{optional} or exists $p->{default} or $p->{slurpy}) {
			$type_params_stuff .= '{';
			$type_params_stuff .= sprintf('optional=>%d,', !!$p->{optional}) if exists $p->{optional};
			$type_params_stuff .= sprintf('default=>sub{scalar(%s)},', $p->{default}) if exists $p->{default};
			$type_params_stuff .= sprintf('slurpy=>%d,', !!$p->{slurpy}) if exists $p->{slurpy};
			$type_params_stuff .= '},';
		}
	}
	
	@signature_var_list = '$arg' if $seen_named;
	$type_params_stuff .= ']';
	
	if (@head or @tail) {
		require Type::Params;
		'Type::Params'->VERSION(1.009002);
		my $head_stuff = join(q[,] => map { $_->{type_is_block} ? sprintf('scalar(do %s)', $_->{type}) : B::perlstring($_->{type}) } @head);
		my $tail_stuff = join(q[,] => map { $_->{type_is_block} ? sprintf('scalar(do %s)', $_->{type}) : B::perlstring($_->{type}) } @tail);
		my $opts = sprintf('{head=>%s,tail=>%s},', $head_stuff?"[$head_stuff]":0, $tail_stuff?"[$tail_stuff]":0);
		substr($type_params_stuff, 1, 0) = $opts; # insert options after "["
		unshift @signature_var_list, map $_->{name}, @head;
		push @signature_var_list, map $_->{name}, @tail;
	}
	
	return (
		$seen_named,
		join(',', @signature_var_list),
		$type_params_stuff,
		$extra,
	);
}

sub _handle_role_list {
	my $me = shift;
	my ($rolelist, $kind) = @_;
	my @return;
	
	while (length $rolelist) {
		$rolelist =~ s/^\s+//xs;
		
		my $prefix = '';
		my $role = undef;
		my $role_is_block = 0;
		my $suffix = '';
		my $role_params   = undef;
		
		if ($rolelist =~ /^((?&PerlBlock)) $GRAMMAR/xso) {
			$role = $1;
			$role_is_block = 1;
			$rolelist =~ s/^\Q$role//xs;
			$rolelist =~ s/^\s+//xs;
		}
		elsif ($rolelist =~ /^((?&PerlQualifiedIdentifier)) $GRAMMAR/xso) {
			$role = $1;
			$rolelist =~ s/^\Q$role//xs;
			$rolelist =~ s/^\s+//xs;
		}
		else {
			die "expected role name, got $rolelist";
		}
		
		if ($rolelist =~ /^\?/xs) {
			die 'unexpected question mark' if $kind eq 'class';
			$suffix = '?';
			$rolelist =~ s/^\?\s*//xs;
		}
		elsif ($rolelist =~ /^((?&PerlList)) $GRAMMAR/xso) {
			$role_params = $1;
			$rolelist =~ s/^\Q$role_params//xs;
			$rolelist =~ s/^\s+//xs;
		}
		
		if ($role_is_block) {
			push @return, sprintf('sprintf(q(%s%%s%s), scalar(do %s))', $prefix, $suffix, $role);
		}
		else {
			push @return, B::perlstring("$prefix$role$suffix");
		}
		if ($role_params) {
			push @return, sprintf('[%s]', $role_params);
		}
		
		$rolelist =~ s/^\s+//xs;
		if (length $rolelist) {
			$rolelist =~ /^,/ or die "expected comma, got $rolelist";
			$rolelist =~ s/^\,\s*//;
		}
	}
	
	return join(",", @return);
}

sub _handle_name_list {
	my ($me, $names) = @_;
	return unless $names;
	
	state $re = _fetch_re('MxpDecoratedIdentifierSolo');
	my @names = grep defined, ($names =~ /($re) $GRAMMAR/xg);
	return @names;
}

sub _handle_factory_keyword {
	my ($me, $name, $via, $code, $has_sig, $sig, $attrs) = @_;
	
	my $optim;
	for my $attr (@$attrs) {
		$optim = 1 if $attr =~ /^:optimize\b/;
	}
	
	if ($via) {
		return sprintf(
			'q[%s]->_factory(%s, \\(%s));',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			($via  =~ /^\{/ ? "scalar(do $via)"  : B::perlstring($via)),
		);
	}
	if (!$has_sig) {
		my $munged_code = sprintf('sub { my ($factory, $class) = (@_); do %s }', $code);
		return sprintf(
			'q[%s]->_factory(%s, { caller => __PACKAGE__, code => %s, optimize => %d });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$optim ? B::perlstring($munged_code) : $munged_code,
			!!$optim,
		);
	}
	my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
	my $munged_code = sprintf('sub { my($factory,$class,%s)=(shift,shift,@_); %s; do %s }', $signature_var_list, $extra, $code);
	sprintf(
		'q[%s]->_factory(%s, { caller => __PACKAGE__, code => %s, named => %d, signature => %s, optimize => %d });',
		$me,
		($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
		$optim ? B::perlstring($munged_code) : $munged_code,
		!!$signature_is_named,
		$type_params_stuff,
		!!$optim,
	);
}

sub _handle_method_keyword {
	my $me = shift;
	my ($name, $code, $has_sig, $sig, $attrs) = @_;
	
	my $optim;
	for my $attr (@$attrs) {
		$optim = 1 if $attr =~ /^:optimize\b/;
	}
	
	my $lex_name;
	if (defined $name and $name =~ /^\$(.+)$/) {
		$lex_name = $name;
	}
	
	my $return = '';
	
	if (defined $name and not defined $lex_name) {
		if ($has_sig) {
			my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
			my $munged_code = sprintf('sub { my($self,%s)=(shift,@_); %s; my $class = ref($self)||$self; do %s }', $signature_var_list, $extra, $code);
			$return = sprintf(
				'q[%s]->_can(%s, { caller => __PACKAGE__, code => %s, named => %d, signature => %s, optimize => %d });',
				$me,
				($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
				$optim ? B::perlstring($munged_code) : $munged_code,
				!!$signature_is_named,
				$type_params_stuff,
				!!$optim,
			);
		}
		else {
			my $munged_code = sprintf('sub { my $self = $_[0]; my $class = ref($self)||$self; do %s }', $code);
			$return = sprintf(
				'q[%s]->_can(%s, { caller => __PACKAGE__, code => %s, optimize => %d });',
				$me,
				($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
				$optim ? B::perlstring($munged_code) : $munged_code,
				!!$optim,
			);
		}
	}
	else {
		if ($has_sig) {
			my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
			my $munged_code = sprintf('sub { my($self,%s)=(shift,@_); %s; my $class = ref($self)||$self; do %s }', $signature_var_list, $extra, $code);
			$return = sprintf(
				'q[%s]->wrap_coderef({ caller => __PACKAGE__, code => %s, named => %d, signature => %s, optimize => %d });',
				'MooX::Press',
				$optim ? B::perlstring($munged_code) : $munged_code,
				!!$signature_is_named,
				$type_params_stuff,
				!!$optim,
			);
		}
		else {
			my $munged_code = sprintf('sub { my $self = $_[0]; my $class = ref($self)||$self; do %s }', $code);
			$return = sprintf(
				'q[%s]->wrap_coderef({ caller => __PACKAGE__, code => %s, optimize => %d });',
				'MooX::Press',
				$optim ? B::perlstring($munged_code) : $munged_code,
				!!$optim,
			);
		}
	}
	
	if ($lex_name) {
		return "my $lex_name = $return";
	}
	
	return $return;
}

sub _handle_multimethod_keyword {
	my $me = shift;
	my ($name, $code, $has_sig, $sig, $attrs) = @_;
	
	my $optim;
	my $extra_code = '';
	for my $attr (@$attrs) {
		$optim = 1 if $attr =~ /^:optimize\b/;
		$extra_code .= sprintf('alias=>%s', B::perlstring($1)) if $attr =~ /^:alias\((.+)\)$/;
	}
	
	if ($has_sig) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
		my $munged_code = sprintf('sub { my($self,%s)=(shift,@_); %s; my $class = ref($self)||$self; do %s }', $signature_var_list, $extra, $code);
		return sprintf(
			'q[%s]->_multimethod(%s, { caller => __PACKAGE__, code => %s, named => %d, signature => %s, %s });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$munged_code,
			!!$signature_is_named,
			$type_params_stuff,
			$extra_code,
		);
	}
	else {
		my $munged_code = sprintf('sub { my $self = $_[0]; my $class = ref($self)||$self; do %s }', $code);
		return sprintf(
			'q[%s]->_multimethod(%s, { caller => __PACKAGE__, code => %s, named => 0, signature => sub { @_ }, %s });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$munged_code,
			$extra_code,
		);
	}
}

sub _handle_modifier_keyword {
	my ($me, $kind, $names, $code, $has_sig, $sig, $attrs) = @_;

	my $optim;
	for my $attr (@$attrs) {
		$optim = 1 if $attr =~ /^:optimize\b/;
	}
	
	my @names = $me->_handle_name_list($names);
	
	my $processed_names =
		join q[, ],
		map { /^\{/ ? "scalar(do $_)" : B::perlstring($_) } @names;

	if ($has_sig) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
		my $munged_code;
		if ($kind eq 'around') {
			$munged_code = sprintf('sub { my($next,$self,%s)=(shift,shift,@_); %s; my $class = ref($self)||$self; do %s }', $signature_var_list, $extra, $code);
		}
		else {
			$munged_code = sprintf('sub { my($self,%s)=(shift,@_); %s; my $class = ref($self)||$self; do %s }', $signature_var_list, $extra, $code);
		}
		sprintf(
			'q[%s]->_modifier(q(%s), %s, { caller => __PACKAGE__, code => %s, named => %d, signature => %s, optimize => %d });',
			$me,
			$kind,
			$processed_names,
			$optim ? B::perlstring($munged_code) : $munged_code,
			!!$signature_is_named,
			$type_params_stuff,
			!!$optim,
		);
	}
	elsif ($kind eq 'around') {
		my $munged_code = sprintf('sub { my ($next, $self) = @_; my $class = ref($self)||$self; do %s }', $code);
		sprintf(
			'q[%s]->_modifier(q(%s), %s, { caller => __PACKAGE__, code => %s, optimize => %d });',
			$me,
			$kind,
			$processed_names,
			$optim ? B::perlstring($munged_code) : $munged_code,
			!!$optim,
		);
	}
	else {
		my $munged_code = sprintf('sub { my $self = $_[0]; my $class = ref($self)||$self; do %s }', $code);
		sprintf(
			'q[%s]->_modifier(q(%s), %s, { caller => __PACKAGE__, code => %s, optimize => %d });',
			$me,
			$kind,
			$processed_names,
			$optim ? B::perlstring($munged_code) : $munged_code,
			!!$optim,
		);
	}
}

sub _handle_package_keyword {
	my ($me, $kind, $name, $version, $compact_extends, $compact_with, $code, $has_sig, $sig, $plus, $opts) = @_;
	
	my $compact_code = '';
	if ($compact_extends) {
		$compact_code .= sprintf('q[%s]->_extends(%s);', $me, $me->_handle_role_list($compact_extends, 'class'));
	}
	if ($compact_with) {
		$compact_code .= sprintf('q[%s]->_with(%s);', $me, $me->_handle_role_list($compact_with, 'role'));
	}
	if ($version) {
		$compact_code .= sprintf('%s::version(%s);', $me, $version =~ /^[0-9]/ ? B::perlstring($version) : $version);
	}
	
	if ($kind eq 'abstract') {
		$kind = 'class';
		$code = "{ q[$me]->_abstract(1);  $compact_code $code }";
	}
	elsif ($kind eq 'interface') {
		$kind = 'role';
		$code = "{ q[$me]->_interface(1); $compact_code $code }";
	}
	elsif (length $compact_code) {
		$code = "{ $compact_code $code }";
	}
	
	if ($name and $has_sig) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
		my $munged_code = sprintf('sub { q(%s)->_package_callback(sub { my ($generator,%s)=(shift,@_); %s; do %s }, @_) }', $me, $signature_var_list, $extra, $code);
		sprintf(
			'use Zydeco::_Gather -parent => %s; use Zydeco::_Gather -gather, %s => { code => %s, named => %d, signature => %s }; use Zydeco::_Gather -unparent;',
			B::perlstring("$plus$name"),
			B::perlstring("$kind\_generator:$plus$name"),
			$munged_code,
			!!$signature_is_named,
			$type_params_stuff,
		);
	}
	elsif ($has_sig) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
		my $munged_code = sprintf('sub { q(%s)->_package_callback(sub { my ($generator,%s)=(shift,@_); %s; do %s }, @_) }', $me, $signature_var_list, $extra, $code);
		sprintf(
			'q[%s]->anonymous_generator(%s => { code => %s, named => %d, signature => %s }, toolkit => %s, prefix => %s, factory_package => %s, type_library => %s)',
			$me,
			$kind,
			$munged_code,
			!!$signature_is_named,
			$type_params_stuff,
			B::perlstring($opts->{toolkit}||'Moo'),
			B::perlstring($opts->{prefix}),
			B::perlstring($opts->{factory_package}),
			B::perlstring($opts->{type_library}),
		);
	}
	elsif ($name) {
		$code
			? sprintf(
				'use Zydeco::_Gather -parent => %s; use Zydeco::_Gather -gather, %s => q[%s]->_package_callback(sub %s); use Zydeco::_Gather -unparent;',
				B::perlstring("$plus$name"),
				B::perlstring("$kind:$plus$name"),
				$me,
				$code,
			)
			: sprintf(
				'use Zydeco::_Gather -gather, %s => {};',
				B::perlstring("$kind:$plus$name"),
			);
	}
	else {
		$code ||= '{}';
		sprintf(
			'q[%s]->anonymous_package(%s => sub { do %s }, toolkit => %s, prefix => %s, factory_package => %s, type_library => %s)',
			$me,
			$kind,
			$code,
			B::perlstring($opts->{toolkit}||'Moo'),
			B::perlstring($opts->{prefix}),
			B::perlstring($opts->{factory_package}),
			B::perlstring($opts->{type_library}),
		);
	}
}

sub _handle_has_keyword {
	my ($me, $names, $rawspec, $default) = @_;
	
	$rawspec = '()' if !defined $rawspec;
	
	if (defined $default and $default =~ /\$self/) {
		$rawspec = "lazy => !!1, default => sub { my \$self = \$_[0]; $default }, $rawspec";
	}
	elsif (defined $default) {
		$rawspec = "default => sub { $default }, $rawspec";
	}
	
	my @names = $me->_handle_name_list($names);
	
	my @r;
	for my $name (@names) {
		$name =~ s/^\+\*/+/;
		$name =~ s/^\*//;
		
		if ($name =~ /^\$(.+)$/) {
			my $display_name = $1;
			unshift @r, "my $name";
			push @r, sprintf(
				'q[%s]->_has(%s, is => "private", accessor => \\%s, %s)',
				$me,
				($display_name =~ /^\{/) ? "scalar(do $display_name)" : B::perlstring($display_name),
				$name,
				$rawspec,
			);
		}
		else {
			push @r, sprintf(
				'q[%s]->_has(%s, %s)',
				$me,
				($name =~ /^\{/) ? "scalar(do $name)" : B::perlstring($name),
				$rawspec,
			);
		}
	}
	join ";", @r;
}

sub _handle_requires_keyword {
	my ($me, $name, $has_sig, $sig) = @_;
	my $r1 = sprintf(
		'q[%s]->_requires(%s);',
		$me,
		($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
	);
	my $r2 = '';
	if (STRICT and $has_sig) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff, $extra) = $me->_handle_signature_list($sig);
		$r2 = sprintf(
			'q[%s]->_modifier(q(around), %s, { caller => __PACKAGE__, code => %s, named => %d, signature => %s, optimize => %d });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			'sub { my $next = shift; goto $next }',
			!!$signature_is_named,
			$type_params_stuff,
			1,
		);
	}
	"$r1$r2";
}

sub _syntax_error {
	require Carp;
	if (ref $_[-1]) {
		my $ref = pop;
		my ($me, $kind, @poss) = @_;
		Carp::croak(
			"Unexpected syntax in $kind.\n" .
			"Expected:\n" .
			join("", map "\t$_\n", @poss) .
			"Got:\n" .
			"\t" . substr($$ref, 0, 32)
		);
	}
	else {
		my ($me, $kind, $msg) = @_;
		Carp::croak("Unexpected syntax in $kind.\n" . $msg);
	}
}

my $owed = 0;
sub _inject {
	my ($me, $ref, $trim_length, $new_code, $pad_at_end) = @_;
	$pad_at_end ||= 0;
	
	my @orig_lines = split /\n/, substr($$ref, 0, $trim_length), -1;
	my @new_lines  = split /\n/, $new_code, -1;
	
	if ($#orig_lines > $#new_lines) {
		my $diff = $#orig_lines - $#new_lines;
		if ($owed and $owed > $diff) {
			$owed -= $diff;
			$diff = 0;
		}
		elsif ($owed) {
			$diff -= $owed;
			$owed = 0;
		}
		my $prefix = "\n" x $diff;
		$new_code = $pad_at_end ? $new_code.$prefix : $prefix.$new_code;
	}
	elsif ($#orig_lines < $#new_lines) {
		$owed += ($#new_lines - $#orig_lines);
	}
	
	substr $$ref, 0, $trim_length, $new_code;
}

#
# KEYWORDS/UTILITIES
#

my @EXPORTABLES = qw(
	-booleans
	-privacy
	-utils
	-types
	-is
	-assert
	-features
	try
	class abstract role interface
	begin end before_apply after_apply
	include toolkit extends with requires
	has constant method multi factory before after around
	type_name coerce
	version authority overload
);

sub unimport {
	Keyword::Simple::undefine($_) for qw<
	class abstract role interface
	begin end before_apply after_apply
	include toolkit extends with requires
	has constant method multi factory before after around
	type_name coerce
	version authority overload
	>;
	goto \&Exporter::Tiny::unimport;
}

sub import {
	no warnings 'closure';
	my ($me, %opts) = (shift, @_);
	my $caller = ($opts{caller} ||= caller);
	
	if ('Zydeco::_Gather'->_already($caller)) {
		require Carp;
		Carp::croak("Zydeco is already in scope");
	}
	
	require MooX::Press;
	'MooX::Press'->_apply_default_options(\%opts);
	
	my %want = map +($_ => 1), @{ $opts{keywords} || \@EXPORTABLES };
	
	# Optionally export wrapper subs for pre-declared types
	#
	if ($opts{declare}) {
		my $types = $opts{type_library};
		for my $name (@{ $opts{declare} }) {
			eval qq{
				sub $caller\::$name         ()   { goto \\&$types\::$name }
				sub $caller\::is_$name      (\$) { goto \\&$types\::is_$name }
				sub $caller\::assert_$name  (\$) { goto \\&$types\::assert_$name }
				1;
			} or die($@);
		}
	}
	
	# Export utility stuff
	#
	Zydeco::_Gather->import::into($caller, -gather => %opts);
	strict->import::into($caller);
	warnings->import::into($caller);
	MooX::Press::Keywords->import::into($caller, $_)
		for grep $want{$_}, qw(-booleans -privacy -util);
	Syntax::Keyword::Try->import::into($caller) if $want{try};
	if ($] >= 5.018) {
		feature->import::into($caller, qw( say state unicode_strings unicode_eval evalbytes current_sub fc ))
			if $want{-features};
	}
	elsif ($] >= 5.014) {
		feature->import::into($caller, qw( say state unicode_strings ))
			if $want{-features};
	}
	my @libs = qw/ Types::Standard Types::Common::Numeric Types::Common::String /;
	push @libs, $opts{type_library} if $opts{type_library}->isa('Type::Library');
	for my $library (@libs) {
		$library->import::into($caller, $_)
			for grep $want{$_}, qw( -types -is -assert );
	}
	
	# `include` keyword
	#
	Keyword::Simple::define include => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpIncludeSyntax', anchor => 'start') or $me->_syntax_error(
			'include directive',
			'include <name>',
			$ref,
		);
		
		my ($pos, $name) = ($+[0], $+{name});
		my $qualified = 'MooX::Press'->qualify_name($name, $opts{prefix});
		$me->_inject($ref, $pos, sprintf('BEGIN { eval(q[%s]->_include(%s)) or die($@) };', $me, B::perlstring($qualified)));
	} if $want{include};

	# `class` keyword
	#
	Keyword::Simple::define class => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpClassSyntax', anchor => 'start') or $me->_syntax_error(
			'class declaration',
			'class <name> (<signature>) { <block> }',
			'class <name> { <block> }',
			'class <name>',
			'class (<signature>) { <block> }',
			'class { <block> }',
			'class;',
			$ref,
		);
		
		my ($pos, $plus, $name, $version, $sig, $compact_extends, $compact_with, $block) = ($+[0], $+{plus}, $+{name}, $+{version}, $+{sig}, $+{compact_extends}, $+{compact_with}, $+{block});
		my $has_sig = !!exists $+{sig};
		$plus  ||= '';
		$block ||= '{}';
		
		$me->_inject($ref, $pos, "\n#\n#\n#\n#\n".$me->_handle_package_keyword(class => $name, $version, $compact_extends, $compact_with, $block, $has_sig, $sig, $plus, \%opts), 1);
	} if $want{class};

	Keyword::Simple::define abstract => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpAbstractSyntax', anchor => 'start') or $me->_syntax_error(
			'abstract class declaration',
			'abstract class <name> (<signature>) { <block> }',
			'abstract class <name> { <block> }',
			'abstract class <name>',
			'abstract class (<signature>) { <block> }',
			'abstract class { <block> }',
			'abstract class;',
			$ref,
		);
		
		my ($pos, $plus, $name, $version, $sig, $compact_extends, $compact_with, $block) = ($+[0], $+{plus}, $+{name}, $+{version}, $+{sig}, $+{compact_extends}, $+{compact_with},$+{block});
		my $has_sig = !!exists $+{sig};
		$plus  ||= '';
		$block ||= '{}';
		
		$me->_inject($ref, $pos, $me->_handle_package_keyword(abstract => $name, $version, $compact_extends, $compact_with, $block, $has_sig, $sig, $plus, \%opts), 1);
	} if $want{abstract};

	for my $kw (qw/ role interface /) {
		Keyword::Simple::define $kw => sub {
			my $ref = shift;
			
			$$ref =~ _fetch_re('MxpRoleSyntax', anchor => 'start') or $me->_syntax_error(
				"$kw declaration",
				"$kw <name> (<signature>) { <block> }",
				"$kw <name> { <block> }",
				"$kw <name>",
				"$kw (<signature>) { <block> }",
				"$kw { <block> }",
				"$kw;",
				$ref,
			);
			
			my ($pos, $name, $version, $sig, $compact_extends, $compact_with, $block) = ($+[0], $+{name}, $+{version}, $+{sig}, $+{compact_extends}, $+{compact_with}, $+{block});
			my $has_sig = !!exists $+{sig};
			$block ||= '{}';
			
			$me->_inject($ref, $pos, $me->_handle_package_keyword($kw => $name, $version, $compact_extends, $compact_with, $block, $has_sig, $sig, '', \%opts), 1);
		} if $want{$kw};
	}

	Keyword::Simple::define toolkit => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpToolkitSyntax', anchor => 'start') or $me->_syntax_error(
			'toolkit declaration',
			'toolkit <toolkit> (<extensions>)',
			'toolkit <toolkit>;',
			$ref,
		);
		
		my ($pos, $name, $imports) = ($+[0], $+{name}, $+{imports});
		
		if ($imports) {
			my @imports = grep defined,
				($imports =~ / ((?&PerlQualifiedIdentifier)|(?&PerlComma)) $GRAMMAR /xg);
			my @processed_imports;
			while (@imports) {
				no warnings 'uninitialized';
				my $next = shift @imports;
				if ($next =~ /^::(.+)$/) {
					push @processed_imports, $1;
				}
				elsif ($next =~ /^[^\W0-9]/) {
					push @processed_imports, sprintf('%sX::%s', $name, $next);
				}
				else {
					die "Expected package name, got $next";
				}
				$imports[0] eq ',' and shift @imports;
			}
			$me->_inject($ref, $pos, sprintf('q[%s]->_toolkit(%s);', $me, join ",", map(B::perlstring($_), $name, @processed_imports)));
		}
		
		else {
			$me->_inject($ref, $pos, sprintf('q[%s]->_toolkit(%s);', $me, B::perlstring($name)));
		}
	} if $want{toolkit};

	# `begin`, `end`, `before_apply`, and `after_apply` keywords
	#
	my %injections = (
		begin        => [ '$package,$kind', '' ],
		end          => [ '$package,$kind', '' ],
		before_apply => [ '$role,$package',  'my $kind = "Role::Hooks"->is_role($package)?"role":"class";' ],
		after_apply  => [ '$role,$package',  'my $kind = "Role::Hooks"->is_role($package)?"role":"class";' ],
	);
	for my $kw (qw/ begin end before_apply after_apply /) {
		Keyword::Simple::define $kw => sub {
			my $ref = shift;
			
			$$ref =~ _fetch_re('MxpHookSyntax', anchor => 'start') or $me->_syntax_error(
				"$kw hook",
				"$kw { <block> }",
				$ref,
			);
			
			my ($pos, $capture) = ($+[0], $+{hook});
			my $inj = sprintf('q[%s]->_%s(sub { my (%s) = @_; %s; do %s });', $me, $kw, $injections{$kw}[0], $injections{$kw}[1], $capture);
			$me->_inject($ref, $pos, $inj);
		} if $want{$kw};
	}
	
	# `type_name` keyword
	#
	Keyword::Simple::define type_name => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpTypeNameSyntax', anchor => 'start') or $me->_syntax_error(
			'type name declaration',
			'type_name <identifier>',
			$ref,
		);
		
		my ($pos, $capture) = ($+[0], $+{name});
		$me->_inject($ref, $pos, sprintf('q[%s]->_type_name(%s);', $me, B::perlstring($capture)));
	} if $want{type_name};
	
	# `extends` keyword
	#
	Keyword::Simple::define extends => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpExtendsSyntax', anchor => 'start') or $me->_syntax_error(
			'extends declaration',
			'extends <classes>',
			$ref,
		);
		
		my ($pos, $capture) = ($+[0], $+{list});
		$me->_inject($ref, $pos, sprintf('q[%s]->_extends(%s);', $me, $me->_handle_role_list($capture, 'class')));
	} if $want{extends};
	
	# `with` keyword
	#
	Keyword::Simple::define with => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpWithSyntax', anchor => 'start') or $me->_syntax_error(
			'with declaration',
			'with <roles>',
			$ref,
		);
		
		my ($pos, $capture) = ($+[0], $+{list});
		
		$me->_inject($ref, $pos, sprintf('q[%s]->_with(%s);', $me, $me->_handle_role_list($capture, 'role')));
	} if $want{with};
	
	# `requires` keyword
	#
	Keyword::Simple::define requires => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpRequiresSyntax', anchor => 'start') or $me->_syntax_error(
			'requires declaration',
			'requires <name> (<signature>)',
			'requires <name>',
			$ref,
		);
		
		my ($pos, $name, $sig) = ($+[0], $+{name}, $+{sig});
		my $has_sig = !!exists $+{sig};
		$me->_inject($ref, $pos, $me->_handle_requires_keyword($name, $has_sig, $sig));
	} if $want{requires};
	
	# `has` keyword
	#
	Keyword::Simple::define has => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpHasSyntax', anchor => 'start') or $me->_syntax_error(
			'attribute declaration',
			'has <names> (<spec>) = <default>',
			'has <names> (<spec>)',
			'has <names> = <default>',
			'has <names>',
			$ref,
		);
		
		my ($pos, $name, $spec, $default) = ($+[0],  $+{name}, $+{spec}, $+{default});
		my $has_spec    = !!exists $+{spec};
		my $has_default = !!exists $+{default};
		$me->_inject($ref, $pos, $me->_handle_has_keyword($name, $has_spec ? $spec : undef, $has_default ? $default : undef));
	} if $want{has};
	
	# `constant` keyword
	#
	Keyword::Simple::define constant => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpConstantSyntax', anchor => 'start') or $me->_syntax_error(
			'constant declaration',
			'constant <name> = <value>',
			$ref,
		);
		
		my ($pos, $name, $expr) = ($+[0], $+{name}, $+{expr});
		$me->_inject($ref, $pos, sprintf('q[%s]->_constant(%s, %s);', $me, B::perlstring($name), $expr));
	} if $want{constant};
	
	# `method` keyword
	#
	Keyword::Simple::define method => sub {
		my $ref = shift;
		
		state $re_attr = _fetch_re('MxpAttribute');
		
		$$ref =~ _fetch_re('MxpMethodSyntax', anchor => 'start') or $me->_syntax_error(
			'method declaration',
			'method <name> <attributes> (<signature>) { <block> }',
			'method <name> (<signature>) { <block> }',
			'method <name> <attributes> { <block> }',
			'method <name> { <block> }',
			'method <attributes> (<signature>) { <block> }',
			'method (<signature>) { <block> }',
			'method <attributes> { <block> }',
			'method { <block> }',
			$ref,
		);
		
		my ($pos, $name, $attributes, $sig, $code) = ($+[0], $+{name}, $+{attributes}, $+{sig}, $+{code});
		my $has_sig = !!exists $+{sig};
		my @attrs   = $attributes ? grep(defined, ( ($attributes) =~ /($re_attr)/xg )) : ();
		
		$me->_inject($ref, $pos, $me->_handle_method_keyword($name, $code, $has_sig, $sig,  \@attrs));
	} if $want{method};

	# `multi` keyword
	#
	Keyword::Simple::define multi => sub {
		my $ref = shift;
		
		state $re_attr = _fetch_re('MxpAttribute');
		
		$$ref =~ _fetch_re('MxpMultiSyntax', anchor => 'start') or $me->_syntax_error(
			'multimethod declaration',
			'multi method <name> <attributes> (<signature>) { <block> }',
			'multi method <name> (<signature>) { <block> }',
			'multi method <name> <attributes> { <block> }',
			'multi method <name> { <block> }',
			$ref,
		);
		
		my ($pos, $name, $attributes, $sig, $code) = ($+[0], $+{name}, $+{attributes}, $+{sig}, $+{code});
		my $has_sig = !!exists $+{sig};
		my @attrs   = $attributes ? grep(defined, ( ($attributes) =~ /($re_attr)/xg )) : ();
		
		$me->_inject($ref, $pos, $me->_handle_multimethod_keyword($name, $code, $has_sig, $sig, \@attrs));
	} if $want{multi};

	# `before`, `after`, and `around` keywords
	#
	for my $kw (qw( before after around )) {
		Keyword::Simple::define $kw => sub {
			my $ref = shift;
			
			state $re_attr = _fetch_re('MxpAttribute');
		
			$$ref =~ _fetch_re('MxpModifierSyntax', anchor => 'start') or $me->_syntax_error(
				"$kw method modifier declaration",
				"$kw <names> <attributes> (<signature>) { <block> }",
				"$kw <names> (<signature>) { <block> }",
				"$kw <names> <attributes> { <block> }",
				"$kw <names> { <block> }",
				$ref,
			);
			
			my ($pos, $name, $attributes, $sig, $code) = ($+[0], $+{name}, $+{attributes}, $+{sig}, $+{code});
			my $has_sig = !!exists $+{sig};
			my @attrs   = $attributes ? grep(defined, ( ($attributes) =~ /($re_attr)/xg )) : ();
			
			$me->_inject($ref, $pos, $me->_handle_modifier_keyword($kw, $name, $code, $has_sig, $sig, \@attrs));
		} if $want{$kw};
	}
	
	Keyword::Simple::define factory => sub {
		my $ref = shift;
		
		if ( $$ref =~ _fetch_re('MxpFactorySyntax', anchor => 'start') ) {
			state $re_attr = _fetch_re('MxpAttribute');
			my ($pos, $name, $attributes, $sig, $code) = ($+[0], $+{name}, $+{attributes}, $+{sig}, $+{code});
			my $has_sig = !!exists $+{sig};
			my @attrs   = $attributes ? grep(defined, ( ($attributes) =~ /($re_attr)/xg )) : ();
			$me->_inject($ref, $pos, $me->_handle_factory_keyword($name, undef, $code, $has_sig, $sig, \@attrs));
			return;
		}
		
		$$ref =~ _fetch_re('MxpFactoryViaSyntax', anchor => 'start') or $me->_syntax_error(
			'factory method declaration',
			'factory <name> <attributes> (<signature>) { <block> }',
			'factory <name> (<signature>) { <block> }',
			'factory <name> <attributes> { <block> }',
			'factory <name> { <block> }',
			'factory <name> via <methodname>',
			'factory <name>',
			$ref,
		);
		
		my ($pos, $name, $via) = ($+[0], $+{name}, $+{via});
		$via ||= 'new';
		$me->_inject($ref, $pos, $me->_handle_factory_keyword($name, $via, undef, undef, undef, []));
	} if $want{factory};
	
	Keyword::Simple::define coerce => sub {
		my $ref = shift;
		
		$$ref =~ _fetch_re('MxpCoerceSyntax', anchor => 'start') or $me->_syntax_error(
			'coercion declaration',
			'coerce from <type> via <method_name> { <block> }',
			'coerce from <type> via <method_name>',
			$ref,
		);
		
		my ($pos, $from, $via, $code) = ($+[0], $+{from}, $+{via}, $+{code});
		if ($from =~ /^\{/) {
			$from = "scalar(do $from)"
		}
		elsif ($from !~ /^(q\b)|(qq\b)|"|'/) {
			$from = B::perlstring($from);
		}
		if ($via =~ /^\{/) {
			$via = "scalar(do $via)"
		}
		elsif ($via !~ /^(q\b)|(qq\b)|"|'/) {
			$via = B::perlstring($via);
		}
		
		$me->_inject($ref, $pos, sprintf('q[%s]->_coerce(%s, %s, %s);', $me, $from, $via, $code ? "sub { my \$class; local \$_; (\$class, \$_) = \@_; do $code }" : ''));
	} if $want{coerce};
		
	# Go!
	#
	on_scope_end {
		eval "package $caller; use Zydeco::_Gather -go; 1"
			or Carp::croak($@);
	};
	
	# Need this to export `authority` and `version`...
	@_ = ($me);
	push @_, grep $want{$_}, @Zydeco::EXPORT;
	goto \&Exporter::Tiny::import;
}

our %OPTS;

# `version` keyword
#
sub version {
	$OPTS{version} = shift;
}

# `authority` keyword
#
sub authority {
	$OPTS{authority} = shift;
}

# `overload` keyword
#
sub overload {
	if (@_ == 1 and ref($_[0]) eq 'HASH') {
		push @{ $OPTS{overload} ||= [] }, %{+shift};
	}
	elsif (@_ == 1 and ref($_[0]) eq 'ARRAY') {
		push @{ $OPTS{overload} ||= [] }, @{+shift};
	}
	else {
		push @{ $OPTS{overload} ||= [] }, @_;
	}
}

# `Zydeco::PACKAGE_SPEC` keyword
#
sub PACKAGE_SPEC { \%OPTS }


#
# CALLBACKS
#

sub _package_callback {
	shift;
	my $cb = shift;
	local %OPTS = (in_package => 1);
	&$cb;
	delete $OPTS{in_package};
#	use Data::Dumper;
#	$Data::Dumper::Deparse = 1;
#	print "OPTS:".Dumper $cb, +{ %OPTS };
	return +{ %OPTS };
}
sub _has {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('attribute declaration', 'Not supported outside class or role');
	my ($attr, %spec) = @_;
	$OPTS{has}{$attr} = \%spec;
}
sub _extends {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('extends declaration', 'Not supported outside class');
	@{ $OPTS{extends}||=[] } = @_;
}
sub _type_name {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('extends declaration', 'Not supported outside class or role');
	$OPTS{type_name} = shift;
}
sub _begin {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('begin hook', 'Not supported outside class or role (use import option instead)');
	push @{$OPTS{begin}||=[]}, shift;
}
sub _end {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('end hook', 'Not supported outside class or role (use import option instead)');
	push @{$OPTS{end}||=[]}, shift;
}
sub _before_apply {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('before_apply hook', 'Not supported outside role');
	push @{$OPTS{before_apply}||=[]}, shift;
}
sub _after_apply {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('after_apply hook', 'Not supported outside role');
	push @{$OPTS{after_apply}||=[]}, shift;
}
sub _interface {
	shift;
	$OPTS{interface} = shift;
}
sub _abstract {
	shift;
	$OPTS{abstract} = shift;
}
sub _with {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('with declaration', 'Not supported outside class or role');
	push @{ $OPTS{with}||=[] }, @_;
}
sub _toolkit {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('toolkit declaration', 'Not supported outside class or role (use import option instead)');
	my ($toolkit, @imports) = @_;
	$OPTS{toolkit} = $toolkit;
	push @{ $OPTS{import}||=[] }, @imports if @imports;
}
sub _requires {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('requires declaration', 'Not supported outside role');
	push @{ $OPTS{requires}||=[] }, @_;
}
sub _coerce {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('coercion declaration', 'Not supported outside class');
	push @{ $OPTS{coerce}||=[] }, @_;
}
sub _factory {
	my $me = shift;
	$OPTS{in_package} or $me->_syntax_error('factory method declaration', 'Not supported outside class');
	push @{ $OPTS{factory}||=[] }, @_;
}
sub _constant {
	my $me = shift;
	my ($name, $value) = @_;
	if (! $OPTS{in_package}) {
		'MooX::Press'->install_constants(scalar(caller), { $name => $value });
		return;
	}
	$OPTS{constant}{$name} = $value;
}
sub _can {
	my $me = shift;
	my ($name, $code) = @_;
	if (! $OPTS{in_package}) {
		'MooX::Press'->install_methods(scalar(caller), { $name => $code });
		return;
	}
	$OPTS{can}{$name} = $code;
}
sub _multimethod {
	my $me = shift;
	my ($name, $spec) = @_;
	if (! $OPTS{in_package}) {
		'MooX::Press'->install_multimethod(scalar(caller), 'class', $name, $spec);
		return;
	}
	push @{ $OPTS{multimethod} ||= [] }, $name => $spec;
}
sub _modifier {
	my $me = shift;
	my ($kind, @args) = @_;
	if (! $OPTS{in_package}) {
		my $codelike = pop @args;
		my $coderef  = 'MooX::Press'->_prepare_method_modifier(scalar(caller), $kind, \@args, $codelike);
		require Class::Method::Modifiers;
		Class::Method::Modifiers::install_modifier(scalar(caller), $kind, @args, $coderef);
	}
	push @{ $OPTS{$kind} ||= [] }, @args;
}
sub _include {
	my $me = shift;
	$OPTS{in_package} and $me->_syntax_error('include directive', 'Not supported inside class or role');
	
	require Path::ScanINC;
	my @chunks = split /::/, $_[0];
	$chunks[-1] .= '.pl';
	my $file = Path::ScanINC->new->first_file(@chunks);
	
	if (!$file) {
		require Carp;
		Carp::croak("No such file: " . join("/", @chunks));
	}
	
	ref $file eq 'ARRAY' and die "not supported yet";
	my $code = $file->slurp_utf8;
	
	sprintf(
		"do {\n# line 1 %s\n%s\n};\n1;\n",
		B::perlstring($file),
		$code,
	);
}

#{
#	package Zydeco::Anonymous::Package;
#	our $AUTHORITY = 'cpan:TOBYINK';
#	our $VERSION   = '0.508';
#	use overload q[""] => sub { ${$_[0]} }, fallback => 1;
#	sub DESTROY {}
#	sub AUTOLOAD {
#		my $me = shift;
#		(my $method = our $AUTOLOAD) =~ s/.*:://;
#		$$me->$method(@_);
#	}
#	
#	package Zydeco::Anonymous::Class;
#	our $AUTHORITY = 'cpan:TOBYINK';
#	our $VERSION   = '0.508';
#	our @ISA       = qw(Zydeco::Anonymous::Package);
#	sub new {
#		my $me = shift;
#		$$me->new(@_);
#	}
#	use overload q[&{}] => sub {
#		my $me = shift;
#		sub { $me->new(@_) }
#	};
#	
#	package Zydeco::Anonymous::Role;
#	our $AUTHORITY = 'cpan:TOBYINK';
#	our $VERSION   = '0.508';
#	our @ISA       = qw(Zydeco::Anonymous::Package);
#	
#	package Zydeco::Anonymous::ParameterizableClass;
#	our $AUTHORITY = 'cpan:TOBYINK';
#	our $VERSION   = '0.508';
#	our @ISA       = qw(Zydeco::Anonymous::Package);
#	sub generate_package {
#		my $me  = shift;
#		my $gen = $$me->generate_package(@_);
#		bless \$gen, 'Zydeco::Anonymous::Class';
#	}
#	use overload q[&{}] => sub {
#		my $me = shift;
#		sub { $me->new_class(@_) }
#	};
#
#	package Zydeco::Anonymous::ParameterizableRole;
#	our $AUTHORITY = 'cpan:TOBYINK';
#	our $VERSION   = '0.508';
#	our @ISA       = qw(Zydeco::Anonymous::Package);
#	sub generate_package {
#		my $me  = shift;
#		my $gen = $$me->generate_package(@_);
#		bless \$gen, 'Zydeco::Anonymous::Class';
#	}
#	use overload q[&{}] => sub {
#		my $me = shift;
#		sub { $me->new_role(@_) }
#	};
#}

my $i = 0;
sub anonymous_package {
	my $me = shift;
	my ($kind, $callback, %opts) = @_;
	my $package_dfn = $me->_package_callback($callback);
	
	for my $forbidden (qw/ factory type_name coerce /) {
		die if exists $package_dfn->{$forbidden};
	}
	$package_dfn->{type_name}  = undef;
	$package_dfn->{factory}    = undef;
	
	my $qname = sprintf('%s::__ANON_%06d__', __PACKAGE__, ++$i);
	
	require MooX::Press;
	my $method = "make_$kind";
	MooX::Press->$method("::$qname", %opts, %$package_dfn);
	
	require Module::Runtime;
	$INC{Module::Runtime::module_notional_filename($qname)} = __FILE__;
	#return bless(\$qname, "Zydeco::Anonymous::".ucfirst($kind));
	return $qname;
}

sub anonymous_generator {
	my $me = shift;
	my ($kind, $callback, %opts) = @_;
	my $qname = sprintf('%s::__ANON_%06d__', __PACKAGE__, ++$i);
	
	require MooX::Press;
	my $method = "make_$kind\_generator";
	MooX::Press->$method("::$qname", %opts, generator => $callback);
	
	require Module::Runtime;
	$INC{Module::Runtime::module_notional_filename($qname)} = __FILE__;
	#return bless(\$qname, "Zydeco::Anonymous::Parameterizable".ucfirst($kind));
	return $qname;
}

1;

__END__

