package String::ProgressBar; ## Produces a simple progress bar


use strict;
use Carp;
use vars qw($VERSION);

our $VERSION='0.04';



# It is an OO class to produce a simple progress bar which can be used at 
# a shell. It does not use curses and has no large dependencies.
#
#
# SYNOPSIS
# ========
#
#    use String::ProgressBar;
#    my $pr = String::ProgressBar->new( max => 30 );
#
#    $pr->update( 10 ); # step 10 of 30
#    $pr->write;
#
#    # shows that:
#    # [=======             ]  33% [10/30]
#
#    # If you want to print it by yourself:
#
#    use String::ProgressBar;
#    my $pr = String::ProgressBar->new( max => 30 );
#
#    print $pr->update( 10 )->string()."\r";
#
#
#  
#
# The progress bar has a fix matrix and look liket that:
#
#  first          [====================] 100% [30/30]
#
#
#
# LICENSE
# =======   
# You can redistribute it and/or modify it under the conditions of LGPL.
# 
# AUTHOR
# ======
# Andreas Hernitscheck  ahernit(AT)cpan.org




# Constructor
#
# It can take several key value pairs (here you see also the default values):
#
#                length          =>  20     # length of the bar
#                border_left     =>  '['    # left bracked of the bar
#                border_right    =>  ']',   # right bracked of the bar
#                bar             =>  '=',   # used element of the bar
#                show_rotation   =>  0,     # if it should show a rotating element
#                show_percent    =>  1,     # show percent
#                show_amount     =>  1,     # show value/max
#                text            =>  '',    # text before text bar. If empty, starts on the very left end
#                info            =>  '',    # text after the bar
#                print_return    =>  0,     # whether it should return after last value with new line
#                text_length     =>  14,    # length of the text before the bar
#                allow_overflow  =>  0,     # allow values to exceed 100%
#                bar_overflow    =>  0,     # allow bar to exceed normal width when value is over 100%
#                
#                
sub new { # $object ( max => $int )
    my $pkg = shift;
    my $self = bless {}, $pkg;
    my $v={@_};

    # default values
    my $def = {
                value           =>  0,
                length          =>  20,
                border_left     =>  '[',
                border_right    =>  ']',
                bar             =>  '=',
                show_rotation   =>  0,
                show_percent    =>  1,
                show_amount     =>  1,
                text            =>  '',
                info            =>  '',
                print_return    =>  0,
                text_length     =>  14,
                allow_overflow  =>  0,
                bar_overflow    =>  0,
               };

    # asign default values
    foreach my $k (keys %$def){
        $self->{ $k } = $def->{ $k };
    }

    if ( not $self->{"text"} ){
        $self->{"text"} = 0;
    }
    
    
    foreach my $k (keys %$v){
        $self->{ $k } = $v->{ $k };
    }


    
    my @req = qw( max );
    
    foreach my $r (@req){
        if ( ! $self->{$r} ){
            croak "\'$r\' required in constructor";
        }
    }

    
    
    return $self;
}


# updates the bar with a new value
# and returns the object itself.
sub update {
    my $self = shift;
    my $value = shift;
    
    if ( !$self->{'allow_overflow'} && $value > $self->{'max'}  ){
        $value = $self->{'max'};
    }
    
    $self->{'value'} = $value;
    
    return $self;
}


# updates text (before bar) with a new value
# and returns the object itself.
sub text { # $object ($string)
    my $self = shift;
    my $value = shift;
    
    $self->{'text'} = $value;
    
    return $self;
}


# updates info (after bar) with a new value
# and returns the object itself.
sub info { # $object ($string)
    my $self = shift;
    my $value = shift;
    
    $self->{'info_last'} = $self->{'info'};
    $self->{'info'} = $value;
    
    
    return $self;
}



# Writes the bar to STDOUT. 
sub write { # void ()
    my $self = shift;
    my $bar = $self->string();
    
    print "$bar\r";
    
    if ( $self->{'print_return'} && ($self->{'value'} == $self->{'max'}) ){
        print "\n";
    }
    
}


# returns the bar as simple string, so you may write it by
# yourself.
sub string { # $string
    my $self = shift;
    my $str;
    
    my $ratio = $self->{'value'} / $self->{'max'};
    my $percent = int( $ratio * 100 );

    my $bar_ratio = $ratio;
    $bar_ratio = 1 if $bar_ratio > 1 && !$self->{'bar_overflow'};

    my $bar = $self->{'bar'} x ( $bar_ratio *  $self->{'length'} );
    $bar .= " " x ($self->{'length'} - length($bar) );
    
    $bar = $self->{'border_left'} . $bar . $self->{'border_right'};
    
    $str = "$bar";
   
    if ( $self->{'show_percent'} ){
       $str.=" ".sprintf("%3s",$percent)."%";
    }

    if ( $self->{'show_amount'} ){
       $str.=" [".sprintf("%".length($self->{'max'})."s",$self->{'value'})."/".$self->{'max'}."]";
    }    

    if ( $self->{'show_rotation'} ){
       my $char = $self->_getRotationChar();
       $str.=" [$char]";
    }    

    if ( $self->{'info'} || $self->{'info_used'} ){
       $str.=" ".sprintf("%-".length($self->{'info_last'})."s", $self->{'info'});
       $self->{'info_used'} = 1;
    }    

    
    
    if ( $self->{'text'} ){
       $str=sprintf("%-".$self->{'text_length'}."s", $self->{'text'})." $str";
    }    
    
    return $str;
}

# Returns a rotating slash.
# With every call one step further
sub _getRotationChar {
    my $self  = shift;
    
    my @matrix = qw( / - \ | );
    
    $self->{rotation_counter} = ($self->{rotation_counter}+1) % (scalar(@matrix)-1);
    
    return $matrix[ $self->{rotation_counter} ];
}


1;


#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

String::ProgressBar - Produces a simple progress bar


=head1 SYNOPSIS


   use String::ProgressBar;
   my $pr = String::ProgressBar->new( max => 30 );

   $pr->update( 10 ); # step 10 of 30
   $pr->write;

   # shows that:
   # [=======             ]  33% [10/30]

   # If you want to print it by yourself:

   use String::ProgressBar;
   my $pr = String::ProgressBar->new( max => 30 );

   print $pr->update( 10 )->string()."\r";


 

The progress bar has a fix matrix and look liket that:

 first          [====================] 100% [30/30]





=head1 DESCRIPTION

It is an OO class to produce a simple progress bar which can be used at 
a shell. It does not use curses and has no large dependencies.




=head1 REQUIRES

L<Carp> 


=head1 METHODS

=head2 new

 my $object = $this->new(max => $int);

Constructor

It can take several key value pairs (here you see also the default values):

               length          =>  20     # length of the bar
               border_left     =>  '['    # left bracked of the bar
               border_right    =>  ']',   # right bracked of the bar
               bar             =>  '=',   # used element of the bar
               show_rotation   =>  0,     # if it should show a rotating element
               show_percent    =>  1,     # show percent
               show_amount     =>  1,     # show value/max
               text            =>  '',    # text before text bar. If empty, starts on the very left end
               info            =>  '',    # text after the bar
               print_return    =>  0,     # whether it should return after last value with new line
               text_length     =>  14,    # length of the text before the bar
               allow_overflow  =>  0,     # allow values to exceed 100%
               bar_overflow    =>  0,     # allow bar to exceed normal width when value is over 100%




=head2 info

 my $object = $this->info($string);

updates info (after bar) with a new value
and returns the object itself.


=head2 string

 my $string = $this->string();

returns the bar as simple string, so you may write it by
yourself.


=head2 text

 my $object = $this->text($string);

updates text (before bar) with a new value
and returns the object itself.


=head2 update

 $this->update();

updates the bar with a new value
and returns the object itself.


=head2 write

 $this->write();

Writes the bar to STDOUT.



=head1 AUTHOR

Andreas Hernitscheck  ahernit(AT)cpan.org


=head1 LICENSE

You can redistribute it and/or modify it under the conditions of LGPL.



=cut

