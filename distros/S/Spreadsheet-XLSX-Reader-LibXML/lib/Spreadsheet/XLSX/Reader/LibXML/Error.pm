package Spreadsheet::XLSX::Reader::LibXML::Error;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::Error-$VERSION";

use Moose;
use Carp qw( cluck longmess );
#~ our @CARP_NOT = qw(
		#~ Spreadsheet::XLSX::Reader::LibXML::Error
		#~ Class::MOP::Class
		#~ Moose::Meta::Method::Delegation
	#~ );
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use Types::Standard qw(
		Str
		Bool
    );
use Devel::StackTrace;
use lib	'../../../../../lib',;
use Spreadsheet::XLSX::Reader::LibXML::Types qw( ErrorString );
###LogSD	with 'Log::Shiras::LogSpace';
###LogSD	use Log::Shiras::Telephone;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has error_string =>(
		isa			=> ErrorString,
		clearer		=> 'clear_error',
		reader		=> 'error',
		writer		=> 'set_error',
		init_arg 	=> undef,
		coerce		=> 1,
		trigger	=> sub{
			my ( $self, $error ) = @_;
			###LogSD	my	$phone = Log::Shiras::Telephone->new( 
			###LogSD				name_space => $self->get_all_space . '::set_error',  );
			my $error_string;
			###LogSD	$error_string = "In name_space: " . $self->get_all_space . "\n";
			if( $self->spewing_longmess ){
				$error_string .= longmess( $error );
			}else{
				$error_string .= $error;
			}
			###LogSD	$phone->talk( level => 'warn', message => [ $error_string . "\n------------------------------\n" ] );
			if( $self->if_warn ){
				warn "$error_string\n";
			}
		},
		predicate => 'has_error',
	);

has should_warn =>(
		isa		=> Bool,
		default	=> 0,
		writer	=> 'set_warnings',
		reader	=> 'if_warn',
	);

has spew_longmess =>(
		isa		=> Bool,
		default	=> 1,
		writer	=> 'should_spew_longmess',
		reader	=> 'spewing_longmess',
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

#~ sub DEMOLISH{
	#~ my ( $self ) = @_;
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD				$self->get_all_space . '::hidden::DEMOLISH', );
	#~ ###LogSD		$phone->talk( level => 'debug', message => [
	#~ ###LogSD			"Closing the error instance" ] );
	#~ print "Error closed\n";
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::Error - Moose class for remembering the last error

=head1 SYNOPSIS
	
    #!/usr/bin/env perl
    $|=1;
    use MooseX::ShortCut::BuildInstance qw( build_instance );
    use Spreadsheet::XLSX::Reader::LibXML::Error;

    my  $action = build_instance(
            add_attributes =>{ 
                error_inst =>{
                    handles =>[ qw( error set_error clear_error set_warnings if_warn ) ],
                },
            },
			error_inst => Spreadsheet::XLSX::Reader::LibXML::Error->new(
				should_warn => 1,# 0 to turn off cluck when the error is set
			),
        );
    print $action->dump;
          $action->set_error( "You did something wrong" );
    print $action->dump;
    print $action->error . "\n";
	
    ##############################################################################
    # SYNOPSIS Screen Output
    # 01: $VAR1 = bless( {
    # 02:             'error_inst' => bless( {
    # 03:                                 'should_warn' => 1,
    # 04:                                 'log_space' => 'Spreadsheet::XLSX::Reader::LogSpace'
    # 04:                             }, 'Spreadsheet::XLSX::Reader::Error' )
    # 05:         }, 'ANONYMOUS_SHIRAS_MOOSE_CLASS_1' );
    # 06: You did something wrong at ~~lib/Spreadsheet/XLSX/Reader/LibXML/Error.pm line 31.
    # 08:    Spreadsheet::XLSX::Reader::Error::__ANON__('Spreadsheet::XLSX::Reader::Error=HASH(0x45e818)', 'You did something wrong') called at writer Spreadsheet::XLSX::Reader::Error::set_error of attribute error_string (defined at ../lib/Spreadsheet/XLSX/Reader/Error.pm line 42) line 13
    # 09:    Spreadsheet::XLSX::Reader::Error::set_error('Spreadsheet::XLSX::Reader::Error'=HASH(0x45e818)', 'You did something wrong') called at C:/strawberry/perl/site/lib/Moose/Meta/Method/Delegation.pm line 110
    # 10:    ANONYMOUS_SHIRAS_MOOSE_CLASS_1::set_error('ANONYMOUS_SHIRAS_MOOSE_CLASS_1=HASH(0x45e890)', 'You did something wrong') called at error_example.pl line 18
    # 11: $VAR1 = bless( {
    # 12:             'error_inst' => bless( {
    # 13:                                 'should_warn' => 1,
    # 14:                                 'error_string' => 'You did something wrong'
    # 15:                             }, 'Spreadsheet::XLSX::Reader::Error' )
    # 16:         }, 'ANONYMOUS_SHIRAS_MOOSE_CLASS_1' );
    # 17: You did something wrong
    ##############################################################################
    
=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own excel 
parser.  To use the general package for excel parsing out of the box please review the 
documentation for L<Workbooks|Spreadsheet::XLSX::Reader::LibXML>,
L<Worksheets|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>

This L<Moose> class contains two L<attributes|Moose::Manual::Attributes>.  It is intended 
to be used through (by) L<delegation|Moose::Manual::Delegation> in other classes.  The first 
attribute is used to store the current error string.  The second, is set to turn on or off 
pushing the error string to STDERR when the first attribute is (re)set.

=head2 Attributes

Data passed to new when creating an instance.   For modification of 
these attributes see the listed 'attribute methods'. For more information on 
attributes see L<Moose::Manual::Attributes>.

=head3 error_string

=over

B<Definition:> This stores an error string for recall later.

B<Default> undef (init_arg = undef)

B<Range> any string (error objects with the 'as_string' or 'message' are auto coerced to 
a string)

B<attribute methods> Methods provided to adjust this attribute
		
=back

=head4 error

=over

B<Definition:> returns the currently stored error string

=back

=head4 clear_error

=over

B<Definition:> clears the currently stored error string

=back

=head4 set_error( $error_string )

=over

B<Definition:> sets the attribute with $error_string.

=back

=head3 should_warn

=over

B<Definition:> This determines if the package will push any low level errors logged 
during processing to STDERR when they occur. (rather than just made available) It 
should be noted that failures that kill the package should push to STDERR by default.  
If your Excel sheet is malformed it can error without failing.  Sometimes this package 
will handle those cases correctly and sometimes it wont.  If you want to know more 
behind the scenes about the unexpected behaviour of the sheet then turn this attribute 
on.

B<Default> 1 -> it will push to STDERR

B<Range> Boolean values

B<attribute methods> Methods provided to adjust this attribute
		
=back

=head4 set_warnings( $bool )

=over

B<Definition:> Turn pushed warnings on or off

=back

=head4 if_warn

=over

B<Definition:> Returns the current setting of this attribute

=back

=head3 spew_longmess

=over

B<Definition:> This (the Error) class is capable of pulling the L<Carp/longmess> 
for each error in order to understand what happened.  If that is just too much 
you can change the behaviour

B<Default> 1 -> it will pull the longmess (using Carp);

B<Range> Boolean values

B<attribute methods> Methods provided to adjust this attribute
		
=back

=head4 should_spew_longmess( $bool )

=over

B<Definition:> add the longmess to errors

=back

=head4 spewing_longmess

=over

B<Definition:> Returns the current setting of this attribute

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> get clases in this package to return error numbers and or error strings and 
then provide opportunity for this class to localize.
B<2.> Get the @CARP_NOT section to work and skip most of the Moose level reporting

=back

=head1 AUTHOR

=over

Jed Lund

jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2014, 2015 by Jed Lund

=head1 DEPENDENCIES

=over

L<version> - 0.77

L<Moose>

L<Carp> - cluck

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<Types::Standard>

L<Spreadsheet::XLSX::Reader::LibXML::Types> - v0.34

=back

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::XLSX> - 2007+

L<Spreadsheet::ParseXLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9