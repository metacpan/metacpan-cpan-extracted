package Spreadsheet::Reader::Format::Types;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.6.4');
#~ use Log::Shiras::Unhide qw( :debug );
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::Format::Types-$VERSION";
		
use strict;
use warnings;
use Type::Utils -all;
use Type::Library 1.000
	-base,
	-declare => qw(															
		NegativeNum					ZeroOrUndef					NotNegativeNum
		PositiveNum					Excel_number_0
	);#
use IO::File;
BEGIN{ extends "Types::Standard" };
my $try_xs =
		exists($ENV{PERL_TYPE_TINY_XS}) ? !!$ENV{PERL_TYPE_TINY_XS} :
		exists($ENV{PERL_ONLY})         ?  !$ENV{PERL_ONLY} :
		1;
if( $try_xs and exists $INC{'Type/Tiny/XS.pm'} ){
	eval "use Type::Tiny::XS 0.010";
	if( $@ ){
		die "You have loaded Type::Tiny::XS but versions prior to 0.010 will cause this module to fail";
	}
}

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9



#########1 Type Library       3#########4#########5#########6#########7#########8#########9

declare PositiveNum,
	as Num,
	where{ $_ > 0 };

declare NegativeNum,
	as Num,
	where{ $_ < 0 };
	
declare ZeroOrUndef,
	as Maybe[Num],
	where{ !$_ };
	
declare NotNegativeNum,
	as Num,
	where{ $_ > -1 };


#########1 Excel Defined Converions     4#########5#########6#########7#########8#########9

declare_coercion Excel_number_0,
	to_type Any, from Maybe[Any],
	via{ $_ };

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9
	

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

__PACKAGE__->meta->make_immutable;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::Format::Types - A type library for Spreadsheet readers
    
=head1 DESCRIPTION

Not written yet

=head1 TYPES

=head2 PositiveNum

This type checks that the value is a number and is greater than 0

=head3 coercions

none

=head2 NegativeNum

This type checks that the value is a number and is less than 0

=head3 coercions

none

=head2 ZeroOrUndef

This type allows the value to be the number 0 or undef

=head3 coercions

none

=head2 NotNegativeNum

This type checks that the value is a number and that the number is greater than 
or equal to 0

=head3 coercions

none

=head1 NAMED COERCIONS

=head2 Excel_number_0

This is essentially a pass through coercion used as a convenience rather than writing the 
pass through each time a coercion is needed but no actual work should be performed on the 
value

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::Format/issues
|https://github.com/jandrew/p5-spreadsheet-reader-format/issues>

=back

=head1 TODO

=over

B<1.> Nothing yet

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2016 by Jed Lund

=head1 DEPENDENCIES

=over

L<Type::Tiny> - 1.000

=back

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
