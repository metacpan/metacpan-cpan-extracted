This module provides a way for a super user to effectively logon as any RT
user without knowing their password. It provides a html form where a super
user can select a user from the list of users he/she wants to become.

This form is provided as a link under Configuration->Tools->Become User

INSTALLING:

   1.  Unzip the downloaded file
          tar xvfz RTx-BecomeUser-1.0.tar.gz
   2.  cd to the unzipped directory
          cd RTx-BecomeUser-1.0
   3.  Set RTHOME environment variable
          export RTHOME=/u01/rt/rt  (This will be the RT install directory)

   4.  Install this module

       perl Makefile.PL
       make
       make install

FILES:

   1. html/Admin/Tools/BecomeUser.html

       This is the mason template which acts as the main form and sets up
       the RT session and pity much does all the work
 
   2. html/Callbacks/BecomeUserCallbacks/Admin/Elements/ToolTabs

       This callback adds the Become User link under Configuration->Tools

BUGS/ENHANCEMENTS:

   I would love to listen from you about any bugs or enhancements.
   Please mail me at poddar007@gmail.com
