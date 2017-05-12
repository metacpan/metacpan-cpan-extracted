
=for PBS =head1 Pbsfile locator test

Test if the Pbsfile locator works properly with multiple source directories

Pbsfiles that are not supposed to be loaded contain a single 'die' instruction. The following command
will display information about how the Pbsfiles are located. -tda adds the pbsfile to the dependency graph dump.

  pbs -no_warp -dsi -tno all -sd . -sd sd1 -sd sd2 -display_subpbs_search_info -display_all_subpbs_alternatives -cw2 green -sfi -tda -o

=cut


AddRule 'all', ['all' => 'd1', 'd2', 'd3'] ;

AddSubpbsRule('d1', 'd1', 'd1/Pbsfile.pl', 'd1') ;
AddSubpbsRule('d2', 'd2', 'd2/Pbsfile.pl', 'd2') ;
AddSubpbsRule('d3', 'd3', 'd3/Pbsfile.pl', 'd3') ;
