# Parse::SAMGov

This module parses the daily or monthly files of the entities registered with
the U.S. Government's System for Award Management (SAM) available at
<https://www.sam.gov>.

# INSTALL

Using `cpanminus`:


    $ cpanm Parse::SAMGov


Using `cpan`:


    $ cpan -i Parse::SAMGov


Using source code from Github:


    # you need Dist::Zilla installed
    $ cpanm Dist::Zilla 
    $ dzil authordeps | cpanm
    $ dzil test
    $ dzil install

# DATA

The data files as of 2023 can be found at <https://sam.gov/data-services/Entity%20Registration/Public%20V2?privacy=Public> for Entity Registrations and at <https://sam.gov/data-services/Exclusions/Public%20V2?privacy=Public> for Exclusions.

There is now a V2 format for the data and the codebase has been updated to handle both V1 and V2 data to maintain backwards compatibility of the code-base. By default it will now do V2 files. As of this writing V2 files have 142 columns per line and V1 files have 150 columns per line, so the codebase auto-detects the file type for the Entity Registration.

V1 used the DUNS number as an identifier and V2 uses a SAM Unique Identifier instead of the DUNS number, and the DUNS number is now blank or empty. The columns in both data files are now in different order.


# LICENSE

This code is licensed under the license terms of Perl 5.

# COPYRIGHT

&copy; 2016-2023. Selective Intellect LLC.

# AUTHOR

Vikas N. Kumar(@vikasnkumar)

