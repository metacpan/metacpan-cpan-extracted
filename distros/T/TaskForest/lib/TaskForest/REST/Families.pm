package TaskForest::REST::Families;

use strict;
use warnings;
use HTTP::Status;
use TaskForest::REST;
use Data::Dumper;

sub handle {
    my ($q, $parent_hash, $h) = @_;

    my $name = $h->{path_info} || '';
    my $hash = { title => "Family $name" };

    my $method = $parent_hash->{method};

    my %functions = ( PUT => \&PUT, GET => \&GET, HEAD => \&HEAD, DELETE => \&DELETE, POST => \&POST);
                      
    $functions{$method}->($q, $parent_hash, $h, $hash);

    return $hash;
}

sub POST    { &TaskForest::REST::methodNotAllowed($_[1], 'HEAD,GET,PUT,DELETE'); }


sub DELETE  {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $dir       = $parent_hash->{config}->{family_dir};
    my $file_name = $h->{path_info};
    $file_name    =~ s/[^a-z0-9_\-\/\-\:\,\.]//ig;

    # save this for the getModified function
    $hash->{_resource_file_name} = "$dir/$file_name";
    
    &TaskForest::REST::DELETE($q, $parent_hash, $h, $hash, { delete_resource       => \&TaskForest::REST::deleteFile });
               

    $hash->{file_name}     = $file_name;
    
}

sub PUT     {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $dir       = $parent_hash->{config}->{family_dir};
    my $file_name = $h->{path_info};
    $file_name    =~ s/[^a-z0-9_\-\/\-\:\,\.]//ig;

    # save this for the getModified function
    $hash->{_resource_file_name} = "$dir/$file_name";
    if (!defined($h->{file_contents})) {
        # if it's not defined, its a client PUT,
        # if it is defined, it's an overloaded POST
        $h->{file_contents} = $parent_hash->{request}->content;
    }
    
    &TaskForest::REST::PUT($q, $parent_hash, $h, $hash, { get_modified_tags => \&TaskForest::REST::getModifiedTagsForFile,
                                                          get_content       => \&TaskForest::REST::getContentForTextFile,
                                                          put_content       => \&TaskForest::REST::putContentForTextFile });
               

    $hash->{file_name}     = $file_name;
    
}

    

sub GET {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $dir       = $parent_hash->{config}->{family_dir};
    my $file_name = $h->{path_info};
    $file_name    =~ s/[^a-z0-9_\-\/\-\:\,\.]//ig;

    # save this for the getModified function
    $hash->{_resource_file_name} = "$dir/$file_name";

    &TaskForest::REST::GET($q, $parent_hash, $h, $hash, { get_modified_tags => \&TaskForest::REST::getModifiedTagsForFile,
                                                          check_existence   => \&TaskForest::REST::checkExistenceForFile,
                                                          get_content       => \&TaskForest::REST::getContentForTextFile });
               

    $hash->{file_name}     = $file_name;
    
}

sub HEAD {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $dir       = $parent_hash->{config}->{family_dir};
    my $file_name = $h->{path_info};
    $file_name    =~ s/[^a-z0-9_\-\/\-\:\,\.]//ig;

    # save this for the getModified function
    $hash->{_resource_file_name} = "$dir/$file_name";

    &TaskForest::REST::HEAD($q, $parent_hash, $h, $hash, { get_modified_tags => \&TaskForest::REST::getModifiedTagsForFile,
                                                          check_existence   => \&TaskForest::REST::checkExistenceForFile});
               

    $hash->{file_name}     = $file_name;
    
}

1;
