package Myco::Util::Strings;

###############################################################################
# $Id: Strings.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Util::Strings -  a Myco entity class

=head1 SYNOPSIS

  use Myco::Util::Strings;

=head1 DESCRIPTION

A simple shell to store oft-used string-manipulation routines.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;

##############################################################################
# Programatic Dependencies
use Data::Dumper;
use Digest::SHA1;
use MIME::Base64;

##############################################################################
# Constants
##############################################################################

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw(Myco::Entity);
my $md = Myco::Entity::Meta->new( name => __PACKAGE__ );

##############################################################################
# Function and Closure Prototypes
##############################################################################

##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS METHODS

=head2 pretty_print

  my $attribute_label = Myco::Util::Strings->pretty_print('person_last_name');
  my $do_these_words_match = $attribute_label eq 'Person Last Name';

Attempts to prettify any string.

=cut

sub pretty_print {
    my $self = shift;
    my $str = shift;

    # substitute underscores for spaces
    $str =~ s/_/' '/eg if $str =~ /.+_.+/;

    # capitalize each word
    $str =~ s/\b(\w)/uc($1)/eg;

    return $str;
}
# a shorter-named 'alias' method
sub fmt { $_[0]->pretty_print($_[1]) }


=head2 get_last_uri_word

  my $title = Myco::Util::Strings->get_last_uri_word('/o/person/search/');
  my $nice_uri_last_word = $title eq 'Search';

Attempts to prettify and return the last word in a base uri.

=cut

sub get_last_uri_word {
    my $self = shift;
    my $uri = shift;

    $uri =~ s/\// /;
    $uri =~ s{.*[^\w](\w)}{$1};
    return $self->pretty_print($uri);
}



=head2 js_dumper

  my %hash = ( a => 1, b => 2, c => 3 );
  my $javascript_hash = Myco::Util::Strings->get_javascript(\%hash);
  my $hashes_match = $javascript_hash eq "{ 'a' : 1, 'b' : 2, 'c' : 3 }";

Makes use of Data::Dumper to stringify a Perl data structure and format it for
use as a javascript data structure.

=cut

sub js_dumper {
    my $self = shift;
    my $perl_structure = shift;

    my $js_structure = Dumper($perl_structure);
    for ($js_structure) {
        # replace Perl-style hash commas w/colons
        s/=>/\:/g;
        # remove the leading '$VAR1 = ' from Dumper
        s/^\$VAR[0-9]+\s*=\s*//;
        # remove trailing ';'
        s/\;$//;
        # remove newlines
#        s/\n//g;
    }
    return $js_structure;
}



=head2 classname

  my $strfmt = Myco::Util::Strings->new;
  my $abbr = $strfmt->get_abbr_classname('Myco::Animal::GiantSquid');
  my $isa_squid = $abbr eq 'Giant Squid';

Parses out a nice class name.

=cut

sub classname {
    my $class_name = $_[1];
    $class_name =~ s/.*::(\w)/$1/;
    return join ' ', $class_name =~ /([A-Z]{1}[a-z]+)/g;
}
sub get_abbr_classname { shift->classname(@_) }

=head2 rand_str

  my $strfmt = Myco::Util::Strings->new;
  my $random_string = $strfmt->rand_str(6); # like 13d0vr

Generates a psudo-random alphanumeric string of n-length.

=cut

sub rand_str {
  shift;
  my $len = shift || 0;
  my @alphanum = ('a'..'z', 0..9);
  return join '', map { $alphanum[int(rand @alphanum-1)] } 1..$len;
}

=head2 ssha_crypt

  my $password = Myco::Util::Strings->ssha_crypt('hush-hush', $salt);

Encrypt a string using the SSHA (Secure Salted Hash Algorithm).
Salt is optional, and will be generated in its absence.

=cut

sub ssha_crypt {
  shift;
  my ($pass, $salt) = @_;
  if (! $salt) {
    for (0..10) {
      open(RANDOM, '/dev/random');
      $salt .= join '', <RANDOM>;
      last if length $salt > 10;
    }
  }
  my $ctx = Digest::SHA1->new;
  $ctx->add($pass);
  $ctx->add($salt);
  return '{SSHA}' . encode_base64($ctx->digest . $salt, '');
}

##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Util::Strings::Test|Myco::Util::Strings::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
