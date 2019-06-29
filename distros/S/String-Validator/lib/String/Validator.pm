package String::Validator;
$String::Validator::VERSION = '2.02';
use 5.008;
use strict;
use warnings;

# ABSTRACT: A Collection of Routines for validating and transforming strings


1;

# End of Validator

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Validator - A Collection of Routines for validating and transforming strings

=head1 VERSION

version 2.02

=head1 Description

A Collection of Routines for validating and transforming strings

=head2 Why String::Validator

You have a string and you need to know if it is what you need it to be.
You just wasted three hours before you realized it was going to take
longer than you thought and just started to poke around cpan to find
something to use instead. The String Validator Collection is what you are looking for.

Since as often as not you're not just validating strings, but also
trying to get them into a specific format, many String::Validator Modules
will do this.

=head3 The String::Validator Module

The Core Module, String::Validator is empty. It contains some common
documentation, and all other String::Validator Modules are dependencies
to install it. You can type cpanm String::Validator to install the current
version of all of the Modules.

=head1 Methods Common to String::Validator Modules

=head2 The New Method

The new method for String-Validators takes as an argument a hash of
parameters, these will be different for each module. See the specific
Module's Documentation.

=head2 The Postive and Negative Method

The negative method B<IsNot_Valid> will return 0 (false) for a valid string
and the reason as a string for an invalid one.

The positive method B<Is_Valid> will return 1 (true) and 0 (false). To find out
why a string failed use the errstr method.

Both Is_Valid and IsNot_Valid will take either one string or two strings as
arguments. If two strings are provided they are compared. When two strings are
provided and do not match only 1 error is observed, because String::Validator cannot
know which (if either) to continue evaluating. If called subsequently the String() method will
return Null and the errorcnt() method will return 1.

=head2 errstr, errcnt

B<errcnt> returns the number of errors seen on the last call to Is/IsNot_Valid.
B<errstr> returns a string describing the errors encountered.

=head2 String, Reformatting

The String method always returns the internal representation of the
last string evaluated by Is/IsNot_Valid. The exceptions are that a new
String::Validator Object will return a NULL value, as it will following
a mismatch error when the string is passed twice.
String-Validators may provide reformat methods appropriate to their purpose
and will be documented in their own POD.

=head2 Example

 my $Validator = String::Validator::Demo->new(
    format => 'fake', min_length => 6, max_length => 17 ) ;
 if ( $Validator->IsNot_Valid('ThisString') { do something }
     or
 unless ( $Validator->IsNot_Valid('ThatString') { die $Validator->errstr() }
     maybe
 if ( $Validator->IsNot_Valid('ThisString', 'RepeatThisString') { do something }
 say  $Validator->String ;

=head2 CamelCase lowercase

The base class String::Validator::Common provides both the CamelCase and lowercase
versions of the methods it provides for use by the end user of the inheriting module,
this is done to make it even more convenient.

=head1 Customizing with Language and Custom Messages.

As of Version 2.0 the ->new Method to takes two optional parameters: language and custom_messages, which are expected to be a hash of message names and messages, in some cases the messages are code_refs. String::Validator::Language contains translation modules. You may also pass a hash over-riding the messages of a String::Validator with custom_messages. If you want to write customzed messages in a Validator Module, obtain a list of the messages, by using Data::Dumper or Data::Printer against an object of that validator; without any languages loaded.

 my $TranslatedValidator =
     String::Validator::SomeValidator->new(
         language=> String::Validator::Language::CHACKOBSA->new,
         custom_messages => {
         	somevalidator_sandworm => 'Shai-Halud'});

See String::Validator::Language for a list of available languages.

There are a few examples of this in the tests. The coderef form example test is in password because that module has messages that use a coderef.

=head1 Making Validator Better

Everything Validator does is a waste of time (if you had to do it yourself).
So if you find you've wasted time validating something that fits
with the Validator theme, write it up and send it in. If you think
Validator does a poor job of something, send a better solution.
If you already made a module even better, just wrap it up as a Validator.

If you use String Validator in a Language other than English and don't see your language in String::Validator::Language, or that it is missing some messages, Submit a translation patch for String::Validator::Language.

=head1 Bug Reports and Patches

Please submit Bug Reports and Patches via https://github.com/brainbuz/String-Validator.

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by John Karr.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
