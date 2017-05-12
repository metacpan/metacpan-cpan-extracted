OTRS Ticket Auto Assignment
=============================



1.1	System Environment
OTRS is perl based web framework for HelpDesk and IT Service Management. It runs on linux/unix based system on commodity hardware.
1.2	Requirement References
New work flow development for Ticket Auto Assignment of new ticket.
New Interface for sysconfig entry of selection of group, role list whose ticket will be auto allocated.
Adding new module to interact with the GUI interfaces.
Syconfig based configuration for entry of selection of group, role list whose ticket will be auto allocated.
Notification message should be based on Notification Template System available in OTRS.
Adding new cron job script for the above requirement.

1.3	 New OTRS Ticket Auto Assignment
When a new ticket is created by the customer, the ticket will be auto allocated to the next avialable agent.
1.3.1	Description
This extension adds new feature to OTRS.  When any ticket is created by default it is allocated to 'Admin OTRS', 
this extension allows auto allocation of tickets to agent who are currently online without any manual intervention. 
Main Features of this module :
·   	 A batch file will run after regular interval to find the list of tickets which are still not allocated to any user.  
·	Then, based on the configuration, batch file will find a suitable agent to whom ticket can be allocated. 
·	A ticket is kept in default state till a suitable agent is not found.
1.3.2	Flow of Events
Pseudo Code:
·	Get a list of tickets which are in 'new' state. For each ticket identify the queue to which ticket belongs and group associated with that queue.
·	A agent is considred online if the LastRequest parameter of Session is less than certain (Inactive minutes; present in sysconfig) amount of time from current time.
·	Sysconfig has options to provide either RoleList, GroupList or both. 
·	If only GroupList is provided then agent is considered suitable only if agent belongs to the group to which queue of the ticket is associated. Agent must have 'rw' access to it.
·	If only RoleList is provided then agent is considered suitable only if agent belongs to any of the roles mentioned.
·	If both RoleList and GroupList is provided then agent is considered suitable only if it belongs to both to any of the roles mentioned and group to which queue of the ticket is associated. 
·	After a list of all suitable agents has been found then ticket is assigned to a agent with least sum of 'total open' and 'total closed'.
·	If no suitable agent is present then ticket is kept is defaul state. The batch file will process such tickets in consecutive runs.
1.4	Definitions, Acronyms and Abbreviations

1.5	Design Constraints
               There is no such design constrains.
1.6	Assumptions
1.6.1       Reusable Components identified
        	One new modules (TicketAutoAssignment.pm) is developed which can be reused for different other purposes.
1.7	Dependencies
	The new modules developed have dependencies with SLA.pm, the OTRS framework module
1.8	System Environment
1)	 Determination of Integration Sequence
	The package for the new module should be implemented, then the pl file should be implemented as cron job
2) 	Integration Environment
	OTRS 3.0 Frameworkor above.
3) 	Integration Procedure and Criteria
	use command:
	1. cd /opt/otrs
	2. find `perl -e 'print "@INC"'` -name '*.pm' -print | tee ~/Perl-OTRS-modules-installed.txt
      3. cat Perl-OTRS-modules-installed.txt | grep “TicketAutoAssignment.pm”
  	should be under /opt/otrs/Kernel/Module/
2	External Interfaces
2.1	External Interfaces Provided
	External interfaces for admin is provided by OTRS framework, An additional entry to select role, group list is there in TicketAutoAssignment.xml file.
	(A new entry under group AutoAssign and subgroup 'Core::Ticket::AutoAssign' is made.)
	Path= /opt/otrs/Kernel/Config/File/TicketAutoAssignment.xml

3	Detailed Design
	File Path at a glance after Instalation
		<File Permission="755" Location="bin/otrs.AutoAllocation.pl" Encode="Base64"></File>
		<File Permission="644" Location="Kernel/Modules/TicketAutoAssignment.pm" Encode="Base64"></File>
		<File Permission="644" Location="Kernel/Config/Files/TicketAutoAssignment.xml" Encode="Base64"></File>				

4.  	pm files need to be installed:
    	The webframe module in /opt/otrs/Kernel/Module/TicketAutoAssignment.pm to support GUI
5. 	Addition in /opt/otrs/Kernel/Config/File/TicketAutoAssignment.xml
7. 	Lastly the Apache need to be restarted.
8. 	Finally a cron job AutoAllocation.pl need to be run 

