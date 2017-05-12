package TERN::it;

use 5.00000;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

@EXPORT = qw(
	it
	exists_it
	exists_itA
	exists_itH
	defined_it
);

$VERSION = '0.01';


# Preloaded methods go here.

my $it;

sub it(){
	return $$it;
};

sub defined_it(\$){
	return defined(${$it=shift});
};

sub exists_itH(\%$);
sub exists_it(\%$){
	my ($hr, $key) = @_;
	if (exists $hr->{$key}){
		return $it = \$hr->{$key};
	}else{
		return ${$it = \undef};
	};
};

*exists_itH = \&exists_it;

sub exists_itA(\@$){
	my ($ar, $key) = @_;
	if (exists $ar->[$key]){
		return $it = \($ar->[$key]);
	}else{
		return ${$it = \undef};
	};
};

1;

__END__

=head1 NAME

TERN::it - Perl extension for easing nonautovivifying aggregate accesses

=head1 SYNOPSIS

  use TERN::it;
  
  it()
  exists_it(\%$)
  exists_itA(\@)
  exists_itH(\%$)
  defined_it(\$)

  # instead of 
  # print gen_printable $Data->{$state}->{$city}->{$lastname}->{$firstname}
  #
  exists_it %Data, $state and
  exists_it %{it()}, $city and
  exists_it %{it()}, $lastname and
  exists_it %{it()}, $firstname and
  print gen_printable it;



=head1 DESCRIPTION

  $TERN::it is a reserved variable that holds the object of the
  most recent C<exists> or <defined> operation.  The point of this
  is to allow descent into complex data structures without autovivifying
  the empty upper layers and also without repeating all the upper descent
  steps.  This is a small speed win.  This is how TERN will handle
  descent into compex, nested containers.
  
  C<it> this subroutine accesses the current value of it.
  
  C<exists_it> this subroutine takes two arguments, the first a hash
  and the second a key.  If we had prototype-based dispatch, there could
  be two versions be used with an array or a hash and Perl would figure out
  which to call but we don't.
  
  C<exists_itA> 
  	exists_itA @fish, 7	# the same as exists $fish[7] but sets C<it>
	
  C<exists_itH>
  	an alias to exists_it, for symmetry with exists_itA
  	
  C<defined_it>
	defined_it($something) 	# the same as defined(${$TERN::it = \$something})
  

=head2 EXPORT

  it
  exists_it
  exists_itA
  exists_itH
  defined_it


=head1 AUTHOR

David Nicol, <lt>davidnico@cpan.org<gt>

=head1 SEE ALSO

L<TERN>.

=cut
