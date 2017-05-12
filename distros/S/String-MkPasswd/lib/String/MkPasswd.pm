package String::MkPasswd;

use 5.006001;
use strict;
use base qw(Exporter);

use Carp qw(croak);

# Defaults.
use constant LENGTH		=> 9;
use constant MINNUM		=> 2;
use constant MINLOWER	=> 2;
use constant MINUPPER	=> 2;
use constant MINSPECIAL	=> 1;
use constant DISTRIBUTE	=> "";
use constant FATAL		=> "";

# A few conveniences for dealing with homographs
use constant ALLOWAMBIGUOUS => 0;
use constant NOAMBIGUOUS    => 1;
our %IS_AMBIGUOUS = (
	'o' => 1, # easily confused with zero, especially when capitalized
	'0' => 1, # easily confused with capital O
	'1' => 1, # easily confused for lower l or capital I
	'i' => 1, # especially when capitalized, easily confused for 1, lower l, or pipe
	'l' => 1, # easily confused for 1 or capital I
	'v' => 1, # a pair of these looks like w
	'w' => 1, # one of these looks like a pair of v's
	'c' => 1, # can be confused for a paren
	'|' => 1, # easily confused with 1, lower l, or capital I
	'_' => 1, # easily confused with dash
	'-' => 1, # easily confused with underscore
	'.' => 1, # easily confused with comma
	',' => 1, # easily confused with period
	':' => 1, # easily confused with colon
	';' => 1, # easily confused with semicolon
	']' => 1, # easily confused with } and )
	'[' => 1, # easily confused with { and (
	'(' => 1, # easily confused with { and [
	')' => 1, # easily confused with } and ]
	'{' => 1, # easily confused with ( and [
	'}' => 1, # easily confused with ) and ]
);

our %EXPORT_TAGS = (
	all	=> [ qw(mkpasswd) ],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };
our $VERSION = "0.05";
our $FATAL = "";

my %keys = (
	ALLOWAMBIGUOUS() => {
		dist => {
			lkeys	=> [ qw(q w e r t a s d f g z x c v b) ],
			rkeys	=> [ qw(y u i o p h j k l n m) ],
			lnums	=> [ qw(1 2 3 4 5 6) ],
			rnums	=> [ qw(7 8 9 0) ],
			lspec	=> [ qw(! @ $ %), "#" ],
			rspec	=> [
				qw(^ & * ( ) - = _ + [ ] { } \ | ; : ' " < > . ? /), ","
			],
		},
		undist => {
			lkeys	=> [
				qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)
			],
			lkeys => [
				qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)
			],
			rkeys	=> [
				qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)
			],
			lnums	=> [ qw(0 1 2 3 4 5 6 7 8 9) ],
			rnums	=> [ qw(0 1 2 3 4 5 6 7 8 9) ],
			lspec	=> [
				qw(! @ $ % ~ ^ & * ( ) - = _ + [ ] { } \ | ; : ' " < > . ? /),
				"#", ","
			],
			rspec	=> [
				qw(! @ $ % ~ ^ & * ( ) - = _ + [ ] { } \ | ; : ' " < > . ? /),
				"#", ","
			],
		},
	}
);


# Build unambiguous (NOAMBIGUOUS) keys entries from the ALLOWAMBIGUOUS set
foreach my $distribution ( keys %{ $keys{ ALLOWAMBIGUOUS() } } ) {
	foreach my $block ( keys %{ $keys{ ALLOWAMBIGUOUS() }->{ $distribution } } ) {
		$keys{ NOAMBIGUOUS() }->{ $distribution }->{ $block } = [
			grep
				{ ! $IS_AMBIGUOUS{ $_ } }
				@{ $keys{ ALLOWAMBIGUOUS() }->{ $distribution }->{ $block } }
		];
	}
}

sub mkpasswd {
	my $class	= shift if UNIVERSAL::isa $_[0], __PACKAGE__;
	my %args	= @_;

	# Configuration.
	my $length		= $args{"-length"}     || LENGTH;
	my $minnum		= defined $args{"-minnum"}
		? $args{"-minnum"}
		: MINNUM;
	my $minlower	= defined $args{"-minlower"}
		? $args{"-minlower"}
		: MINLOWER;
	my $minupper	= defined $args{"-minupper"}
		? $args{"-minupper"}
		: MINUPPER;
	my $minspecial	= defined $args{"-minspecial"}
		? $args{"-minspecial"}
		: MINSPECIAL;
	my $distribute	= defined $args{"-distribute"}
		? $args{"-distribute"}
		: DISTRIBUTE;
	my $ambiguousity = defined $args{"-noambiguous"}
		? $args{"-noambiguous"}
		: ALLOWAMBIGUOUS;
	my $fatal		= defined $args{"-fatal"}
		? $args{"-fatal"}
		: FATAL;

	if ( $minnum + $minlower + $minupper + $minspecial > $length ) {
		if ( $fatal || $FATAL ) {
			croak "Impossible to generate $length-character password with "
					. "$minnum numbers, $minlower lowercase letters, "
					. "$minupper uppercase letters and $minspecial special "
					. "characters";
		} else {
			return;
		}
	}

	# If there is any underspecification, use additional lowercase letters.
	$minlower = $length - ($minnum + $minupper + $minspecial);

	# Choose left or right starting hand.
	my $initially_left = my $isleft = int rand 2;

	# Select distribution of keys.
	my $lkeys = $distribute ? $keys{$ambiguousity}{dist}{lkeys} : $keys{$ambiguousity}{undist}{lkeys};
	my $rkeys = $distribute ? $keys{$ambiguousity}{dist}{rkeys} : $keys{$ambiguousity}{undist}{rkeys};
	my $lnums = $distribute ? $keys{$ambiguousity}{dist}{lnums} : $keys{$ambiguousity}{undist}{lnums};
	my $rnums = $distribute ? $keys{$ambiguousity}{dist}{rnums} : $keys{$ambiguousity}{undist}{rnums};
	my $lspec = $distribute ? $keys{$ambiguousity}{dist}{lspec} : $keys{$ambiguousity}{undist}{lspec};
	my $rspec = $distribute ? $keys{$ambiguousity}{dist}{rspec} : $keys{$ambiguousity}{undist}{rspec};

	# Generate password.

	my @lpass = (undef) x $length;	# password chars typed by left hand
	my @rpass = (undef) x $length;	# password chars typed by right hand
	my ($left, $right);

	($left, $right) = &_psplit($minnum, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, $lnums->[rand @$lnums]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, $rnums->[rand @$rnums]);
	}

	($left, $right) = &_psplit($minlower, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, $lkeys->[rand @$lkeys]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, $rkeys->[rand @$rkeys]);
	}

	($left, $right) = &_psplit($minupper, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, uc $lkeys->[rand @$lkeys]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, uc $rkeys->[rand @$rkeys]);
	}

	($left, $right) = &_psplit($minspecial, \$isleft);
	for ( my $i = 0; $i < $left; $i++ ) {
		&_insert(\@lpass, $lspec->[rand @$lspec]);
	}
	for ( my $i = 0; $i < $right; $i++ ) {
		&_insert(\@rpass, $rspec->[rand @$rspec]);
	}

	# Merge results together.
	my $lpass = join "", map { defined $_ ? $_ : () } @lpass;
	my $rpass = join "", map { defined $_ ? $_ : () } @rpass;

	return $initially_left ? "$lpass$rpass" : "$rpass$lpass";
}

# Insert $char into password at a random position, thereby spreading the
# different kinds of characters throughout the password.
sub _insert {
	my $pass	= shift;	# ref = ARRAY
	my $char	= shift;

	my $pos;
	do {
		$pos = int rand(1 + @$pass);
	} while ( defined $pass->[$pos] );

	$pass->[$pos] = $char;
}

# Given a size, distribute between left and right hands, taking into account
# where we left off.
sub _psplit {
	my $max		= shift;
	my $isleft	= shift;	# ref = SCALAR

	my ($left, $right);

	if ( $$isleft ) {
		$right = int($max / 2);
		$left = $max - $right;
		$$isleft = !($max % 2);
	} else {
		$left = int($max / 2);
		$right = $max - $left;
		$$isleft = !($max % 2);
	}

	return ($left, $right);
}

1;

__END__

=head1 NAME

String::MkPasswd - random password generator

=head1 SYNOPSIS

  use String::MkPasswd qw(mkpasswd);

  print mkpasswd();

  # for the masochisticly paranoid...
  print mkpasswd(
      -length     => 27,
      -minnum     => 5,
      -minlower   => 1,   # minlower is increased if necessary
      -minupper   => 5,
      -minspecial => 5,
      -distribute => 1,
  );

=head1 ABSTRACT

This Perl library defines a single function, C<mkpasswd()>, to generate
random passwords.  The function is meant to be a simple way for
developers and system administrators to easily generate a relatively
secure password.

=head1 DESCRIPTION

The exportable C<mkpasswd()> function returns a single scalar: a random
password.  By default, this password is nine characters long with a
random distribution of four lower-case characters, two upper-case
characters, two digits, and one non-alphanumeric character.  These
parameters can be tuned by the user, as described in the L</"ARGUMENTS">
section.

=head2 ARGUMENTS

The C<mkpasswd()> function takes an optional hash of arguments.

=over 4

=item -length

The total length of the password.  The default is 9.

=item -minnum

The minimum number of digits that will appear in the final password.
The default is 2.

=item -minlower

The minimum number of lower-case characters that will appear in the
final password.  The default is 2.

=item -minupper

The minimum number of upper-case characters that will appear in the
final password.  The default is 2.

=item -minspecial

The minimum number of non-alphanumeric characters that will appear in
the final password.  The default is 1.

=item -distribute

If set to a true value, password characters will be distributed between
the left- and right-hand sides of the keyboard.  This makes it more
difficult for an onlooker to see the password as it is typed.  The
default is false.

=item -noambiguous

If set to a true value, password characters will not include any that
might be mistaken for others. This is particularly helpful if you're
distributing a printed list of passwords to a group of people. The
default is false.

=item -fatal

If set to a true value, C<mkpasswd()> will L<Carp::croak()> rather than
return C<undef> on error.  The default is false.

=back

If B<-minnum>, B<-minlower>, B<-minupper>, and B<-minspecial> do not add
up to B<-length>, B<-minlower> will be increased to compensate.
However, if B<-minnum>, B<-minlower>, B<-minupper>, and B<-minspecial>
add up to more than B<-length>, then C<mkpasswd()> will return C<undef>.
See the section entitled L</"EXCEPTION HANDLING"> for how to change this
behavior.

=head2 EXCEPTION HANDLING

By default, C<mkpasswd()> will return C<undef> if it cannot generate a
password.  Some people are inclined to exception handling, so
B<String::MkPasswd> does its best to accommodate them.  If the variable
C<$String::MkPasswd::FATAL> is set to a true value, C<mkpasswd()> will
L<Carp::croak()> with an error instead of returning C<undef>.

=head2 EXPORT

None by default.  The C<mkpasswd()> method is exportable.

=head1 SEE ALSO

L<http://expect.nist.gov/#examples>, L<mkpasswd(1)>

=head1 AKNOWLEDGEMENTS

Don Libes of the National Institute of Standards and Technology, who
wrote the Expect example, L<mkpasswd(1)>.

=head1 AUTHOR

Chris Grau E<lt>cgrau@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2012 by Chris Grau

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.1 or, at
your option, any later version of Perl 5 you may have available.

=cut
