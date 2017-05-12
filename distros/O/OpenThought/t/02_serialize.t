#!/usr/bin/perl

# $Id: 02_serialize.t,v 1.6 2003/08/28 20:51:44 andreychek Exp $

use strict;
use Test::More  tests => 8;
use lib ".";
use lib "./t";
use OpenThoughtTests();

$OpenThought::Prefix = "./openthought";

my $field_data1 = { stooge1  => "Larry"          };
my $field_data2 = { stooge2  => [ "Moe" ]      };
my $field_data3 = { stooge2  => [ "Moe", 1 ]   };

my $field_data4 = { stooge3  => [ [ "Curly" ] ]  };

my $field_data5 = { stooges  => [ [ "Larry", 0 ],
                                  [ "Moe", 1 ],
                                  [ "Curly", 2 ],
                                ]
                   };

my $html_data  = { title    => "<b>Stooges</b>" };

my $o = OpenThought->new( "", { OpenThoughtData => "openthought/" });
my $ser_fields1    = $o->serialize({ fields     => $field_data1         });
my $ser_fields2    = $o->serialize({ fields     => $field_data2         });
my $ser_fields3    = $o->serialize({ fields     => $field_data3         });
my $ser_fields4    = $o->serialize({ fields     => $field_data4         });
my $ser_fields5    = $o->serialize({ fields     => $field_data5         });
my $ser_focus      = $o->serialize({ focus      => "stooge1"            });
my $ser_javascript = $o->serialize({ javascript => "alert('nyayaya');"  });
my $ser_html       = $o->serialize({ html       => $html_data           });

ok ( $ser_fields1 eq q{<script>Packet = new Object;Packet["stooge1"]="Larry";parent.OpenThoughtUpdate(Packet);</script>},
    "Scalar Field Serialization" );

ok ( $ser_fields2 eq q{<script>Packet = new Object;stooge2=new Array;stooge2[0]="Moe";stooge2[1]="";Packet["stooge2"]=stooge2;parent.OpenThoughtUpdate(Packet);</script>},
    "Single Element Array Serialization" );

ok ( $ser_fields3 eq q{<script>Packet = new Object;stooge2=new Array;stooge2[0]="Moe";stooge2[1]="1";Packet["stooge2"]=stooge2;parent.OpenThoughtUpdate(Packet);</script>},
    "Duel Element Array Serialization" );

ok ( $ser_fields4 eq q{<script>Packet = new Object;stooge3=new Array;stooge3[0]=new Array("Curly","");Packet["stooge3"]=stooge3;parent.OpenThoughtUpdate(Packet);</script>},
    "Single Element Array of Arrays Serialization" );

ok ( $ser_fields5 eq q{<script>Packet = new Object;stooges=new Array;stooges[0]=new Array("Larry","0");stooges[1]=new Array("Moe","1");stooges[2]=new Array("Curly","2");Packet["stooges"]=stooges;parent.OpenThoughtUpdate(Packet);</script>},
    "Multiple Element Array of Arrays Serialization" );

ok ( $ser_focus eq q{<script>parent.FocusField('stooge1');</script>},
    "Focus Serialization" );

ok ( $ser_javascript eq q{<script>with (parent.contentFrame) { alert('nyayaya'); }</script>},
    "JavaScript Serialization" );

ok ( $ser_html eq q{<script>Packet = new Object;Packet["title"]="<b>Stooges</b>";parent.OpenThoughtUpdate(Packet, 'html');</script>},
    "HTML Serialization" );
