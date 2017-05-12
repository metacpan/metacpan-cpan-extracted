package TaskForest::REST::InsList;

use strict;
use warnings;
use HTTP::Status;
use TaskForest::REST;
use Data::Dumper;

sub handle {
    my ($q, $parent_hash, $h) = @_;
    my $hash = { title => "Instructions List" };

    my $method = $parent_hash->{method};

    my %functions = ( PUT => \&PUT, GET => \&GET, HEAD => \&HEAD, DELETE => \&DELETE, POST => \&POST);
                      
    $functions{$method}->($q, $parent_hash, $h, $hash);

    return $hash;
}

sub PUT     { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }
sub HEAD    { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }
sub DELETE  { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }
sub POST    { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }

sub GET {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $dir       = $parent_hash->{config}->{instructions_dir};

    # save this for the getModified function
    $hash->{_resource_file_name} = $dir;

    &TaskForest::REST::GET($q, $parent_hash, $h, $hash, { get_modified_tags => \&TaskForest::REST::getModifiedTagsForFile,
                                                          check_existence   => \&TaskForest::REST::checkExistenceForFile,
                                                          get_content       => \&TaskForest::REST::getDirListing });
               

    $hash->{dir_name}     = $dir;
}







1;
