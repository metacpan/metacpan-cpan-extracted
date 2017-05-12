package Parse::RecDescent::Consumer;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Parse::RecDescent::Consumer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(&Consumer
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(&Consumer
	
);

our $VERSION = sprintf '%2d.%02d', q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;


# Preloaded methods go here.
 sub Parse::RecDescent::Consumer {
  my $text=shift;
  my $closure = sub { 
    my $new_length=length($_[0]); 
    my $original_text = $text; 
    my $original_length = length($text); 
    return substr($original_text, 0, ($original_length-$new_length));
  }
 }

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Parse::RecDescent::Consumer - reveal text matched through n token transitions.

=head1 SYNOPSIS

  use Parse::RecDescent::Consumer;

# then in a Parse::RecDescent grammar...

url: <rulevar: $C>
url: { $C = Consumer($text) } httpurl { REBOL::url->new(value => $C->($text)) }
   | { $C = Consumer($text) } ftpurl  { REBOL::url->new(value => $C->($text)) }


=head1 DESCRIPTION

A common need when writing grammars is to know how much text was
consumed at different points in a parse. Usually, this involves a lot
of brain-twisting unwinding of of highly nested list-of-lists (of
lists...). Instead this module allows you to take the low-road
approach. You simply create a C<Consumer> which records the current
text about to be parsed. 

After you have successfully transitioned through the desired tokens,
you simply re-call your C<Consumer> and it gives you the text that was
consumed during the token transitions without you having to unravel a
highly nested list-of-lists (of lists...).

=head1 IMPLEMENTATION

when you first call Consumer(), you are returned a closure which has
the current text remaining to be parsed in it. When you evaluate the
closure, passing it the (more or less consumed) new text, the closure
calculates the difference in length between the two texts, and returns
a substring of the first equating to the amount of text consumed
between calls:

 sub Parse::RecDescent::Consumer {
  my $text=shift;
  my $closure = sub { 
    my $new_length=length($_[0]); 
    my $original_text = $text; 
    my $original_length = length($text); 
    return substr($original_text, 0, ($original_length-$new_length));
  }
 }


=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
