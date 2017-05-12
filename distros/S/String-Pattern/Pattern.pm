# Copyright (c) 2000 Ivo Zdravkov. All rights reserved.  This program is
# free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package Pattern;
	
	use strict;
	use overload
		'""' => "to_string";
	use vars qw($VERSION);
	$VERSION='0.90';

	sub new{
        my $proto = shift;
		my $pattern = shift;

        my $class = ref($proto) || $proto;

		my $self = {};
		$self->{PATTERN} = undef;
		$self->{MATCHES} = undef;
		$self->{DATA} = {}; # tag => {REX => '.+', VAR_REF => variable ref}
		$self->{PREPARED} = undef;

		bless($self, $class);
		$self->pattern($pattern) if $pattern;
		return $self
	}
	
	sub bind{
		my $self = shift;
		my $tag = shift; my $var_ref = shift; my $rex=shift;
		
		if ($rex and $rex=~/\((..)/ and  $1 ne '?:') {
			warn "Bind failed for tag $tag \n".
				"Brackets are not allowed in regular expression, excep like these : (?:..)";
			return undef
		}

		$self->{DATA}->{$tag}->{VAR_REF} = $var_ref;
		$self->{DATA}->{$tag}->{REX} = $rex || '.*';
		$self->{PREPARED} = 0;

		my $q_tag = $self->quote($tag);
		warn "There is no $tag tag in the pattern \n" 
			unless $self->{PATTERN} =~/$q_tag/;

		return 1
	}

	sub bind_like{
		my $self = shift;
		my $other = shift;

		unless ( ref($other) eq ref($self) ) {
			warn "Not same object type: ".ref($self)."\n";
			return undef
		}

		my $success = 1;
		my ($tag, $info);
		while ( ($tag, $info) = each %{$other->{DATA}} ) {
			$self->bind( $tag => $info->{VAR_REF}, $info->{REX})
				or $success = 0;
		}

		return $success
	}

	sub pattern{
		my $self = shift;
		my $pattern = shift;

		if (defined $pattern) {
			$self->{PATTERN}=$pattern;
			$self->{PREPARED} = 0;
			return 1
		}else{
			return $self->{PATTERN}
		}
	}
	
	sub prepare{
		my $self = shift;

		my $index=0;
		my $pattern=$self->{PATTERN};

		# clear old indexes
		$self->{DATA}->{$_}->{APPEARANCE}=[] for (keys %{$self->{DATA}});

		# create indexes
		my $s_p = join('|', map {'(?:'.$self->quote($_).')'} keys %{$self->{DATA}} );
		die "There is no any bindings defined" unless $s_p;

		while ($pattern=~/($s_p)/gs){
			push @{$self->{DATA}->{$1}->{APPEARANCE}}, $index++
		}

		# compile rex
		$self->{REX} = $self->to_rex;;
		$self->{PREPARED}=1;

		return 1
	}

	sub identify{
		my $self = shift;
		my $string = shift;
		
		$self->prepare unless $self->{PREPARED};
		
		my $identical=1;
		my $tag; my $first;	my @appearances;
		my $rex=$self->{REX};

		if (@{$self->{MATCHES}} = $string=~/$rex/s) {
			$identical=1
		}else{
			return 0
		}
		
		# check for identical repetitions
		for $tag (keys %{$self->{DATA}} ){
			($first, @appearances)=@{$self->{DATA}->{$tag}->{APPEARANCE}};
			next unless defined $first;

			for (@appearances) {
				$identical=0 if $self->{MATCHES}[$first] ne $self->{MATCHES}[$_] ;
			} 
			last unless $identical
		}
		
		# set bounded variables
		if ($identical) {
			for $tag (keys %{$self->{DATA}} ){
				if (@{$self->{DATA}->{$tag}->{APPEARANCE}}) {
					${$self->{DATA}->{$tag}->{VAR_REF}}=
						$self->{MATCHES}[$self->{DATA}->{$tag}->{APPEARANCE}[0]]
				}else{
					next
				}
			}
		}
		return $identical
	}

	sub quote{
		my $self = shift;
		my $rex = shift;

		$rex=~s/([\$\?@\[\]{}*+\.^|\\])/\\$1/g;

		return $rex
	}
	
	sub dequote{
		my $self = shift;
		my $string = shift;

		$string =~ s/\\(.)/$1/g;
		return $string;
	}

	sub to_rex{
		my $self = shift;
		
		my $rex=$self->quote($self->{PATTERN});
		my $s_p = join('|', map {'(?:'.$self->quote($self->quote($_)).')'} keys %{$self->{DATA}} );
		
		$rex=~s/($s_p)/
			if (exists $self->{DATA}->{$self->dequote($1)}) {
				"(".$self->{DATA}->{$self->dequote($1)}->{REX}.")"
			}else{
				warn "problems with rex creation for tag $1"
			}
		/ge;

		return '^'.$rex.'$';		 
	}

	sub to_string{
		my $self = shift;
		
		my $result = $self->{PATTERN};

		for my $tag (keys %{ $self->{DATA} }) {
			$result =~ s/$tag/${$self->{DATA}->{$tag}->{VAR_REF}}/g;
		}

		return $result
	}
1;
__END__

=head1 NAME

String::Pattern - create / identify strings by pattern

=head1 SYNOPSIS

	use String::Pattern;
	use strict;

	my $code = "73545-ved-8877";
	my $name = "Benalgin";
	my $prescription = 'X';
	my $price = 10.99;
	my $date;

	my $p = new Pattern 'code: 1223144-x-67 name: Aspirin prescription: [pr_flag] price: $5.90';
	my $print_view = new Pattern q{
		record date : 8/11/00
		code: 1223144-x-67
		name: Aspirin
		[pr_flag] prescription
		price: $5.90
	};

	$p->bind( '1223144-x-67' => \$code);
	$p->bind( Aspirin => \$name);
	$p->bind( '5.90' => \$price, '\d+(?:[,\.]\d{2})?');
	$p->bind( pr_flag => \$prescription);
	$print_view->bind_like($p);
	$print_view->bind( '8/11/00' => \$date);
	
	my $q="$p"; # equivalent ot my $q=$p->to_string;

	$prescription=" ";
	my $r = 'code: 1223144x-69 name: Aspirin-Bayer prescription: [ ] price: $3.124';

	for my $string ($r,	$p,	$q) {
		print $string, "\n";
		if ($p->identify($string)) {
			print "Match on pattern \n";
			$date = localtime;
			print $print_view."\n";
		}else{
			print "Not match on pattern \n\n"
		}
	}

=head1 DESCRIPTION

This module is designed to deal whith non atomic data strings representations whith fixed number of items on it - such as addresses, business cards, product descriptors etc. It simplificies string creation based on preliminary defined human readable patterns ( templates ) and identifying that any given string has format, "described" in the same pattern. 

=head2 Methods

=over 4

=item pattern

=item pattern ($string)

if C<$string> is supplied then it will be used as pattern, otherwise currently used pattern is returned

=item bind ( tag => \$var)

=item bind ( tag => \$var, $re)

binds var ref to specific part of pattern (tag). When string is created, all occuriences of that tag will be replaced with the value of C<$var>. Regular expession C<$re> is used to describe what the tag looks like, and increases the accuracy of L<identify> method in ambiguous cases. Pattern is used to build one regular expession whith backreferences ( for each occurrence of tag ) , so brackets usage in C<$re> must be only like this (?: ... ).

=item to_string

Creates string based on pattern and bindings. This method is invoked when object ref is evaluated in string context

=item identify ($string)

Returns 1 if C<$string> matches on pattern and all occurrences of given tag are equal, then sets vars to first occurrence of respective bounded tag. Otherwise returns 0 and nothig is changed.

=item bind_like ($other_pattern_object)

Gets bindings from other object. May be useful for copy like operations avoiding boring declararions.
	
	my $p1 = new String::Pattern .....;
	my $p2 = new String::Pattern .....;

	# a lot of bind ...
	$p1->bind....;
	...
	$p1->bind....;
	$p2->bind_like($p1);

	# $p2 specific binds
	$p2->bind....;
	
	if ($p1->identify(...)) {
		print $p2
	}

so $p2 have all of $p1 bindings plus one additional

=back

=head2 to do

=over 4

=item erros and warnings

Adding some useful warnings and erros about content of variables, and their ralations with tags in the pattern

=back

=head1 AUTHOR

Ivo Zdravkov, ivoz@starmail.com

=head1 SEE ALSO

perl (1), perlre (3)

=cut
