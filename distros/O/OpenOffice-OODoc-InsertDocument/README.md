# SYNOPSIS

    use OpenOffice::OODoc;
    
    my $oodoc_dest_document = odfDocument(file => "MyDestFile.odt");
    my $oodoc_from_document = odfDocument(file => "MyFromFile.odt");
    
    my $replace_me_element = $oodoc_dest_document
        ->selectElementByContent("[[ replace_me ]]");
    $oodoc_dest_document
        ->insertDocument( $replace_me_element, 'before', $oodoc_from_document );
    $replace_me_element->delete;

# DESCRIPTION

This module will enable to merge the content from one [OpenOffice::OODoc](https://metacpan.org/pod/OpenOffice::OODoc) into
another.

# METHODS

## appendDocument TODO

Inserts an OpenOffice::OODoc at the end off the document.

    $oodoc_orig->appendDocument( $oodoc_from, new_page => 1 );

## insertDocument

Inserts a OODoc document at location.

    $oodoc_dest_document->insertDocument( $oodoc_element, 'after', $oodoc_from );

If there is any style associated with the `$oodoc_element`, than that will be
used for styling the document to be inserted. Otherwise, it will use default
body styles instead.

# CAVEAT
