## PRIMERVIEW version 3.0
Author: Damien O'Halloran, The George Washington University

[![GitHub issues](https://img.shields.io/github/issues/dohalloran/PRIMERVIEW.svg)](https://github.com/dohalloran/PRIMERVIEW/issues)

## Installation
1. Download and extract the primerview.zip file  
`tar -xzvf primerview.zip`  
2. The extracted dir will be called PRIMERVIEW  
```cmd
  cd PRIMERVIEW  
  perl Makefile.PL  
  make  
  make test  
  make install 
```  
## Getting Started  
1. You must have `muscle.exe` in your PATH  
[Click here to get MUSCLE](http://www.drive5.com/muscle/) 
2. You must have `primer3` in your PATH  
[Click here to get primer3](https://sourceforge.net/projects/primer3/) 
3. Must have following [BioPerl](https://github.com/bioperl) modules:  
Bio::SeqIO  
Bio::Tools::Run::Alignment::Muscle  
Bio::AlignIO  
Bio::Align::Graphics  
Bio::Graphics  
Bio::SeqFeature::Generic  
WARNING: the subroutine 'clean_up' deletes the '.fa', '.fa.fasta', and '.fa.fasta.aln' extension files generated from cwd  
4. Start with a sequence file in FASTA format (for example see `test_seqs.fasta`)  

## Usage 
Run as follows:  
```perl
  use strict;
  use warnings;
  use PRIMERVIEW;

  my $in_file = "test_seqs.fasta";

  my $tmp = PRIMERVIEW->new();
 
   $tmp->load_selections(  
      in_file         => $in_file, 
      single_view     => "1",   
      batch_view      => "1",      
      clean_up        => "1"   
   ); 
   
   $tmp->run_primerview();  
``` 

## Contributing
All contributions are welcome.

## Testing

PRIMERVIEW was successfully tested on:

- [x] Microsoft Windows 7 Enterprise ver.6.1
- [x] Linux Ubuntu 64-bit ver.16.04 LTS

## Support
If you have any problem or suggestion please open an issue [here](https://github.com/dohalloran/PRIMERVIEW/issues).

## License 
GNU GENERAL PUBLIC LICENSE





