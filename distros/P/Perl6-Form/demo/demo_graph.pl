use Perl6::Form;

@vert_label = qw(Villain's fortunes);
$hor_label  = "Time";
@data = <DATA>;

print form
   {single=>'='},
   '     ^                                        ',
   ' = = | {""""""""""""""""""""""""""""""""""""} ', @vert_label, \@data,
   '     +--------------------------------------->',
   '      {|||||||||||||||||||||||||||||||||||||} ', $hor_label;

__DATA__

      *
    *   *
   *     *

  *       *

 *         *



*           *
