package MySQL::Admin::Documentation;

use 5.018002;
use strict;
use warnings;
use Pod::Usage;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw(help readPod);

our $VERSION = '1.12';

sub help{
  pod2usage(1) ;

}

sub readPod{
    my $pod     =  '%htdocs%/javascript/cms.js';
    open(READ, "<$pod") or warn "$! $/";
    my $sJs = '';
    my $bPrint = 0;
    while (<READ>) {
        $bPrint = 1 if $_ =~ /^=/;
        $bPrint = 0 if $_ =~ /=cut/g;
        $sJs .= $_ if $bPrint;

    }
    open(EDIT, '+<%docu%') or warn "$! $/";
    my $sPerl = '';
    while (<EDIT>) {
        $sPerl  .= $_ ;
	last if $_ =~ /^__END__$/;
    }
    seek(EDIT, 0, 0);
    print EDIT $sPerl.$sJs."$/=cut$/";
    truncate(EDIT, tell(EDIT));
    close(EDIT);
}
#readPod();

1;
__END__
=head2 NAME

    MySQL::Admin 

=head2 SYNOPSIS

    MySQL administration Web-App and Content Management System

    cpan MySQL::Admin

This System works like following: index.html 

Css Overview:

=begin html

<pre>
#############################################
#  .window                                  #
#  #######################################  #
#  #.tab                                 #  #   
#  #######################################  #
#  #.menu                  #.content     #  #
#  # ##################### #             #  # 
#  # #.menuContainer     # #             #  #
#  # #.verticalMenuLayout# #.ShowTables  #  #
#  # #.menuCaption       # #.caption     #  #
#  # #.menuContent       # #             #  #
#  # ##################### #             #  #
#  #                       #             #  #
#  #######################################  #
#                                           #
#############################################
</pre>

=end html

javascript/cms.js
    
      // In the  function init() a ( xmlhttprequest ) load the Content.
      // <a onclick="requestURI('$ENV{SCRIPT_NAME}?action=HelloWorld','HelloWorld','HelloWorld')">HelloWorld</a>      

=begin html

<pre>
      requestURI(
        url,     // Script url  
        id,      // Tabwidget id
        txt,     // Tabwidget text
        bHistory,// Browser History
        formData,// Form Data 
        method,  // Submit Type GET or POST
       );
    or 
    <form onsubmit="submitForm(this,'$m_sAction','$m_sTitle');return false;" method="GET" enctype="multipart/form-data">
    <input type="hidden" name="action" value="">
</pre>

=end html

    since apache 2.x GET have maxrequestline so use POST for alarge requests.
    
    POST requests don't saved in the Browser history (back button ). 
    
install.sql

    The actions will bill stored in actions.

=begin html

<pre>
    INSERT INTO actions (
        `action`, #Name of the action
        `file`,   #file contain the code
        `title`,  #title 
        `right`,  #right 0 guest 1 user 5 admin
        `sub`     # sub name  main for the while file 
        ) values('HelloWorld','HelloWorld.pl','HelloWorld','0','main');

    INSERT INTO actions (`action`,`file`,`title`,`right`,`sub`) values('HelloSub','HelloSub.pl','HelloWorld','0','HelloSub');
</pre>

=end html

    In action_set:

=begin html

<pre>
    INSERT INTO actions_set (
        `action`,           #action called
        `foreign_action`,   #foreign key
        `output_id`         #output id 
        ) values('HelloWorld','HelloWorld','content');

    INSERT INTO actions_set (`action`,`foreign_action`,`output_id`) values('HelloWorld','HelloSub','otherOutput');
    
    
    INSERT INTO mainMenu (
        `title`,   # link title
        `action`,  # action defined in actions_set
        `right`,   # 0 guest 1 user 5 admin
        `position`,# top 1 ... x bottom 
        `menu`,    #top or left
        `output`   #requestURI or javascript or loadPage  or href
        )  values('HelloWorld','HelloWorld','0','1','top','requestURI');
</pre>

=end html

  This will call 2 files HelloWorld.pl HelloSub.pl with following output.

cgi-bin/Content/HelloWorld.pl

    #Files are called via do ().
    
    #you are in the MySQL::Admin::GUI namespace

    print  "Hello World !"
    
    .br()
    
    .a(
    
      {
      
      -href => "mailto:$m_hrSettings->{admin}{email}"
      
      },'Mail me')
    
    .br()
    
    1;

cgi-bin/Content/HelloSub.pl

    sub HelloSub{

      print "sub called";
    
    }
    
    1;


cgi-bin/mysql.pl

    Returns a actionset stored in the Mysql Database.
    
    One sub for every output id.
    
    <xml>
    
    <output id="otherOutput">sub called</output>

    <output id="content">Hello World !<br /><a href="mailto:">Mail me</a><br /></output>

    </xml>

this file will be transformed trough xslt in main Template     

index.html

    <div id=otherOutput>sub called</div>

    <div id=content>Hello World !<br /><a href="mailto:">Mail me</a><br /></div>

</pre>

I write a whole Documentation soon.No feedback so I'm not in rush.

Look at http://lindnerei.sourceforge.net or http://lindnerei.de for further Details.
 
=head2 loadPage(inXml, inXsl, outId, tabId, title)

param inXml

  XmL Document or filename

param inXsl

  XsL Document or filename
  
outId, tabId, title set L<requestURI>
  
=head2 intputMask(id, regexp) 

 onkeydown="intputMask(this.id,"(\w+)")"
 
 Would only accept chars for given id as Input.
  
=head2 submitForm(node, tabId, tabTitle, bHistory, method, uri)

=begin html

<pre>
      requestURI(
        node,       // Script url  
        tabId,      // Tabwidget id
        tabTitle,   // Tabwidget text
        bHistory,   // Browser History
        method,     // Form Data 
        uri,        // Submit Type GET or POST
       );
    or 
    <form onsubmit="submitForm(this,'$m_sAction','$m_sTitle');return false;" method="GET" enctype="multipart/form-data">
    <input type="hidden" name="action" value="">
</pre>

=end html

=head2 requestURI(url, id, txt, bHistory, formData, method, bWaid)

=begin html

<pre>
      requestURI(
        url,     // Script url  
        id,      // Tabwidget id
        txt,     // Tabwidget text
        bHistory,// Browser History
        formData,// Form Data 
        method,  // Submit Type GET or POST
       );
    or 
    <form onsubmit="submitForm(this,'$m_sAction','$m_sTitle');return false;" method="GET" enctype="multipart/form-data">
    <input type="hidden" name="action" value="">
</pre>

=end html

=head2 loadXMLDoc(filename)

var xml = loadXMLDoc(filename);

=head2 alert(txt)

Styled replacment for alert

=head2 confirm2(txt, sub, arg, arg2, arg3) 

Styled replacment for confirm.

confirm2( 'Foo ?',
    function(a,b){
      alert (a +" " +b);
     },
     "foo",
     "bar"
     );"

=head2 prompt(txt, sub)

Styled replacment for prompt.

prompt('Enter Text',
function(txt){
 alert(txt);
}
);

=head2 evalId(id)

eval <script></script> tags within given id

=head2 translate(string)

use MySQL::Admin for translations.

=head2 disableOutputEscaping(id) 


=head2 $(id) 

 eq document.getElementById()

=head2  insertAtCursorPosition(txt)


=head2 getElementPosition(id) 

 object.x - .y =  getElementPosition(id);

=head2 move(id, x, y)


=head2 getWindowSize()

 object.x - .y =  getWindowSize();

=head2 setText(id, string)


=head2 getText(id) 


=head2 hide(id) 


=head2 visible(id) 


=head2 ScrolBarWidth()


=head2 enableDropZone(id)


=head2 Autocomplete(evt)


oAutocomplete = $("txt");

autocomplete.push("foo");

autocomplete.push("bar");

oAutocomplete.addEventListener('keyup', Autocomplete);

Autocomplete(evt) 

<textarea id="txt"></textarea>

=head2 selKeyword(id) 

insert vales from an  <select></select> into autocomplete

=head2 checkButton(id,parent)

fake (styled) checkbox for HTML::Editor 

=head2 COPYRIGHT

    Copyright (C) 2006-2016 by Hr. Dirk Lindner

    perl -e'sub lze_Rocks{print/(...)/ for shift;}sub{&{"@_"}}->("lze_Rocks")'

    This program is free software; you can redistribute it and/or modify it 
    under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; This program is distributed in the hope 
    that it will be useful, but WITHOUT ANY WARRANTY; without even
    the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details

=cut
