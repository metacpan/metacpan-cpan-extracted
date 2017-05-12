package Solstice::View;

# $Id: View.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::View - A superclass for constructing views.

=head1 SYNOPSIS

  package MyView;

  use base qw(Solstice::View);

  our $template = 'path/to/template.html';

  # If you dynamically choose a template, you need to specify the possibilities up 
  # front, so the compiler knows how to deal with them.  In most cases, this line 
  # is unnecessary:
  $self->setPossibleTemplates('template_cool.html', 'template_lame.html');

  sub generateParams {
    # To add a single scalar or array ref
    $self->setParam('param_name', $scalar);
    $self->setParam('param_name', \@array);

    # To add to a loop...
    $self->addParam('loop_name', \%hash_ref);

    # To add multiple values at once...
    $self->setParams(\%hash_ref);
  }

  # You can do this instead, but it's old, and not recommended.
  sub _getTemplateParams {
    return { my => "specific", template => "params" };
  }

=head1 DESCRIPTION

This is a virtual class for creating solstice view objects.  This class
should never be instantiated as an object, rather, it should always 
be sub-classed.   

=cut

use 5.006_000;
use strict;
use warnings;
no  warnings qw(redefine);

use base qw(Solstice);

use File::Path;
use Solstice::NamespaceService;
use Solstice::Compiler::View;
use Solstice::List;

use Solstice::ConfigService;
use Solstice::IconService;
use Solstice::ButtonService;
use Solstice::MessageService;
use Solstice::NavigationService;
use Solstice::UserService;
use Solstice::LogService;
use Solstice::LangService;
use Solstice::PreferenceService;
use Solstice::Service::Memory;

use constant TRUE  => 1;
use constant FALSE => 0;
use constant COMPILED_PATH_KEY => '__solstice_compiled_view_path_';

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);
our $use_wireframes = FALSE; # package-level flag for wireframes
our $check_template_freshness;

=head2 Export

No symbols exported..

=head2 Methods

=over 4

=cut


=item new($model)

Creates a new Solstice::View object.  C<$model> is the
data model for the view

=cut

sub new {
    my $class = shift;
    my $model = shift;

    my $self = $class->SUPER::new(@_); 

    $self->setModel($model);

    $self->{'_is_subview'} = FALSE;
    $self->{'_subview_error'} = FALSE;

    #set the app to draw the template from based on package prefix
    (ref $self) =~ /^(.*?)::/;
    $self->_setApp($1);

    my $template = $self->_getPackageTemplate($self);

    if (defined $template) {
        $self->_setTemplate($template);
    }

    if (!defined $Solstice::View::check_template_freshness) {
        my $config = Solstice::ConfigService->new();

        $Solstice::View::check_template_freshness = $config->getDevelopmentMode();
    }

    $self->_clearParams();

    return $self;
}

=item getErrorHTML()

Takes an error object and returns the html you can put in your template.

This function isn't doing anything anymore.  Is it even being used??

=cut

sub getErrorHTML {
    my $self = shift;

    warn "getErrorHTML is deprecated and will never return a value. Called from ". join(' ', caller());

    my $error_screen = "";
#    $error_view->paint(\$error_screen);

    return $error_screen;
}

=item setModel($model)

Sets the data model  for this view.

=cut

sub setModel {
    my $self = shift;
    $self->{'_model'} = shift;
}

=item getModel()

Returns the data model for this view. 

=cut

sub getModel {
    my $self = shift;
    return $self->{'_model'};
}

=item setError($form_results)

Sets an error for this view.

=cut

sub setError {
    my $self = shift;
    $self->{'_error'} = shift;
}

=item getError()

Returns the error for this view. 

=cut

sub getError {
    my $self = shift;
    return $self->{'_error'};
}

=item setPossibleTemplates(@template_names)

Sets all of the templates that might be used by the view.

=cut

sub setPossibleTemplates {
    my $self = shift;
    $self->{'_possible_templates'} = \@_;
}

=item getPossibleTemplates()

Returns the templates that this view might use.

=cut

sub getPossibleTemplates {
    my $self = shift;
    return $self->{'_possible_templates'} || [];
}

=item makeButton {

=cut

sub makeButton {
    my $self = shift;
    my $params = shift;
    my $namespace = shift;

    return undef unless defined $params;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    return $self->getButtonService($namespace)->makeButton($params);
}

=item makeStaticButton {

=cut

sub makeStaticButton {
    my $self = shift;
    my $params = shift;
    my $namespace = shift;

    return undef unless defined $params;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    return $self->getButtonService($namespace)->makeStaticButton($params);
}

=item makeFlyoutButton {

=cut

sub makeFlyoutButton {
    my $self = shift;
    my $params = shift;
    my $namespace = shift;

    return undef unless defined $params;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    return $self->getButtonService($namespace)->makeFlyoutButton($params);
}

=item makePopinButton {

=cut

sub makePopinButton {
    my $self = shift;
    my $params = shift;
    my $namespace = shift;

    return undef unless defined $params;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    return $self->getButtonService($namespace)->makePopinButton($params);
}

=item makePopupButton {

=cut

sub makePopupButton {
    my $self = shift;
    my $params = shift;
    my $namespace = shift;

    return undef unless defined $params;

    unless (defined $namespace){
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    return $self->getButtonService($namespace)->makePopupButton($params);
}

=item addSortParams($sort_service)

Adds the sorting widgets for a given sort service object.

=cut

sub addSortParams {
    my $self = shift;
    my $sort_service = shift;

    return FALSE unless defined $sort_service;

    my %sort_links = $sort_service->getSortLinks();
    foreach my $key (keys %sort_links) {
        $self->setParam($key, $sort_links{$key});
    }

    return TRUE;
}

=item paint(\$screen)

Appends the HTML code for this view to C<$screen>.

This will try to compile a paint method, if there's a path for compiled views in config.

=cut

sub paint {
    my $self = shift;
    my $screen = shift;

    no strict 'refs'; ## no critic
    my $package = ref $self;
    if (!${$package.'::'}{'_paint'}) {
        if (my $return = $self->_compilePaint($screen)) {
            return $return;
        }
    }
    else {
        return $self->_paint($screen)
    }
    return FALSE;
}

=item setParam('name', 'value')

Sets a param's value.  Multiple calls to this method will overwrite previous values.

=cut

sub setParam {
    $_[0]->{'_params'}{$_[1]} = $_[2];
#    my $self = shift;
#    my ($name, $value) = @_;
#    if (defined $name) {
#        $self->{'_params'}{$name} = $value;
#    }
}

=item setParams(\%hash)

Sets multiple values into a param.  Multiple calls will overwrite previous values.

=cut

sub setParams {
    my $self = shift;
    my $hash_ref = shift;
    foreach my $key (keys %{$hash_ref}) {
        $self->setParam($key, $hash_ref->{$key});
    }
}

=item addParam('loop_name', $data_ref)

This adds the data combo to the loop given.  Multiple calls will add multiple values.

=cut

sub addParam {
    my $self = shift;
    my ($loop, $data_ref) = @_;
    
    # Do we want this to check whether the value at $loop is an array ref?
    push @{$self->{'_params'}{$loop}}, $data_ref;
}


=item setSubView("key_name", $view_object)

This tells the view that a subview has already been created, so it should use
that instead of creating a new one.

=cut

sub setSubView {
    my $self = shift;
    my $key  = shift;
    my $view = shift;
    $self->{'_subviews'}{$key} = $view;
}

=item getSubView("key_name")

This is a method for a view to get a subview that may have already been
created.

=cut

sub getSubView {
    my $self = shift;
    my $key = shift;
    return $self->{'_subviews'}{$key};
}

=item setIsSubView()

This turns on a flag for a view, so that it knows it is not the top-level view.
By default all views will think they are top level, which impacts the way they
react upon form submission error.

=cut

sub setIsSubView {
    my $self = shift;
    $self->{'_is_subview'} = 1;
}

=item isSubView()

Returns the flag specifying whether this view is a sub view.

=cut

sub isSubView {
    my $self = shift;
    return $self->{'_is_subview'};
}

=item setSubViewHasError()

This sets a flag that says a subview has an error.  This makes it so the top
level view can show a more global error message.

=cut

sub setSubViewHasError {
    my $self = shift;
    $self->{'_subview_error'} = 1;
}

=item subViewHasError()

Returns a flag saying whether a subview has an error.

=cut

sub subViewHasError {
    my $self = shift;
    return $self->{'_subview_error'};
}

=item createChildViewList( 'loop_name', 'var_name' )

=cut

sub createChildViewList {
    my ($self, $loop, $name) = @_;

    return undef unless ($loop && $name);

    my $list = Solstice::List->new();

    ${$self->{'_child_views'}}{$loop} = {
        name    => $name,
        value   => $list->getAll(),
    };
    ${$self->{'_child_views'}}{$loop}{'loop'} = TRUE;

    return $list;
}

=item addChildView()

=cut


sub addChildView {
    my $self = shift;
    if(scalar @_ == 3){
        my ($loop, $name, $value) = @_;
        ${$self->{'_child_views'}}{$loop} = { name => $name, value => $value};
        ${$self->{'_child_views'}}{$loop}{'loop'} = TRUE;
    }else{
        my ($name, $value) = @_;
        
        unless (defined $value) {
            my $config = $self->getConfigService();
            if($config->getDevelopmentMode()){
                $self->warn('Tried to add an undefined child view');
            }
            return FALSE;
        }
        
        ${$self->{'_child_views'}}{$name} = $value;
        ${$self->{'_child_views'}}{$name}{'loop'} = FALSE;
    }

    return TRUE;
}

=item addChildViews()

this is an alias for addChildView, since it can actually handle many views

=cut

*addChildViews = *addChildView;

=item processChildViews()

=cut

sub processChildViews {
    my $self = shift;

    return unless (defined $self->{'_child_views'});

    my %return;
    for my $key (keys %{$self->{'_child_views'}}){
        if ($self->{'_child_views'}->{$key}{'loop'} == TRUE) {
            for my $view ( @{$self->{'_child_views'}->{$key}{'value'}} ){
                my $html; 
                $view->paint(\$html);
                if (!defined $html || $html !~ /\S/) { $html = ''; }
                push @{$return{$key}}, {$self->{'_child_views'}->{$key}{'name'} => $html};
            }
        } else {
            #just a normal view
            my $html; 
            $self->{'_child_views'}->{$key}->paint(\$html);
            
            if (!defined $html || $html !~ /\S/) { $html = ''; }
            $return{$key} = $html;
        }

    }

    return %return;
}

=item generateParams()

This should fill out the params for the view, by way of setParam and addParam.

=cut

sub generateParams {
    return TRUE;  # No need to override this, if the template has no variables.
}

=item generateChildParams()

Process child views and add params to the view.

=cut

sub generateChildParams {
    my $self = shift;

    return TRUE if $self->{'_processed_child_views'};
    
    my %child_views = $self->processChildViews();
    for my $key (%child_views) {
        $self->setParam($key, $child_views{$key});
    }
    
    return $self->{'_processed_child_views'} = TRUE;
}

=back

=head2 Private Methods

=over 4

=item _setApp()

Sets the template file for this view.  The template file is assumed to live in
the relative 'templates' directory.

=cut

sub _setApp {
    my $self = shift;
    $self->{'_app'} = shift;
}

=item _getApp()

Returns the template file for this view.  The template file is assumed to live
in the relative 'templates' directory.

=cut

sub _getApp {
    my $self = shift;
    return $self->{'_app'};
}

=item _setTemplate()

Sets the template file for this view.  The template file is assumed to live in
the relative 'templates' directory.

=cut

sub _setTemplate {
    my $self = shift;
    $self->{'_template'} = shift;
}

=item _getTemplate()

Returns the template file for this view.  The template file is assumed to live
in the relative 'templates' directory.

=cut

sub _getTemplate {
    my $self = shift;
    return $self->{'_template'};
}

=item _setTemplatePath()

=cut

sub _setTemplatePath {
    my $self = shift;
    $self->{'_template_path'} = shift;
}

=item _getTemplatePath()

=cut

sub _getTemplatePath {
    my $self = shift;
    return $self->{'_template_path'};
}

=item _getPackageTemplate()

=cut

sub _getPackageTemplate {
    my $self = shift;
    my $template_var = (ref $self).'::template';

    my $template;
    { 
        no strict 'refs'; ## no critic
        $template = $$template_var;
    }
    return $template;
}

=item _getTemplateEngine()

=cut

sub _getTemplateEngine {
    my $self = shift;
    return $self->{'_tmpl_engine'};
}

=item _createTemplatePath()

This will return the path to templates.  If it's been set already, it will return 
that, otherwise it will figure it out.

=cut

sub _createTemplatePath {
    my $self = shift;
    
    my $config = Solstice::ConfigService->new();

    if (defined $self->_getTemplatePath() && $self->_getTemplatePath()) {
        my $template_path = $self->_getTemplatePath();
        if ($template_path !~ m/^\//) {
            return $config->getRoot() .'/'. $template_path;
        }
        return $template_path;

    }elsif( $config->getNoConfig() ){
        return $config->getRoot().'/templates';

    } else {
        my $app_namespace = '';
        if (defined $self->_getApp() && $self->_getApp()) {
            $app_namespace = $self->_getApp();
        } else {
            my $ns_service = Solstice::NamespaceService->new();
            $app_namespace = $ns_service->getAppNamespace();
        }
        my $config = Solstice::ConfigService->new($app_namespace);
        return $config->getAppTemplatePath();
    }
}

=item _getTemplateParams()

This will return the data for a template.  Can be overridden by old-skool view subclasses.
This handles errors for us.  Yay!

=cut

sub _getTemplateParams {
    my $self = shift;

    # Add validation errors...
    if (my $error = $self->getError()) {
        my $params = $error->getFormMessages();
        for my $key (keys %$params) {
            $self->setParam($key, $params->{$key});
        }
    }

    # Add local params...
    $self->generateParams();
    
    # Process child views...
    $self->generateChildParams();

    return $self->{'_params'};
}

=item _clearParams()

Clears out all params added or set.

=cut

sub _clearParams {
    my $self = shift;
    $self->{'_params'} = {};
}


sub isDownloadView {
    return FALSE;
}

sub sendHeaders {
    Solstice::Server->new()->setContentType('text/html; charset=UTF-8');
}




#####################
#### These methods support compiling views and caching the compiled copies
#####################

=item _templateModified() 

Determines whether the template has been modified, and recompiles if needed.

=cut

=item _compilePaint($screen)

=cut

sub _compilePaint {
    my $self = shift;
    my $screen = shift;

    my $cache_on_disk = $self->_getCompiledViewsDir() ? 1 : 0;
    my $package_name = ref $self;

    my $paint_method;
    if( $cache_on_disk ){

        if ( $self->_needsCompilation() ){
            $paint_method = $self->_buildPaintMethod();

            #put the compiled method in the on disk cache
            my $compiled_view_path = $self->_getCompiledViewPath();
            open (my $COMPILED_PAINT, ">",  "$compiled_view_path") || die "Unable to open $compiled_view_path for writing: $!\n";
            print $COMPILED_PAINT $paint_method;
            close $COMPILED_PAINT;

        }else{
            #we don't need to compile, so the one on disk is already good, pull it up
            $paint_method = $self->_loadCachedPaintMethod();
        }

    }else{
        #if we're not using an on-disk cache, build everytime
        $paint_method = $self->_buildPaintMethod();
    }

    die "No paint method could be compiled for $package_name!" unless $paint_method;

        #attach the compiled paint method to our package
        eval "$paint_method"; ## no critic
        die "$package_name failed to compile view, $@" if ($@);
        {
            no strict 'refs'; ## no critic
            *{"${package_name}::_paint"} = *{"${package_name}::Compiled::paint"};
        }

    $self->_paint($screen);

    return 1;
}


sub _needsCompilation {
    my $self = shift;
    my $compare_date = shift;

    #which compiled view are we talking about? If it's not there at all, we need to compile
    my $view_path = $self->_getCompiledViewPath();
    return TRUE unless -f $view_path;

    #don't do all this file stat-ing if dev mode is off
    return FALSE unless $check_template_freshness;

    #we need a list of all possible templates to check for modifications
    #so add the singular to the possible templates list
    my $tmpl_path = $self->_createTemplatePath() || '';
    my $template  = $self->_getTemplate();

    if (!defined $template) {
        my $class = ref($self);
        $self->warn("No template specified for view subclass $class. Add this line to $class: our \$template = 'path/to/template.html'; called");
        return TRUE;
    }

    my @possible_templates = $self->getPossibleTemplates();
    push @possible_templates, $template;

    foreach my $tmpl_file (@possible_templates) {

        my $full_path = $tmpl_path .'/'. $tmpl_file;
        my $template_mod_date = (stat($full_path))[9];

        next unless defined $template_mod_date;
        return TRUE if ((stat($view_path))[9] < $template_mod_date);
        if($compare_date){
            return TRUE if $compare_date < $template_mod_date;
        }
    }

    return FALSE;
}

sub _buildPaintMethod {
    my $self = shift;

    my $compiler = Solstice::Compiler::View->new();

    my $paint_method = $compiler->makePaintMethod($self);

    if (!defined $paint_method) {
        die "Could not generate paint method for ". ref $self;
    }

    my $package_name = ref $self;
    $paint_method = "package ${package_name}::Compiled;\n$paint_method\n\n1;";

    return $paint_method;
}


sub _loadCachedPaintMethod {
    my $self = shift;
    my $compiled_view_path = $self->_getCompiledViewPath();

    open (my $PAINT, '<',$compiled_view_path);
    my $method = join("\n", <$PAINT>);
    close $PAINT;

    return $method;
}


sub _getCompiledViewsDir {
    my $self = shift;

    my $config = $self->getConfigService();
    my $compiled_path = $config->getCompiledViewPath() ? $config->getCompiledViewPath() : undef;

    # Make sure the directory exists and is writable
    if($compiled_path && !$self->_checkCompiledViewsDir($compiled_path)){
        undef $compiled_path;
    }

    return $compiled_path;
}


sub _checkCompiledViewsDir {
    my $self = shift;
    my $path = shift;

    return unless defined $path;

    my $service = Solstice::Service::Memory->new();
    my $path_exists = $service->get(COMPILED_PATH_KEY.'_path_exists__'.$path);
    if (!defined $path_exists) {
        if (!-e $path) {
            mkpath($path, 0, oct('0711'));
        }
        if (!-d $path) {
            die "$path is not a directory";
        }
        if (!-w $path) {
            die "$path is not writeable";
        }
        $service->set(COMPILED_PATH_KEY.'_path_exists__'.$path, TRUE);
    }
    return TRUE;
}

sub _getCompiledViewPath {
    my $self = shift;

    #where would this specific compiled view live?
    my $view_path = ref $self;
    $view_path =~ s/::/_/g;
    $view_path .= '.cmpl';
    $view_path = $self->_getCompiledViewsDir()."/$view_path";

    return $view_path;
}



1;

__END__

=back

=head2 Modules Used

L<Solstice::View::MessageService|Solstice::View::MessageService>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



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
