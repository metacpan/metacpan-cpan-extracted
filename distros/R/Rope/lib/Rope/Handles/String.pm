package Rope::Handles::String;

use strict;
use warnings;

sub new {
	my ($class, $str) = @_;
	bless \$str, __PACKAGE__;
}

sub increment {
	my ($self) = @_;
	my $str = ${$self};
	my $num = $str =~ s/(\d+)$// && $1;
	$num++;
	${$self} = $str . $num;
	return ${$self};
}

sub decrement {
	my ($self) = @_;
	my $str = ${$self};
	my $num = $str =~ s/(\d+)$// && $1;
	$num--;
	${$self} = $str . ($num == 0 ? '' : $num);
	return ${$self};
}

sub append { ${$_[0]} = ${$_[0]} . $_[1] }
 
sub prepend { ${$_[0]} = $_[1] . ${$_[0]} }

sub replace {
	if (ref($_[2]) eq 'CODE') {
		${$_[0]} =~ s/$_[1]/$_[2]->()/e;
	}
	elsif ($_[2]) {
		${$_[0]} =~ s/$_[1]/$_[2]/;
	} else {
		${$_[0]} =~ s/$_[1]/$1/;
	}
	${$_[0]};
}


sub match { ${$_[0]} =~ /$_[1]/; }

sub chop { CORE::chop ${$_[0]} }
 
sub chomp { CORE::chomp ${$_[0]} }
 
sub clear { ${$_[0]} = '' }
 
sub length { CORE::length ${$_[0]} }
 
sub substr {
	if (@_ >= 4) {
		substr ${$_[0]}, $_[1], $_[2], $_[3];
	}
	elsif (@_ == 3) {
		substr ${$_[0]}, $_[1], $_[2];
	}
	else {
		substr ${$_[0]}, $_[1];
	}
}

1;

__END__

=head1 NAME

Rope::Handles::String - Rope handles strings

=head1 VERSION

Version 0.36

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;

	property singular => (
		initable => 1,
		handles_via => 'Rope::Handles::String'
	);

	property plural => (
		initable => 1,
		handles_via => 'Rope::Handles::String',
		handles => {
			plural_increment => 'increment',
			plural_decrement => 'decrement',
			plural_match => 'match',
		}
	);

	...

=head1 Methods

=head2 increment

=head2 decrement

=head2 append

=head2 prepend

=head2 replace

=head2 match

=head2 chop

=head2 chomp

=head2 clear

=head2 length

=head2 substr

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope>

=item * Search CPAN

L<https://metacpan.org/release/Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

