function nameAddress(page, xpos, ypos)
{  var thePage = 0;
      
   if (page)
	{	thePage = page;
	}
	
	var myRec = [ 40, 650, 0, 0];              // default position
	if (xpos)
	{	myRec[0] = xpos;
	}
	if (ypos)
	{ myRec[1] = ypos;
	}
	
   var labelText = [ "Mr/Ms", "First_Name", "Surname",
                     "Adress", "City", "Zip_Code", "Country",
                     "Phone", "Mobile_Phone", "E-mail",
                     "Company", "Profession", "Interest_1", "Interest_2",
                     "Hobby" ];   
   
   for ( var i = 0; i < labelText.length; i++)
   {
      myRec[2] = myRec[0] + 80;               // length of the label
	   myRec[3] = myRec[1] - 15;               // height ( or depth if you like)

      // a label field is created

      var fieldName = labelText[i] + "Label";
	   var lf1       = this.addField(fieldName, "text", thePage, myRec);
	   lf1.fillColor = color.white;
      lf1.textColor = color.black;
      lf1.readonly  = true;
      lf1.textSize  = 12;
      lf1.value     = labelText[i];
      lf1.display   = display.visible;

      // a text field for the customer to fill-in his/her name is created   
 
	   myRec[0] = myRec[2] + 2;               // move 2 pixels to the right 
	   myRec[2] = myRec[0] + 140;             // length of the fill-in field

	   var tf1         = this.addField(labelText[i], "text", thePage, myRec);
	   tf1.fillColor   = ["RGB", 1, 1, 0.94];
      tf1.strokeColor = ["RGB", 0.7, 0.7, 0.6];
      tf1.textColor   = color.black;
      tf1.borderStyle = border.s;
	   tf1.textSize    = 12;
      tf1.display     = display.visible;
      
      myRec[0] = myRec[0] - 82    // move 82 pixels to the left
      myRec[1] = myRec[1] - 17;   // move 17 pixels down
    } 
         
}

function butt(page, xpos, ypos)
{     
	var myRec = [ 400, 50, 0, 0];              // default position
	if (xpos)
	{	myRec[0] = xpos;
	}
	if (ypos)
	{ myRec[1] = ypos;
	}
   
   if (app.viewerType == 'Exchange')
   {   myRec[2] = myRec[0] + 70;               // length of the button
	    myRec[3] = myRec[1] - 40;               // width
       var f = this.addField("actionField","button", page , myRec);
       var Str = "send(" + page + ");";        
	    f.setAction("MouseUp", Str);
	    f.fillColor = color.ltGray;
       f.buttonSetCaption("Sign&Send"); 
       f.borderStyle = border.b;
       f.lineWidth = 3;
	    f.strokeColor = color.blue;
	    f.highlight = highlight.p;
       myRec[1] -= 110;
       myRec[2] = myRec[0] + 160;               
       myRec[3] = myRec[1] - 100;               
       var info  = this.addField("info", "text", page, myRec);
       info.fillColor   = color.white;
       info.textColor   = color.black;
       info.readonly    = true;
       info.multiline   = true;
       info.borderStyle = border.s;
       info.textSize    = 12;
       info.display     = display.visible;
       var str3 = 'Fill-in this form, ' 
                + 'then press <Sign&Send> to sign. ';
        info.value     = str3;


   }
   else
   {   myRec[2] = myRec[0] + 160;               
       myRec[3] = myRec[1] - 100;               
       var rAddr  = this.addField("returnAddr", "text", page, myRec);
       rAddr.fillColor   = color.white;
       rAddr.textColor   = color.black;
       rAddr.readonly    = true;
       rAddr.multiline   = true;
       rAddr.borderStyle = border.s;
       rAddr.textSize    = 12;
       rAddr.display     = display.visible;
       var str2 = 'Fill-in this form, ' 
                + 'then print it. Write your signature below this text, '
                + ' and send the document by fax to            '   
                + " No  +46-8-991199999";
        rAddr.value     = str2;

       
   }
   1;
}

function send(page)
{	var bort = this.getField("actionField");
  	var bRec = bort.rect;
   bort.display = display.hidden;
   var inf = this.getField("info");
   inf.value = 'Login and put your signature in some free area of the document';
   app.execMenuItem("ppklite:Login");  
   app.execMenuItem("DIGSIG:PlaceSigPullRight");
   var k = this.addField("MailExp", "button", page , bRec);
   k.setAction("MouseUp", "maila()");
   k.fillColor = color.ltGray;
   k.buttonSetCaption("MailExp");
   k.borderStyle = border.b;
   k.strokeColor = color.blue;
   k.highlight = highlight.p;
   inf.value = 'When properly signed, press <MailExp> to send the document by mail to us';
	1;
  
}

function maila()
{  this.mailForm(true, "admin@totallyInvented.com","","","Response", "Message");
   var inf = this.getField("info");
   inf.value = ' ';
}

