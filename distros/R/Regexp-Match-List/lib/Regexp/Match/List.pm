package Regexp::Match::List;

#   $Id: List.pm,v 1.1.1.1.8.3 2004/04/29 01:45:31 dgrant Exp $

#   IDEA: allow match() to skip regexps below a certain hitrate.
#   IDEA: use qr// to precompile regexps


use strict;
use warnings;

use base qw( Class::Base );

use Data::Sorting qw( :basics :arrays );
use Data::Dumper;

use vars qw($VERSION %CONF);

$VERSION = 0.50;

%CONF = 
#   CONFIGURATION --  This configuation is loaded into $self via load_args()
( 
    #   INTERNAL DEFAULTS (can be touched externally) 
    USESTUDY    => 1,   #   use "study STRING;" for regexp strings
    OPCHECK     => 50,  #   Num of match() calls before calling optimize()
    OPSKIP      => 0,   #   Skip optimize() ?
    OPWEIGHT    => 1,   #   Default regexp hit weight
    OPHITS      => 0,   #   Default regexp hits
    OPSORTCONF  =>      #   Data::Sorting Sort Rules. Used in optimize()
    [                   #   The hashlike syntax is to get around some issue
                        #   in Data::Sorting that wouldn't let me use a hashref
        -compare  => 'numeric',
        -order    => 'reverse',
        -sortkey  => sub { $_[0]->{'hits'} * $_[0]->{'weight'} }
    ],
    
    #   INTERNAL STRUCTURE (cannot be touched externally)
    '_RE'       => [],  #   Store regexps in arrayref. See add()
    '_COUNT'    =>      #   Number of times a function has been called
    {
        match       => 0,   
        optimize    => 0
    },                              
);
 


sub match($$)
#   PUBLIC METHOD
#   Test a string for all available regular expressions.
#    
{
    my $self = shift;
    my ($string) = @_;
    my ($RE, $test, @results);
    
    #   A possible regexp optimization. see % perldoc -f study
    study $string if ($self->{'USESTUDY'});

    REGEXP:
    for my $i (0..$#{ $self->{'_RE'} })
    #   Iterate through all regular expressions.
    #   This uses a for() b/c it allows for more control 
    #   than Set::Array::foreach() (we can escape on a match)
    {
        $self->_increment();            #   $self->{'_COUNT'}{'match'}++
        $self->optimize();              #   which is used by optimize() 
        
        $RE = $self->{'_RE'}->[$i];     #   The current regular expression   

        #   Execute the regular expression in list context and
        #   store the results ($1 .. $n) in an array
        @results = ($string =~ $RE->{'test'});

        $self->debug("STRING:$string\n");
        $self->debug("TEST:$RE->{'test'}\n");
        $self->debug("RESULTS:", (scalar(@results)), '-', join(',', @results), "\n\n");
        
        if ($RE->callback(@results))
        #   A successful match may not be enough for a positive
        #   result depending on the outcome of the callback which
        #   is entirely out of Regexp::Match::List's control. 
        #   When it is, we acknowledge and reward a successful 
        #   regular expression, then bust out of this hellish loop. 
        {
            $RE->count_hit();           #   $RE->{'hits'}++
            last REGEXP;                #   Bust out
        }
    }
    
    #print Dumper($RE, @results);
    
    return ($results[0])
        ? ($RE, @results)
        : ();
}

sub add(\%)
#   PUBLIC METHOD
#   Add a regular expression to the mix.
#    IN:    (scalar) regular expression w/o '/' (i.e. '^.+?\s$')
#           [(scalar) multiplier for hits, used by optimize() ]
#   OUT:    Whatever Set::Array::push() returns
{
    my $self = shift;
    my %re = @_;
    
    $self->check_re_conf(\%re);
    
    $re{'weight'}   ||= $self->{'OPWEIGHT'};
    $re{'hits'}     ||= $self->{'OPHITS'};
    
    push (@{ $self->{'_RE'} }, Regexp::Match::List::RE->create(%re));
}

sub check_re_conf(\%)
#   Determine whether the given hashref contains all the information
#   required to create a regexp entry in $self->{'RE'}
#   TODO: complete check_re_conf()
{
    my $self = shift;
    return 1;
}

sub optimize()
#   PUBLIC METHOD, USED INTERNALLY
#   Sort Set::Array object of regular expressions by # of times
#   match() is called. This will run only when match() has been called
#   a multiple of $self->{'OPCHECK'} times
{
    my $self = shift;
    my $cnt_match = $self->_count('match');
    
    #   We only optimize when...
    return if (
        #   we are told allowed to, and when...
        ($self->{'OPSKIP'} == 1) ||
        #   the iteration counter reaches a multiple of $self->{'OPCHECK'}
        (($cnt_match % $self->{'OPCHECK'}) > 1)
    );
    
    #   Count up a hit for this function only when we actually resort
    #   This information is only useful for reference
    $self->_increment();            #   $self->{'_COUNT'}{'optimize'}++
    
    $self->debug("optimize(): running at match() call #$cnt_match\n\n");
    
    #   Sort using Data::Sorting. $self->{'OPSORTCONF'} contains a
    #   sort rule configuration.    
    sort_arrayref($self->{'_RE'}, @{ $self->{'OPSORTCONF'} });

}






#   EXTREMELY PRIVATE METHODS
#   Haha. Philstrdamous, I know you love this one.
#   Increments a counter by one. The particular counter is determined
#   by the calling function. i.e. $self->{'_COUNT'}{'optimize'}++
sub _increment() { $_[0]->{'_COUNT'}{ (split '::', (caller(1))[3])[3] }++ }
#   Returns the value of the counter for the given function
sub _count() { $_[0]->{'_COUNT'}{$_[1]} }






#   CONSTRUCTOR RELATED
sub init()
#   Rekindle all that we are
{
    my ($self, $config) = @_;           #   Get vars from Class::Base::new()
    $self->load_args($config);          #   Load config into $self 
    $self->create_attributes();         #   Set our attributes and defaults
    return $self;
}

sub create_attributes()
#   Add internal attributes to $self (does not overwrite existing values)
#   AND apply default values to externally setable parameters
{
    my $self = shift;
    
    #   See %CONF declaration at the top of this file 
    
    foreach my $a (keys %CONF)
    {
        $self->{$a} = $CONF{$a} unless (exists($self->{$a}));
    }
    
    return $self;
}

sub load_args($$)
#   Used by the constructor to load config into $self.
#   NOTE: _ is skipped
{
    my ($self, $args) = (shift, shift);
    
    for my $key (keys %{ $args }) 
    {
        #   Skip values that could overwrite internal attributes
        next if $key =~ /^\_/;  
        
        (!exists($self->{$key}))
            ? $self->{$key} = $args->{$key}
            : ($self->debug("loadArgs: $key already exists in \$self"));
    }
    
    return $self;
}


###############################################################################

#   TODO: move into separate module (Regexp::Match::List::RE?) 
package Regexp::Match::List::RE;
#   A simple object to store a regular expression test and all its matter

sub create()
#   A constructor. 
#   See add()
{
    my $class = shift;
    my %att = @_;
    my $self = {};
    
    bless \%att, $class;
}

#   Increment hit tally for this regular expression by user value or 1
#   See match()
sub count_hit() { shift->{'hits'} += shift || 1; }

sub callback()
#   Run this regular expression's callback if one exists.
#   By default we will return the result of the regexp test.
#    IN: (array) results ($1 .. $n) of this RE on the current string
#   OUT: (bool) success as determined by the callback
#       
#   See match()
{
    my $self = shift;
    
    #   If there is no callback, return the test result
    return ($#_ >= 0) unless(exists($self->{'callback'}));
    
    #   Send the callback the test result as well as a reference to ourself
    return &{ $self->{'callback'} }($self, @_);
}


#   $Log: List.pm,v $
#   Revision 1.1.1.1.8.3  2004/04/29 01:45:31  dgrant
#   - Initial preparation for CPAN
#
#   Revision 1.1.1.1.8.2  2004/04/23 23:30:25  dgrant
#   - Added callback template to Regexp/Match/List.pm
#
#   Revision 1.1.1.1.8.1  2004/04/16 17:10:34  dgrant
#   - Merging libperl-016 changes into the libperl-1-current trunk
#
#   Revision 1.1.1.1.2.1.20.2  2004/04/08 18:23:56  dgrant
#   *** empty log message ***
#
#   Revision 1.1.1.1.2.1.20.1  2004/04/08 16:42:30  dgrant
#   - No significant change
#
#   Revision 1.1.1.1.2.1  2004/03/25 01:49:51  dgrant
#   - Inital import of List.pm
#   - Added cvs Id and Log variables
#

1;
__END__


=head1 NAME

Regexp::Match::List - Matches a string to a list of regular expressions

=head1 SYNOPSIS 1 (short)

    my $re = Regexp::Match::List->new( 
        DEBUG     => 1,               #   share debugging output (caught by Class::Base)
        OPCHECK   => 100,             #   how often to reoptimize regexps 
        OPSKIP    => 0,               #   Skip optimize()?
        OPWEIGHT  => 1,               #   default regexp hit multiplier
        OPSORTSUB => sub { ... },     #   sorting algorithm used by optimize()
    );

    $re->add('(?i:(trans)(\w\w\w)(tite))', weight => 1.5, hits => 0, somekey => somevalue );

    #   $RE contains the configured regular expression that successfully matched
    #   the string. You have access to $RE->{'weight'}, $RE->{'callback'}, 
    #   $RE->{'somekey'}, etc... 
    #   @results contains the m// for paired parentheses. In the example below, 
    #   it would contain ('trans','ves','tite');
    my ($RE, @results) = $re->match('transvestite ');
    
    #   Callback template:
    sub somesub($@) 
    #   This callback is called regardless of whether the regular expression
    #   matched the string. Returning any true value will tell match() that 
    #   this was a success. Any non-true value will admit failure.
    {
        my ($RE, @results) = @_;   
       
        # ... do something
        # here you can add more criteria for a particular match
        #   
       
        #   Here we maintain the same return value that match() would
        #   return on. Any true value will tell match() this match was
        #   a smashing success.
        return $#results >= 0; 
        
        #   If we did this, all matches would be considered unsuccessful
        #   return 0;
    }


    
    
=head1 DESCRIPTION

    Regexp::Match::List matches a string to a list of regular expressions
    with callbacks and sorting optimization for large datasets.
    Think Regexp::Match::Any with optimization (sort on usage trends, most 
    popular first -- see Data::Sorting) and expanded functionality.
    
    
    note: all parameters are stored in an RE object and returned on a positive match
    note: the callback is called for every regexp test (successful or not)
         so it gets the final say as to whether or not there was a match
    note: the callback is given the RE object. (see bottom the example above)
   
=head1 STABILITY

This module is currently undergoing rapid development and there is much left to 
do. This module is beta-quality, although it hasn't been extensively tested
or optimized. 

It has been tested only on Solaris 8 (SPARC64).

=head1 KNOWN BUGS

None

=head1 SEE ALSO

Regexp::Match::Any, Regexp::Common, Data::Sorting, Class::Base

=head1 AUTHOR

Delano Mandelbaum, E<lt>horrible<AT>murderer.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Delano Mandelbaum

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html


=cut
