package String::Mask;
use 5.006; use strict; use warnings;
use base 'Import::Export';

our $VERSION = '0.02';
our %EX = (
	mask => [qw/all/]
);

sub mask {
	my ($string, $pos, $length, $mask_char) = @_;
	$pos ||= 'start';
	$length ||= int(length($string) / 2);
	if ($pos eq 'end') {
		$string =~ s/(.*)(.{$length})$/_mask($1, $mask_char).$2/es;
	} elsif ($pos eq 'middle') {
		my $half = int((length($string) - $length) / 2);
		$string =~ s/(.{$half})(.{$length})(.*)/_mask($1, $mask_char).$2._mask($3, $mask_char)/e;
	} else {
		$string =~ s/(\w{$length})(.*)/$1._mask($2, $mask_char)/e;
	}
	return $string;
}

sub _mask {
	my ($string, $char) = @_;
	$char ||= '*';
	$string =~ s/[^.@]/$char/g;
	return $string;
}

1;

__END__

=head1 NAME

String::Mask - The great new String::Mask!

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use String::Mask qw/mask/;

	mask('thisusedtobeanemail@gmail.com'); # 'thisusedtobean*****@*****.***'
	mask('thisusedtobeanemail@gmail.com', 'end'); # '***************mail@gmail.com'
	mask('9991234567', 'middle', 4, '_'); # '___1234___'


=head1 EXPORT

=head2 mask

This function accepts 4 arguments:

	mask($string, $position, $length, $char);

=over

=item string

The text that you like to mask.

=item position

The position you would like to be visible. Currently you have three options start, middle or end. The default is start.

=item length

The number of characters that should remain visible. The default is half the length of the passed string.

=item mask character

The mask character that will replace any masked text. The default is *.

=back

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-mask at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Mask>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Mask

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Mask>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/String-Mask>

=item * Search CPAN

L<https://metacpan.org/release/String-Mask>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of String::Mask
