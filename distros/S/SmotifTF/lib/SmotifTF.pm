package SmotifTF;

use 5.8.8;
use strict;
use warnings;

=head1 DESCRIPTION

SmotifTF template-free modeling algorithm. 

SmotifTF builds a protein model using a dynamic library of supersecondary
structure fragments obtained from a set of remotely related PDB
structures. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 PRE-REQUISITES

The Smotif-based modeling algorithm requires the query protein sequence as input. 

Software / data:

1. Psipred (http://bioinf.cs.ucl.ac.uk/psipred/)

2. HHSuite (ftp://toolkit.genzentrum.lmu.de/pub/HH-suite/)

3. Psiblast and Delta-blast (http://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

4. Modeller (version 9.14 https://salilab.org/modeller/)

5. DSSP (http://swift.cmbi.ru.nl/gv/dssp/)

6. Local PDB directory (central or user-designated from http://www.rcsb.org). Many PDB structures
   are incomplete with missing residues. The SmotifTF algorithm performs best when the PDB 
   structures are complete. Hence, we use Modeller (https://salilab.org/modeller/) to model the 
   missing residues in the PDB to obtain complete structures. The algorithm can work with 
   incomplete PDB structures but the performance may not be as expected. The SMotifTF software 
   can handle gzipped (.gz) or unzipped (.ent) PDB structure files. 

   The software for remodeling the missing residues can be obtained from our website at: 
   http://fiserlab.org/remodel_pdb.tar.gz
   This can be used to remodel missing residues in the entire PDB and these remodeled
   structures can be used in the SmotifTF package. The SmotifTF package can handle both
   regular and remodeled PDB database.

Download and install the above mentioned software / data according to their instructions. 

Note: Psipred may require legacy blast and Psiblast and Delta-blast are part of the Blast+ package. 
      .ncbirc file may be required in the home directory for Psipred. 
    
=head1 DATABASES REQUIRED: 

1. PDBAA blast database is required (ftp://ftp.ncbi.nlm.nih.gov/blast/db/). 

2. HHsuite databases NR20 and PDB70 are required (ftp://toolkit.genzentrum.lmu.de/pub/HH-suite/databases/hhsuite_dbs/)

=head1 DOWNLOAD AND INSTALLATION

Download SmotifTF package from CPAN: 

http://search.cpan.org/dist/SmotifTF/

Installation of the software (also available in the README file):

 tar -zxvf SmotifTF-version.tar.gz

 cd SmotifTF-version/

 perl Makefile.PL 

 make

 make test

 make install

=head1 SET UP THE CONFIGURATION FILE:

The configuration file, smotiftf_config.ini has all the information
regarding the required library files and other pre-requisite software. 

Set all the paths and executables in this file correctly.

Set environment varible in .bashrc file:

export SMOTIFTF_CONFIG_FILE=/home/user/MyPerlLib/share/perl5/SmotifTF-version/smotiftf_config.ini

=head1 MODELING ALGORITHMIC STEPS

       ----------------------------------------------------
      |First run the Pre-requisites:                       |
      |   Psipred, HHblits+HHsearch, Psiblast,             |
      |         Delta-blast                                |
      |                                                    |
      |   Single-core job                                  |
      |   Usage: perl smotiftf_prereq.pl --step=all        |
      |    --sequence_file=1zzz.fasta --dir=1zzz           |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 1:                                          |
      |         Compare SmotifS                            |
      |                                                    |
      |   Multi-core / cluster job                         |
      |   Usage: perl smotiftf.pl --step=1 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 2:                                          | 
      |         Rank SmotifS                               |
      |                                                    |
      |   Multi-core / cluster job                         |
      |   Usage: perl smotiftf.pl --step=2 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 3:                                          |
      |         Enumerate all possible combinations of     | 
      |         Smotifs (about a million models)           |
      |                                                    |
      |   Multi-core / cluster job                         |
      |   Usage: perl smotiftf.pl --step=3 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 4:                                          |   
      |         Rank enumerated structures using a         |
      |         composite energy function                  |
      |                                                    |
      |   Single-core job                                  |
      |   Usage: perl smotiftf.pl --step=4 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 5:                                          |   
      |         Run Modeller to generate top 5 complete    |  
      |         models                                     |
      |                                                    |
      |   Single-core job                                  |
      |   Usage: perl smotiftf.pl --step=5 --pdb=1zzz      |
       ----------------------------------------------------

=head1 HOW TO RUN SMOTIFTF

1. The two perl scripts needed to run SmotifTF are:
   smotiftf_prereq.pl and smotiftf.pl
   If installed locally, provide the correct path name to the 
   SmotifTF perl library in both scripts.

2. Create a subdirectory with a dummy pdb file name (eg: 1abc or 1zzz). 

3. Put the query fasta file (1zzz.fasta) in this directory.

4. Run the pre-requisites first. This runs Psipred, HHblits+HHsearch,
   Psiblast and Delta-blast. Input is the query sequence in fasta format 
   and the outputs are (a) dynamic database of Smotifs and (b) the putative 
   Smotifs in the query protein. These are used in the subsequent modeling 
   steps. Follow the instructions given in smotiftf_prereq.pl. For more 
   information about the pre-requisites use: perl smotiftf_prereq.pl -help

   Usage: perl smotiftf_prereq.pl --step=all --sequence_file=1zzz.fasta --dir=1zzz 

6. After the pre-requisites are completed, run steps 1 to 5 as given 
   above sequentially. Output from previous steps are often required 
   in subsequent steps. Wait for each step to be completed without 
   errors before going to the next step. Follow the instructions given 
   in smotiftf.pl. For more information use: perl smotiftf.pl -help

   Usage: perl smotiftf.pl --step=[1-5] --pdb=1zzz

7. To run steps 1-5 together use: 
   perl smotiftf.pl --step=all --pdb=1zzz

8. Use multiple-cores or clusters as available, for steps 1 & 3 above.  
   These are slow and require a lot of computational resources. 

Results: 

Top 5 models are stored in the subdirectory (1abc or 1zzz) as:
Model.1.pdb, Model.2.pdb, Model.3.pdb, Model.4.pdb & Model.5.pdb 

=head1 REFERENCE

Vallat BK, Fiser A.
Modularity of protein folds as a tool for template-free modeling of sequences
Manuscript under review. 

=head1 AUTHORS

Brinda Vallat, Carlos Madrid, Andras Fiser C<< <andras at fiserlab.org> >>

=head1 SUPPORT and DOCUMENTATION

Please report any bugs or feature requests to C<bug-smotiftf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SmotifTF>.

You can find documentation for this module with the perldoc command.

    perldoc SmotifTF

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SmotifTF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SmotifTF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SmotifTF>

=item * Search CPAN

L<http://search.cpan.org/dist/SmotifTF/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Fiserlab Members .

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

1; # End of SmotifTF
