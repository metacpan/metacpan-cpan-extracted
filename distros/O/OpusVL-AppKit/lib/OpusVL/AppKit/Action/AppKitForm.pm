package OpusVL::AppKit::Action::AppKitForm;

############################################################################################################################
# use lines.
############################################################################################################################
use Moose;
use namespace::autoclean;
use MRO::Compat; 
extends 'Catalyst::Action';
use File::ShareDir;
use List::MoreUtils qw/uniq/;

############################################################################################################################
# Methods
############################################################################################################################

sub execute 
{
    my $self = shift;
    my ($controller, $c, @args) = @_;

    # get the FormFu object ...
    die("Failed to pull form from controller. Ensure your Controller 'extends' Catalyst::Controller::HTML::FormFu") unless $controller->can('form');
    my $form = $controller->form;
    
    # Configure the form to generate IDs automatically
    $form->auto_id("formfield_%n_%r_%c");
    # The action attribute should point the path of the config file...
    my $config_file = $self->attributes->{AppKitForm}->[0];

    unless ( $controller->appkit_myclass )
    {
        die("Failed to load AppKitForm.. no appkit_myclass specified for $controller ");
    }

    # build the start of config file path..
    my $path = File::ShareDir::module_dir( $controller->appkit_myclass ) . '/root/forms/';
    # ... build the rest of the path..
    if ( defined $config_file )
    {
        $path .= $config_file;
    }
    else
    {
        $path .= $self->reverse . '.yml';
    }

    $c->log->debug("AppKitForm Loading config: $path \n" ) if $c->debug;

    # .. now get the full path...
    my $form_file = File::Spec->rel2abs( $path );

    if ( -r $form_file )
    {
        # .. load it..
        $self->load_config_file ( $c, $form, $form_file );
        my $new_formfu = $form->can('auto_container_comment_class');
        if($c->config->{no_formfu_classes})
        {
            unless($new_formfu)
            {
                $c->log->warn('no_formfu_classes feature will not work without upgrade to HTML::FormFu 1.0');
            }
        }
        else
        {
            if($new_formfu)
            {
                $form->auto_container_class('%t');
                $form->auto_container_label_class('label');
                $form->auto_container_comment_class('comment');
                $form->auto_comment_class('comment');
                $form->auto_container_error_class('error');
                $form->auto_container_per_error_class('error_%s_%t');
                $form->auto_error_class('error_message error_%s_%t');
            }
        }
    
        my $previous_indicator = $form->indicator;
        $form->indicator(sub 
        {
            my $self = shift;
            my $query = shift;
            if(uc $form->method eq 'POST') {
                unless(uc $c->req->method eq 'POST')
                {
                    # check form is a post, if not return false.
                    return 0;
                }
            }
            if($previous_indicator) 
            {
                return $query->param($previous_indicator);
            }
            else
            {
                my @names = uniq grep {defined} map { $_->nested_name } @{ $self->get_fields };
                return grep { defined $query->param($_) } @names;
            }
        });

        $self->process( $form );
        
        # .. stash it..
        $c->stash->{ 'form' } = $form;
    }
    else
    {
        die("Could not find form config: $form_file ");
    }

    # call the next 'excute'...
    my $r = $self->next::method(@_);

    return $r;
}

sub load_config_file
{
    my $self = shift;
    my $c = shift;
    my $form = shift;
    my $form_file = shift;

    $form->load_config_file ( $form_file );
}

sub process
{
    my $self = shift;
    my $form = shift;
    # this is here so that other classes/roles can hook this method.
    # .. process it..
    $form->process;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Action::AppKitForm

=head1 VERSION

version 2.29

=head1 SYNOPSIS

    package TestX::CatalystX::ExtensionA::Controller::ExtensionA 
    sub formpage :Local :AppKitForm("admin/users/userform.yml")
    {
        my ($self, $c) = @_;
        $self->stash->{form}
        $c->stash->{template} = 'formpage.tt';
    }

=head1 DESCRIPTION

    When extension plugins for the AppKit are written they often use FormFu. The Confguration file these
    extentions FormFu bits can be tricky to load, what with all the namespace changes that occur.
    This action class helps in making things more tidy.

    Basically this is just uses File::ShareDir (with the 'appkit_myclass' config key) to find the dir and looks
    for the config file like so './root/forms/<actionname>.yml' .. or if you passed an argument, it will look for
    './root/forms/ARGUMENT0'

=head1 NAME

    OpusVL::AppKit::Action::AppKitForm - Action class for OpusVL::AppKit FormConfig Loading

=head1 SEE ALSO

    L<Catalyst>
    L<OpusVL::AppKit::Base::Controller::GUI>

=head2 execute
    Method called when an action is requested that has the 'AppKitForm' attribute.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
