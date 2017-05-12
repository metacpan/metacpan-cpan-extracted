#!perl
use 5.008001; use utf8; use strict; use warnings;

use only 'Locale::KeyedText' => '1.6.0-';
use only 'Rosetta::Model' => '0.71.0-';

package Rosetta::Utility::SQLParser;
use version; our $VERSION = qv('0.3.0');

######################################################################
######################################################################

# These are constant values used by this module.
my $EMPTY_STR = q{};

######################################################################

sub new {
    my ($class) = @_;
    my $parser = bless {}, ref $class || $class;



    return $parser;
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
    my ($parser, $msg_key, $msg_vars) = @_;
    # Throws an exception consisting of an object.
    ref $msg_vars eq 'HASH' or $msg_vars = {};
    for my $var_key (keys %{$msg_vars}) {
        if (ref $msg_vars->{$var_key} eq 'ARRAY') {
            $msg_vars->{$var_key} = 'PERL_ARRAY:[' . (join q{,},map {$_||$EMPTY_STR} @{$msg_vars->{$var_key}}) . ']';
        }
    }
    die Locale::KeyedText->new_message( $msg_key, $msg_vars );
}

sub _assert_arg_node_type {
    my ($parser, $meth_name, $arg_name, $exp_node_types, $arg_value) = @_;
    $parser->_throw_error_message( 'ROS_U_SP_METH_ARG_UNDEF',
        { 'METH' => $meth_name, 'ARGNM' => $arg_name } )
        if !defined $arg_value;
    $parser->_throw_error_message( 'ROS_U_SP_METH_ARG_NO_NODE',
        { 'METH' => $meth_name, 'ARGNM' => $arg_name, 'ARGVL' => $arg_value } )
        if !ref $arg_value or !UNIVERSAL::isa( $arg_value, 'Rosetta::Model::Node' );
    return
        if @{$exp_node_types} == 0; # any Node type is acceptable
    my $given_node_type = $arg_value->get_node_type();
    $parser->_throw_error_message( 'ROS_U_SP_METH_ARG_WRONG_NODE_TYPE',
        { 'METH' => $meth_name, 'ARGNM' => $arg_name,
        'EXPNTYPE' => $exp_node_types, 'ARGNTYPE' => $given_node_type } )
        if !grep { $given_node_type eq $_ } @{$exp_node_types};
    # If we get here, $arg_value is acceptable to the method.
}

######################################################################
######################################################################

1;
__END__

=encoding utf8

=head1 NAME

Rosetta::Utility::SQLParser - Parse ANSI/ISO SQL:2003 and other SQL variants

=head1 VERSION

This document describes Rosetta::Utility::SQLParser version 0.3.0.

=head1 SYNOPSIS

I<This documentation section will be written later.>

=head1 DESCRIPTION

This module is a reference implementation of fundamental Rosetta::Model
features.

The Rosetta::Utility::SQLParser Perl 5 module is a functional but quickly built
Rosetta::Model utility class that converts one or more SQL strings into a set
of related Rosetta::Model Nodes that are functionally equivalent, and can be
used for a variety of tasks that SQL would normally be used with, but
saving the users from having to parse the string SQL themselves.  This
class will parse multiple string SQL variants; usually it can determine the
intent of a SQL string based soley from examining the string itself, but in
cases where the string is ambiguous as to what SQL variant it is, this
class takes arguments that let you give it hints to resolve the ambiguity;
by default it will resolve ambiguities by whatever decision results in
something closer to the ANSI/ISO SQL:2003 (or 1999 or 1992) standard.

Rosetta::Utility::SQLParser is designed to implement common functionality for
multiple Rosetta Engine classes (such as Rosetta::Engine::Generic) allowing
them to focus more on the non-SQL specific aspects of their work.  A
Rosetta Engine would typically invoke this class when reverse-engineering a
database schema where the database returns the schema object descriptors as
SQL strings ('create' statements usually) rather than the information being
in an "information schema".  This class can also be used by code on the
application-side of a Rosetta::Interface tree (such as
Rosetta::Emulator::DBI); for example, a module that emulates an older
database interface which wants to accept database commands as SQL strings
can use this module to parse those. (For your reference, see also the
Rosetta::Utility::SQLBuilder module, which implements the inverse functionality
to SQLParser, and is used in both of the same places.)

I<CAVEAT:  SIGNIFICANT PORTIONS OF THIS MODULE ARE NOT WRITTEN YET.>

=head1 CONSTRUCTOR FUNCTIONS

This function is stateless and can be invoked off of either this module's
name or an existing module object, with the same result.

=head2 new()

    my $parser = Rosetta::Utility::SQLParser->new();
    my $parser2 = $parser->new();

This "getter" function/method will create and return a single
Rosetta::Utility::SQLParser (or subclass) object.  All of this object's
properties are set to default values that should cause the object to
resolve SQL parsing ambiguities in a manner leaning towards the SQL:2003
standard.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl modules L<version> and L<only>, which would
conceptually be built-in to Perl, but aren't, so they are on CPAN instead.

It also requires these modules that are on CPAN: L<Locale::KeyedText>
'1.6.0-' (for error messages), L<Rosetta::Model> '0.71.0-'.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Rosetta::Utility::SQLParser::L::en>, L<Locale::KeyedText>,
L<Rosetta::Model>, L<Rosetta::Utility::SQLBuilder>, L<Rosetta::Engine::Generic>,
L<Rosetta::Emulator::DBI>, L<DBIx::MyParse>.

=head1 BUGS AND LIMITATIONS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible
ways.

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta::Utility::SQLParser reference implementation
of a SQL:2003 string parser that uses the Rosetta::Model database portability
library.

Rosetta::Utility::SQLParser is Copyright (c) 2002-2005, Darren R. Duncan.  All
rights reserved.  Address comments, suggestions, and bug reports to
C<perl@DarrenDuncan.net>, or visit L<http://www.DarrenDuncan.net/> for more
information.

Rosetta::Utility::SQLParser is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License (GPL) as
published by the Free Software Foundation (L<http://www.fsf.org/>); either
version 2 of the License, or (at your option) any later version.  You
should have received a copy of the GPL as part of the
Rosetta::Utility::SQLParser distribution, in the file named "GPL"; if not,
write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.

Linking Rosetta::Utility::SQLParser statically or dynamically with other
modules is making a combined work based on Rosetta::Utility::SQLParser.  Thus,
the terms and conditions of the GPL cover the whole combination.  As a
special exception, the copyright holders of Rosetta::Utility::SQLParser give
you permission to link Rosetta::Utility::SQLParser with independent modules,
regardless of the license terms of these independent modules, and to copy
and distribute the resulting combined work under terms of your choice,
provided that every copy of the combined work is accompanied by a complete
copy of the source code of Rosetta::Utility::SQLParser (the version of
Rosetta::Utility::SQLParser used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on
Rosetta::Utility::SQLParser, and which is fully useable when not linked to
Rosetta::Utility::SQLParser in any form.

Any versions of Rosetta::Utility::SQLParser that you modify and distribute must
carry prominent notices stating that you changed the files and the date of
any changes, in addition to preserving this original copyright notice and
other credits.  Rosetta::Utility::SQLParser is distributed in the hope that it
will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of
Rosetta::Utility::SQLParser would appreciate being informed any time you create
a modified version of Rosetta::Utility::SQLParser that you are willing to
distribute, because that is a practical way of suggesting improvements to
the standard version.

=cut
