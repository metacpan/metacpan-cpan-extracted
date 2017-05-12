package Regex::Iterator;

use strict;
use vars qw($VERSION);

$VERSION = "0.4";


=pod

=head1 NAME

Regex::Iterator - provides an iterator interface to regexps

=head1 SYNOPSIS

	my $string = 'string to search';
	my $re     = qr/[aeiou]/i; 
	# a plain string of 'aeiou' would work as well

	

	my $it = Regex::Iterator->new($regex, $string);

	while (my $match = $it->match) {
		$it->replace('o');
	}
	print $it->result,"\n"; # 'strong to soorch'
	print $it->string,"\n"; # 'string to search'


=head1 DESCRIPTION

Inspired by Mark Jason Dominus' talk I<Programming with Iterators and Generators> 
(available from http://perl.plover.com/yak/iterators/) this is an iterative regex 
matcher based on the work I did for B<URI::Find::Iterator>


=head1 METHODS

=head2 new <regex> <string> 
    
Fairly self explanatory - takes a regex and a string to match it against.

C<regex> can be the result of a C<qr{}>

=cut


sub new {
    my ($class, $re, $string) = @_;

    my $self          = bless {}, $class;
	
	$self->string($string);
	$self->re($re);


    return bless $self, $class;

}


=head2 string [ string ]

Gets the current string we're matching against.

If a new string is optionally passed in then it will be set 
as the string for the iterator to match on and the iterator 
will be reset.

Setting returns the object itself to allow chaining.

=cut

sub string {
	my $self = shift;

	return $self->{_orig} unless @_;

	$self->{_orig} = $_[0];
	$self->rewind;

	return $self;
}



=head2 re [ regex ]

Gets the current regex we're matching with.

If a new regex is optionally passed in then it will be set 
as the regex for the iterator to match with. Does not 
reset the iterator so you can change patterns halfway through 
an iteration if necessary. The regex will be automatically 
compiled using C<qr//> for speed.

Setting returns the object itself to allow chaining.

=cut

sub re {
	my $self = shift;

	return $self->{_re} unless @_;
	
	my $re  = $_[0];  
	$re = qr/$re/ unless ref($re) eq 'Regexp';


	$self->{_re} = $re;

	return $self;
}

=head2 match

Returns the current match as a string.

It then advances to the next one.

=cut 


sub match {
        my $self = shift;
        return undef unless defined $self->{_remain};



        local $1;
        "null" =~ m!()!; # set $1 to ""
        $self->_next();

        my $re = $self->{_re};

        $self->{_remain}   =~ /(.*?)($re)(.*)/s;


        return unless defined $2 and $2 ne "";

		
        my $match = $2;
        my $pre  = $1; $pre  = '' unless defined $pre;
		my $post = $+; $post = '' unless defined $post;

        $self->{_result}  .= $pre;
        $self->{_remain}   = $post; 
        $self->{_match}    = $match;

        return $match;
}



=head2 replace <replacement>

Replaces the current match with I<replacement>

=cut

sub replace {
        my ($self, $replace) = @_;
        return 0 unless defined $self->{_match};
        $self->{_match} = $replace;
		return 1;
}


=head2 rewind

Rewinds the object's state to the original string (as supplied by set_string),
this allows matching to begin from the beginning again

=cut

sub rewind {
  my $self = shift;

  $self->{_remain} = $self->string;
  $self->{$_}      = '' for qw( _match _result );

  return $self;
}





=head2 result

Returns the string with all replacements.

=cut 

sub result {
    my $self = shift;

	return join '', grep { defined } @$self{qw/ _result _match _remain /};
}


# internal iterator method

sub _next {
         my $self = shift;
         return undef unless defined $self->{_match};
        
         $self->{_result}  .= $self->{_match};
         $self->{_match}    = undef;
}


=pod

=head1 BUGS

None that I know of but there are probably loads.

=head1 COPYING

Distributed under the same terms as Perl itself.

=head1 AUTHOR

Copyright (c) 2004, 

Simon Wistow <simon@thegestalt.org>	

Matt Lawrence <mattlaw@cpan.org>

=head1 SEE ALSO

L<URI::Find::Iterator>, http://perl.plover.com/yak/iterators/

=cut

# keep perl happy
1;
