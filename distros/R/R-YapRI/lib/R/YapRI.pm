package R::YapRI;


###############
### PERLDOC ###
###############

=head1 NAME

R::YapRI - Yet Another Perl R Inteface

=cut

our $VERSION = '0.05';
$VERSION = eval $VERSION;

1;
__END__

=head1 SYNOPSIS

  use R::YapRI::Base;

  ## WORKING WITH THE DEFAULT MODE:

  my $rbase = R::YapRI::Base->new();
  $rbase->add_command('bmp(filename="myfile.bmp", width=600, height=800)');
  $rbase->add_command('dev.list()');
  $rbase->add_command('plot(c(1, 5, 10), type = "l")');
  $rbase->add_command('dev.off()');
 
  $rbase->run_commands();
  
  my $result_file = $rbase->get_result_file();
  
  ## To work with blocks, check R::YapRI::Block


=head1 DESCRIPTION

Yet another perl wrapper to interact with R. 
C<R::YapRI> is a collection of modules to interact with R using Perl.

The mechanism is simple, it writes R commands into a command file and 
execute it using the R as command line: 

 R [options] < infile > outfile

More information about the basic usage can be found in L<R::YapRI::Base>.

But there are some tricks. It can also define blocks and combine them, so it can
extend the interaction between packages of information. For example, it can
create a block to check the length of a vector using default as base

 my $newblock = $rbase->create_block('lengthblock', 'default');
 $newblock->add_command('length(x * y)');
 $newblock->run_block();
 my @results = $newblock->read_results();
 
 if ($results[0] == 10) {
    my $newblock2 = $rbase->create_block('meanblock', 'default');
    $newblock2->add_command('z <- mean(x * y)');
    $newblock2->run_block();
    my @results2 = $newblock2->read_results();
 }

More information about the use of blocks can be found at L<R::YapRI::Block>.

It can use interpreters (L<R::YapRI::Interpreter::Perl>), so sometimes
it can use perl HASHREF instead of strings to C<add_command>.

 $rbase->add_command('mean(c(2,3,5,7,11,13,17,19,23,29))');
 $rbase->add_command({ mean => [2,3,5,7,11,13,17,19,23,29]});

It uses two switches to trace the R commands that you are running:

=over 4

=item *

disable_keepfiles/enable_keepfiles, to not delete the command files and
the result files after the execution of the code.

=item *

disable_debug/enable_debug, to print to C<STDERR> the R commands from the 
command file before executing them.

=back


=head1 ADVANCED FEATURES

Here are some examples of modules that wrap L<R::YapRI::Base> for an extended 
functionality.

=head2 Matrix manipulation L<R::YapRI::Data::Matrix>

  use R::YapRI::Base;
  use R::YapRI::Data::Matrix;

  my $rbase = R::YapRI::Base->new();
  $rbase->create_block('BLOCK1');

  my $rmatrix = R::YapRI::Data::Matrix->new( { name     => 'matrix1',
                                               coln     => 3,
                                               rown     => 3,
                                               colnames => ['a', 'b', 'c'],
                                               rownames => ['X', 'Y', 'Z'],
                                               data     => [1,2,3,4,5,6,7,8,9],
                                             } );
 
  $rmatrix->send_rbase($rbase, 'BLOCK1');
  $rbase->add_command('eigenvect1 <- eigen(matrix1)$vectors', 'BLOCK1');
  my $eigenvectors = read_rbase($rbase, 'BLOCK1', 'eigenvect1');


=head2 Simple graph creation L<R::YapRI::Graph::Simple>

  use R::YapRI::Base;
  use R::YapRI::Data::Matrix;
  use R::YapRI::Graph::Simple;

  my $rbase = R::YapRI::Base->new();

  my $rmatrix = R::YapRI::Data::Matrix->new( { name     => 'gene_expr',
                                               coln     => 2,
                                               rown     => 1,
                                               colnames => ['WT', 'Mut'],
                                               rownames => ['TIR1'],
                                               data     => [674, 54],
                                             } );

  my $rgraph = R::YapRI::Graph::Simple->new({
    rbase  => $rbase,
    rdata  => { height => $rmatrix },
    grfile => "TirGeneExpression.bmp",
    device => { bmp => { width => 600, height => 600 } },
    sgraph => { barplot => { beside => 'TRUE',
                             main   => 'Tir Gene Expression',
                             xlab   => 'Samples',
                             ylab   => 'Expression',
                             col    => ["dark blue", "dark red"],
              } 
    },

  $rgraph->build_graph('GRAPHBLOCK1');
  my ($filegraph, $fileresults) = $rgraph->build_graph();


=head1 AUTHOR

Aureliano Bombarely <aurebg@vt.edu>

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Lukas Mueller

=item *

Robert Buels

=item *

Naama Menda

=item *

Jonathan "Duke" Leto

=item *

Olivier "dolmen" MenguE<eacute>

=back

=head1 PUBLIC REPOSITORY

Hosted at GitHub: L<https://github.com/solgenomics/yapri>

=head1 COPYRIGHT AND LICENCE

Copyright 2011 Boyce Thompson Institute for Plant Research

Copyright 2011 Sol Genomics Network (solgenomics.net)

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

