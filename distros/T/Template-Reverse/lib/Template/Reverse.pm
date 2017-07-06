package Template::Reverse;

# ABSTRACT: A template generator getting different parts between pair of text
use Moo;
use utf8;
use Template::Reverse::Util;
use constant::Atom qw(WILDCARD BOF EOF);
use Algorithm::Diff qw(sdiff);
use List::Util qw(max min);
require Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(WILDCARD BOF EOF);

our $VERSION = '0.202'; # VERSION


has 'sidelen' => (
    is=>'rw',
    default => sub{return 10;}
);


sub detect{
    my ($self,$arr1,$arr2,$sidelen) = @_;
    $sidelen ||= $self->sidelen();
    $arr1 = [BOF, @{$arr1}, EOF];
    $arr2 = [BOF, @{$arr2}, EOF];
    my $diff = _diff($arr1,$arr2);
    my $pattern = _detect($diff, $sidelen);
    return $pattern;
}

### internal functions

sub _detect{
    my ($diff, $sidelen) = @_;
    my @parts = partition_by(sub{$_[0]==WILDCARD}, @{$diff});
    my @each_parts = partition(3, 2, @parts);

    my @res;
    foreach my $part (@each_parts){
        my($pre, $wc, $post) = @{$part};
        my @pre = @{$pre};
        my @post = @{$post};
        @pre = splice(@pre, max(0-@pre,-$sidelen));
        @post = splice(@post, 0, min(0+@post,$sidelen));
        push(@res, {pre=>\@pre, post=>\@post});
    }
    return \@res;
}

sub _diff{
    my ($a,$b) = @_;
    my @d = sdiff($a,$b);
    my @rr;
    my $idx = 0;
    for my $r (@d){
        if( $r->[0] eq 'u' ){
            push(@rr,$a->[$idx]);
        }
        else{
            push(@rr,WILDCARD) unless WILDCARD == $rr[-1];
        }
        $idx++ if $r->[0] ne '+';
    }
    return \@rr;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Reverse - A template generator getting different parts between pair of text

=head1 VERSION

version 0.202

=head1 SYNOPSIS

    use Template::Reverse;
    my $rev = Template::Reverse->new();

    my $parts = $rev->detect($arr_ref1, $arr_ref2); # returns [ Template::Reverser::Part, ... ]

    use Template::Reverse::Converter::TT2;
    my $converter = Template::Reverse::Converter::TT2->new();
    my @templates = $converter->Convert($parts); 

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

=head1 CI

=for html <a href="https://travis-ci.org/sng2c/Template-Reverse"><img src="https://travis-ci.org/sng2c/Template-Reverse.svg?branch=master"></a>

=head1 FUNCTIONS

=head3 new(OPTION_HASH_REF)

=head4 sidelen=>$max_length_of_each_side

sidelen is a short of "side character's each max length".
the default value is 10. Setting 0 means full-length.

If you set it as 3, you get max 3 length pre-text and post-text array each part.

This is needed for more faster performance.

=head3 BOF, EOF

Template::Reverse exports BOF(Begin of file) and EOF(End of file).
These are needed for more explicit implementation.
And you can see them return parts

=head3 detect($arr_ref1, $arr_ref2)

Get an array-ref of L<Template::Reverse::Part> from two array-refs which contains text or object implements as_string() method.
A L<Template::Reverse::Part> class means an one changable token.

It returns like below.

    $rev->detect([qw(A b C)], [qw(A d C)]);
    # List is converted as below
    #
    # qw(A b C) -> (BOF, qw(A b C), EOF)
    # 
    # [ { [BOF, 'A'],['C', EOF] } ] <- Please focus at data, not expression.
    #   : :........: :..,,,,,.: :     
    #   :     pre       post    :
    #   :.......................:  
    #           Part #1
    #

    $rev->detect([qw(A b C d E)],[qw(A f C g E)]);
    #
    # [ { [BOF, 'A'], ['C'] }, { ['C'], ['E', EOF] } ]
    #   : :........:  :...: :  : :...:  :........: :
    #   :  pre        post  :  :  pre      post    :
    #   :...................:  :...................:
    #          Part #1                Part #2
    #

    $rev->detect([qw(A1 A2 B C1 C2 D E1 E2)],[qw(A1 A2 D C1 C2 F E1 E2)]);
    #
    # [ { [BOF,'A1','A2'],['C2','C2'] }, { ['C1','C2'], ['E2','E2',EOF] } ]
    #

    my $str1 = [qw"I am perl and smart"];
    my $str2 = [qw"I am KHS and a perlmania"];
    my $parts = $rev->detect($str1, $str2);
    #
    # [ { [BOF,'I','am'], ['and'] } , { ['and'],[EOF] } ]
    #   : :............:  :.....: :   :               :
    #   :      pre         post   :   :               :
    #   :.........................:   :...............:
    #              Part #1                  Part #2
    #

    # You can get same result for object arrays.
    my $objs1 = [$obj1, $obj2, $obj3];
    my $objs2 = [$obj1, $obj3];
    #
    # [ { [ BOF,$obj1 ], [ $obj3, EOF ] } ]
    #   : :...........:  :............: :
    #   :      pre            post      :
    #   :...............................:
    #                Part #1

Returned arrayRef is list of detected changing parts.

Actually, the returned value is like below.

    [ 
        {pre=>[BOF, ...], post=>[...]},
        ...
        {pre=>[...], post=>[..., EOF]},
    ]

You can get a changed token if you find just 'pre' and 'post' parts on splited target.

=head1 SEE ALSO

=over

=item L<Template::Extract>

=item L<Parse::Token::Lite>

=back

=head1 SOURCE

L<https://github.com/sng2c/Template-Reverse>

=head1 THANKS TO

L<https://metacpan.org/author/AMORETTE>

This module is dedicated to AMORETTE.
He was interested in this module and was cheering me up.

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
