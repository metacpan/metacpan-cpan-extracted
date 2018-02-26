use strict;
use warnings;
use Test::More;

BEGIN{ use_ok('Pod::Term') };

my $test_pod = <<POD;

=pod

=head1 Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis sollicitudin integer molestie vel morbi velit integer interdum et convallis dui mauris nunc sapien libero sed sit elementum.

=head2 Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus gravida.

=over

=item text item 1

=item text item 2

=item text item 3

=back

=over

=item *

bullet item 1

=item *

bullet item 2

=item *

bullet item 3

=back

=head3 Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

=head4 Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis consectetuer at leo tortor convallis. Ante metus mattis id eu sapien suspendisse quo interdum.

=cut

POD


my $test_props = {
    indent => 5,
    after_indent => 3,
    top_spacing => 2,
    bottom_spacing => 3
};

my @test_els = (
    'head2',
    'Verbatim',
    'over-text',
    'item-bullet'
);


my $expected = {
head2 => {

    top_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.



Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    bottom_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title


Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    after_indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

   Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec 
   ut fermentum consectetuer sit tincidunt consectetur. Euismod montes 
   risus. Velit leo hendrerit quis nonummy ante justo libero risus 
   adipiscing tempus gravida.


   text item 1
   text item 2
   text item 3


   * bullet item 1
   * bullet item 2
   * bullet item 3

   Head3 title

   Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
   dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
   imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
   quis donec ut quis pede iure sociis lorem et purus ullamcorper.

    This is verbatim text

   Head4 title

   Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
   libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
   Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
   massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
   consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
   suspendisse quo interdum.

",
    indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

     Head2 Title

     Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue 
     nec ut fermentum consectetuer sit tincidunt consectetur. Euismod montes 
     risus. Velit leo hendrerit quis nonummy ante justo libero risus 
     adipiscing tempus gravida.


     text item 1
     text item 2
     text item 3


     * bullet item 1
     * bullet item 2
     * bullet item 3

     Head3 title

     Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque 
     nulla dictum aliquam nulla purus cursus eget. Elit sapien parturient. 
     Tortor imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula 
     id at dui quis donec ut quis pede iure sociis lorem et purus 
     ullamcorper.

      This is verbatim text

     Head4 title

     Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
     libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae 
     et. Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc 
     convallis massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. 
     Quis consectetuer at leo tortor convallis. Ante metus mattis id eu 
     sapien suspendisse quo interdum.

" },

Verbatim => {

    top_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.



 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    bottom_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text


Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    after_indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

      This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

"},

'over-text' => {

    top_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.



text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    bottom_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3




* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    after_indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


   text item 1
   text item 2
   text item 3


   * bullet item 1
   * bullet item 2
   * bullet item 3

   Head3 title

   Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
   dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
   imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
   quis donec ut quis pede iure sociis lorem et purus ullamcorper.

    This is verbatim text

   Head4 title

   Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
   libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
   Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
   massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
   consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
   suspendisse quo interdum.

",
    indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


     text item 1
     text item 2
     text item 3


     * bullet item 1
     * bullet item 2
     * bullet item 3

     Head3 title

     Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque 
     nulla dictum aliquam nulla purus cursus eget. Elit sapien parturient. 
     Tortor imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula 
     id at dui quis donec ut quis pede iure sociis lorem et purus 
     ullamcorper.

      This is verbatim text

     Head4 title

     Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
     libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae 
     et. Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc 
     convallis massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. 
     Quis consectetuer at leo tortor convallis. Ante metus mattis id eu 
     sapien suspendisse quo interdum.

"},

'item-bullet' => {

    top_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3




* bullet item 1


* bullet item 2


* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    bottom_spacing => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1


* bullet item 2


* bullet item 3



Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    after_indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


* bullet item 1
* bullet item 2
* bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

",
    indent => 

"Head1 Title

Etiam aenean cras laoreet integer sed. Scelerisque lacinia cursus arcu proin 
suspendisse. Accumsan nulla in mauris egestas mattis ultrices eu quis 
sollicitudin integer molestie vel morbi velit integer interdum et convallis 
dui mauris nunc sapien libero sed sit elementum.

Head2 Title

Feugiat etiam eu porta sed massa imperdiet convallis wisi class augue nec ut 
fermentum consectetuer sit tincidunt consectetur. Euismod montes risus. 
Velit leo hendrerit quis nonummy ante justo libero risus adipiscing tempus 
gravida.


text item 1
text item 2
text item 3


     * bullet item 1
     * bullet item 2
     * bullet item 3

Head3 title

Condimentum vivamus faucibus. Tellus felis sapien maecenas natoque nulla 
dictum aliquam nulla purus cursus eget. Elit sapien parturient. Tortor 
imperdiet sociis. Lorem tellus suspendisse. Porta sit et ligula id at dui 
quis donec ut quis pede iure sociis lorem et purus ullamcorper.

 This is verbatim text

Head4 title

Tristique eu a in arcu praesent. Dolor maecenas libero vivamus cursus 
libero. Integer parturient fusce. Mauris ut placerat. Ultrices vitae et. 
Suscipit sit dui. Volutpat nisl erat egestas ut posuere nunc convallis 
massa. Natoque vel diam. Mauris et auctor. Pede eu maecenas. Quis 
consectetuer at leo tortor convallis. Ante metus mattis id eu sapien 
suspendisse quo interdum.

"}};


foreach my $el_name ( @test_els ){

    foreach my $prop_name (keys %$test_props){

        my $parser = Pod::Term->new;
 
        $parser->globals({
            max_cols => 76,
            base_color => undef
        });

        $parser->prop_map({
                head1 => {
                display => 'block',
                stacking => 'revert',
                indent => 0,
                after_indent => 0,
                bottom_spacing => 2
            },

            head2 => {
                display => 'block',
                stacking => 'revert',
                indent => 0,
                after_indent => 0,
                bottom_spacing => 2
            },

            head3 => {
                display => 'block',
                stacking => 'revert',
                indent => 0,
                after_indent => 0,
                bottom_spacing => 2
            },

            head4 => {
                display => 'block',
                stacking => 'revert',
                indent => 0,
                after_indent => 0,
                bottom_spacing => 2
            },

            'over-text' => {
                display => 'block',
                stacking => 'spot',
                indent => 0,
                top_spacing => 1,
                bottom_spacing => 1
            },

            'over-number' => {
                display => 'block',
                stacking => 'nest',
                indent => 0,
                top_spacing => 1,
                bottom_spacing => 1
            },

            'over-bullet' => {
                display => 'block',
                stacking => 'nest',
                indent => 0,
                top_spacing => 1,
                bottom_spacing => 1
            },

            'item-text' => {
                display => 'block',
                stacking => 'nest',
                indent => 0,
                after_indent => 0,
                bottom_spacing => 1
            },

            'item-number' => {
                display => 'block',
                stacking => 'nest',
                prepend => { 
                    text => '@number. ',
                },
                bottom_spacing => 1
            },

            'item-bullet' => {
                display => 'block',
                stacking => 'nest',
                prepend => {
                    text => '* '
                },
                bottom_spacing => 1
            },

            'B' => {
                display => 'inline',
            },

            'C' => {
                display => 'inline',
            },

            'I' => {
                display => 'inline',
            },

            'L' => {
                display => 'inline',
            },

            'E' => {
                display => 'inline'
            },

            'F' => {
                display => 'inline',
            },

            'S' => {
                display => 'inline',
                wrap => 'verbatim'
            },

            'Para' => {
                display => 'block',
                stacking => 'nest',
                bottom_spacing => 2,
            },

            'Verbatim' => {
                display => 'block',
                stacking => 'nest',
                bottom_spacing => 2,
                wrap => 'verbatim'
            },

            'Document' => {
                display => 'block',
                stacking => 'nest',
                indent => 0
            }
        });

        $parser->set_prop($el_name,$prop_name, $test_props->{$prop_name});

        my $got;
#        $parser->output_string( \$got );

        {
            local *STDOUT;
            open STDOUT, '>', \$got;
            $parser->parse_string_document( $test_pod );
            close STDOUT;
        }

        is_deeply( $got, $expected->{$el_name}{$prop_name}, 
            "pod formats correctly with $prop_name adjusted for $el_name" );

    }
}


done_testing();


print "*** DONE ***\n";





