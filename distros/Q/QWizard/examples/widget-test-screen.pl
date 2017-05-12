#!/usr/bin/perl

use strict;

use QWizard;
use QWizard::API;
use QWizard::Plugins::History qw(get_history_widgets);

sub get_tree_parent {
    my ($qw, $nodename) = @_;
    return if ($nodename eq 'top');
    return 'top' if ($nodename eq 'Letters' || $nodename eq 'Numbers');
    return 'Letters' if ($nodename =~ /^[A-Z]$/);
    return 'Numbers' if ($nodename =~ /^[0-9]$/);
}

sub get_tree_children {
    my ($qw, $nodename) = @_;
    return [qw(Letters Numbers)] if ($nodename eq 'top');
    return [0..9] if ($nodename eq 'Numbers');
    return ['A'..'Z'] if ($nodename eq 'Letters');
}

my $graphlotsdata;
for (my $i = 0; $i <= 3.1415*4; $i += .1) {
    # clip one data set just slightly to make sure x spreads out over it
    next if ($i > 3.1415*.75 && $i < 3.1415*1.25);
    push @{$graphlotsdata->[0]},[$i, sin($i)];
    push @{$graphlotsdata->[1]},[$i, cos($i)];
}

my @graph_opts =
  (
   x_label           => 'X Label',
   y_label           => 'Y label',
   title             => 'Some simple graph',
   bgclr => 'white',
   x_grid_lines => 'true',
   y_grid_lines => 'true',
   transparent => 0,
   brush_size => 3
  );


# use Data::Dumper;
# print Dumper($graphlotsdata);

my %primaries =
  (
   testscreen =>
   {
    title => 'Widget test screen',
    introduction => 'this is the introduction area',
    topbar => [qw_menu('topprimenu','',
		       [qw(menuopt1 menuopt2 menuopt3)])],
    leftside => [qw_menu('leftmenu','',
			 [qw(lopt1 lopt2 lopt3)]),
		 ["Special Widgets",
		  qw_menu('leftmenu2','pick:',
			  [qw(special1 special1)]),
		  qw_checkbox('leftcheck','check:',
			      1,0)],
		 get_history_widgets()],
    rightside => [qw_menu('rightmenu','',
			 [qw(ropt1 ropt2 ropt3)]),
		 qw_checkbox('rightcheck','opt:',1,0)],
    questions =>
    [
     qw_label("label:","label text"),
     qw_paragraph("paragraph:","paragraph text " x 20),
     qw_text('textn',"text:", default => "test input",
	     helpdesc => 'short help'),
     {name => 'hidetextn', type => 'hidetext', text => 'hidetext:',
      helpdesc => 'short help', helptext => 'long help'},
     qw_textbox('textboxn',"textbox:"),
     qw_label("seperator:","should be a break after this question line"),
     "",
     qw_checkbox('checkboxn',"checkbox:", 'on', 'off', default => 'off',
		 refresh_on_change => 1),
     qw_checkbox('checkboxni',"indented checkbox:", 'on', 'off',
		 default => 'off', indent => 1, button_label => 'extra text'),
     qw_checkbox('checkboxnc',"conditional checkbox:", 'on', 'off',
		 default => 'off', indent => 1,
		 doif => sub {qwparam('checkboxn') eq 'on'}),
     qw_menu('menun','menu:',{ menuval1 => 'menulabel1',
			       menuval2 => 'menulabel2',
			       menuval3 => 'menulabel3'},
	     default => 'menuval2'),
     qw_radio('radion','radio:',{ radioval1 => 'radiolabel1',
				  radioval2 => 'radiolabel2',
				  radioval3 => 'radiolabel3'},
	      default => 'radioval2'),
     { type => 'fileupload',
       text => 'fileupload:',
       name => 'fileuploadn',},
     { type => 'filedownload',
       text => 'Download a file:',
       name => 'bogusdown',
       datafn => 
       sub { 
	   my $fh = shift;
	   print $fh "hello world: menun=" . qwparam('menun') . "\n";
       }
     },
     { type => 'multi_checkbox',
       text => 'multi_checkbox:',
       labels => [qw(mcheckvalue1 mchecklabel1 mcheckvalue2 mchecklabel2)],
       name => 'multi_checkboxn'},

      { type => 'bar',
        name => 'testbar',
        values => [[ qw_button('testbarbut','',1,'My Bar Button1'),
		     qw_menu('testbarmenu','',['Bar Menu opt 1',
					       'Bar Menu opt 2',])]]
      },

     { type => 'table',
       text => 'table:',
       headers => [['header1','header2']],
       values => [[['r1c1', 'r1c2'],
		   [ [['subr1c1','subr1c2'],['subr2c1','subr2c2']],
		     qw_text("subwidgetn","sub widget:")
		   ]]]},
     { type => 'image',
       imagealt => 'alt name',
       text => 'image:',
       image => 'smile.png'
     },
     { type => 'button',
       name => 'buttonn',
       text => 'button:',
       values => 'button text',
       default => 'button val'},

     { type => 'tree',
       name => 'treen',
       root => 'top',
       text => 'tree:',
       parent => \&get_tree_parent,
       children => \&get_tree_children,
       default => 'Q',
       expand_all => sub { return 2 if (qwparam('expand_all')) }
     },
     { type => 'checkbox',
       indent => 1,
       name => 'expand_all',
       refresh_on_change => 1,
       text => 'Expand all:'},

     { type => 'table',
       text => 'graphs',
       values =>
       [[[
	  # basic simple point graphs
	  { type => 'graph',
	    already_in_bins => 1,
	    values => [
		       [[1,2,4,'A','B'],[8,5,7,9,10],[1,3,9,4,2.45]]
		      ],
	  },
	  { type => 'graph',
	    'use_gd_graph' => 1,
	    already_in_bins => 1,
	    values => [
		   [[1,2,4,'A','B'],[8,5,7,9,10],[1,3,9,4,2.45]]
		      ],
	  },
	  ],[
	     # auto scaling graphs to get around lame graph modules
	     { type => 'graph',
	       multidata => 1,
#	       values => $graphlotsdata,
	       values => [$graphlotsdata],
	       graph_options => [x_label => 'X',
				 y_label => 'Y',
				 title => 'Broken Sin/Cos',],
	     },
	     { type => 'graph',
	       'use_gd_graph' => 1,
	       multidata => 1,
#	       values => $graphlotsdata,
	       values => [$graphlotsdata],
	       graph_options => [x_label => 'X',
				 y_label => 'Y',
				 title => 'Broken Sin/Cos',],
	     },
	    ]
	 ]]
     }
    ],

    actions_descr =>
    ['Description of how we will use various values: @textn@,@menun@,...'],

    actions =>
    ["msg:results of widget twiddles:",
     sub {
	 my @results;
	 foreach my $i (qw(textn hidetextn textboxn checkboxn menun radion 
			   buttonn subwidgetn fileuploadn
			   testbarmenu testbarbut
			   multi_checkboxnmcheckvalue1
			   multi_checkboxnmcheckvalue2
			   leftmenu leftcheck
			   rightmenu rightcheck
			   treen)) {
	     push @results,
	       sprintf("msg: %-15s: %s", $i, qwparam($i));
	 }
	 return \@results;
     }]
    }
  );

my $wiz = new QWizard(primaries => \%primaries,
		      topbar => [qw_menu('File','',['File','opt1','opt2'])],
		      title => "The Widget Test Wizard");
$wiz->magic('testscreen');
