package String::Mutate;
use strict;
use Class::Prototyped;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


#################### subroutine ####################
# Make our array of junk-like characters

our @JUNK;
sub mkjunk {

  for (my $i = 33; $i <= 47; $i++) {
    push @JUNK, chr($i);
  }
  

}

#################### constructor ####################

sub proto {

  mkjunk;

  my $p = Class::Prototyped->new
    (
     string => 'Hello, World'
    );

  my $p2 = Class::Prototyped->new
    (
     'parent*' => $p
    );

  my $mir = $p2->reflect;
  $mir->addSlots
    (
     m_append  => \&append,
     m_prepend => \&prepend,
     m_insert  => \&insert,
    );

  $mir->addSlot
    (
     m_rand_insert => sub { 
       my ($self, $insert_text) = @_;
       $self->m_insert($insert_text);
     }
    );

  $mir->addSlot
    (
     m_chunk_of_junk => \&chunk_of_junk
     );

  return $p2;

}


#################### methods ####################
# We install these in the constructor, but write
# them out here because the bodies are too long
# to fit into the constructor

sub append {

    my ($self, $text) = @_;

    $self->string($self->string . $text);
$self;
}

sub prepend {

    my ($self, $text) = @_;

    $self->string($text . $self->string);
$self;
}

sub insert {

    my ($self, $text, $position) = @_;

    if (not defined $position or $position < 1) {
      my $lth = length $self->string;
      #warn "string length; $lth";
      $position = 1 + int(rand( $lth - 1 ));
      #warn "rand_position: $position";
    }

    my $pre  = substr($self->string, 0, $position);
    my $post = substr($self->string, $position);
    my $out  = "$pre$text$post";
    $self->string($out);
$self;
}

sub chunk_of_junk {
  my ($self, $chunk_length) = @_;

  defined $chunk_length or die 'must supply chunk length' ;

  my $chunk;

  for (1 .. $chunk_length) {
    $chunk = $chunk . $JUNK[ rand @JUNK   ] ;
  }

  #warn "CHUNK: $chunk JUNK: @JUNK";


  $self->m_rand_insert($chunk);
$self;
}

#################### main pod documentation begin ###################

=head1 NAME

String::Mutate - extensible chaining of string modifiers

=head1 SYNOPSIS

  use String::Mutate;
  
  # Create base object with a string slot and some useful
  # string modifiers.
  my $proto = String::Mutate->proto;

  $proto->string # "Hello, World"

  # Hello, World. It's me Bob
  $proto->m_append(". It's me Bob");

  # Biff!Hello, World. It's me Bob
  $proto->m_prepend("Biff!");

  # Biff!--Hello, World. It's me Bob
  $proto->m_insert("--", 4);

  # Insert yuy at some_random_place into the string
  $proto->m_rand_insert("yuy");

  # Insert $number junk chars at some_random_place into the string
  $proto->string('reset to clean string');
  my $number=4;
  $proto->m_chunk_of_junk($number); # res()`*et to clean string


=head1 DESCRIPTION

There comes a time in every data munger's career when he needs to muck up the 
data. This module is designed to make it easy to code up your own 
special wecial, tasty-wasty string mucker-uppers. It comes with the 
mucker-uppers you saw in the SYNOPSIS. But you are dealing with a
L<Class::Prototyped|Class::Prototyped> object, so you can extend the 
beskimmers out of it if you so please.

And now.... method chaining!

=head1 USAGE

Well, the SYNOPSIS told all. But let's say what we just said again.

First you construct your prototype object:

 my $proto = String::Mutate->proto;

Then you call any of the C<m_*> methods which will then mutate
C<< $proto->string >> and leave the results in same. So without further adieu,
here are the pre-packaged string mutators

=head2 BUILT-IN STRING MUTATION METHODS 


=head2 m_append

 Usage     : $proto->m_append('some text to append');
 Purpose   : Append text to $proto->string
 Argument  : the text to append.

=cut

=head2 m_prepend

 Usage     : $proto->m_prepend('some text to PREpend');
 Purpose   : Prepend text to $proto->string
 Argument  : the text to Prepend.

=head2 m_insert

 Usage     : $proto->m_insert('insertiontext', $after_what_char);
 Purpose   : put insertion text into string after a certain char
 Returns   : nothing. this is OOP you know.
 Argument  : 
  1 - the text to insert
  2 - the 1-offset position to insert at


=head2 m_rand_insert

 Usage     : $proto->m_rand_insert('text');
 Purpose   : put insertion text into string at some random place
 Returns   : nothing. this is OOP you know.
 Argument  : 
  1-  the text to insert at some random place in the string. When is someone
      going to write something to automatically generate this assinine
      butt-obvious documentation from my fresh, crispy clean with no 
      caffeine source code?! sounds like a good master's project for some
      AI weenie.

=head2 m_chunk_of_junk

 Usage     : $proto->m_chunk_of_junk($chunk_size)
 Purpose   : put a string of junk chars of length $chunk_size into 
             string at some random place
 Returns   : nothing. this is OOP you know.
 Argument  : How long you want the chunk of junk to be. Actually it isnt
             how long you *want* it to be. It is how long it will be whether
             you want it that way or not. Computers are like that. Stubborn
             lil suckers. Fast, useful, but not so obliging.

=cut


=head1 BUGS

There are rougly 3,562,803 bugs in this code. 


=head1 AUTHOR

    Terrence M. Brannon
    CPAN ID: TBONE
    metaperl.org computation
    tbone@cpan.org
    http://www.metaperl.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO



=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

