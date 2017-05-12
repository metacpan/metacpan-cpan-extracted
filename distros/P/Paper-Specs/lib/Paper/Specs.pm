
package Paper::Specs;
use strict;
use vars qw($VERSION %brands $brand $units $layout %units $strict $debug);

$VERSION='0.10';

$units  = 'in';
$layout = 'normal';
$brand  = '';
$strict = 1;
$debug  = 0;

=head1 NAME

Paper::Specs - Size and layout information for paper stock, forms, and labels.

=head1 SYNOPSIS

 use Paper::Specs units => 'cm';
 my $form = Paper::Specs->find( brand => 'Avery', code => '1234');

 use Paper::Specs units => 'cm', brand => 'Avery';
 my $form = Paper::Specs->find( code => '1234');

 # location of first label on sheet
 my ($xpos, $ypos) = $form->label_location( 1, 1);
 my ($h, $w)       = $form->label_size;

=head1 IMPORTANT NOTES

I appologise in advance for the hasty nature of this code. I want to
get it out to support some other code I am writing. I promise to revisit
it shortly to clear up the rough patches - however your valuable input
is most welcome.

CAVEAT ALPHA CODE - This is a preliminary module and will be subject to 
fluctuations in API and structure based on feedback from users. 

I expect that there will be some interest in this code and it should
firm up quickly.

If this module does not deliver what you are looking for then you
are encouraged to contact the author and voice your needs!

OTHER LABELS - I know about the Labels.xml file which is part of OpenOffice
but have not figured out how it is encoded. I have the gLabels specifications
file too. I plan to use these to help populate the data for this module.

=head1 Paper::Specs methods

=over

=item Import options

You can supply any of the methods for this class when it is imported:

 use Paper::Specs
    strict => 1,
    units  => 'cm';

=cut

sub import {

    my $class=shift;

    while ( @_ ) {
        my ($arg, $val) = (shift, shift);
        $class->$arg($val) if UNIVERSAL::can( $class, $arg);
    }

}

=item @forms = Paper::Specs->find( criteria )

Returns a list of forms that matches the criteria. There are
two fields for criteria: brand and code. The brand can be set
for the class via the Paper::Specs->brand method.

You must supply at least a brand or a code to find. If no
brand is supplied then all known brands will be searched.

If you set the module to strict, its default, the find must
return extactly zero or one forms as a scalar. Otherwise
it will throw an exception.

See the beginning of this module for examples of finds.

=cut

sub find {

    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;


    my %opts = @_;
    my $brand = $opts{'brand'} || $brand;
    my $code  = $opts{'code'}; 

    die "We need a code or a brand to search for\n" unless $code || $brand;

    my @found=();
    foreach my $brand ( ($brand || $self->brands) ) {

        my $sclass = "${class}::${brand}";
        eval "use $sclass";
        # skip ones that do not load - lame but effective for now
        if ($Paper::Specs::debug) {
          warn $@ if $@;
        }
        next if $@;

        push @found, $sclass->find( $code );

    }

    if ($self->strict) {

        if (@found && scalar(@found) == 1) {
            return $found[0];
        }

        if (@found) {
            die 'More than one form matches and $self is in strict mode\n';
        } 

        return ();

    } else {
        return wantarray ? @found : \@found;
    }

}

# Nice to snoop the lib for all installed Paper modules
# next iteration of code, this is good enough for now
%brands=(
    'standard'      => 1,
    #'APLI'          => 1,
    #'Agipa'         => 1,
    #'Alpi'          => 1,
    #'Ascom'         => 1,
    'Avery'         => 1,
    #'DataBecker'    => 1,
    #'Ednet'         => 1,
    #'Epson'         => 1,
    #'Great Gizmos'  => 1,
    #'Herlitz'       => 1,
    #'Herma'         => 1,
    #'Imation-SoniX' => 1,
    #'LeLabel'       => 1,
    #'Leitz'         => 1,
    #'Memorex'       => 1,
    #'Meritline'     => 1,
    #'Neato'         => 1,
    #'Sigel'         => 1,
    #'Southworth'    => 1,
    #'Stomper'       => 1,
    #'Zweckform'     => 1,
    #'unknown'       => 1,
    'photo'         => 1,
);

=item @brands = Paper::Specs->brands

Returns a list or reference to a list of the brands for the paper forms that
this module is aware of. One brand, 'standard' is reserved for well known paper
formats such as letter, A4, etc.

=cut

sub brands {

    return wantarray ? ( keys %brands ) : [ keys %brands ];

}

=item $new_value = Paper::Specs->convert( value, units )

Converts 'value' which is in 'units' to new value which is in Paper::Specs->units units.

=cut

sub convert {

    my $value = shift;
    my $src_units = shift || 'in';

    return $value / $units{$src_units} * $units{$units};

}

%units = (
    'in' => 1,
    'cm' => 2.54,
    'mm' => 25.4,
    'pt' => 72,
);

=item $units = Paper::Specs->units( units )

Gets/sets the units that you wish to work with in your code. If you are
using metric then you might want 'mm' or 'cm'. If you are using empirial
then you might want 'in' or 'pt' (points = 1/72 in).

Current units supported are: in, cm, mm, and pt.

=cut

sub units {

    my $self=shift;

    if (@_) {
        $units = shift if exists $units{$_[0]};
    }

    return $units;

}

=item Paper::Specs->layout( 'normal' | 'pdf' )

This sets the co-ordinate system for some forms such as labels. 'normal' puts
(0,0) at the top left corner. 'pdf' puts (0,0) at the lower left corner.

As well 'pdf' calls units('pt'). You can reset this afterwards if you are working
in a different unit system.

=cut


sub layout {

    my $self=shift;

    if (@_) {
        $layout = lc shift;
        $layout = 'normal' unless $layout eq 'normal' || $layout eq 'pdf';
        if ( $layout eq 'pdf' ) {
            $self->units('pt');
        }
    }

    return $layout;

}

=item Paper::Specs->strict( 0 | 1 )

Sets the strictness of this module. If it is strict then it will throw exceptions via 'die' for things
like finding more than one form on a find method.

The default is to be strict.

=cut

sub strict {

    my $self=shift;
    if (@_) {
        $strict = $_[0] ? 1 : 0;
    }
    return $strict;

}

=back

=head1 Paper::Specs items

You get little object references back when you find specifications. These
objects can supply you with information that you are looking for but do not
actually store any values.

You should test that the object is of the type you are looking for

 if ($form->type ne 'label') {
    die "Feed me labels Seymore\n";
 }

Other than that - most forms should be based on a sheet (of paper) but will have
different methods depending on what they are.

=head1 Paper::Specs::sheet methods / $form->type eq 'sheet'

These methods apply forms of type 'sheet' and all that are derived from it. (all other forms and stock)

=over 4

=item ($h, $w) = $form->sheet_size

Returns the height and width of your sheet.

=item $size = $form->sheet_width

Width of the stock

=item $size = $form->sheet_height

Height of the stock

=back

=head1 Paper::Specs::label methods / $form->type eq 'label'

These methods apply to forms of type 'label' and all that are derived from it. 

Inherits methods from Paper::Specs::sheet.

=over 4

=item ( $width, $height ) = $form->label_size

Returns just that; a list with the width and height of a label in it

=item ( $x, $y ) = $form->label_location( $r, $c )

Returns the location of the upper left corner for label at row $r and col $c 
based on your current format/co-ordinate system.

=item $size = $form->margin_left

Space between left edge of paper and first column of labels.

=item $size = $form->margin_right

Space between right edge of paper and last column of labels.

=item $size = $form->margin_top

Space between top edge of paper and first row of labels.

=item $size = $form->margin_bottom

Space between bottom edge of paper and last row of labels.

=item $size = $form->label_height

Height of one label

=item $size = $form->label_width

Width of one label

=item $count = label_rows

Number of rows of labels on a sheet

=item $count = label_cols

Number of columns of labels on a sheet

=item $size = $form->gutter_cols

Inner space between labels - column gutter.

=item $size = $form->gutter_rows

Inner space between labels - row gutter.

=back

=head1 SEE ALSO

Paper::Specs homepage - L<http://perl.jonallen.info/projects/paper-specs>

=head1 BUGS

Please report your bugs and suggestions for improvement to <jj@jonallen.info>.

=head1 AUTHORS

Originally written by Jay Lawrence <jlawrenc@cpan.org>

From version 0.06 onwards this module is maintained by Jon Allen (JJ) <jj@jonallen.info> / L<http://perl.jonallen.info>

=head1 COPYRIGHT and LICENCE

Copyright (c)2001-2003 - Jay Lawrence, Infonium Inc. All rights reserved.

Modifications from version 0.06 onwards Copyright (c) 2004-2005 Jon Allen (JJ).

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Software distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. This software 
is not affiliated with the Apache Software Foundation (ASF).

=cut

1;
