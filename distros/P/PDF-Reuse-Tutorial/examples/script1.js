   // script1.js

   function nameAddress(page, xpos, ypos)
   {  var thePage = 0;
      if (page)
      {   thePage = page;
      }
	
      var myRec = [ 40, 650, 0, 0];              // default position
      if (xpos)
      {   myRec[0] = xpos;
      }
      if (ypos)
      {   myRec[1] = ypos;
      }
	
      var labelText = [ "Mr/Ms", "First_Name", "Surname",
                        "Adress", "City", "Zip_Code", "Country",
                        "Phone", "Mobile_Phone", "E-mail",
                        "Company", "Profession", "Interest_1", "Interest_2",
                        "Hobby" ];   
   
      for ( var i = 0; i < labelText.length; i++)
      {   myRec[2] = myRec[0] + 80;               // length of the label
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
