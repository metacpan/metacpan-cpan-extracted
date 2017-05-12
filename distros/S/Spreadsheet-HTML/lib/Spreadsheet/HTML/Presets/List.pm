package Spreadsheet::HTML::Presets::List;
use strict;
use warnings FATAL => 'all';

sub list {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my $list = [];
    if (exists $args->{row}) {
        $args->{row} = 0 unless $args->{row} =~ /^\d+$/;
        $list = @$data[$args->{row}];
    } else {
        $args->{col} = 0 unless $args->{col} && $args->{col} =~ /^\d+$/;
        $list = [ map { $data->[$_][$args->{col}] } 0 .. $#$data ];
    }

    shift @$list if $args->{headless};

    $HTML::AutoTag::ENCODE  = defined $args->{encode}  ? $args->{encode}  : exists $args->{encodes};
    $HTML::AutoTag::ENCODES = defined $args->{encodes} ? $args->{encodes} : '';
    return $args->{_auto}->tag(
        tag   => $args->{ordered} ? 'ol' : 'ul', 
        attr  => $args->{ol} || $args->{ul},
        cdata => [
            map {
                my ( $cdata, $attr ) = Spreadsheet::HTML::_extrapolate( $_, undef, $args->{li} );
                { tag => 'li', attr => $attr, cdata => $cdata }
            } @$list
        ]
    );
}

sub select {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my $cdata  = [];
    my $values = [];
    if (exists $args->{row}) {
        $args->{row} = 0 unless $args->{row} =~ /^\d+$/;
        $cdata  = @$data[$args->{row}];
        $values = @$data[$args->{row} + 1];
    } else {
        $args->{col} = 0 unless $args->{col} && $args->{col} =~ /^\d+$/;
        $cdata  = [ map { $data->[$_][$args->{col}] } 0 .. $#$data ];
        $values = [ map { $data->[$_][$args->{col} + 1 ] } 0 .. $#$data ];
    }

    my $selected = [];
    if ($args->{selected}) {
        $args->{selected} = [ $args->{selected} ] unless ref $args->{selected};
        for my $text (@$cdata) {
            if (grep $_ eq $text, @{ $args->{selected} }) {
                push @$selected, 'selected';
            } else {
                push @$selected, undef;
            }
        }
    }

    my $attr = { value => [] };
    $attr->{value}    = $cdata   if $args->{values};
    $attr->{selected} = $selected if map defined $_ ? $_ : (), @$selected;

    my $options = [
        map { 
            my ( $cdata, $opt_attr ) = Spreadsheet::HTML::_extrapolate( $_, $attr, $args->{option} );
            { tag => 'option', attr => $opt_attr, cdata => $cdata };
        } $args->{values} ? @$values : @$cdata
    ];

    if (ref( $args->{optgroup} ) eq 'ARRAY' and @{ $args->{optgroup} }) {
        my @groups = @{ $args->{optgroup} };
        my @ranges = Spreadsheet::HTML::_range( 0, $#$options, $#groups );
        splice( @$options, $_, 0, { tag => 'optgroup', attr => { label => pop @groups } } ) for reverse @ranges;
    }

    if ($args->{headless}) {
        shift @$options;
        shift @{ $attr->{value} };
    }

    $HTML::AutoTag::ENCODE  = defined $args->{encode}  ? $args->{encode}  : exists $args->{encodes};
    $HTML::AutoTag::ENCODES = defined $args->{encodes} ? $args->{encodes} : '';

    my $label = '';
    if ($args->{label}) {
        $label = $args->{_auto}->tag( %{ Spreadsheet::HTML::_tag( %$args, tag => 'label' ) } );
    }

    return $label . $args->{_auto}->tag(
        tag   => 'select', 
        attr  => $args->{select},
        cdata => [
            ( $args->{placeholder} 
                ? { tag => 'option', attr => { value => '' }, cdata => $args->{placeholder} } 
                : ()
            ), @$options
        ],
    );
}

=head1 NAME

Spreadsheet::HTML::Presets::List - Generate <select>, <ol> and <ul> lists.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new( data => \@data );
  print $generator->list( ordered => 1 );
  print $generator->select( values => 1, placeholder => 'Pick one' );

  # or
  use Spreadsheet::HTML qw( list );
  print list( data => \@data, col => 2 );
  print Spreadsheet::HTML::select( data => \@data, row => 0 );

Note that C<select()> is not exportable, due to the existance of Perl's
built-in C<select()> function.

=head1 METHODS

=over 4

=item * C<list( ordered, col, row, %params )>

Renders ordered <ol> and unordered <ul> lists.

=back

=head2 LITERAL PARAMETERS

=over 8

=item * C<headless>

Boolean. Discard first element. Useful for datasets that include headings.

  headless => 1

=item * C<ordered>

Boolean. Uses <ol> instead of <ul> container when true.

  ordered => 1

=item * C<col>

Integer. Start at this column. If neither C<col> nor C<row> is specified,
then the first column (0) is used.

  col => 2

=item * C<row>

Integer. Start at this row. If neither C<row> nor C<col> is specified,
then the first column (0) is used (not the first row).

  row => 0

=back

=head2 TAG PARAMETERS

=over 8

=item * C<ol>

Hash reference of attributes.

  ol => { class => 'list' }

=item * C<ul>

Hash reference of attributes.

  ul => { class => 'list' }

=item * C<li>

Accepts hash reference, sub reference, or array ref containing either or both.

  li => { class => [qw( odd even )] }
  li => sub { ucfirst shift }
  li => [ { class => 'item' }, sub { sprintf '%2d', shift } ]

=back

=over 4

=item * C<select( col, row, values, selected, placeholder, optgroup, label, %params )>

Renders <select> lists.

=back

=head2 LITERAL PARAMETERS

=over 8

=item * C<headless>

Discard first element. Useful for datasets that include headings.

  headless => 1

=item * C<col>

Integer. Start at this column. If neither C<col> nor C<row> is specified,
then the first column (0) is used.

  col => 2

=item * C<row>

Integer. Start at this row. If neither C<row> nor C<col> is specified,
then the first column (0) is used (not the first row).

  row => 0

=item * C<values>

Optional boolean. Default false. The selected C<row> or C<col> will be
used as the <option> tags' CDATA value.

  values => 0

When set to true the selected C<col> or C<row> will be used as the <option>
tags' 'value' attribute and the NEXT C<col> or C<row> (respectively) will
be used as the <option> tags' CDATA value.

  values => 1

=item * C<selected>

Optional scalar or array ref of default <option> CDATA values (if C<values> is false>)
or <option> 'value' attributes (if C<values> is true) to be initially selected.

  selected => 'id1'
  selected => [qw( id1 id4 )]

=item * C<placeholder>

Optional string. Inserts the C<placeholder> as the first <option> in the <select> list.
This <option> will always have a value attribute set to empty string regardless of the
value of C<values>.

  placeholder => 'Please select an option'

=item * C<label>

Emits <label> tag for list. Either a scalar string or a special hash ref whose
only key is the CDATA for the <label> and the only value is the attributes as a hash ref.

  label => 'Label with no attributes'
  label => { 'Label with attributes' => { class => 'label' } }

=item * C<optgroup>

Optional array ref of scalars.

  optgroup => [ 'Group 1:', 'Group 2:', 'Group 3:' ]

=back

=head2 TAG PARAMETERS

=over 8

=item * C<select>

Hash reference of attributes.

  select => { class => 'select' }

=item * C<option>

Accepts hash reference, sub reference, or array ref containing either or both.

  option => { class => [qw( odd even )] }
  option => sub { uc shift }
  option => [ sub { uc shift }, { class => [qw( odd even )] } ]

=back

=head1 SEE ALSO

=over 4

=item L<Spreadsheet::HTML>

The interface for this functionality.

=item L<Spreadsheet::HTML::Presets>

More presets.

=item L<http://www.w3.org/TR/html5/forms.html>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
