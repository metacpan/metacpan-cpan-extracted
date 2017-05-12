=head1 NAME

Telephone::Mnemonic::US::Roles::Term - Maps US telephone numbers from mnemonic 'easy-to-remember' words to digits, it
can also attempts the reverse and maps telephone digits to mnemonic words.

=cut
package Telephone::Mnemonic::US::Roles::Term;

#use 5.012001;
use strict;
use warnings;
use Data::Dumper;
use Tie::DictFile;
use strict;
use warnings;

use 5.010000;
our $VERSION = '0.07';
use Moose::Role;
use namespace::autoclean;

=pod

=head2 printthem
 Input: the output of to_words (a href)
 Output: displays some of the data in a table
=cut
sub printthem {
	my ($self,$input, $res) = @_ ;
	$res || return;
	my $t = new Text::Table; 
	print "$input:\n";
    my @data;
    for (@$res) {
		last if $_->{max_seg} < 3;
	 	 push @data , [ printvalids($_->{lvalid}),  printvalids($_->{rvalid}) ];
	}	
	$t->load( @data);
	say $t;
}
=pod

=head2 printvalids
 Helper function for printthem()
 Input: the hash ref
 Output: a stings 
=cut
sub printvalids {
	my $h = shift || return '';
	@$h || return '';
	join '|', @$h;
}


no Moose::Role;

1;
__END__

=pod

=head2 to_num
 Translates a mnemonic tel number to digits
 Input: an alphanumeric sting, like '(g03) verison'
 Output: a string like, like '(703) 232 3333'
=cut

1;

=pod

=head1 SYNOPSIS

 use Telephone::Mnemonic::US::Roles::Term;
	with 'Telephone::Mnemonc::US::Roles::Term";

=head1 DESCRIPTION

=head2 Role Term


=head2 EXPORT

None by default.


=head1 SEE ALSO

L<Tie::Dict>

=head1 AUTHOR

Ioannis Tambouras E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
