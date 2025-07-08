package Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/ :severities :data_conversion :classification :language /;
use base 'Perl::Critic::Policy';

our $VERSION = '0.0.5';

Readonly::Scalar my $DESC  => q{Builtin function called without parentheses};
Readonly::Scalar my $EXPL  => [ 13 ];

# In each section, the order follows that of perlfunc(1).
# Some keywords may be repeated if they appear in multiple perlfunc sections.

Readonly::Array my @REQUIRED => qw/
	chr crypt fc hex index lc lcfirst length oct ord pack rindex sprintf substr uc ucfirst
	quotemeta split study
	abs atan2 cos exp hex int log oct rand sin sqrt srand
	splice
	join unpack
	delete exists
	binmode close closedir fileno flock read readdir readline rewinddir seek seekdir select syscall sysread sysseek syswrite tell telldir truncate warn write
	pack read syscall sysread sysseek syswrite unpack vec
	chdir chmod chown chroot fcntl glob ioctl link lstat mkdir open opendir readlink rename rmdir select stat symlink sysopen umask unlink utime
	caller
	formline lock scalar
	alarm exec getpriority kill pipe readpipe setpgrp setpriority sleep system waitpid
	bless ref tie tied untie
	accept bind connect getpeername getsockname getsockopt listen recv send setsockopt shutdown socket socketpair
/;

Readonly::Array my @PERMITTED => qw/
	chomp chop
	pos
	eof getc
	exit
	defined reset undef
	getpgrp
	gmtime localtime time
/;

Readonly::Array my @ALLOWED => qw/
	reverse
	each keys pop push shift unshift values
	each keys values
	grep map reverse sort
	die format print printf say
	break continue die do dump eval evalbytes goto last next redo return wantarray
	import local my our package state use
	fork getppid times wait
	do import no package require use
	package use
/;

####-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'require',
			description    => 'Always require parentheses of these operators.',
			default_string => join(' ',@REQUIRED),
			behavior       => 'string list',
		},
		{
			name           => 'permit',
			description    => 'Require parentheses when called with a parameter.',
			default_string => join(' ',@PERMITTED),
			behavior       => 'string list',
		},
		{
			name           => 'allow',
			description    => 'Never require parentheses.',
			default_string => join(' ', @ALLOWED),
			behavior       => 'string list',
		},
	);
}

sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core cosmetic ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
	my ($self,$elem,undef)=@_;
	if(!is_function_call($elem))                        { return }
	if(exists($$self{_allow}{ $elem->content() }))      { return }

	my $sibling=$elem->snext_sibling();
	if(exists($$self{_require}{ $elem->content() })) {
		if(!$sibling||!$sibling->isa('PPI::Structure::List')) { return $self->violation(sprintf("$DESC (%s)",$elem->content()),$EXPL,$elem) }
	}

	if(!$sibling||$sibling->isa('PPI::Structure::List')) { return }

	if(exists($$self{_permit}{ $elem->content() })) {
		if(  $sibling->isa('PPI::Token::Number')
			|| $sibling->isa('PPI::Token::Quote')
			|| $sibling->isa('PPI::Token::QuoteLike')
			|| $sibling->isa('PPI::Token::Symbol')
		) {
			return $self->violation(sprintf("$DESC (%s)",$elem->content()),$EXPL,$elem);
		}
		return;
	}

	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins - Write C<lc($x // "Default")> instead of C<lc $x // "Default">.

=head1 DESCRIPTION

String folding is often used in map lookups where missing parentheses may not provide the expected behavior

	$LOOKUP{ lc $name // 'Default' }
	$LOOKUP{ lc( $name // 'Default' ) }

When C<$name> is undefined, the first form will lookup the value for C<""> (the empty string) and throw warnings from the C<lc> call.  The second form will lookup the value for C<"default">.  As an alternative approach

	$LOOKUP{ lc($name) || 'Default' }

will lookup the value for C<"default"> when C<$name> is undefined, but will still throw warnings from C<lc>.

=head1 CONFIGURATION

The priority for configuration is Allow, Required, Permitted.

=head2 Allow

Functions in the C<allow> section can be called with or without parentheses, no restriction.  This overrides all other configurations.

	[CodeLayout::RequireParensWithBuiltins]
	allow = sqrt

=head2 Required

Names configured in the C<require> section always require parentheses, even when called without arguments or inside blocks.  EG C<lc()> or C<grep {lc($_)}>.  This overrides the C<permit> option.

	[CodeLayout::RequireParensWithBuiltins]
	require = lc lcfirst uc ucfirst

=head2 Required with arguments

Some functions operate on C<$_> or other defaults and may be used without parameters.  If configured in the C<permit> section, the functions will require parentheses when called with a parameter.  EG both C<grep {defined} ...> and C<if(defined($x))> are valid, but C<if(defined $x)> is a violation.

	[CodeLayout::RequireParensWithBuiltins]
	permit = defined

=head1 NOTES

While coding with parentheses can sometimes lead to verbose constructs, a single case without parentheses can lead to invalid data in processing and results.  For these functions, the lack of parentheses causes ambiguity so they can be considered F<necessary>.  Code maintainability must also support quick insert of defaults and handling of warnings for undefined values, so calls without those mechanisms are likely incorrect F<from the start>.

=head1 BUGS

It's possible that some mathematical functions are more natural without parentheses even when followed by lower-precedence operators.  The current policy makes no special exemptions for different precedence interpretations for different functions.

=cut
