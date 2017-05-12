package String::Clean;
BEGIN {
  $String::Clean::VERSION = '0.031';
}

use warnings;
use strict;
use Carp::Assert::More;

# ABSTRACT: use data objects to clean strings

=head1 SYNOPSIS

The goal of this module is to assist in the drudgery of string cleaning by 
allowing data objects to define what and how to clean. 

=head2 EXAMPLES

   use String::Clean;

   my $clean = String::Clean->new();

   $clean->replace( { this => 'that', is => 'was' } , 'this is a test' ); 
      # returns 'that was a test'
   
   # see the tests for more examples 

=head1 THE OPTIONS HASH

Each function can take an optonal hash that will change it's behaviour. This 
hash can be passed to new and will change the defaults, or you can pass to each
call as needed. 

   opt: 
         Any regex options that you want to pass, ie {opt => 'i'} will allow 
         for case insensitive manipulation.
   replace : 
         If the value is set to 'word' then the replace function will look for 
         words instead of just a collection of charicters. 
         example: 

            replace( { is => 'was' },
                     'this is a test',
                   ); 

            returns 'thwas was a test', where 

            replace( { is => 'was' },
                     'this is a test',
                     { replace => 'word' },
                   ); 

            will return 'this was a test' 

   strip :
         Just like replace, if the value is set to 'word' then strip will look
         for words instead of just a collection of charicters. 

   word_ boundary :
         Hook to change what String::Clean will use as the word boundry, by 
         default it will use '\b'. Mainly this would allow String::Clean to 
         deal with strings like 'this,is,a,test'.

   escape :
         If this is set to 'no' then String::Clean will not try to escape any 
         of the things that you've asked it to look for.  

You can also override options at the function level again, but this happens as
merged hash, for example:

   my $clean = String::Clean->new({replace => 'word', opt => 'i'});
   $clean->strip( [qw{a}], 'an Array', {replace =>'non-word'} );
   #returns 'n rray' because opt => 'i' was pulled in from the options at new.
 

=head1 CORE FUNCTIONS

=head2 new

The only thing exciting here is that you can pass the same options hash at 
construction, and this will cascade down to each function call. 

=cut

#---------------------------------------------------------------------------
#  NEW
#---------------------------------------------------------------------------
sub new {
   my ( $class, $opt ) = @_;
   my $self = {};
   if ( ref($opt) eq 'HASH' ) {
      $self->{opt} = $opt;
      $self->{yaml}= {};
   }
   return bless $self, $class;
}

#---------------------------------------------------------------------------
#  REPLACE
#---------------------------------------------------------------------------

=head2 replace

Takes a hash where the key is what to look for and the value is what to replace
the key with.

   replace( $hash, $string, $opts );

=cut

sub replace {
   my ( $self, $hash, $string , $opt) = @_;
   assert_hashref($hash);
   assert_defined($string);
   $opt = $self->_check_for_opt($opt);
   my $o = _build_opt( $opt->{opt} );
   my $b = _boundary( $opt->{word_boundary} );

   foreach my $key ( keys(%$hash) ) {
      my $qmkey = quotemeta($key) unless ( defined($opt->{escape}) && $opt->{escape} =~ m/^no$/ );
      next unless defined $qmkey;
   
      if ( defined($opt->{replace}) 
           && $opt->{replace} =~ m/^word$/i 
      ) {
         $string =~ s/(^|$b)$qmkey($b|$)/$1$hash->{$key}$2/g;
      }
      else {
         $string =~ s/(?$o)$qmkey/$hash->{$key}/g;
      }
   }
   return $string;
}

=head2 replace_word

A shortcut that does the same thing as passing {replace => 'word'} to replace.

   replace_word( $hash, $string, $opts ); 

=cut

sub replace_word {
   my ( $self, $hash, $string , $opt) = @_;
   $opt->{replace} = 'word';
   return $self->replace($hash, $string, $opt);
}


#---------------------------------------------------------------------------
#  STRIP
#---------------------------------------------------------------------------

=head2 strip

Takes an arrayref of items to completely remove from the string.

   strip( $list, $sring, $opt);

=cut

sub strip {
   my ( $self, $list, $string , $opt) = @_;
   assert_listref($list);
   assert_defined($string);
   $opt = $self->_check_for_opt($opt);
   my $o = _build_opt($opt->{opt});
   my $b = _boundary( $opt->{word_boundary} );
   $list = [map{ quotemeta } @$list ] unless ( defined($opt->{escape}) && $opt->{escape} =~ m/^no$/ );
   my $s = ( defined($opt->{strip}) 
             && $opt->{strip} =~ m/^word$/i
           ) 
         ? join '|', map{ $b.$_.$b } @$list
         : join '|', @$list
         ;
   $string =~ s/(?$o)(?:$s)//g;
   return $string;
}

=head2 strip_word

A shortcut that does the same thing as passing {strip => 'word'} to strip.

   strip_word( $list, $string, $opt);

=cut

sub strip_word {
   my ( $self, $list, $string , $opt) = @_;
   $opt->{strip} = 'word';
   return $self->strip($list, $string, $opt);
}


#---------------------------------------------------------------------------
#  CLEAN BY YAML
#---------------------------------------------------------------------------

=head1 WRAPPING THINGS UP AND USING YAML

=head2 clean_by_yaml

Because we have to basic functions that take two seperate data types... why 
not wrap those up, enter YAML. 

   clean_by_yaml( $yaml, $string, $opt );

But how do we do that? Heres an example:

=head3 OLD CODE

   $string = 'this is still just a example for the YAML stuff';
   $string =~ s/this/that/;
   $string =~ s/is/was/;
   $string =~ s/\ba\b/an/;
   $string =~ s/still//;
   $string =~ s/for/to explain/;
   $string =~ s/\s\s/ /g;
   # 'that was just an example to explain the YAML stuff'

=head3 NEW CODE

   $string = 'this is still just a example for the YAML stuff';
   $yaml = q{
   ---
   this : that
   is   : was
   a    : an
   ---
   - still
   ---
   for : to explain
   '  ': ' '
   };
   $string = $clean->clean_by_yaml( $yaml, $string, { replace => 'word' } );
   # 'that was just an example to explain the YAML stuff'

=head3 ISSUES TO WATCH FOR:

=over

=item * Order matters:

As you can see in the example we have 3 seperate YAML docs, this allows for
replaces to be doene in a specific sequence, if that is needed. Here in this
example is would not have mattered that much, here's a better example:

   #swap all instances of 'ctrl' and 'alt' 
   $yaml = q{
   ---
   ctrl : __was_ctrl__
   ---
   alt  : ctrl
   ---
   __was_ctrl__ : alt
   };

=item * Options are global to the YAML doc :
   
If you need to have seperate options applied to seperate sets then they
will have to happen as seprate calls.

=back 

=cut

sub clean_by_yaml {
   use YAML::Any;
   my ( $self, $yaml, $string, $opt) = @_;
   assert_defined($yaml);
   assert_defined($string);
   #$opt = $self->_check_for_opt($opt);
   $self->{yaml}->{$yaml} = [Load($yaml)]
      unless defined $self->{yaml}->{$yaml};
   $opt = $self->_check_for_opt($opt);
   foreach my $doc (@{ $self->{yaml}->{$yaml} }) {
      if ( ref($doc) eq 'ARRAY' ) {
         $string = $self->strip( $doc, $string, $opt);
      }
      elsif ( ref($doc) eq 'HASH' ) {
         $string = $self->replace( $doc, $string , $opt);
      }
      else {
         warn '!!! FAILURE !!! unknown type of data struct for $data. Skipping and moveing on.';
      }

   }
   return $string;
}

#---------------------------------------------------------------------------
#  Helper function that do not get exported and should only be run localy
#---------------------------------------------------------------------------

sub _build_opt {
   my ($opt) = @_;
   return ( defined( $opt ) ) ? $opt : '-i';
}

sub _check_for_opt {
   my ($self, $opt) = @_;
   if (! defined($opt) 
       && defined($self->{opt})
   ) {
      return $self->{opt};
   }
   elsif ( defined($opt) 
       && defined($self->{opt})
   ) {
      return { %{$self->{opt}}, %$opt };
   }
   else {
      return $opt;
   }
}


sub _boundary {
   my ( $b ) = @_;
   return ( defined($b) ) ? $b : '\b';
}


=head1 AUTHOR

ben hengst, C<< <notbenh at CPAN.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-clean at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Clean>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Clean


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Clean>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Clean>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Clean>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Clean>

=back


=head1 ACKNOWLEDGEMENTS
Lindsey Kuper and Jeff Griffin for giving me a reason to cook up this scheme.


=head1 COPYRIGHT & LICENSE

Copyright 2007 ben hengst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of String::Clean
