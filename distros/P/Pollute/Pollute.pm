package Pollute;

use 5.005;
use strict;
no strict 'refs';
# not standard in version 5.00503: use warnings;
use vars qw/$Package $Package1 %Before $VERSION/;

$VERSION = '0.07';	# 07 September 2001.
#	Changes: see Changes file

sub Pollute(){
	($Package) = caller;
	($Package1) = caller(1);
	foreach (keys %{"${Package}::"}){
		$Before{$_} and next;
		*{"${Package1}::$_"} = *{"${Package}::$_"};
	};
	
	undef %Before;
	undef $Package;
	undef $Package1;
};


sub import{
	($Package) = caller;
	%Before = map {($_,1)} keys %{"${Package}::"};

	*{"${Package}::Pollute"} = \&Pollute;
};

1;
__END__

=head1 NAME

  Pollute, Pollute::Persistent - build include files that use modules indirectly

=head1 SYNOPSIS

Pollute - Perl extension to re-export imported symbols
Pollute::Persistent - Better Perl extension to re-export imported symbols


  use Pollute;
  use This;
  use That;
  use TheOther;
  Pollute;	# exports anything imported from This, That or TheOther

or

  use Pollute::Persistent;
  use This;
  use That;
  use TheOther;
  # use of this module exports anything imported from This, That or TheOther
  

=head1 DESCRIPTION

  On use, all the symbols in the caller's symbol table are listed into
  %Pollute::Before, and the Pollute subroutine is exported (through direct
  symbol table manipulation, not through "Exporter.")

  After importing various things, run Pollute to export everything
  you imported since the C<use Pollute> line into the calling package.

  Pollute::Persistent does the same thing, but using lexicals instead
  of package variables.  Instead of requiring an explicit call to "Pollute"
  Pollute::Persistent clobbers the import subroutine, meaning that you can
  create "include file files" by using Pollute::Persistent

=head2 EXPORT

the C<Pollute> function, which pollutes its caller
with the symbols which appear in the symbol table but do
not appear in %Before.


Pollute::Persistent clobbers the calling package's C<import> function,
and is suitable for recursive use.


=head1 AUTHOR

David Nicol, <lt>pollute_author@davidnicol.com<gt>

The name was suggested by Garrett Goebel.  I was going to
call it "ImportExport."

=head1 LICENSE

GPL/Artistic.  Enjoy.

=head1 SEE ALSO

L<Pollute::Persistent>.

=cut
