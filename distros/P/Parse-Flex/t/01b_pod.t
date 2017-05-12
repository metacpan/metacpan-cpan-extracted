use Test::More;


my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
@files =   (    "${dir}blib/lib/Parse/Flex.pm" ,
		"${dir}blib/lib/Parse/Flex/Generate.pm" ,
);
plan  tests=> scalar @files;

eval 'use Test::Pod' ;


SKIP: {        
		skip  'no Test::Pod', scalar @files    if $@ ;
		pod_file_ok( $_,  $_)   for @files;
};

