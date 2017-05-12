# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Formatter::Markup_html;

@EXPORT = qw(html);

use strict;
use Exporter;
use base 'Exporter';

# tag  => [ container?, function ]
my %trans =
( A    => [ 1, ]
, B    => [ 1, ]
, BD   => [ 0, ]
, BQ   => [ 1, ]
, BR   => [ 1, ]
, 'CENTER' => [ 1, ]
, COLOR => [ 1, ]
, DIV  => [ 1, ]
, I    => [ 1, ]
, IMG  => [ 1, ]
, FACE => [ 1, ]
, LI   => [ 1, ]
, MARK => [ 0, ]
, O    => [ 1, ]
, OL   => [ 1, ]
, P    => [ 1, ]
, PRE  => [ 1, ]
, REDO => [ 0, ]
, SUB  => [ 1, ]
, SUP  => [ 1, ]
, TEXT => [ 0, ]
, TT   => [ 1, ]
, U    => [ 1, ]
, UL   => [ 1, ]
);

sub html($)
{   my ($self, $parsed) = @_;

    my %b =
    ( fontsize => 3
    );


}

sub container($)
{   my ($self, $leaf) = @_;
    for(my $str=0; $str=<@$leaf; $str+=2)
    {   if(ref $leaf->[$str] eq 'ARRAY')
        {   $self->containter($leaf->[$str]);
        }
        else
        {   my $cmd = $leaf->[$str];
            $cmd->{}
        }

        print $leaf->[$str+1];
    }
}
1;
