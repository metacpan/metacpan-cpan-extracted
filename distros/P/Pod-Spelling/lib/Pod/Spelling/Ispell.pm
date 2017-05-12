use strict;
use warnings;

package Pod::Spelling::Ispell;

use base 'Pod::Spelling';
no warnings 'redefine';

our $VERSION = 0.2;

require Lingua::Ispell;

Lingua::Ispell::allow_compounds(1);

sub _init {
	shift if not ref $_[0];
	my $self = shift;
	if (not defined $self->{ispell_path}){
		# Which ispell?
		foreach my $p (
			'', # Already on the PATH?
			qw( 
			/usr/local/bin/
			/usr/local/sbin/
			/usr/bin/
			/opt/usr/bin/
			/opt/local/bin/
		)){
			if (-e $p.'ispell'){
				no warnings;
				$self->{ispell_path} = $p.'ispell';
			}
		}
	}

	if (defined $self->{ispell_path}){
		$Lingua::Ispell::path = $self->{ispell_path} 
	} else {
		$self->{spell_check_callback} = undef;	
	}

	return $self;
}


# Accepts one or more lines of text, returns a list mispelt words.
sub _spell_check_callback {
	my $self = shift;
	my @lines = @_;
	my $errors;
	
	for my $r ( Lingua::Ispell::spellcheck( @lines )){
		$errors->{ $r->{term} } ++ if $r->{type} =~ /^(miss|guess|none)$/;
	}
	
	return keys %$errors;
}

1;

__END__

=head1 NAME

Pod::Spelling::Ispell - Spell-test POD with Ispell

=head1 SYNOPSIS

	my $o = Pod::Spelling::Ispell->new(
		allow_words => qw[ Django Rheinhardt ],
	);
	warn "Spelling errors: ", join ', ', $o->check_file( 'blib/Paris.pm' );

=head1 DESCRIPTION

Checks the spelling in POD using the C<ispell> program, which is expected
to be found on the system. 

When calling the constructor, you may supply the argument C<ispell_path>
to specify the full path to the C<ispell> executable. This module has a guess,
but may have missed possible locations.

For details of options and methods, see the parent class,
L<Pod::Spelling|Pod::Spelling>.

=head1 SEE ALSO

L<Pod::Spelling>, L<Lingua::Ispell>.

=head1 AUTHOR

Lee Goddard (C<lgoddard-at-cpan.org>)

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2011, Lee Goddard. All Rights Reserved.

Made available under the same terms as Perl.



