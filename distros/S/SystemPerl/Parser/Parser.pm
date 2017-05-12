# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Parser;
use Carp;

require DynaLoader;
@ISA = qw(DynaLoader);

use strict;
use vars qw($VERSION);

$VERSION = '1.344';

######################################################################
#### Configuration Section

bootstrap SystemC::Parser;

######################################################################
#### Accessors

sub new {
    my $class = shift;  $class = ref $class if ref $class;
    my $self = { strip_autos=>0,
		 @_};

    bless $self, $class;
    return $self;
}

sub read {
    my $self = shift;
    my %param = (@_);
    (-r $param{filename}) or croak "%Error: file not found: $param{filename}, stopped";
    $self->_read_xs($param{filename}, $param{strip_autos}||$self->{strip_autos});
}

sub read_include {
    my $self = shift;
    my %param = (@_);
    (-r $param{filename}) or croak "%Error: file not found: $param{filename}, stopped";
    $self->_read_include_xs($param{filename});
}

#In Parser.XS:
# sub _read_xs {class}
# sub _read_include_xs {class}
# sub filename {class}
# sub lineno {class}

######################################################################
#### Called by the parser

sub auto {}
sub cell {}
sub cell_decl {}
sub covergroup_begin {}
sub covergroup_description {}
sub covergroup_end {}
sub covergroup_page {}
sub covergroup_per_instance {}
sub coverpoint {}
sub coverpoint_begin {}
sub coverpoint_end {}
sub coverpoint_window {}
sub coversample {}
sub cross {}
sub cross_begin {}
sub cross_end {}
sub ctor {}
sub enum_value {}
sub module {}
sub module_continued {}
sub pin {}
sub pin_template {}
sub preproc_sp {}
sub signal {}
sub text {}
sub var_decl {}


sub fileline {
    my $self = shift;
    return ($self->filename||"").":".($self->lineno||"");
}

sub error {
    my ($self,$text,$token)=@_;
    my $fileline = $self->filename.":".$self->lineno;
    croak ("%Error: $fileline: $text\n"
	   ."%Error: ".(" "x length($fileline)).": At token '$token'\nStopped");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Parser - Parse SystemC Files

=head1 SYNOPSIS

    package Trialparser;
    @ISA = qw(SystemC::Parser);

    sub module {
	my $self = shift;
	my $module = shift;
	print $self->filename.":".$self->lineno().": ";
	print "Contains the module declaration for $module\n";
    }

    package main;
    my $sp = Trialparser->new();
    $sp->read ("test.sp");

=head1 DESCRIPTION

L<SystemC::Parser> reads SystemC files, and parses out the netlist
interconnectivity and other information.  As the tokens are recognized,
callbacks are invoked.  Note that the parser is designed to work on
UNPREPROCESSED files.

=head1 MEMBER FUNCTIONS

=over 4

=item $self->new()

Creates a new parser element.

=item $self->read(I<filename>)

Reads the filename and invokes necessary callbacks.

=item $self->read_include(I<filename>)

When called from inside a read() callback function, switches to the
specified include file.  The EOF of the include file will automatically
switch back to the original file.

=back

=head1 ACCESSOR FUNCTIONS

=over 4

=item $self->filename()

Returns the filename of the most recently returned object.  May not match
the filename passed on the command line, as #line directives are honored.

=item $self->lineno()

Returns the line number at the beginning of the most recently returned
object.

=item $self->symbols()

Returns hash reference to list of all symbols with line number the symbol
first was encountered on.  (The hash is created instead of invoking a callback
on each symbol for speed reasons.)  Keywords may also be placed into the symbol
table, this behavior may change.

=back

=head1 CALLBACKS

=over 4

=item $self->auto  (I<text>)

Auto is called with the text matching /*AUTOINST*/, etc.

=item $self->cell  (I<instance>, I<type>)

Cell is called when SP_CELL is recognized.  Parameters are the instance and
type of the cell.

=item $self->cell_decl  (I<type>, I<instances>)

Cell_decl is called when SP_CELL_DECL is recognized.  Parameters are the
type and instances of the cell.  (Note the parameter order is opposite that
of cell().)

=item $self->ctor  (I<modulename>)

Ctor is called when CP_CTOR is recognized.  Parameter is the modulename.

=item $self->enum_value  (I<enum_type>, I<enum_name>, I<enum_value>)

Enum value is called with the enum type and name for a enumeration
value.  If in the file, the enumeration value (=n) is given.

=item $self->error (I<error_text>, I<token>)

Error is called when the parser hits a error.  Token is the last unparsed
token, which often gives a good indication of the error position.

=item $self->module  (I<modulename>)

Module is called when SC_MODULE is recognized.

=item $self->pin  (I<cell>, I<pin>, I<pin_bus>, I<signal>, I<signal_bus>)

Pin is called when SP_PIN is recognized.

=item $self->preproc_sp  (I<text>)

Preproc is called when a #sp line is recognized.

=item $self->signal  (I<type>, I<type_bus>,I<name>,I<name_bus>)

Signal is called on port declarations or sc_signal declarations.
The busses are any [] subscripts after the type names.

=item $self->text  (I<text>)

Text is called for all text not otherwise recognized.  Dumping all
text to a file will produce the original file, minus any #sp and
stripped // Auto inserted comments.

=item $self->var_decl  (I<type>)

Var_decl is called on a variable declaration of sp_ui and any future
SystemPerl types outside of other callbacks.

=back

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.org/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/systemperl>.

Copyright 2001-2014 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SystemC::Manual>

=cut
