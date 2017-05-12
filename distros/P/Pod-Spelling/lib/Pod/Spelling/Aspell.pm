use strict;
use warnings;

package Pod::Spelling::Aspell;
use base 'Pod::Spelling';
use Carp;
no warnings 'redefine';

our $VERSION = 0.1;

require Text::Aspell;

sub _init {
	shift if not ref $_[0];
	my $self = shift;
	
	$self->{aspell} ||= Text::Aspell->new
		or die 'Could not instantiate Text::Aspell';
		
	$self->{aspell}->check('house');
	return $self->{aspell}->errstr if $self->{aspell}->errstr;
	Carp::croak $self if not ref $self;
	return $self;
}

# Accepts one or more lines of text, returns a list mispelt words.
sub _spell_check_callback {
	my $self = shift;
	my @lines = @_;
	my $errors;
	for my $word ( split /\s+/, join( ' ', @lines ) ){
		next if not $word;
		$errors->{ $word } ++ if not $self->{aspell}->check( $word )
			and not $self->{aspell}->errstr;
	}
	
	return keys %$errors;
}

1;

__END__

=head1 NAME

Pod::Spelling::Aspell - Spell-test POD with Aspell

=head1 SYNOPSIS

	my $o = Pod::Spelling::Apsell->new(
		allow_words => qw[ Django Rheinhardt ],
	);
	warn "Spelling errors: ", join ', ', $o->check_file( 'blib/Paris.pm' );

=head1 DESCRIPTION

Checks the spelling in POD using the C<aspell> program, which is expected
to be found on the system. 

You may configure and supply an instance of C<Text::Aspell> to the constructor
with the C<aspell> argument.

For details of options and methods, see the parent class,
L<Pod::Spelling|Pod::Spelling>.

=head1 SEE ALSO

L<Pod::Spelling>, L<Text::Aspell>.

=head1 AUTHOR

Lee Goddard (C<lgoddard-at-cpan.org>)

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2011, Lee Goddard. All Rights Reserved.

Made available under the same terms as Perl.



