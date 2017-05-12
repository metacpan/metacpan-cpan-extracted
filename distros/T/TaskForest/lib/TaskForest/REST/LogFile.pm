package TaskForest::REST::LogFile;

use strict;
use warnings;
use HTTP::Status;
use TaskForest::REST;
use Data::Dumper;

sub handle {
    my ($q, $parent_hash, $h) = @_;

    my $name = $h->{path_info} || '';
    my $hash = { title => "Job $name" };

    my $method = $parent_hash->{method};

    my %functions = ( PUT => \&PUT, GET => \&GET, HEAD => \&HEAD, DELETE => \&DELETE, POST => \&POST);
                      
    $functions{$method}->($q, $parent_hash, $h, $hash);

    return $hash;
}

sub POST    { &TaskForest::REST::methodNotAllowed($_[1], 'HEAD,GET'); }
sub PUT     { &TaskForest::REST::methodNotAllowed($_[1], 'HEAD,GET'); }
sub DELETE  { &TaskForest::REST::methodNotAllowed($_[1], 'HEAD,GET'); }

    

sub GET {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $file_name = $h->{path_info};
    $file_name    =~ s/[^a-z0-9_\-\:\,\.\/]//ig;
    $file_name    =~ s/\.\./__/ig;
    #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $mon++; $year += 1900;
    my $log_dir = $parent_hash->{config}->{log_dir};


    # save this for the getModified function
    $hash->{_resource_file_name} = "$log_dir/$file_name";

    &TaskForest::REST::GET($q, $parent_hash, $h, $hash, { get_modified_tags => \&TaskForest::REST::getModifiedTagsForFile,
                                                          check_existence   => \&TaskForest::REST::checkExistenceForFile,
                                                          get_content       => \&TaskForest::REST::getContentForTextFile });
               

    $hash->{file_name}     = $file_name;
    
}

sub HEAD {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $file_name = $h->{path_info};
    $file_name    =~ s/[^a-z0-9_\-\:\,\.]//ig;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $mon++; $year += 1900;
    my $log_dir = sprintf("$parent_hash->{config}->{log_dir}/%4d%02d%02d", $year, $mon, $mday);

    # save this for the getModified function
    $hash->{_resource_file_name} = "$log_dir/$file_name";

    &TaskForest::REST::HEAD($q, $parent_hash, $h, $hash, { get_modified_tags => \&TaskForest::REST::getModifiedTagsForFile,
                                                          check_existence   => \&TaskForest::REST::checkExistenceForFile});
               

    $hash->{file_name}     = $file_name;
    
}

1;
