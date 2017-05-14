# $Id: Utility.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Utility;
use strict;
use vars '$VERSION'; $VERSION = '0.02';
use base 'Exporter';
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT = @EXPORT_OK = qw(
    %Volume %Length %Note @Note
    name_to_number
    number_to_name
);

# These lists are copied directly from Sean Burke's MIDI::Simple.
#
my %Volume = (
    'ppp'   =>   1,  # pianississimo
    'pp'    =>  12,  # pianissimo
    'p'     =>  24,  # piano
    'mp'    =>  48,  # mezzopiano
    'm'     =>  64,  # mezzo / medio / meta / middle / whatever
    'mezzo' =>  64,
    'mf'    =>  80,  # mezzoforte
    'f'     =>  96,  # forte
    'ff'    => 112,  # fortissimo
    'fff'   => 127,  # fortississimo
);
my %Length = (
    'wn' => 4,     'dwn' => 6,     'ddwn' => 7,       'twn' => (8/3),
    'hn' => 2,     'dhn' => 3,     'ddhn' => 3.5,     'thn' => (4/3),
    'qn' => 1,     'dqn' => 1.5,   'ddqn' => 1.75,    'tqn' => (2/3),
    'en' =>  .5,   'den' =>  .75,  'dden' =>  .75,    'ten' => (1/3),
    'sn' =>  .25,  'dsn' =>  .375, 'ddsn' =>  .4375,  'tsn' => (1/6),
);
my %Note = (
    'C'  =>  0,
    'Cs' =>  1,  'Csharp' =>  1,  'Df' =>  1,  'Dflat' =>  1,
    'D'  =>  2,
    'Ds' =>  3,  'Dsharp' =>  3,  'Ef' =>  3,  'Eflat' =>  3,
    'E'  =>  4,
    'F'  =>  5,
    'Fs' =>  6,  'Fsharp' =>  6,  'Gf' =>  6,  'Gflat' =>  6,
    'G'  =>  7,
    'Gs' =>  8,  'Gsharp' =>  8,  'Af' =>  8,  'Aflat' =>  8,
    'A'  =>  9,
    'As' => 10,  'Asharp' => 10,  'Bf' => 10,  'Bflat' => 10,
    'B'  => 11,
);

# Keep an ordered list too, y'know.
# NOTE: # (Get it? "Note"? Haha *cough*) These must be keys of %Note.
my @Note = qw( C Df D Ef E F Gf G Af A Bf B );

sub name_to_number {
    return $Note{shift};
}

sub number_to_name {
    my $n = shift;
    die $n . ' is out of bounds. Notes are numbered 0 to 11.'
        if $n > 11;

    # Flip the Note hash into a HoL.
    my %name;
    while (my ($k, $v) = each %Note) {
        push @{ $name{$k} }, $v;
    }

    # Return the note name array reference.
    return $name{$n};
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Utility - Utility functions

=head1 ABSTRACT

=head1 DESCRIPTION

Utility functions

=head1 SYNOPSIS

=head1 EXPORTED FUNCTIONS

=head2 name_to_number()

=head2 number_to_name()

=head1 SEE ALSO

L<POE>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
