=head1 NAME

Telephone::Mnemonic::US::Words - Maps US telephone numbers from mnemonic 'easy-to-remember' words to digits, it
can also attempts the reverse and maps telephone digits to mnemonic words.

=cut
package Telephone::Mnemonic::US::Words;

#use 5.012001;
use strict;
use warnings;
use Data::Dumper;
use Tie::DictFile;
use strict;
use warnings;
use Telephone::Mnemonic::US::Number qw/ to_digits /;
use Telephone::Mnemonic::US::Math qw/ str_pairs dict_path find_valids /;
#use Scalar::Util 'looks_like_number';
#use List::Util qw/ first /;

use 5.010000;
our $VERSION = '0.07';
use Moose::Role;
requires 'num';

#has pairs    => (is=>'rw', isa=>'ArrayRef', lazy=>1, default=>sub{[]} );

has result   => (is=>'rw');
has dict     => (is=>'rw', isa=>'HashRef', builder=>'dict_io', lazy=>0, predicate=>'dict_p');
has timeout  => (is=>'rw', isa=>'Num', default=>0);

sub dict_io {
    my %hash;
    $Tie::DictFile::MAX_WORD_LENGTH = 14;
    tie %hash, 'Tie::DictFile', dict_path || return;
	shift->dict( \%hash );
}


sub to_words {
    my $self = shift;
	# Error Checking...
    # TODO: Dict works?
	return unless $self->dict_p ;
    #my $num = to_tel_digits($num) || die "Not a US phone number. Aborting...\n";
    my $num   = to_digits($self->without_area_code) ;
	return if $num =~ /[0-1]/o  ;
    my $pairs = str_pairs($num);
    my $res   = find_valids ($pairs, $self->dict, $self->timeout);
    # sort by max segment
    $res = [sort { $a->{max_seg} < $b->{max_seg} }  @$res];
	$self->result($res) ;
}

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

 use Telephone::Mnemonic::US::Words;
	with 'Telephone::Mnemonc::US::Words";

=head1 DESCRIPTION

=head2 Role Words


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
