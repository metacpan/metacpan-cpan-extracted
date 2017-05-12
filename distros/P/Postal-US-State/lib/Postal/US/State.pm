package Postal::US::State;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

Postal::US::State - State names and codes

=head1 SYNOPSIS

  use Postal::US::State;

  my $code = Postal::US::State->code('Texas');
  my $state = Postal::US::State->state('TX');

=head1 About

State names/codes data are built-in to this module (generated from
http://www.usps.com/ncsc/lookups/abbr_state.txt by the build process).

=cut


my %code_state = (
### STATES REGEN {{{
  AL => 'Alabama',
  AK => 'Alaska',
  AS => 'American Samoa',
  AZ => 'Arizona',
  AR => 'Arkansas',
  CA => 'California',
  CO => 'Colorado',
  CT => 'Connecticut',
  DE => 'Delaware',
  DC => 'District of Columbia',
  FM => 'Federated States of Micronesia',
  FL => 'Florida',
  GA => 'Georgia',
  GU => 'Guam',
  HI => 'Hawaii',
  ID => 'Idaho',
  IL => 'Illinois',
  IN => 'Indiana',
  IA => 'Iowa',
  KS => 'Kansas',
  KY => 'Kentucky',
  LA => 'Louisiana',
  ME => 'Maine',
  MH => 'Marshall Islands',
  MD => 'Maryland',
  MA => 'Massachusetts',
  MI => 'Michigan',
  MN => 'Minnesota',
  MS => 'Mississippi',
  MO => 'Missouri',
  MT => 'Montana',
  NE => 'Nebraska',
  NV => 'Nevada',
  NH => 'New Hampshire',
  NJ => 'New Jersey',
  NM => 'New Mexico',
  NY => 'New York',
  NC => 'North Carolina',
  ND => 'North Dakota',
  MP => 'Northern Mariana Islands',
  OH => 'Ohio',
  OK => 'Oklahoma',
  OR => 'Oregon',
  PW => 'Palau',
  PA => 'Pennsylvania',
  PR => 'Puerto Rico',
  RI => 'Rhode Island',
  SC => 'South Carolina',
  SD => 'South Dakota',
  TN => 'Tennessee',
  TX => 'Texas',
  UT => 'Utah',
  VT => 'Vermont',
  VI => 'Virgin Islands',
  VA => 'Virginia',
  WA => 'Washington',
  WV => 'West Virginia',
  WI => 'Wisconsin',
  WY => 'Wyoming',
  AE => 'Armed Forces Africa',
  AA => 'Armed Forces Americas',
  AE => 'Armed Forces Canada',
  AE => 'Armed Forces Europe',
  AE => 'Armed Forces Middle East',
  AP => 'Armed Forces Pacific',
### STATES REGEN }}}
);
my %state_code = map({lc($code_state{$_}) => $_} keys %code_state);


=head2 code

Retrieve the two-letter code for the given state name (case
insensitive.)  Returns undefined if the state is unknown.

  my $code = Postal::US::State->code('Texas');

=cut

sub code {
  my $package = shift;
  my $state = shift or croak("must have state argument");

  return $state_code{lc($state)};
} # code ###############################################################

=head2 state

Returns the state name for the given code.

  my $state = Postal::US::State->state('TX');

=cut

sub state {
  my $package = shift;
  my $abbr = shift or croak("must have state abbreviation");

  return $code_state{uc($abbr)};
} # state ##############################################################



=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2010 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE



=cut

# vi:ts=2:sw=2:et:sta
1;
