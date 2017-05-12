##Bio-SeqFeature-Generic-Ext-PrimerMap version 1.3
Author: Damien O'Halloran, The George Washington University, 2016

![PrimerMap_Perl LOGO](https://cloud.githubusercontent.com/assets/8477977/19660786/336e11a8-99ff-11e6-92e6-486de155caec.png)

##Installation
1. Download and extract the Bio-SeqFeature-Generic-Ext-PrimerMap.zip file  
`tar -xzvf Bio-SeqFeature-Generic-Ext-PrimerMap.zip`  
2. The extracted dir will be called Bio-SeqFeature-Generic-Ext-PrimerMap  
  `cd Bio-SeqFeature-Generic-Ext-PrimerMap`   
  `perl Makefile.PL`  
  `make`  
  `make test`  
  `make install`  

##Usage 
Run as follows:  
  ` my $tmp = PrimerMap->new();`  
  `$tmp->load_map(`  
   `primer_start => $start,`  
   `primer_end   => $end,`  
   `seq_length   => "1200",`  
   `gene_name    => "myGene",`  
   `out_file     => $output || "output.png"`  
   `);`    
 


## Contributing
All contributions are welcome.

## Support
If you have any problem or suggestion please open an issue [here](https://github.com/dohalloran/Bio-SeqFeature-Generic-Ext-PrimerMap/issues).

## License 
GNU GENERAL PUBLIC LICENSE





