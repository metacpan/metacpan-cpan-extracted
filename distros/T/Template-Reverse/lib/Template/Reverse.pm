package Template::Reverse;

# ABSTRACT: A template generator getting different parts between pair of text

use Moo;
use utf8;
use Template::Reverse::Part;
use Algorithm::Diff qw(sdiff);
use Scalar::Util qw(blessed);
our $VERSION = '0.143'; # VERSION


has 'sidelen' => (
    is=>'rw',
    default => sub{return 10;}
);


my $_WILDCARD = bless [], 'WILDCARD';
sub WILDCARD{return $_WILDCARD};
sub _isWILDCARD{
  return ref $_[0] eq 'WILDCARD';
}


sub detect{
    my $self = shift;
    my @strs = @_;
    my $diff = _diff($strs[0],$strs[1]);
    my $pattern = _detect($diff,$self->sidelen());
    return $pattern;
}


### internal functions
sub _detect{
    my $diff = shift;
    my $sidelen = shift;
    $sidelen = 0 unless $sidelen;
    my @d = @{$diff};
    my $lastStar = 0;
    my @res;
    for(my $i=0; $i<@d; $i++)
    {
        if( _isWILDCARD($d[$i] ) )
        {
            my $from = $lastStar;
            my $to = $i-1;
            if( $sidelen ){
                $from = $to-$sidelen+1 if $to-$from+1 > $sidelen;
            }
            my @pre = @d[$from..$to];
            
            my $j = @d;
            if( $i+1 < @d ){
                for( $j=$i+1; $j<@d; $j++)
                {
                    if( _isWILDCARD( $d[$j] ) ){
                        last;
                    }
                }
            }
            $from = $i+1;
            $to = $j-1;
            if( $sidelen ){
                $to = $from + $sidelen-1 if $to-$from+1 > $sidelen;
            }
            my @post = @d[$from..$to];
            my $part = Template::Reverse::Part->new(pre=>\@pre, post=>\@post);
            push(@res,$part);
            $lastStar = $i+1;
        }
    }
    return \@res;
}


sub _diff{
    my ($a,$b) = @_;
    my ($org_a,$org_b) = @_;

    $a = [map{blessed($_)?$_->as_string:$_}@{$a}];
    $b = [map{blessed($_)?$_->as_string:$_}@{$b}];
    
    my @d = sdiff($a,$b);
    my @rr;
    my $before='';
    my $idx = 0;
    for my $r (@d){
        if( $r->[0] eq 'u' ){
            push(@rr,$org_a->[$idx]);
            $before = '';
        }
        else{
            push(@rr,WILDCARD) unless _isWILDCARD($before);
            $before = WILDCARD;
        }
        $idx++ if $r->[0] ne '+';
        
    }
    return \@rr;
}



1;

__END__

=pod

=head1 NAME

Template::Reverse - A template generator getting different parts between pair of text

=head1 VERSION

version 0.143

=head1 SYNOPSIS

    use Template::Reverse;
    my $rev = Template::Reverse->new();

    my $parts = $rev->detect($arr_ref1, $arr_ref2); # returns [ Template::Reverser::Part, ... ]

    use Template::Reverse::Converter::TT2;
    my @templates = Template::Reverse::TT2Converter::Convert($parts); 

more

    # try this!!
    use Template::Reverse;
    use Data::Dumper;

    my $rev = Template::Reverse->new;

    # generating patterns automatically!!
    my $str1 = ['I',' ','am',' ', 'perl',' ','and',' ','smart']; # White spaces should be explained explicity.
    my $str2 = ['I',' ','am',' ', 'khs' ,' ','and',' ','a',' ','perlmania']; # Use Parse::Lex or Parse::Token::Lite to make it easy.
    my $parts = $rev->detect($str1, $str2);

    my $str3 = "I am king of the world and a richest man";

    # extract with TT2
    use Template::Reverse::Converter::TT2;
    my $tt2 = Template::Reverse::Converter::TT2->new;
    my $templates = $tt2->Convert($parts); # equals to ['I am [% value %] and ',' and [% value %]']

    use Template::Extract;
    my $ext = Template::Extract->new;
    my $value = $ext->extract($templates->[0], $str3);
    print Dumper($value); # output : {'value'=>'king of the world'}

    my $value = $ext->extract($templates->[1], $str3);
    print Dumper($value); # output : {'value'=>'a richest man'}

    # extract with Regexp
    my $regexp_conv = Template::Reverse::Converter::Regexp->new;
    my $regexp_list = $regexp_conv->Convert($parts); 

    my $str3 = "I am king of the world and a richest man";
     
    # extract!!
    foreach my $regexp (@{$regexp_list}){
        if( $str3 =~ /$regexp/ ){
            print $1."\n";
        }
    }

    # When you need to get regexp as string.
    use re regexp_pattern;
    my($pat,$flag) = regexp_pattern( $regexp_list->[0] );
    print $pat; # Regexp generates regexps without flags. So you do not need to use $flag.

=head1 DESCRIPTION

Template::Reverse detects different parts between pair of similar text as merged texts from same template.
And it can makes an output marked differences, encodes to TT2 format for being use by Template::Extract module.

=head1 FUNCTIONS

=head3 new(OPTION_HASH_REF)

=head4 sidelen=>$max_length_of_each_side

sidelen is a short of "side character's each max length".
the default value is 10. Setting 0 means full-length.

If you set it as 3, you get max 3 length pre-text and post-text array each part.

This is needed for more faster performance.

=head3 WILDCARD()

WILDCARD() returns a blessed array reference as 'WILDCARD' to means WILDCARD token.
This is used by _diff() and _detect().

=head3 detect($arr_ref1, $arr_ref2)

Get an array-ref of L<Template::Reverse::Part> from two array-refs which contains text or object implements as_string() method.
A L<Template::Reverse::Part> class means an one changable token.

It returns like below.

    $rev->detect([qw(A b C)], [qw(A d C)]);
    # 
    # [ { ['A'],['C'] } ] <- Please focus at data, not expression.
    #   : :...: :...: :     
    #   :  pre  post  :
    #   :.............:  
    #       Part #1
    #

    $rev->detect([qw(A b C d E)],[qw(A f C g E)]);
    #
    # [ { ['A'], ['C'] }, { ['C'], ['E'] } ]
    #   : :...:  :...: :  : :...:  :...: :
    #   :  pre   post  :  :  pre   post  :
    #   :..............:  :..............:
    #        Part #1          Part #2
    #

    $rev->detect([qw(A1 A2 B C1 C2 D E1 E2)],[qw(A1 A2 D C1 C2 F E1 E2)]);
    #
    # [ { ['A1','A2'],['C2','C2'] }, { ['C1','C2'], ['E2','E2'] } ]
    #

    my $str1 = [qw"I am perl and smart"];
    my $str2 = [qw"I am KHS and a perlmania"];
    my $parts = $rev->detect($str1, $str2);
    #
    # [ { ['I','am'], ['and'] } , { ['and'],[] } ]
    #   : :........:  :.....: :   :            :
    #   :    pre       post   :   :            :
    #   :.....................:   :............:
    #           Part #1               Part #2
    #

    # You can get same result for object arrays.
    my $objs1 = [$obj1, $obj2, $obj3];
    my $objs2 = [$obj1, $obj3];
    #
    # [ { [ $obj1 ], [ $obj3 ] } ]
    #   : :.......:  :.......: :
    #   :    pre       post    :
    #   :......................:
    #           Part #1

Returned arrayRef is list of changable parts.

    You can get a changed token if you find just 'pre' and 'post' sequences on any other token array.

=head1 SEE ALSO

=item *

L<Template::Extract>
L<Parse::Token::Lite>

=head1 SOURCE

L<https://github.com/sng2c/Template-Reverse>

=head1 THANKS TO

=item https://metacpan.org/author/AMORETTE

This module is dedicated to AMORETTE.
He was interested in this module and was cheering me up.

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
