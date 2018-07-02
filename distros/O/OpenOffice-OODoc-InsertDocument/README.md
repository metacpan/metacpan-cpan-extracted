# NAME

OpenOffice::OODoc::InsertDocument - insert, merge or append OpenOffice::OODoc objects

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

This module will enable to merge the content from one `OpenOffice::OODoc` into
another.

# LICENCE

This software is distributed, subject to the EUPL. You may not use this file
except in compliance with the License. You may obtain a copy of the License at
[europa.eu EUPL](http://joinup.ec.europa.eu/software/page/eupl)

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
specific language governing rights and limitations under the License.
