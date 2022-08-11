package OptionHash;
# ABSTRACT: Checking of option hashes


use 5.0.4;
use strict;
use warnings;
use Carp;
use base qw< Exporter >;
our @EXPORT = (qw< ohash_check ohash_define >);
our $VERSION = '0.2.2';

my $ohash_def = bless {keys => {'keys' => 1}}, __PACKAGE__;


sub ohash_define{
    my %x = @_;
    ohash_check($ohash_def, \%x);
    my %def = ( keys => { map{ $_ => 1} @{$x{keys}}} );
    return bless \%def, __PACKAGE__;
}


sub ohash_check($%){
    my($oh, $h) = @_;
    ref $oh eq 'OptionHash' or croak 'Not an OptionHash (you passed '.(ref $oh || 'a plain value').') - expecting ohash_check( $ohash_def, $hashref) ';
    ref $h eq 'HASH' or croak 'Not a hashref - expecting ohash_check( $ohash_def, $hashref) ';
    my $keys = $oh->{keys} or die;
    for( keys(%{$h}) ){
        if( ! exists $keys->{$_} ){
            croak "Invalid key $_ in OptionHash";
        }
    }
}


;1

__END__

=pod

=encoding UTF-8

=head1 NAME

OptionHash - Checking of option hashes

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

  use OptionHash;

  my $cat_def = ohash_define( keys => [qw< tail nose claws teeth >]);

  sub cat{
    my %options = @_;
    ohash_check( $cat_def, \%options);
    # ...
  }

  cat( teeth => 'sharp' );
  cat( trunk => 'long'); # Boom, will fail. Cats dont expect to have a trunk.

=head1 DESCRIPTION

I like to pass options around in hash form because it's clear and
flexible. However it can lead to sloppy mistakes when you typo the
keys. OptionHash quickly checks your hashes against a definition and croaks if
you've passed in bad keys.

Currently.. That's it! Simple but effective.

=head1 EXPORTED SUBS

=head2 ohash_define

Define an optionhash specification, sort-of a type:

 my $cat_def = ohash_define( keys => [ qw< teeth claws > ]);

=head2 ohash_check

Check a hash against a definition:

  ohash_check( $cat_def, \%options);

If everything is okay things will proceed, otherwise ohash_check will croak
(see Carp).

=head1 NOTES

Generally the way to use this is to create the definition "types" at compile
time in the package definition & then check against them later :

 package foo;
 use OptionHash;
 my $DOG_DEF = ohash_define( keys => [ qw< nose > ]);
 sub build_a_dog{
     my( %opts ) = @_;
     ohash_check($DOG_DEF, \%opts);
 }
 1;

=head1 WHY NOT USE...

=head2 Params::ValidationCompiler

Params::ValidationCompiler can also validate a hash of options, and a lot more
besides, so it's well worth a look. There's a lot more going on than in
OptionHash which (I'd say) is a bit more focused (thus far anyway) so it's a
balance between features and complexity. Had I found
Params::ValidationCompiler before I wrote this I probably wouldn't have
bothered to re-invent the wheel, but as I already have I'm glad I did!

=head1 AUTHOR

Joe Higton <draxil@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Joe Higton <draxil@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
