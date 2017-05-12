package Solstice::Controller::FormInput::FileUpload::Multiple;

# $Id: Multiple.pm 25 2006-01-14 00:50:12Z jlaney $

=head1 NAME

Solstice::Controller::FormInput::FileUpload::Multiple - A controller for uploading a file 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::FormInput);

use Solstice::View::FormInput::FileUpload::Multiple;
use Solstice::Factory::Resource::File::BlackBox;
use Solstice::List;
use Solstice::CGI;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant PARAM => 'file_upload';

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=item new($model)

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->setModel(Solstice::List->new());
    
    return $self;
}

=item getView()

Creates the view object for the home page.

=cut

sub getView {
    my $self = shift;

    my $view = Solstice::View::FormInput::FileUpload::Multiple->new();
    $view->setName($self->getName() || PARAM);
    
    return $view;
}

=item update()

=cut

sub update { 
    my $self = shift;
    
    my $param = $self->getName() || PARAM;
   
    my @enc_ids = param($param);
    
    my $ff = Solstice::Factory::Resource::File::BlackBox->new();
    $self->setModel($ff->createByEncryptedIDs(\@enc_ids));
    
    return TRUE;
}

=item validate()

=cut

sub validate {
    return TRUE;
}

=item commit()

=cut

sub commit {
    return TRUE;
}


1;
__END__

=back

=head1 AUTHOR

Educational Technology Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 25 $

=head1 SEE ALSO

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
