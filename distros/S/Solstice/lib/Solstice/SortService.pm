package Solstice::SortService;

=head1 NAME

Solstice::SortService - Create the Solstice::Buttons necessary for managing a sortable table.

=cut

=head1 SYNOPSIS


    #takes three arguments - a preference service in which to store the data, and
    #the key names for the field and direction preference
    my $sort_service = Solstice::SortService->new($pref_service, "sort_field_preference_name", "sort_dir_preference_name");

    #flush may be necessary if used in a controller, as many controller functions run twice per click
    $sort_service->flush();


    #add the fields to sort on.
    $sort_service->addSortField({
            label       => $lang_service->getString('tool_header'),
            button_name => 'tool_sort_button',
            sort_func   => sub {
                lc $a->getApplicationName() cmp lc $b->getApplicationName() ||
                lc $a->getImplementationName() cmp lc $b->getImplementationName()
            },
            action      => 'sort',
            default     => 1,
        });

    $sort_service->addSortField({
            label       => $lang_service->getString('tool_project'),
            button_name => 'project_sort_button',
            action      => 'sort',
            sort_func   => sub {
                lc $a->getImplementationName() cmp lc $b->getImplementationName()
            },
            rev_sort_func    => sub {
                #some optional reverse sort function - otherwise the order
                #given by sort_func is just reversed
            },
        });


    #make use of the sort method
    my $iterator = $list->iterator();
    $iterator->sort($sort_service->getSortMethod());


    #in the view, create the service (with the same params!) and put the auto-created buttons into
    #the param hash
    my $sort_service = Solstice::SortService->new($pref_service, "sort_field_preference_name", "sort_dir_preference_name");

    return {
        %params,
        $self->processChildViews(),
        $sort_service->getSortLinks(),
    }


=head1 DESCRIPTION

=cut 

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::ButtonService;

use constant TRUE  => 1;
use constant FALSE => 0;

my $preferences_stored = FALSE;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=cut

sub new {
    my $obj = shift;
    my ($pref_service, $field_tag, $dir_tag) = @_;
    
    my $self = $obj->SUPER::new();

    caller =~ m/^(\w+):.*$/;
    $self->setNamespace($1);
    $self->setPreferenceService($pref_service);
    $self->setSortFieldTag($field_tag);
    $self->setSortDirTag($dir_tag);
    $self->setUniqueButtonNames({}) unless defined $self->getUniqueButtonNames();
    $self->setFields([]) unless defined $self->getFields();

    return $self;
}

sub addSortField {
    my ($self, $sort_info) = @_;

    #check for params
    return FALSE unless (
        (defined $sort_info->{'label'}|| $sort_info->{'lang_key'}) && 
        defined $sort_info->{'sort_func'} &&
        defined $sort_info->{'button_name'} &&
        defined $sort_info->{'action'}
    );

    #check to ensure only one button is marked default
    if($sort_info->{'default'}){
        if($self->getIsDefaultSet){
            die "Cannot set two defaults in addSortField, caller was ". join(" ", caller);
        }
        $self->setIsDefaultSet(TRUE);
    }

    #check to ensure that each button name is unique
    if(defined $self->getUniqueButtonNames()->{$sort_info->{'button_name'}}){
        die "Duplicate button_name $sort_info->{'button_name'} given to addSortField!";
    }else{
        $self->getUniqueButtonNames()->{$sort_info->{'button_name'}} = TRUE;
    }

    #check if this button was selected last click
    my $button_service = Solstice::ButtonService->new();
    my $is_this_selected = FALSE;
    
    $self->storeSortPreferences();
    
    if($self->getPreference($self->getSortFieldTag())){
        if( $self->getPreference($self->getSortFieldTag()) eq $sort_info->{'button_name'} ){
            $is_this_selected = TRUE;
        }
    
    #No preference found, check if this is the default button, and set the pref
    }elsif($sort_info->{'default'}){
            $is_this_selected = TRUE;

            $self->setFieldPrefToSet($sort_info->{'button_name'});
            if(defined $sort_info->{'default_sort_direction'}){
                $self->setDirPrefToSet($sort_info->{'default_sort_direction'});
            }else{
                $self->setDirPrefToSet(TRUE);
            }
    }

    #if we determined that this was the selected button:
    if($is_this_selected){
        $sort_info->{'chosen'} = TRUE;
        $self->setChosenField($sort_info);
    }

    #add this button to the list
    push @{$self->getFields()}, $sort_info;

    return TRUE;
}

sub storeSortPreferences {
    my $self = shift;
    my $sort_info = shift;

    return TRUE if $preferences_stored;
    $preferences_stored= TRUE;

    my $button_service = Solstice::ButtonService->new();
    if(defined $button_service->getAttribute("sort_service_key_".$self->getNamespace())){
        my $button_name = $button_service->getAttribute("sort_service_key_".$self->getNamespace());
        my $direction = $button_service->getAttribute("sort_service_dir");

        if($self->getPreference($self->getSortFieldTag()) eq $button_name){
            if(defined $self->getPreference($self->getSortDirTag())){
                $self->setDirPrefToSet($self->getPreference($self->getSortDirTag()) ? FALSE : TRUE);
            }else{
                $self->setDirPrefToSet(TRUE);
            }
        }

        $self->setFieldPrefToSet($button_name);

        return TRUE;
    }
    
    return FALSE;
}

sub getSortLinks {
    my $self = shift;


    my $button_service = Solstice::ButtonService->new($self->getNamespace());
    my %sort_buttons;
    
    #reset this value here, we want to make sure preferences only get stored once per click
    $preferences_stored = FALSE;
    
    my $has_user = $self->getUserService()->hasUser();
    my $sort_dir = $has_user ? $self->getPreference($self->getSortDirTag()) : $button_service->getAttribute('sort_service_dir');
    #check each button to see if it is selected, and if not, create
    #a sort link for it.
    for my $sort_info (@{$self->getFields()}){

        my $sort_button = $button_service->makeButton({
                    label    => $sort_info->{'label'},
                    title   => $sort_info->{'title'},
                    action    => $sort_info->{'action'},
                    disabled    => $sort_info->{'disabled'},
                    attributes    => {
                        sort_service_dir    => $sort_dir ? FALSE:TRUE,
                        "sort_service_key_".$self->getNamespace()    => $sort_info->{'button_name'},
                    },
                });
        $sort_button->setLangKey($sort_info->{'lang_key'}) if $sort_info->{'lang_key'};

            if($sort_info->{'chosen'}){

                my $image_path = $sort_dir ? $sort_info->{'ascending_image'} : $sort_info->{'descending_image'};
                my $class = $sort_dir ? "sol_sort_active_ascending" : "sol_sort_active_descending";
                my $sort_dir_button = $button_service->makeButton({
                        label    => $sort_info->{'label'},
                        title   => $sort_info->{'title'},
                        action    => $sort_info->{'action'},
                        image  => $image_path,
                        disabled    => $sort_info->{'disabled'},
                        attributes => {
                            sort_service_dir    => $sort_dir ? FALSE:TRUE,
                            "sort_service_key_".$self->getNamespace()    => $sort_info->{'button_name'},
                        },
                    }
                );
                $sort_dir_button->setLangKey($sort_info->{'lang_key'}) if $sort_info->{'lang_key'};


                $sort_buttons{$sort_info->{'button_name'}} = "<div class=$class>". $sort_button->getTextLink() . 
                                                            (($image_path) ? $sort_dir_button->getImageLink():'')."</div>";
            }else{
                $sort_buttons{$sort_info->{'button_name'}} = "<div class=sol_sort_inactive>".$sort_button->getTextLink()."</div>";
            }
    }

    return %sort_buttons;
}

sub getSortMethod {
    my $self = shift;

    
    my $has_user = $self->getUserService()->hasUser();
    my $sort_dir = $has_user ? $self->getPreference($self->getSortDirTag()) : $self->getButtonService()->getAttribute('sort_service_dir');
    #return the reverse of the sort func if we have desc sorting
    if($sort_dir){
        return $self->getChosenField()->{'sort_func'};
    }else{
        if(defined $self->getChosenField()->{'rev_sort_func'} ){
            return $self->getChosenField()->{'rev_sort_func'};
        }else{
            return sub { 
                my $temp = &{$self->getChosenField()->{'sort_func'}};
                return $temp * -1;
            };
        }
    }
}

sub flush {
    my $self = shift;

    $self->set('_unique_button_names', {});
    $self->set('_chosen_field', undef);
    $self->set('_fields', []);
    $self->set('_is_default_set', FALSE);
    return TRUE;
}

=item sortDateTime($datetime_a, $datetime_b)

Generic datetime object sorting method. Handles the case where 
either datetime object is undefined.

=cut

sub sortDateTime {
    my $self = shift;
    my ($a_date, $b_date) = @_;
    
    if (defined $a_date && defined $b_date) {
        return $a_date->cmpDate($b_date);
    } else {
        return 1 if (defined $a_date && !defined $b_date);
        return -1 if (defined $b_date && !defined $a_date);
        return 0;
    }
}

sub setSortDirTag {
    my $self = shift;
    $self->set('_sort_dir_tag', shift);
}

sub getSortDirTag {
    my $self = shift;
    $self->get('_sort_dir_tag');
}


sub setSortFieldTag {
    my $self = shift;
    $self->set('_sort_field_tag', shift);
}


sub getSortFieldTag {
    my $self = shift;
    $self->get('_sort_field_tag');
}

sub setUniqueButtonNames {
    my $self = shift;
    $self->set('_unique_button_names', shift);
}


sub getUniqueButtonNames {
    my $self = shift;
    $self->get('_unique_button_names');
}

sub setFields {
    my $self = shift;
    $self->set('_fields', shift);
}


sub getFields {
    my $self = shift;
    $self->get('_fields');
}

sub setIsDefaultSet{
    my $self = shift;
    $self->set('_is_default_set', shift);
}


sub getIsDefaultSet {
    my $self = shift;
    $self->get('_is_default_set');
}

sub setChosenField {
    my $self = shift;
    $self->set('_chosen_field', shift);
}


sub setPreferenceService {
    my $self = shift;
    $self->set('_pref_service', shift);
}


sub getPreferenceService {
    my $self = shift;
    $self->get('_pref_service');
}

sub getChosenField {
    my $self = shift;
    my $field = $self->get('_chosen_field');
    if (!defined $field) {
        $field = $self->getFields()->[0];
    }
    return $field;
}

sub setRunAlready {
    my $self = shift;
    $self->set('_run_already', shift);
}

sub getRunAlready {
    my $self = shift;
    $self->get('_run_already');
}


sub setFieldPrefToSet {
    my $self = shift;
    #only set this once
    unless( defined $self->get('_field_pref_to_set')){
        $self->setPreference($self->getSortFieldTag(), shift );
        $self->set('_field_pref_to_set', TRUE) ;
    }
}


sub getFieldPrefToSet {
    my $self = shift;
    $self->get('_field_pref_to_set');
}

sub setDirPrefToSet {
    my $self = shift;
    #only set this once
    unless( defined $self->get('_dir_pref_to_set')){
        $self->setPreference($self->getSortDirTag(), shift);
        $self->set('_dir_pref_to_set', TRUE)
    }
}

sub getDirPrefToSet {
    my $self = shift;
    $self->get('_dir_pref_to_set');
}

sub setPreference {
    my $self = shift;
    $self->getPreferenceService()->setPreference(@_);
}

sub getPreference {
    my $self = shift;
    $self->getPreferenceService()->getPreference(@_);
}



1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 191 $

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
