package String::Validator::Common;
$String::Validator::Common::VERSION = '1.01';
# ABSTRACT: Base Module for creating new String::Validator Modules.

use 5.008;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->{class} = $class;
    $self->_Init();
    return $self;
}

sub IncreaseErr {
    my $self = shift;
    $self->{errstring} .= "@_\n";
    $self->{error}++;
}

# Every time we get a new request
# these values need to be reset from the
# previous request.
sub _Init {
    my $self = shift;
    $self->{errstring} = '';
    $self->{error}     = 0;
    $self->{string}    = '';
}

sub Start {
    my ( $self, $string1, $string2 ) = @_;
    $self->_Init();

    # String comparison, must not fail if no string2 is provided.
    # string2 is also available for destructive operations.
    # Failing the string match alse necessitates immediate
    # error return as the other tests are meaningless as
    # we cannot know if either or neither string is the password.
    no warnings 'uninitialized';
    if ( 0 == length $string2 ) { }
    elsif ( $string1 ne $string2 ) {
        $self->IncreaseErr('Strings don\'t match.');
        return 99;
    }
    $self->{string} = $string1;
    return 0;
}

sub Length {
    my $self   = shift;
    my $string = $self->{string};
    if ( length( $self->{string} ) < $self->{min_len} ) {
        $self->IncreaseErr( "Length of "
              . length( $self->{string} )
              . " Does not meet requirement: Min Length "
              . $self->{min_len}
              . "." );
        return $self->{error};
    }
    if ( $self->{max_len} ) {
        if ( length( $self->{string} ) > $self->{max_len} ) {
            $self->IncreaseErr( "Length of "
                  . length( $self->{string} )
                  . " Does not meet requirement: Max Length "
                  . $self->{max_len}
                  . "." );
            return $self->{error};
        }
    }
    return 0;
}

sub CheckCommon {
    my ( $self, $string1, $string2 ) = @_;
    if ( $self->Start( $string1, $string2 ) ) {
        return $self->{error};
    }
    if ( $self->Length ) { return $self->{error} }
    return 0;
}

# Check serves as example, but more importantly lets
# us test the module.
# Takes 2 strings and runs Start.
# If the strings match it returns 0, else 1.
sub Check {
    my ( $self, $string1, $string2 ) = @_;
    my $started = $self->Start( $string1, $string2 );
    return $self->{error};
}

sub Errcnt {
    my $self = shift;
    return $self->{error};
}

sub Errstr {
    my $self = shift;
    return $self->{errstring};
}

sub IsNot_Valid {
    ( my $self, my $string1, my $string2 ) = @_;
    if   ( $self->Check( $string1, $string2 ) ) { return $self->{errstring} }
    else                                        { return 0 }
}

sub Is_Valid {
    ( my $self, my $string1, my $string2 ) = @_;
    if   ( $self->Check( $string1, $string2 ) ) { return 0 }
    else                                        { return 1 }
}

sub String {
    my $self = shift;
    return $self->{string};
}

# The lowercase version of methods.
sub errcnt      { my $self = shift; $self->Errcnt() }
sub errstr      { my $self = shift; $self->Errstr() }
sub isnot_valid { my $self = shift; $self->IsNot_Valid() }
sub is_valid    { my $self = shift; $self->Is_Valid() }
sub string      { my $self = shift; $self->String() }


1;    # End of String::Validator::Common

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Validator::Common - Base Module for creating new String::Validator Modules.

=head1 VERSION

version 1.01

=head1 DESCRIPTION

A base module for use in creating new String Validators.

=head1 String::Validator::Common Methods and Usage

=head2 Public Methods

The Following Methods are meant to be provided by sublcasses as Public Methods: B<IsValid, IsNotValid, Errstr, Errcnt, String>.

=head2 Semi-Private Methods

The remaining methods are meant for use within subclasses of String::Validator::Common. They are not preceded with _ characters because they are being exposed from SVC to the inheriting class.

=head2 new

Modules Using String Validator Common extend the attributes in their own new methods.

 use String::Validator::Common;
 sub new {
 my $class = shift ;
 my $self = { @_ } ;
 use base ( 'String::Validator::Common' ) ;
 unless ( defined $self->{ some_param } )
   { $self->{ some_param } = 'somedefault'; }
 ...
 bless $self , $class ;
 return $self ;
 }

=head2 Check

Check is a stub subroutine, that you will replace in any Validator Module you write
with the code to validate the string. Is_Valid and IsNot_Valid base their results on Check. Check returns $self->{error}, if there are no errors this will be 0. When you
replace Check in your Validator Module you should implement the same behaviour so that IsValid and IsNot_Valid work. 

=head2 IsNot_Valid

Takes a string and optionally a second string (if you want to make sure two copies of a string are identical as well). Runs the Check subroutine and returns $self->{errstring} if there is an error, otherwise it returns 0. This will evaluate to true if there was an error and false if the string was valid.

=head2 Is_Valid

Takes a string and optionally a second string (if you want to make sure two copies of a string are identical as well). Runs the Check subroutine and returns 1 if Check returned 0, and 0 if Check returned a true value. If you want ->Errcnt() count or ->Errstr you will need to request them via their methods before another string is processed.

=head2 IncreaseErr

A String::Validator contains two error variables error and errstring. When an
error is found, simply pass a brief description to this method to increment
the errorcount, and append the present description to the errstring.

 if ( 1 != 2 ) { $self->IncreaseErr( q/1 Still Doesn't equal 2!/ ) }

=head2 Start

This method initializes three key values: $self->{errstring} ,
$self->{error}, and $self->{string} to NULL, 0, NULL. If no errors are found
error and errstring will remain 0 and NULL. string will be used to hold
the string being evaluated. Arguments are the
string to be evaluated and optionally a second string to be compared with the
first. If the strings are mismatched the sub will return 99, and string will
remain NULL, the inheriting module should immediately return the error and
not contine. 

=head2 Length

Checks $self->{ string } against $self->{ min_length } and $self->{ max_length }
If the length checks pass it returns 0, if one fails it immediately returns
the incremented value of error.

=head2 CheckCommon

CheckCommon is just a shortcut to run Start and Length.

=head2 Errstr, Errcnt, String

Provides these methods for inheritance as described in the String::Validator documentation.

=head2 is_valid, isnot_valid, errcnt, errstr, string

Permit LowerCase invokation of these methods.

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/brainbuz/String-Validator/issues>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by John Karr.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
