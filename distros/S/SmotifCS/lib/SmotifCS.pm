package SmotifCS;

use 5.10.1 ;
use strict;
use warnings;

=head1 DESCRIPTION

SmotifCS Hybrid Modeling Method

SMOTIFCS implement a hybrid protein modeling algorithms that relies 
on a library of protein super-secondary structure motifs (Smotifs) 
and easily obtainable NMR experimental data.

=head1 VERSION

Version 0.06
=cut

our $VERSION = '0.07';


=head1 PRE-REQUISITES: 

The hybrid modeling algorithm requires a BMRB formatted chemical shift file as input. 
Additionally, if the structure of the protein is known from any alternate resource,
then a PDB-formatted structure file is required. This pdb-file can be present in a
centralized local directory or a user-designated separate directory. 

	Third-party Software:

	1. MySQL  
	2. Phylip 
	3. Modeller 
	4. NMRPipe/TALOS 

	Other requirements:

	1. MySQL Smotif database 
        (http://fiserlab.org/SmotifCS/vilas_loop_pred.sql.gz)
	
    2. Smotif chemical shift library and related files (
        http://fiserlab.org/SmotifCS/chemical_shift.tar.gz)
	
    3. Local PDB directory (central or user-designated) - updated (http://www.rcsb.org). 

	The path to all the pre-requisites should be provided in smotifcs.ini configuration file. 


=head1    HOW TO RUN THE SmotifCS HYBRID MODELING ALGORITHM: 
    INITIALIZE THE CONFIGURATION FILE: 
    
    1.Set up the configuration file:

    The configuration file, smotifcs_config.ini has all the information
    regarding the required library files and other pre-requisite software. 

    Set all the paths and executables in this file correctly.

    Set environment varible in .bashrc file:

    export SMOTIFCS_CONFIG_FILE=/home/user/SmotifCS-0.01/smotifcs_config.ini

    in $HOME/smotifcs_config.ini file.

    2. Set environment varible in .bashrc file:
    export SMOTIFCS_CONFIG_FILE=/home/user/smotifcs_config.ini
    
    3. Create a subdirectory with a dummy pdb file name (eg: 1abc or 1zzz). 

    4. Put the chemical shift input file (in BMRB format) in this directory.
    Use the filename 1abc/pdb1abcshifts.dat or 1zzz/pdb1zzzshifts.dat for
    the BMRB formatted chemical shift input file.
  
       For testing purpose you can download an input file (in BMBR format) 
       from:
	   http://fiserlab.org/SmotifCS/pdb1aabshifts.dat

    5. Optional: If structure is known, include a pdb format structure file
    in the same directory. 1abc/pdb1abc.ent or 1zzz/pdb1zzz.ent

    6. Run steps 1 to 6 as given above sequentially. Output from previous
    steps are often required in subsequent steps. Wait for each step to
    be completed without errors before going to the next step. 

    7. To run all steps together use: 
    perl smotifcs.pl --step=all --pdb=1zzz --chain=A --havestructure=0

    8. Use multiple-cores or clusters as available, for steps 2, 3 & 4.  
    These are slow and require a lot of computational resources. 

    8. If structure is known, use --havestructure=1.
    Else, use --havestructure=0 in all the steps. 

    Results: 

    Top 5 models are stored in the subdirectory (1abc or 1zzz) as:
    Model.1.pdb, Model.2.pdb, Model.3.pdb, Model.4.pdb & Model.5.pdb	


=head1 MODELING PROTEINS USING A SUPER-SECONDARY STRUCTURE LIBRARY AND NMR CHEMICAL SHIFT INFORMATION

    SMOTIFCS implement a hybrid protein modeling algorithms that relies on a library of protein 
    super-secondary structure motifs (Smotifs) and easily obtainable NMR experimental data.


	MODELING ALGORITHM STEPS: 

    Step 1:				             
    Run Talos+			             
    Get SS, Phi/PSi, Smotif Information (Single-core task)		     	             

        Usage: 
        perl smotifcs.pl --step=1 --pdb=1zzz  --chain=A --havestructure=0	     


    Step 2:                                             
    Compare experimental CS of Query SmotifS to theoretical CS of library Smotifs         
    (Multi-core task/ cluster job)		     

        Usage: 
        perl smotifcs.pl --step=2 --pdb=1zzz  --chain=A --havestructure=0           


    Step 3:                                             
    Cluster and rank chosen SmotifS (Multi-core task/ cluster job)                       

        Usage: 
        perl smotifcs.pl --step=3 --pdb=1zzz  --chain=A --havestructure=0           


    Step 4:                                             
    Enumerate all possible combinations of  Smotifs	(about a million models)	     
    (Multi-core task/ cluster job)                       

        Usage: 
        perl smotifcs.pl --step=4 --pdb=1zzz --chain=A --havestructure=0           


    Step 5:                                             
    Rank enumerated structures using a composite energy function  (Single-core task)                   

        Usage: 
        perl smotifcs.pl --step=5 --pdb=1zzz  --chain=A --havestructure=0           

        
    Step 6:                                             
    Run Modeller to generate top 5 complete models  (Single-core task)                     	       
        
        Usage: 
        perl smotifcs.pl --step=6 --pdb=1zzz --chain=A --havestructure=0           


    Reference: 

    Menon V, Vallat BK, Dybas JM, Fiser A.
    Modeling proteins using a super-secondary structure library and NMR chemical
    shift information.
    Structure, 2013, 21(6):891-9.



=head1 Authors:

Vilas Menon, Brinda Vallat, Joe Dybas, Carlos Madrid and Andras Fiser. 



=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc SmotifCS

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=SmotifCS

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/SmotifCS

    CPAN Ratings
        http://cpanratings.perl.org/d/SmotifCS

    Search CPAN
        http://search.cpan.org/dist/SmotifCS/


LICENSE AND COPYRIGHT

Copyright (C) 2015 Fiserlab Members 

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of SmotifCS
